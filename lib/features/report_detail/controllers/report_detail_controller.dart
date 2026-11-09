import 'package:flutter/material.dart';

import '../../../data/models/comment_model.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../data/repositories/comment_repository.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for report details and comment discussion thread.
class ReportDetailController extends ChangeNotifier {
  ReportDetailController({
    required this.reportId,
    required this.reportRepository,
    required this.commentRepository,
    ReportModel? initialReport,
    this.currentUserId,
  }) : _report = initialReport,
       _isLoading = initialReport == null,
       _isLoadingComments = true {
    loadData();
  }

  final String reportId;
  final ReportRepository reportRepository;
  final CommentRepository commentRepository;
  final String? currentUserId;

  ReportModel? _report;
  ReportModel? get report => _report;

  List<CommentModel> _comments = [];
  List<CommentModel> get comments => _comments;

  bool _isLoading = false;
  bool get isLoading => _isLoading && _report == null;

  bool _isLoadingComments = false;
  bool get isLoadingComments => _isLoadingComments;

  bool _isSendingComment = false;
  bool get isSendingComment => _isSendingComment;

  bool _isVoting = false;
  bool get isVoting => _isVoting;

  bool _isTogglingDiscussion = false;
  bool get isTogglingDiscussion => _isTogglingDiscussion;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> loadData() async {
    if (_report == null) {
      _isLoading = true;
    }
    _isLoadingComments = true;
    notifyListeners();

    try {
      final fetched = await reportRepository.getReportById(
        reportId,
        userId: currentUserId,
      );
      if (_isDisposed) return;
      if (fetched != null) {
        _report = fetched;
      }
    } catch (_) {}

    try {
      final fetchedComments = await commentRepository.getComments(reportId);
      if (_isDisposed) return;
      _comments = fetchedComments;
      if (_report != null) {
        _report = _report!.copyWith(commentsCount: fetchedComments.length);
        reportRepository.updateReport(_report!);
      } else {
        reportRepository.updateReportCommentsCount(
          reportId,
          fetchedComments.length,
        );
      }
    } catch (_) {
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _isLoadingComments = false;
        notifyListeners();
      }
    }
  }

  /// Memuat ulang komentar saja secara asinkron tanpa memuat ulang seluruh detail laporan
  Future<void> refreshComments() async {
    _isLoadingComments = true;
    notifyListeners();

    try {
      final fetchedComments = await commentRepository.getComments(reportId);
      if (_isDisposed) return;
      _comments = fetchedComments;
      if (_report != null) {
        _report = _report!.copyWith(commentsCount: fetchedComments.length);
        reportRepository.updateReport(_report!);
      } else {
        reportRepository.updateReportCommentsCount(
          reportId,
          fetchedComments.length,
        );
      }
    } catch (_) {
    } finally {
      if (!_isDisposed) {
        _isLoadingComments = false;
        notifyListeners();
      }
    }
  }

  Future<void> vote(String userId, String voteType) async {
    final currentReport = _report;
    // 1. In-flight lock & validasi laporan
    if (currentReport == null || _isVoting) return;

    // Invarian Produk: Vote hanya diizinkan jika isVotingActive
    if (!currentReport.isVotingActive) return;

    // 2. Optimistic UI Update: Update seketika tanpa menunggu respon jaringan
    final previousReport = currentReport;
    final optimisticReport = currentReport.calculateOptimisticVote(voteType);

    _isVoting = true;
    _report = optimisticReport;
    _errorMessage = null;
    notifyListeners();

    // 3. Eksekusi request backend asinkron
    try {
      final updated = await reportRepository.voteReport(
        reportId: reportId,
        userId: userId,
        voteType: voteType,
      );
      if (_isDisposed) return;
      _report = updated;
      notifyListeners();
    } catch (e) {
      if (_isDisposed) return;
      // 4. Rollback State jika request gagal
      _report = previousReport;
      _errorMessage = 'Gagal memperbarui vote. Silakan coba kembali.';
      notifyListeners();
    } finally {
      _isVoting = false;
    }
  }

  Future<bool> submitComment({
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required UserRole authorRole,
    required String body,
    String? parentCommentId,
  }) async {
    if (body.trim().isEmpty || _isSendingComment) return false;

    // Invarian Produk: Komentar hanya jika canAddComment (diskusi aktif & non-terminal)
    if (_report?.canAddComment != true) {
      _errorMessage = 'Diskusi telah dinonaktifkan untuk laporan ini.';
      notifyListeners();
      return false;
    }

    _isSendingComment = true;
    notifyListeners();

    try {
      final comment = await commentRepository.addComment(
        reportId: reportId,
        authorId: authorId,
        authorName: authorName,
        authorAvatarUrl: authorAvatarUrl,
        authorRole: authorRole,
        body: body,
        parentCommentId: parentCommentId,
      );

      _comments.add(comment);
      if (_report != null) {
        _report = _report!.copyWith(commentsCount: _comments.length);
        reportRepository.updateReport(_report!);
      } else {
        reportRepository.updateReportCommentsCount(reportId, _comments.length);
      }
      _isSendingComment = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSendingComment = false;
      debugPrint('Error submitComment: $e');
      _errorMessage =
          'Gagal mengirim komentar. Silakan periksa koneksi dan coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Menghapus komentar milik pengguna aktif atau admin
  Future<bool> deleteComment({
    required String commentId,
    required String userId,
    bool isCallerAdmin = false,
  }) async {
    try {
      await commentRepository.deleteComment(
        commentId,
        userId: userId,
        isCallerAdmin: isCallerAdmin,
      );

      _comments.removeWhere((c) => c.id == commentId);
      if (_report != null) {
        _report = _report!.copyWith(commentsCount: _comments.length);
        reportRepository.updateReport(_report!);
      } else {
        reportRepository.updateReportCommentsCount(reportId, _comments.length);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus komentar: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Memperbarui laporan secara langsung dari hasil Edit
  void setReport(ReportModel updatedReport) {
    _report = updatedReport;
    reportRepository.updateReport(updatedReport);
    notifyListeners();
  }

  /// Menghapus laporan secara logis (Soft Delete)
  Future<bool> softDeleteReport(
    String userId, {
    bool isCallerAdmin = false,
  }) async {
    try {
      final updated = await reportRepository.softDeleteReport(
        reportId: reportId,
        currentUserId: userId,
        isCallerAdmin: isCallerAdmin,
      );
      _report = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle status diskusi (aktif / nonaktif) oleh pemilik laporan atau admin
  Future<bool> toggleDiscussion({
    required String userId,
    bool isCallerAdmin = false,
  }) async {
    if (_report == null || _isTogglingDiscussion) return false;

    final newStatus = !_report!.isDiscussionActive;
    _isTogglingDiscussion = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await reportRepository.toggleDiscussionActive(
        reportId: reportId,
        currentUserId: userId,
        isDiscussionActive: newStatus,
        isCallerAdmin: isCallerAdmin,
      );
      if (_isDisposed) return false;
      _report = updated;
      notifyListeners();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isTogglingDiscussion = false;
      notifyListeners();
    }
  }

  /// Mempublikasikan laporan jika berstatus draft
  Future<bool> publishDraft() async {
    if (_report == null || !_report!.isDraft) return false;

    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await reportRepository.publishDraft(reportId);
      if (_isDisposed) return false;
      _report = updated;
      notifyListeners();
      return true;
    } catch (e) {
      if (_isDisposed) return false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
