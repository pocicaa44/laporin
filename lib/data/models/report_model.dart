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
  });

  final String id;
  final String reportNumber;
  final String authorId;
  final String authorName;
  final String? authorUsername;
  final String? authorAvatarUrl;
  final String areaId;
  final String areaName;
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

  /// Apakah laporan telah di-soft-delete oleh pemiliknya
  bool get isDeleted => deletedAt != null;

  /// Aturan visibilitas publik mutlak (PRD 5.4 & AGENTS.md 3.2):
  /// !isDeleted AND publication_state = 'published' AND handling_status NOT IN ('rejected', 'cancelled')
  bool get isPubliclyVisible =>
      !isDeleted &&
      publicationState == PublicationState.published &&
      handlingStatus != HandlingStatus.rejected &&
      handlingStatus != HandlingStatus.cancelled;

  /// Apakah laporan telah mencapai status terminal
  bool get isTerminal =>
      isDeleted ||
      handlingStatus == HandlingStatus.rejected ||
      handlingStatus == HandlingStatus.cancelled;

  /// Aturan interaksi voting:
  /// Upvote & downvote hanya aktif jika laporan publik, belum dihapus,
  /// dan status BUKAN completed (selesai) atau rejected (ditolak).
  bool get isVotingActive =>
      isPubliclyVisible &&
      !isDeleted &&
      handlingStatus != HandlingStatus.completed &&
      handlingStatus != HandlingStatus.rejected &&
      handlingStatus != HandlingStatus.cancelled;

  /// Aturan diskusi komentar:
  /// Komentar baru hanya dapat dikirim jika laporan publik, belum dihapus,
  /// status bukan rejected/cancelled, dan diskusi dalam keadaan aktif (isDiscussionActive).
  bool get canAddComment =>
      isPubliclyVisible &&
      !isDeleted &&
      handlingStatus != HandlingStatus.rejected &&
      handlingStatus != HandlingStatus.cancelled &&
      isDiscussionActive;

  /// Aturan penghapusan laporan oleh pemilik (author):
  /// - Status baru / pending review: BISA hapus dengan confirmation dialog.
  /// - Status ditolak atau selesai: BISA hapus dengan confirmation dialog.
  /// - Status diterima / dilihat (accepted) atau sedang diproses (in_progress): TIDAK DAPAT dihapus.
  bool get canAuthorDelete {
    if (isDeleted) return false;
    if (handlingStatus == HandlingStatus.accepted ||
        handlingStatus == HandlingStatus.inProgress) {
      return false;
    }
    return handlingStatus == HandlingStatus.newReport ||
        handlingStatus == HandlingStatus.rejected ||
        handlingStatus == HandlingStatus.completed ||
        publicationState == PublicationState.pendingReview;
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
    );
  }
}
