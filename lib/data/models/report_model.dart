/// Status penanganan laporan sesuai PRD.md Bagian 5.1 & AGENTS.md Invarian 3.1
enum HandlingStatus {
  newReport('new', 'Baru'),
  accepted('accepted', 'Diterima'),
  inProgress('in_progress', 'Diproses'),
  completed('completed', 'Selesai'),
  rejected('rejected', 'Ditolak'),
  cancelled('cancelled', 'Dibatalkan');

  const HandlingStatus(this.value, this.label);
  final String value;
  final String label;

  static HandlingStatus fromString(String? val) {
    return HandlingStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => HandlingStatus.newReport,
    );
  }
}

/// Status publikasi / moderasi sesuai PRD.md Bagian 5.2 & AGENTS.md Invarian 3.1
enum PublicationState {
  pendingReview('pending_review', 'Menunggu Review'),
  published('published', 'Dipublikasikan'),
  held('held', 'Perlu Review'),
  archived('archived', 'Diarsipkan');

  const PublicationState(this.value, this.label);
  final String value;
  final String label;

  static PublicationState fromString(String? val) {
    return PublicationState.values.firstWhere(
      (e) => e.value == val,
      orElse: () => PublicationState.published,
    );
  }
}

/// Model data utama laporan yang menggabungkan kebutuhan PRD & DESIGN
class ReportModel {
  const ReportModel({
    required this.id,
    required this.reportNumber,
    required this.authorId,
    required this.authorName,
    this.authorUsername,
    this.authorAvatarUrl,
    required this.areaId,
    required this.areaName,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.locationAddress,
    required this.handlingStatus,
    required this.publicationState,
    this.rejectionReason,
    this.moderationReason,
    this.publishedAt,
    this.terminalAt,
    this.archiveAfter,
    this.deletedAt,
    this.deletedByUser = false,
    this.deletedByUserAt,
    this.deletedByAdmin = false,
    this.deletedByAdminAt,
    required this.createdAt,
    required this.updatedAt,
    this.upvotesCount = 0,
    this.downvotesCount = 0,
    this.commentsCount = 0,
    this.currentUserVote,
    this.photoUrls = const [],
    this.completionProofUrl,
    this.completionProofType,
    this.completionNotes,
    this.isDiscussionActive = true,
    this.isDraft = false,
    this.isPrivate = false,
    this.provinceId,
  });

  final String id;
  final String reportNumber;
  final String authorId;
  final String authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String areaId;
  final String areaName;
  final String? provinceId;
  final String title;
  final String description;
  final String category;
  final double latitude;
  final double longitude;
  final String locationAddress;
  final HandlingStatus handlingStatus;
  final PublicationState publicationState;
  final String? rejectionReason;
  final String? moderationReason;
  final DateTime? publishedAt;
  final DateTime? terminalAt;
  final DateTime? archiveAfter;
  final DateTime? deletedAt;
  final bool deletedByUser;
  final DateTime? deletedByUserAt;
  final bool deletedByAdmin;
  final DateTime? deletedByAdminAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int upvotesCount;
  final int downvotesCount;
  final int commentsCount;
  final String? currentUserVote; // 'up', 'down', null
  final List<String> photoUrls;
  final String? completionProofUrl;
  final String? completionProofType;
  final String? completionNotes;
  final bool isDiscussionActive;
  final bool isDraft;
  final bool isPrivate;

  /// Formatted username (e.g. '@budi_santoso') with fallback if username not set
  String get displayAuthorUsername {
    if (authorUsername != null && authorUsername!.trim().isNotEmpty) {
      final clean = authorUsername!.trim().replaceFirst('@', '');
      return '@$clean';
    }
    if (authorName.trim().isNotEmpty && authorName != 'Warga Laporin') {
      final clean = authorName.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '_',
      );
      return '@$clean';
    }
    return '@warga_laporin';
  }

  /// Apakah laporan telah di-soft-delete (oleh user atau admin atau deletedAt diisi)
  bool get isDeleted => deletedAt != null || deletedByUser || deletedByAdmin;

  /// Apakah laporan telah dihapus oleh pelapor (user)
  bool get isDeletedByUser => deletedByUser;

  /// Apakah laporan telah dihapus oleh admin
  bool get isDeletedByAdmin => deletedByAdmin;

  /// Apakah laporan telah dihapus oleh KEDUA belah pihak (syarat hapus permanen)
  bool get isPermanentlyDeleted => deletedByUser && deletedByAdmin;

  /// Aturan visibilitas publik mutlak (PRD 5.4 & AGENTS.md 3.2):
  /// Tidak tampil publik jika bersifat privat, dihapus oleh salah satu pihak, sedang draft, atau terminal/rejected/cancelled
  bool get isPubliclyVisible =>
      !isPrivate &&
      !isDeleted &&
      !deletedByUser &&
      !deletedByAdmin &&
      !isDraft &&
      publicationState == PublicationState.published &&
      handlingStatus != HandlingStatus.rejected &&
      handlingStatus != HandlingStatus.cancelled;

  /// Apakah laporan telah mencapai status terminal
  bool get isTerminal =>
      isDeleted ||
      handlingStatus == HandlingStatus.rejected ||
      handlingStatus == HandlingStatus.cancelled;

  /// Aturan interaksi voting:
  /// Upvote & downvote hanya aktif jika laporan publik, bukan privat, belum dihapus,
  /// dan status BUKAN completed (selesai) atau rejected (ditolak).
  bool get isVotingActive =>
      !isPrivate &&
      isPubliclyVisible &&
      !isDeleted &&
      handlingStatus != HandlingStatus.completed &&
      handlingStatus != HandlingStatus.rejected &&
      handlingStatus != HandlingStatus.cancelled;

  /// Aturan diskusi komentar:
  /// Komentar baru hanya dapat dikirim jika laporan publik, bukan privat, belum dihapus,
  /// status bukan rejected/cancelled, dan diskusi dalam keadaan aktif (isDiscussionActive).
  bool get canAddComment =>
      !isPrivate &&
      isPubliclyVisible &&
      !isDeleted &&
      handlingStatus != HandlingStatus.rejected &&
      handlingStatus != HandlingStatus.cancelled &&
      isDiscussionActive;

  /// Aturan pengeditan laporan oleh pemilik (author/user):
  /// - Laporan berstatus 'completed' (selesai) atau 'rejected' (ditolak) bersifat IMMUTABLE.
  /// - Laporan yang sudah dihapus (isDeleted) atau dibatalkan (cancelled) juga tidak dapat diedit.
  /// - Hanya laporan aktif berstatus newReport, accepted, atau inProgress yang dapat diedit.
  bool get canEdit {
    if (isDeleted) return false;
    if (handlingStatus == HandlingStatus.completed ||
        handlingStatus == HandlingStatus.rejected ||
        handlingStatus == HandlingStatus.cancelled) {
      return false;
    }
    return true;
  }

  /// Alasan/keterangan mengapa laporan tidak dapat diedit
  String? get cannotEditReason {
    if (isDeleted) return 'Laporan yang sudah dihapus tidak dapat diedit.';
    if (handlingStatus == HandlingStatus.completed) {
      return 'Laporan berstatus selesai tidak dapat diedit.';
    }
    if (handlingStatus == HandlingStatus.rejected) {
      return 'Laporan yang ditolak tidak dapat diedit.';
    }
    if (handlingStatus == HandlingStatus.cancelled) {
      return 'Laporan yang dibatalkan tidak dapat diedit.';
    }
    return null;
  }

  /// Aturan penghapusan laporan oleh pemilik (author/user):
  /// - Jika sudah dihapus oleh user (atau deletedAt sudah terisi): TIDAK DAPAT dihapus lagi.
  /// - Jika sudah dihapus oleh admin: BISA dihapus untuk menyelesaikan penghapusan permanen dua pihak.
  /// - Status baru dipublikasikan (newReport): BISA dihapus oleh pelapor.
  /// - Status draft: BISA dihapus oleh pelapor.
  /// - Status ditolak, selesai, atau dibatalkan: BISA dihapus dengan confirmation dialog.
  /// - Status diterima / dilihat (accepted) atau sedang diproses (in_progress): TIDAK DAPAT dihapus.
  bool get canAuthorDelete {
    if (deletedByUser) return false;
    if (deletedAt != null && !deletedByAdmin) return false;
    if (deletedByAdmin) return true;
    if (isDraft) return true;
    return handlingStatus == HandlingStatus.newReport ||
        handlingStatus == HandlingStatus.completed ||
        handlingStatus == HandlingStatus.rejected ||
        handlingStatus == HandlingStatus.cancelled;
  }

  /// Aturan penghapusan laporan oleh admin (Task 2):
  /// - Admin HANYA dapat menghapus laporan jika pelapor (warga) telah menghapusnya (deletedByUser == true).
  /// - Jika sudah dihapus oleh admin: TIDAK DAPAT dihapus lagi.
  bool get canAdminDelete {
    if (deletedByAdmin) return false;
    return deletedByUser;
  }

  /// Alasan mengapa admin belum dapat menghapus laporan
  String? get cannotAdminDeleteReason {
    if (deletedByAdmin) return 'Laporan sudah dihapus oleh admin.';
    if (!deletedByUser) return 'Laporan belum dihapus oleh pelapor.';
    return null;
  }

  /// Persentase downvote aktif (PRD 4.4 & AGENTS.md 3.3)
  double get downvotePercentage {
    final total = upvotesCount + downvotesCount;
    if (total == 0) return 0.0;
    return (downvotesCount / total) * 100;
  }

  /// Evaluasi ambang downvote (min 10 total, min 6 downvote, >= 70%)
  bool get reachedDownvoteThreshold =>
      (upvotesCount + downvotesCount >= 10) &&
      (downvotesCount >= 6) &&
      (downvotePercentage >= 70.0);

  /// Menghitung state baru laporan secara deterministik untuk Upvote, Downvote, Switch Vote, dan Cancel Vote.
  /// Menerapkan aturan PRD FR-05 & AGENTS.md 3.3 (Threshold downvote).
  ReportModel calculateOptimisticVote(String targetVoteType) {
    int up = upvotesCount;
    int down = downvotesCount;
    String? newVote;

    if (currentUserVote == targetVoteType) {
      // Toggle off / batalkan vote
      newVote = null;
      if (targetVoteType == 'up') {
        up = up > 0 ? up - 1 : 0;
      } else if (targetVoteType == 'down') {
        down = down > 0 ? down - 1 : 0;
      }
    } else {
      // Switch vote atau vote baru
      if (currentUserVote == 'up') {
        up = up > 0 ? up - 1 : 0;
      } else if (currentUserVote == 'down') {
        down = down > 0 ? down - 1 : 0;
      }

      newVote = targetVoteType;
      if (targetVoteType == 'up') {
        up++;
      } else if (targetVoteType == 'down') {
        down++;
      }
    }

    // Evaluasi ambang batas downvote
    PublicationState newPubState = publicationState;
    String? newModerationReason = moderationReason;

    final totalVotes = up + down;
    final downPercentage = totalVotes > 0 ? (down / totalVotes) * 100 : 0.0;

    if (totalVotes >= 10 && down >= 6 && downPercentage >= 70.0) {
      newPubState = PublicationState.held;
      newModerationReason =
          'Ambang batas downvote tercapai (${downPercentage.toStringAsFixed(1)}%). Ditahan untuk review moderasi.';
    }

    return copyWith(
      upvotesCount: up,
      downvotesCount: down,
      currentUserVote: newVote,
      clearCurrentUserVote: newVote == null,
      publicationState: newPubState,
      moderationReason: newModerationReason,
      updatedAt: DateTime.now(),
    );
  }

  ReportModel copyWith({
    String? id,
    String? reportNumber,
    String? authorId,
    String? authorName,
    String? authorUsername,
    String? authorAvatarUrl,
    String? areaId,
    String? areaName,
    String? title,
    String? description,
    String? category,
    double? latitude,
    double? longitude,
    String? locationAddress,
    HandlingStatus? handlingStatus,
    PublicationState? publicationState,
    String? rejectionReason,
    String? moderationReason,
    DateTime? publishedAt,
    DateTime? terminalAt,
    DateTime? archiveAfter,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? deletedByUser,
    DateTime? deletedByUserAt,
    bool clearDeletedByUserAt = false,
    bool? deletedByAdmin,
    DateTime? deletedByAdminAt,
    bool clearDeletedByAdminAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? upvotesCount,
    int? downvotesCount,
    int? commentsCount,
    String? currentUserVote,
    bool clearCurrentUserVote = false,
    List<String>? photoUrls,
    String? completionProofUrl,
    String? completionProofType,
    String? completionNotes,
    bool clearCompletionNotes = false,
    bool? isDiscussionActive,
    bool? isDraft,
    bool? isPrivate,
    String? provinceId,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reportNumber: reportNumber ?? this.reportNumber,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationAddress: locationAddress ?? this.locationAddress,
      handlingStatus: handlingStatus ?? this.handlingStatus,
      publicationState: publicationState ?? this.publicationState,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      moderationReason: moderationReason ?? this.moderationReason,
      publishedAt: publishedAt ?? this.publishedAt,
      terminalAt: terminalAt ?? this.terminalAt,
      archiveAfter: archiveAfter ?? this.archiveAfter,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      deletedByUser: deletedByUser ?? this.deletedByUser,
      deletedByUserAt: clearDeletedByUserAt
          ? null
          : (deletedByUserAt ?? this.deletedByUserAt),
      deletedByAdmin: deletedByAdmin ?? this.deletedByAdmin,
      deletedByAdminAt: clearDeletedByAdminAt
          ? null
          : (deletedByAdminAt ?? this.deletedByAdminAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvotesCount: upvotesCount ?? this.upvotesCount,
      downvotesCount: downvotesCount ?? this.downvotesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      currentUserVote: clearCurrentUserVote
          ? null
          : (currentUserVote ?? this.currentUserVote),
      photoUrls: photoUrls ?? this.photoUrls,
      completionProofUrl: completionProofUrl ?? this.completionProofUrl,
      completionProofType: completionProofType ?? this.completionProofType,
      completionNotes: clearCompletionNotes
          ? null
          : (completionNotes ?? this.completionNotes),
      isDiscussionActive: isDiscussionActive ?? this.isDiscussionActive,
      isDraft: isDraft ?? this.isDraft,
      isPrivate: isPrivate ?? this.isPrivate,
      provinceId: provinceId ?? this.provinceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_number': reportNumber,
      'author_id': authorId,
      'author_name': authorName,
      'author_username': authorUsername,
      'author_avatar_url': authorAvatarUrl,
      'area_id': areaId,
      'area_name': areaName,
      'province_id': provinceId,
      'title': title,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'location_address': locationAddress,
      'handling_status': handlingStatus.value,
      'publication_state': publicationState.value,
      'rejection_reason': rejectionReason,
      'moderation_reason': moderationReason,
      'published_at': publishedAt?.toUtc().toIso8601String(),
      'terminal_at': terminalAt?.toUtc().toIso8601String(),
      'archive_after': archiveAfter?.toUtc().toIso8601String(),
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'deleted_by_user': deletedByUser,
      'deleted_by_user_at': deletedByUserAt?.toUtc().toIso8601String(),
      'deleted_by_admin': deletedByAdmin,
      'deleted_by_admin_at': deletedByAdminAt?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'upvotes_count': upvotesCount,
      'downvotes_count': downvotesCount,
      'comments_count': commentsCount,
      'photo_urls': photoUrls,
      'completion_proof_url': completionProofUrl,
      'completion_proof_type': completionProofType,
      'completion_notes': completionNotes,
      'is_discussion_active': isDiscussionActive,
      'is_draft': isDraft,
      'is_private': isPrivate,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    String? authorUsername =
        json['author_username'] as String? ?? json['username'] as String?;
    String? authorAvatarUrl =
        json['author_avatar_url'] as String? ?? json['avatar_url'] as String?;
    String authorName = json['author_name'] as String? ?? 'Warga Laporin';

    // Parse joined profiles table if available
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      final p = json['profiles'] as Map<String, dynamic>;
      if (p['username'] != null && (p['username'] as String).isNotEmpty) {
        authorUsername = p['username'] as String;
      }
      if (p['full_name'] != null && (p['full_name'] as String).isNotEmpty) {
        authorName = p['full_name'] as String;
      }
      if (p['avatar_url'] != null && (p['avatar_url'] as String).isNotEmpty) {
        authorAvatarUrl = p['avatar_url'] as String;
      }
    }

    final parsedHandlingStatus = HandlingStatus.fromString(
      json['handling_status'] as String?,
    );

    final rawDiscussionActive = json['is_discussion_active'];
    final bool parsedDiscussionActive = rawDiscussionActive != null
        ? (rawDiscussionActive as bool)
        : (parsedHandlingStatus != HandlingStatus.completed &&
              parsedHandlingStatus != HandlingStatus.rejected);

    return ReportModel(
      id: json['id'] as String,
      reportNumber: json['report_number'] as String? ?? 'LPR-2026',
      authorId: json['author_id'] as String? ?? '',
      authorName: authorName,
      authorUsername: authorUsername,
      authorAvatarUrl: authorAvatarUrl,
      areaId: json['area_id'] as String? ?? '',
      areaName: json['area_name'] as String? ?? 'Kota Administrasi',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Fasilitas Umum',
      latitude: (json['latitude'] as num?)?.toDouble() ?? -6.2088,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.8456,
      locationAddress: json['location_address'] as String? ?? 'Lokasi Terpilih',
      handlingStatus: parsedHandlingStatus,
      publicationState: PublicationState.fromString(
        json['publication_state'] as String?,
      ),
      rejectionReason: json['rejection_reason'] as String?,
      moderationReason: json['moderation_reason'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'].toString())?.toLocal()
          : null,
      terminalAt: json['terminal_at'] != null
          ? DateTime.tryParse(json['terminal_at'].toString())?.toLocal()
          : null,
      archiveAfter: json['archive_after'] != null
          ? DateTime.tryParse(json['archive_after'].toString())?.toLocal()
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())?.toLocal()
          : null,
      deletedByUser: (json['deleted_by_user'] as bool?) ?? false,
      deletedByUserAt: json['deleted_by_user_at'] != null
          ? DateTime.tryParse(json['deleted_by_user_at'].toString())?.toLocal()
          : null,
      deletedByAdmin: (json['deleted_by_admin'] as bool?) ?? false,
      deletedByAdminAt: json['deleted_by_admin_at'] != null
          ? DateTime.tryParse(json['deleted_by_admin_at'].toString())?.toLocal()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal() ??
                DateTime.now()
          : DateTime.now(),
      upvotesCount: (json['upvotes_count'] as num?)?.toInt() ?? 0,
      downvotesCount: (json['downvotes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      currentUserVote: json['current_user_vote'] as String?,
      photoUrls:
          (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      completionProofUrl: json['completion_proof_url'] as String?,
      completionProofType: json['completion_proof_type'] as String?,
      completionNotes: json['completion_notes'] as String?,
      isDiscussionActive: parsedDiscussionActive,
      isDraft: (json['is_draft'] as bool?) ?? false,
      isPrivate: (json['is_private'] as bool?) ?? false,
      provinceId: json['province_id']?.toString(),
    );
  }
}
