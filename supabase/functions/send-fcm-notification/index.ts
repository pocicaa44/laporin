// Supabase Edge Function: send-fcm-notification
// FCM HTTP v1 Sender with Google Service Account OAuth2 Authentication
// Sesuai PRD.md Bagian 10, AGENTS.md Invarian & Aturan Keamanan Supabase

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const UUID_REGEX =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

interface ServiceAccountConfig {
  project_id: string;
  client_email: string;
  private_key: string;
}

interface NotificationResult {
  sentCount: number;
  failedCount: number;
  invalidTokens: string[];
}

// 1. Helper: Mengambil kredensial Firebase Service Account dari Supabase Secrets
function getFirebaseConfig(): ServiceAccountConfig | null {
  const saJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (saJson && saJson.trim().length > 0) {
    try {
      const parsed = JSON.parse(saJson);
      if (parsed.client_email && parsed.private_key && parsed.project_id) {
        return {
          project_id: parsed.project_id,
          client_email: parsed.client_email,
          private_key: parsed.private_key.replace(/\\n/g, "\n"),
        };
      }
    } catch (e) {
      console.error("Gagal parse FIREBASE_SERVICE_ACCOUNT JSON secret:", e);
    }
  }

  const projectId = Deno.env.get("FIREBASE_PROJECT_ID") || "laporin-4b090";
  const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
  const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");

  if (clientEmail && privateKey) {
    return {
      project_id: projectId,
      client_email: clientEmail,
      private_key: privateKey.replace(/\\n/g, "\n"),
    };
  }

  return null;
}

// 2. Helper: Base64 & Base64Url Encoding yang aman dari Call Stack Overflow
function bytesToBase64(bytes: Uint8Array): string {
  let binary = "";
  const len = bytes.byteLength;
  const chunkSize = 8192;
  for (let i = 0; i < len; i += chunkSize) {
    const chunk = bytes.subarray(i, Math.min(i + chunkSize, len));
    binary += String.fromCharCode.apply(null, chunk as unknown as number[]);
  }
  return btoa(binary);
}

function base64UrlEncode(input: string | Uint8Array): string {
  const bytes =
    typeof input === "string" ? new TextEncoder().encode(input) : input;
  const base64 = bytesToBase64(bytes);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// 3. Helper: Pembuatan & Caching Google OAuth 2.0 Access Token
let cachedAccessToken: string | null = null;
let tokenExpiresAt = 0;

async function getGoogleAccessToken(
  config: ServiceAccountConfig
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedAccessToken && tokenExpiresAt > now + 60) {
    return cachedAccessToken;
  }

  const pemContents = config.private_key
    .replace(/-----BEGIN[ A-Z0-9_-]+-----/g, "")
    .replace(/-----END[ A-Z0-9_-]+-----/g, "")
    .replace(/[\r\n\s]/g, "");

  const binaryDerString = atob(pemContents);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: config.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaim = base64UrlEncode(JSON.stringify(claim));
  const signingInput = `${encodedHeader}.${encodedClaim}`;

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  const jwt = `${signingInput}.${base64UrlEncode(new Uint8Array(signature))}`;

  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!tokenResponse.ok) {
    const errorText = await tokenResponse.text();
    throw new Error(`Google OAuth2 token request failed: ${errorText}`);
  }

  const tokenData = await tokenResponse.json();
  cachedAccessToken = tokenData.access_token;
  tokenExpiresAt = now + (tokenData.expires_in || 3600);
  return cachedAccessToken;
}

// 4. Helper: Mengirim pesan FCM HTTP v1 ke satu token
async function sendSingleFcm(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data: Record<string, unknown>
): Promise<{ ok: boolean; status: number; unregistered?: boolean; error?: string }> {
  const fcmUrl = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

  // FCM HTTP v1 mewajibkan seluruh value pada message.data bertipe string
  const stringData: Record<string, string> = {
    click_action: "FLUTTER_NOTIFICATION_CLICK",
    title: title,
    body: body,
  };
  for (const [key, val] of Object.entries(data)) {
    if (val !== undefined && val !== null) {
      stringData[key] = String(val);
    }
  }

  const payload = {
    message: {
      token: token,
      notification: {
        title: title,
        body: body,
      },
      data: stringData,
      android: {
        priority: "high",
        notification: {
          channel_id: "laporin_channel",
          sound: "default",
          notification_priority: "PRIORITY_HIGH",
        },
      },
    },
  };

  try {
    const response = await fetch(fcmUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (response.ok) {
      return { ok: true, status: response.status };
    }

    const errBody = await response.text();
    console.error(`[FCM Error] HTTP ${response.status}:`, errBody);

    const isUnregistered =
      response.status === 404 ||
      errBody.includes("UNREGISTERED") ||
      errBody.includes("registration-token-not-registered");

    return {
      ok: false,
      status: response.status,
      unregistered: isUnregistered,
      error: errBody,
    };
  } catch (err) {
    return {
      ok: false,
      status: 500,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

// 5. Helper: Batch Concurrent Sender dengan batasan concurrency (20 token per chunk)
async function sendFcmBatch(
  accessToken: string,
  projectId: string,
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, unknown>
): Promise<NotificationResult> {
  const uniqueTokens = Array.from(new Set(tokens.filter((t) => t && t.trim().length > 0)));
  if (uniqueTokens.length === 0) {
    return { sentCount: 0, failedCount: 0, invalidTokens: [] };
  }

  let sentCount = 0;
  let failedCount = 0;
  const invalidTokens: string[] = [];

  const BATCH_SIZE = 20;
  for (let i = 0; i < uniqueTokens.length; i += BATCH_SIZE) {
    const batch = uniqueTokens.slice(i, i + BATCH_SIZE);
    const results = await Promise.allSettled(
      batch.map((tok) =>
        sendSingleFcm(accessToken, projectId, tok, title, body, data)
      )
    );

    for (let j = 0; j < results.length; j++) {
      const res = results[j];
      const tok = batch[j];
      if (res.status === "fulfilled" && res.value.ok) {
        sentCount++;
      } else {
        failedCount++;
        if (res.status === "fulfilled" && res.value.unregistered) {
          invalidTokens.push(tok);
        }
      }
    }
  }

  return { sentCount, failedCount, invalidTokens };
}

// 6. Logic Handler Report Status (Strict DRY)
async function handleReportStatusChanged(
  supabase: SupabaseClient,
  accessToken: string,
  projectId: string,
  reportId: string
): Promise<NotificationResult> {
  const { data: report, error: repErr } = await supabase
    .from("reports")
    .select("id, report_number, author_id, title, handling_status, rejection_reason")
    .eq("id", reportId)
    .maybeSingle();

  if (repErr || !report) {
    throw new Error(`Report not found: ${reportId}`);
  }

  // Validasi format UUID author_id sebelum query ke device_tokens (menghindari error 22P02 Postgres)
  if (!report.author_id || !UUID_REGEX.test(report.author_id)) {
    console.warn(`report.author_id '${report.author_id}' bukan UUID valid, melewati pengiriman.`);
    return { sentCount: 0, failedCount: 0, invalidTokens: [] };
  }

  const statusLabels: Record<string, string> = {
    accepted: "diterima",
    in_progress: "diproses",
    completed: "selesai",
    rejected: "ditolak",
    cancelled: "dibatalkan",
    new: "baru",
  };

  const statusLabel = statusLabels[report.handling_status] || report.handling_status;
  let title = "Status laporan Anda diperbarui!";
  let notifBody = `Laporan ${report.title} ${statusLabel}`;

  if (report.handling_status === "completed") {
    title = "Laporan Anda telah diselesaikan!";
    notifBody = `Laporan ${report.title} telah selesai ditangani. Terima kasih atas partisipasi Anda!`;
  } else if (report.handling_status === "rejected") {
    title = "Laporan Anda ditolak!";
    notifBody = `Laporan ${report.title} tidak dapat diproses${report.rejection_reason ? `: ${report.rejection_reason}` : "."}`;
  }

  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("token")
    .eq("user_id", report.author_id);

  const tokenList = (tokens || []).map((t: { token: string }) => t.token);
  return await sendFcmBatch(accessToken, projectId, tokenList, title, notifBody, {
    type: "report_status_changed",
    report_id: report.id,
    handling_status: report.handling_status,
  });
}

// 7. Logic Handler Announcement (Strict DRY)
async function handleAnnouncementPublished(
  supabase: SupabaseClient,
  accessToken: string,
  projectId: string,
  announcementId: string
): Promise<NotificationResult> {
  if (!UUID_REGEX.test(announcementId)) {
    throw new Error(`announcement_id '${announcementId}' bukan UUID valid`);
  }

  const { data: announcement, error: annErr } = await supabase
    .from("announcements")
    .select("id, title, content, is_published")
    .eq("id", announcementId)
    .maybeSingle();

  if (annErr || !announcement || !announcement.is_published) {
    throw new Error(`Announcement not found or not published: ${announcementId}`);
  }

  const title = "Pengumuman baru diterbitkan!";
  const preview = announcement.title || "Lihat pengumuman sekarang.";

  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("token");

  const tokenList = (tokens || []).map((t: { token: string }) => t.token);
  return await sendFcmBatch(accessToken, projectId, tokenList, title, preview, {
    type: "announcement_published",
    announcement_id: announcement.id,
  });
}

// 8. Generic Dispatcher for Direct & Triggered Payloads (Strict DRY)
async function dispatchNotificationFromPayload(
  supabase: SupabaseClient,
  accessToken: string,
  projectId: string,
  payload: Record<string, any>
): Promise<NotificationResult> {
  const title = payload.title || "Notifikasi Baru";
  const body = payload.body || "";
  const data = payload.data || {};
  let tokenList: string[] = [];

  if (payload.target_role === "admin") {
    const { data: adminProfiles } = await supabase
      .from("profiles")
      .select("id")
      .eq("role", "admin");
    const adminIds = (adminProfiles || []).map((p: { id: string }) => p.id);
    if (adminIds.length > 0) {
      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("token")
        .in("user_id", adminIds);
      tokenList = (tokens || []).map((t: { token: string }) => t.token);
    }
  } else if (Array.isArray(payload.recipient_user_ids) && payload.recipient_user_ids.length > 0) {
    const validUuids = payload.recipient_user_ids.filter((id: string) => UUID_REGEX.test(id));
    if (validUuids.length > 0) {
      const { data: tokens } = await supabase
        .from("device_tokens")
        .select("token")
        .in("user_id", validUuids);
      tokenList = (tokens || []).map((t: { token: string }) => t.token);
    }
  } else if (payload.broadcast === true) {
    const { data: tokens } = await supabase
      .from("device_tokens")
      .select("token");
    tokenList = (tokens || []).map((t: { token: string }) => t.token);
  }

  return await sendFcmBatch(accessToken, projectId, tokenList, title, body, data);
}

// 8. Entry point utama Edge Function
Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseServiceKey) {
      return new Response(
        JSON.stringify({ error: "Supabase environment not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Verifikasi Otorisasi Caller (Mendukung Bearer Authorization atau apikey header)
    const authHeader = req.headers.get("Authorization") || req.headers.get("authorization");
    const apiKeyHeader = req.headers.get("apikey");
    const token = (authHeader ? authHeader.replace(/^Bearer\s+/i, "") : apiKeyHeader)?.trim();

    if (!token) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization or apikey header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let isServiceRole = false;
    if (
      supabaseServiceKey &&
      (token === supabaseServiceKey.trim() || apiKeyHeader?.trim() === supabaseServiceKey.trim())
    ) {
      isServiceRole = true;
    } else {
      // Verifikasi apakah caller membawa service_role JWT Supabase
      for (const candidate of [token, apiKeyHeader]) {
        if (!candidate) continue;
        try {
          const raw = candidate.replace(/^Bearer\s+/i, "").trim();
          const parts = raw.split(".");
          if (parts.length === 3) {
            let base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
            while (base64.length % 4 !== 0) {
              base64 += "=";
            }
            const payload = JSON.parse(atob(base64));
            if (
              payload.role === "service_role" &&
              (payload.ref === "ecgnhfkzvivddgbbfajx" || payload.iss === "supabase")
            ) {
              isServiceRole = true;
              break;
            }
          }
        } catch (_) {
          // ignore non-jwt parsing error
        }
      }
    }

    if (!isServiceRole) {
      const {
        data: { user },
        error: userErr,
      } = await supabase.auth.getUser(token);
      if (userErr || !user) {
        return new Response(
          JSON.stringify({ error: "Unauthorized user" }),
          { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Verifikasi role user harus admin
      const { data: profile } = await supabase
        .from("profiles")
        .select("role")
        .eq("id", user.id)
        .maybeSingle();

      if (profile?.role !== "admin") {
        return new Response(
          JSON.stringify({ error: "Forbidden: Admin access required" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // Ambil kredensial Firebase
    const fbConfig = getFirebaseConfig();
    if (!fbConfig) {
      return new Response(
        JSON.stringify({
          error:
            "Firebase Service Account belum dikonfigurasi di Supabase Secrets (FIREBASE_SERVICE_ACCOUNT atau FIREBASE_CLIENT_EMAIL & FIREBASE_PRIVATE_KEY)",
        }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json().catch(() => ({}));
    const eventType =
      body.event ||
      body.event_type ||
      (body.record ? body.record.event_type : null);
    const eventPayload = body.payload || body.record?.payload || body;
    const webhookQueueRecordId = body.record?.id;

    const accessToken = await getGoogleAccessToken(fbConfig);

    let totalResult: NotificationResult = {
      sentCount: 0,
      failedCount: 0,
      invalidTokens: [],
    };

    if (eventPayload.title && eventPayload.body) {
      try {
        totalResult = await dispatchNotificationFromPayload(
          supabase,
          accessToken,
          fbConfig.project_id,
          eventPayload
        );
        if (webhookQueueRecordId) {
          await supabase
            .from("notification_queue")
            .update({ status: "processed", processed_at: new Date().toISOString() })
            .eq("id", webhookQueueRecordId);
        }
      } catch (err) {
        if (webhookQueueRecordId) {
          await supabase
            .from("notification_queue")
            .update({
              status: "failed",
              error_message: err instanceof Error ? err.message : String(err),
            })
            .eq("id", webhookQueueRecordId);
        }
        throw err;
      }
    } else if (eventType === "report_status_changed") {
      const reportId = eventPayload.report_id;
      if (!reportId) {
        return new Response(
          JSON.stringify({ error: "Missing report_id in payload" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      try {
        totalResult = await handleReportStatusChanged(
          supabase,
          accessToken,
          fbConfig.project_id,
          reportId
        );
        if (webhookQueueRecordId) {
          await supabase
            .from("notification_queue")
            .update({ status: "processed", processed_at: new Date().toISOString() })
            .eq("id", webhookQueueRecordId);
        }
      } catch (err) {
        if (webhookQueueRecordId) {
          await supabase
            .from("notification_queue")
            .update({
              status: "failed",
              error_message: err instanceof Error ? err.message : String(err),
            })
            .eq("id", webhookQueueRecordId);
        }
        throw err;
      }
    } else if (eventType === "announcement_published") {
      const announcementId = eventPayload.announcement_id;
      if (!announcementId) {
        return new Response(
          JSON.stringify({ error: "Missing announcement_id in payload" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      try {
        totalResult = await handleAnnouncementPublished(
          supabase,
          accessToken,
          fbConfig.project_id,
          announcementId
        );
        if (webhookQueueRecordId) {
          await supabase
            .from("notification_queue")
            .update({ status: "processed", processed_at: new Date().toISOString() })
            .eq("id", webhookQueueRecordId);
        }
      } catch (err) {
        if (webhookQueueRecordId) {
          await supabase
            .from("notification_queue")
            .update({
              status: "failed",
              error_message: err instanceof Error ? err.message : String(err),
            })
            .eq("id", webhookQueueRecordId);
        }
        throw err;
      }
    } else if (eventType === "process_queue" || body.type === "process_queue") {
      const { data: queueItems } = await supabase
        .from("notification_queue")
        .select("*")
        .eq("status", "pending")
        .order("created_at", { ascending: true })
        .limit(20);

      if (queueItems && queueItems.length > 0) {
        for (const item of queueItems) {
          try {
            let itemResult: NotificationResult = { sentCount: 0, failedCount: 0, invalidTokens: [] };
            if (item.payload?.title && item.payload?.body) {
              itemResult = await dispatchNotificationFromPayload(
                supabase,
                accessToken,
                fbConfig.project_id,
                item.payload
              );
            } else if (item.event_type === "report_status_changed") {
              itemResult = await handleReportStatusChanged(
                supabase,
                accessToken,
                fbConfig.project_id,
                item.payload.report_id
              );
            } else if (item.event_type === "announcement_published") {
              itemResult = await handleAnnouncementPublished(
                supabase,
                accessToken,
                fbConfig.project_id,
                item.payload.announcement_id
              );
            }

            totalResult.sentCount += itemResult.sentCount;
            totalResult.failedCount += itemResult.failedCount;
            totalResult.invalidTokens.push(...itemResult.invalidTokens);

            await supabase
              .from("notification_queue")
              .update({ status: "processed", processed_at: new Date().toISOString() })
              .eq("id", item.id);
          } catch (itemErr) {
            await supabase
              .from("notification_queue")
              .update({
                status: "failed",
                error_message: itemErr instanceof Error ? itemErr.message : String(itemErr),
              })
              .eq("id", item.id);
          }
        }
      }
    } else {
      return new Response(
        JSON.stringify({ error: `Unknown event type: ${eventType}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Bersihkan token invalid yang sudah tidak terdaftar di FCM
    const uniqueInvalid = Array.from(new Set(totalResult.invalidTokens));
    if (uniqueInvalid.length > 0) {
      await supabase
        .from("device_tokens")
        .delete()
        .in("token", uniqueInvalid);
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent_count: totalResult.sentCount,
        failed_count: totalResult.failedCount,
        cleaned_invalid_tokens: uniqueInvalid.length,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Unhandled error in send-fcm-notification:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Internal Server Error",
      }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
