enum NotificationType {
  statusChanged('status_changed', 'Perubahan Status'),
  newComment('new_comment', 'Komentar Baru'),
  replyComment('reply_comment', 'Balasan Komentar'),
  upvoted('upvoted', 'Dukungan Warga'),
  moderation('moderation', 'Tindakan Moderasi'),
  announcement('announcement', 'Pengumuman Resmi'),
  newReport('new_report', 'Laporan Baru');

  const NotificationType(this.value, this.label);
  final String value;
  final String label;

  static NotificationType fromString(String? val) {
    if (val == null) return NotificationType.statusChanged;
    switch (val) {
      case 'status_changed':
      case 'report_status_changed':
        return NotificationType.statusChanged;
      case 'new_comment':
        return NotificationType.newComment;
      case 'reply_comment':
        return NotificationType.replyComment;
      case 'upvoted':
      case 'report_upvoted':
        return NotificationType.upvoted;
      case 'moderation':
        return NotificationType.moderation;
      case 'announcement':
      case 'announcement_published':
        return NotificationType.announcement;
      case 'new_report':
      case 'new_report_created':
        return NotificationType.newReport;
      default:
        return NotificationType.values.firstWhere(
          (e) => e.value == val,
          orElse: () => NotificationType.statusChanged,
        );
    }
  }
}

/// Model notifikasi sesuai PRD.md Bagian 10.1 & DESIGN.md 5.12
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.reportId,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? reportId;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      reportId: reportId,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.value,
      'report_id': reportId,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Notifikasi',
      message: json['message'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      reportId: json['report_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}
