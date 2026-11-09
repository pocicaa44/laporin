# Laporin — Entity Relationship Diagram (ERD)

Dokumen ini memvisualisasikan arsitektur relasional database **Laporin** menggunakan diagram Mermaid resmi beserta kardinalitas dan relasi foreign key.

---

## 1. Diagram Relasi Entitas

```mermaid
erDiagram
    AUTH_USERS ||--|| PROFILES : "1-to-1 auth sync"
    ADMINISTRATIVE_REGIONS ||--o{ ADMINISTRATIVE_REGIONS : "parent-child hierarchy"
    
    PROFILES ||--o{ REPORTS : "authors"
    PROFILES ||--o{ VOTES : "casts"
    PROFILES ||--o{ COMMENTS : "writes"
    PROFILES ||--o{ ANNOUNCEMENTS : "publishes (admin only)"
    PROFILES ||--o{ DEVICE_TOKENS : "registers"
    PROFILES ||--o{ NOTIFICATIONS : "receives"

    ADMINISTRATIVE_REGIONS ||--o{ REPORTS : "province_id"
    ADMINISTRATIVE_REGIONS ||--o{ REPORTS : "city_id"
    ADMINISTRATIVE_REGIONS ||--o{ REPORTS : "district_id"
    ADMINISTRATIVE_REGIONS ||--o{ REPORTS : "village_id"

    REPORTS ||--o{ VOTES : "collects"
    REPORTS ||--o{ COMMENTS : "hosts"
    REPORTS ||--o{ NOTIFICATIONS : "references"

    COMMENTS ||--o{ COMMENTS : "parent_comment (nested reply)"

    PROFILES {
        uuid id PK "references auth.users(id)"
        text username UK "unique citizen handle"
        text full_name "display name"
        text avatar_url "compressed avatar link"
        text role "user | admin"
        text_array assigned_area_ids "for officer delegation"
        timestamptz created_at
        timestamptz updated_at
    }

    ADMINISTRATIVE_REGIONS {
        uuid id PK "gen_random_uuid()"
        varchar code UK "Kemendagri / BPS code"
        varchar name "region name"
        varchar level "country | province | regency | district | village"
        uuid parent_id FK "references administrative_regions(id)"
        geometry boundary "MultiPolygon SRID 4326"
        geography center_point "Point SRID 4326"
        varchar source "BPS / KEMENDAGRI"
        varchar boundary_status "verified | pending"
        timestamptz created_at
        timestamptz updated_at
    }

    REPORTS {
        text id PK "client or gen_random_uuid()"
        varchar report_number UK "LPR-YYYY-XXXX"
        text author_id FK "references profiles(id)"
        text author_name "snapshot author name"
        text author_username "snapshot @username"
        text author_avatar_url "snapshot avatar link"
        text title "issue title"
        text description "detailed issue text"
        text category "infrastructure category"
        float8 latitude "decimal latitude"
        float8 longitude "decimal longitude"
        geography location "Point SRID 4326 (PostGIS)"
        text location_address "reverse-geocoded address"
        uuid province_id FK "references administrative_regions(id)"
        uuid city_id FK "references administrative_regions(id)"
        uuid district_id FK "references administrative_regions(id)"
        uuid village_id FK "references administrative_regions(id)"
        text area_id "e.g. area-33"
        text area_name "e.g. Jawa Tengah"
        text handling_status "new | accepted | in_progress | completed | rejected | cancelled"
        text publication_state "pending_review | published | held | archived"
        text_array photo_urls "evidence photo URLs"
        int4 upvotes_count "cached upvote count"
        int4 downvotes_count "cached downvote count"
        int4 comments_count "cached comment count"
        text rejection_reason "reason if rejected"
        text moderation_reason "reason if held"
        text completion_proof_url "completion photo URL"
        text completion_proof_type "image"
        text completion_notes "field officer notes"
        bool is_discussion_active "comment active toggle"
        bool is_draft "draft status flag"
        bool deleted_by_user "user deletion flag"
        timestamptz deleted_by_user_at
        bool deleted_by_admin "admin deletion flag"
        timestamptz deleted_by_admin_at
        timestamptz published_at
        timestamptz terminal_at
        timestamptz archive_after
        timestamptz deleted_at
        timestamptz created_at
        timestamptz updated_at
    }

    VOTES {
        uuid id PK "gen_random_uuid()"
        text report_id FK "references reports(id)"
        uuid user_id FK "references profiles(id)"
        text vote_type "up | down"
        timestamptz created_at
        timestamptz updated_at
    }

    COMMENTS {
        text id PK "gen_random_uuid()"
        text report_id FK "references reports(id)"
        text author_id FK "references profiles(id)"
        text author_name "author display name"
        text author_avatar_url "author avatar link"
        text author_role "user | admin"
        text body "comment message body"
        text parent_comment_id FK "nested thread link"
        timestamptz created_at
        timestamptz updated_at
        timestamptz deleted_at
    }

    ANNOUNCEMENTS {
        uuid id PK "gen_random_uuid()"
        text title "announcement title"
        text content "full announcement text"
        text category "Umum | Darurat | dsb"
        uuid author_id FK "references profiles(id)"
        text author_name "admin name"
        text image_url "optional banner link"
        bool is_published "broadcast visibility"
        timestamptz created_at
        timestamptz updated_at
    }

    DEVICE_TOKENS {
        uuid id PK "gen_random_uuid()"
        uuid user_id FK "references profiles(id)"
        text token UK "FCM registration token"
        text platform "android | ios | web"
        timestamptz created_at
        timestamptz updated_at
    }

    NOTIFICATIONS {
        uuid id PK "gen_random_uuid()"
        uuid user_id FK "references profiles(id)"
        text title "notification headline"
        text message "notification content"
        text type "status_changed | announcement | comment"
        text report_id FK "references reports(id)"
        bool is_read "read status flag"
        timestamptz created_at
    }

    NOTIFICATION_QUEUE {
        uuid id PK "gen_random_uuid()"
        text event_type "report_status_changed | broadcast"
        jsonb payload "FCM delivery parameters"
        text status "pending | processing | completed | failed"
        timestamptz created_at
        timestamptz processed_at
        text error_message
    }
```

---

## 2. Ringkasan Kardinalitas & Referential Integrity

| Relasi | Tipe Kardinalitas | Aturan Hapus (ON DELETE) | Penjelasan Integritas |
| :--- | :---: | :---: | :--- |
| `auth.users` $\rightarrow$ `profiles` | 1 to 1 | `CASCADE` | Profil akun terhapus bersih saat akun user dihapus dari auth. |
| `administrative_regions` $\rightarrow$ `administrative_regions` | 1 to Many | `RESTRICT` | Wilayah induk tidak dapat dihapus jika masih membawahi wilayah turunan. |
| `administrative_regions` $\rightarrow$ `reports` | 1 to Many | `SET NULL` | Laporan tetap utuh bila kode wilayah direstrukturisasi/dimekarkan. |
| `profiles` $\rightarrow$ `reports` | 1 to Many | `CASCADE` | Laporan terikat langsung dengan profil pembuat. |
| `reports` $\rightarrow$ `votes` | 1 to Many | `CASCADE` | Seluruh vote laporan terhapus saat laporan dihapus permanen. |
| `profiles` $\rightarrow$ `votes` | 1 to Many | `CASCADE` | Vote terhapus bila profil pemilik vote dihapus. |
| `reports` $\rightarrow$ `comments` | 1 to Many | `CASCADE` | Seluruh komentar terhapus bila laporan dihapus permanen. |
| `comments` $\rightarrow$ `comments` | 1 to Many | `CASCADE` | Balasan komentar bertingkat terhapus bila komentar induk dihapus. |
| `profiles` $\rightarrow$ `announcements`| 1 to Many | `CASCADE` | Pengumuman terikat pada admin pembuat. |
| `profiles` $\rightarrow$ `device_tokens` | 1 to Many | `CASCADE` | Token FCM perangkat terhapus saat akun pengguna dihapus. |
| `profiles` $\rightarrow$ `notifications` | 1 to Many | `CASCADE` | Inbox notifikasi terhapus saat akun pengguna dihapus. |
| `reports` $\rightarrow$ `notifications` | 1 to Many | `CASCADE` | Notifikasi terkait laporan terhapus bila laporan terhapus permanen. |

