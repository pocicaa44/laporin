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
  }) : _report = initialReport {
    loadData();
  }

  final String reportId;
  final ReportRepository reportRepository;
  final CommentRepository commentRepository;

  ReportModel? _report;
  ReportModel? get report => _report;

  List<CommentModel> _comments = [];
  List<CommentModel> get comments => _comments;

  bool _isLoading = false;
  bool get isLoading => _isLoading && _report == null;

  bool _isSendingComment = false;
  bool get isSendingComment => _isSendingComment;

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
      notifyListeners();
    }

    try {
      final fetched = await reportRepository.getReportById(reportId);
      if (_isDisposed) return;
      if (fetched != null) {
        _report = fetched;
      }
    } catch (_) {}

    try {
      final fetchedComments = await commentRepository.getComments(reportId);
      if (_isDisposed) return;
      _comments = fetchedComments;
    } catch (_) {}

    if (!_isDisposed) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> vote(String userId, String voteType) async {
    if (_report == null) return;
    try {
      _report = await reportRepository.voteReport(
        reportId: reportId,
        userId: userId,
        voteType: voteType,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> submitComment({
    required String authorId,
    required String authorName,
    required UserRole authorRole,
    required String body,
  }) async {
    if (body.trim().isEmpty) return false;

    _isSendingComment = true;
    notifyListeners();

    try {
      final comment = await commentRepository.addComment(
        reportId: reportId,
        authorId: authorId,
        authorName: authorName,
        authorRole: authorRole,
        body: body,
      );

      _comments.add(comment);
      if (_report != null) {
        _report = _report!.copyWith(commentsCount: _report!.commentsCount + 1);
      }
      _isSendingComment = false;
      notifyListeners();
      return true;
    } catch (_) {
      _isSendingComment = false;
      notifyListeners();
      return false;
    }
  }
}
