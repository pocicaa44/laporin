import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/services/media_service.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/admin/controllers/admin_report_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dual-Party Report Deletion & Storage Cleanup Tests', () {
    late ReportRepository repository;

    ReportModel createTestReport({
      required String id,
      required String authorId,
      HandlingStatus status = HandlingStatus.completed,
      PublicationState pubState = PublicationState.published,
      List<String> photoUrls = const ['reports/user-1/photo_1.jpg'],
      String? completionProofUrl,
    }) {
      final now = DateTime.now();
      return ReportModel(
        id: id,
        reportNumber: 'LPR-$id',
        authorId: authorId,
        authorName: 'Warga $authorId',
        areaId: 'area-1',
        areaName: 'Jakarta Pusat',
        title: 'Jalan Rusak $id',
        description: 'Ada lubang besar di jalan',
        category: 'Infrastruktur',
        latitude: -6.2,
        longitude: 106.8,
        locationAddress: 'Jl. Merdeka No. $id',
        handlingStatus: status,
        publicationState: pubState,
        photoUrls: photoUrls,
        completionProofUrl: completionProofUrl,
        createdAt: now,
        updatedAt: now,
      );
    }

    setUp(() {
      repository = ReportRepository();
    });

    test('MediaService.parseStoragePath correctly extracts bucket and relative path', () {
      // 1. Full public Supabase URL
      const fullUrl =
          'https://xyz.supabase.co/storage/v1/object/public/report-attachments/reports/user-1/12345_0.jpg';
      final parsed1 = MediaService.parseStoragePath(fullUrl);
      expect(parsed1, isNotNull);
      expect(parsed1!.bucket, equals('report-attachments'));
      expect(parsed1.path, equals('reports/user-1/12345_0.jpg'));

      // 2. Relative storage path
      const relativePath = 'reports/user-1/12345_0.jpg';
      final parsed2 = MediaService.parseStoragePath(relativePath);
      expect(parsed2, isNotNull);
      expect(parsed2!.bucket, equals('report-attachments'));
      expect(parsed2.path, equals('reports/user-1/12345_0.jpg'));

      // 3. Local asset should be rejected
      const assetPath = 'assets/images/logo.png';
      final parsed3 = MediaService.parseStoragePath(assetPath);
      expect(parsed3, isNull);

      // 4. Path traversal should be rejected
      const maliciousPath = 'reports/../secrets.txt';
      final parsed4 = MediaService.parseStoragePath(maliciousPath);
      expect(parsed4, isNull);
    });

    test('User soft-deletes report: hidden from user and public, but still in admin reports', () async {
      final report = createTestReport(id: 'rep-001', authorId: 'user-001');
      repository.updateReport(report);

      // User menghapus laporan
      final updated = await repository.softDeleteReport(
        reportId: 'rep-001',
        currentUserId: 'user-001',
        isCallerAdmin: false,
      );

      expect(updated.deletedByUser, isTrue);
      expect(updated.deletedByAdmin, isFalse);
      expect(updated.isDeleted, isTrue);
      expect(updated.isPermanentlyDeleted, isFalse);

      // 1. Tidak tampil di Laporan Saya pengguna
      final myReports = await repository.getMyReports('user-001');
      expect(myReports.any((r) => r.id == 'rep-001'), isFalse);

      // 2. Tidak tampil di Feed Publik
      final feed = await repository.getPublicFeed();
      expect(feed.any((r) => r.id == 'rep-001'), isFalse);

      // 3. MASIH tampil di Panel Admin (karena admin belum menghapus)
      final adminReports = await repository.getAdminReports();
      expect(adminReports.any((r) => r.id == 'rep-001'), isTrue);

      // 4. Laporan MASIH tersimpan di database
      final inDb = await repository.getReportById('rep-001');
      expect(inDb, isNotNull);
    });

    test('Admin CANNOT delete report before user deletes (Soft Delete Dependency)', () async {
      final report = createTestReport(id: 'rep-002', authorId: 'user-002');
      repository.updateReport(report);

      // Admin mencoba menghapus laporan yang belum dihapus warga -> HARUS DITOLAK
      expect(
        () => repository.softDeleteReport(
          reportId: 'rep-002',
          currentUserId: 'admin-001',
          isCallerAdmin: true,
        ),
        throwsA(predicate((e) => e.toString().contains('sudah dihapus oleh pelapor'))),
      );

      // Laporan MASIH tersimpan dan tidak terhapus
      final inDb = await repository.getReportById('rep-002');
      expect(inDb, isNotNull);
      expect(inDb!.deletedByAdmin, isFalse);
    });

    test('User deletes FIRST, then Admin deletes -> HARD DELETED permanently from database', () async {
      final report = createTestReport(
        id: 'rep-003',
        authorId: 'user-003',
        photoUrls: [
          'reports/user-003/photo1.jpg',
          'reports/user-003/photo2.jpg',
        ],
        completionProofUrl: 'reports/admin/proof.jpg',
      );
      repository.updateReport(report);

      // Step 1: User menghapus laporan
      final userDeleted = await repository.softDeleteReport(
        reportId: 'rep-003',
        currentUserId: 'user-003',
        isCallerAdmin: false,
      );
      expect(userDeleted.deletedByUser, isTrue);
      expect(userDeleted.deletedByAdmin, isFalse);
      expect(userDeleted.isPermanentlyDeleted, isFalse);

      // Laporan masih ada di database
      expect(await repository.getReportById('rep-003'), isNotNull);

      // Step 2: Admin menyetujui / menghapus laporan juga (KEDUA BELAH PIHAK)
      final adminDeleted = await repository.softDeleteReport(
        reportId: 'rep-003',
        currentUserId: 'admin-001',
        isCallerAdmin: true,
      );

      expect(adminDeleted.deletedByUser, isTrue);
      expect(adminDeleted.deletedByAdmin, isTrue);
      expect(adminDeleted.isPermanentlyDeleted, isTrue);

      // Laporan sudah TERHAPUS PERMANEN dari database repository!
      final inDbAfterBoth = await repository.getReportById('rep-003');
      expect(inDbAfterBoth, isNull);

      // Tidak ada di myReports, adminReports, atau public feed
      expect(await repository.getMyReports('user-003'), isEmpty);
      expect(await repository.getAdminReports(), isEmpty);
      expect(await repository.getPublicFeed(), isEmpty);
    });

    test('Admin delete requires user deletion first -> HARD DELETED permanently after both delete', () async {
      final report = createTestReport(
        id: 'rep-004',
        authorId: 'user-004',
        photoUrls: ['reports/user-004/road.png'],
      );
      repository.updateReport(report);

      // Step 1: Admin mencoba menghapus duluan -> Gagal
      expect(
        () => repository.softDeleteReport(
          reportId: 'rep-004',
          currentUserId: 'admin-001',
          isCallerAdmin: true,
        ),
        throwsA(predicate((e) => e.toString().contains('sudah dihapus oleh pelapor'))),
      );

      // Step 2: User menghapus laporan terlebih dahulu -> Berhasil
      final userDeleted = await repository.softDeleteReport(
        reportId: 'rep-004',
        currentUserId: 'user-004',
        isCallerAdmin: false,
      );
      expect(userDeleted.deletedByUser, isTrue);
      expect(userDeleted.deletedByAdmin, isFalse);

      // Step 3: Admin sekarang dapat menghapus laporan -> Sukses & Hard Deleted
      final adminDeleted = await repository.softDeleteReport(
        reportId: 'rep-004',
        currentUserId: 'admin-001',
        isCallerAdmin: true,
      );
      expect(adminDeleted.deletedByUser, isTrue);
      expect(adminDeleted.deletedByAdmin, isTrue);
      expect(adminDeleted.isPermanentlyDeleted, isTrue);

      // Laporan sudah TERHAPUS PERMANEN dari database repository!
      final inDbAfterBoth = await repository.getReportById('rep-004');
      expect(inDbAfterBoth, isNull);
    });

    test('Cannot delete report twice by the same party', () async {
      final report = createTestReport(id: 'rep-005', authorId: 'user-005');
      repository.updateReport(report);

      // User hapus pertama kali -> sukses
      await repository.softDeleteReport(
        reportId: 'rep-005',
        currentUserId: 'user-005',
        isCallerAdmin: false,
      );

      // User mencoba hapus kedua kali -> Exception
      expect(
        () => repository.softDeleteReport(
          reportId: 'rep-005',
          currentUserId: 'user-005',
          isCallerAdmin: false,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Laporan ini sudah dihapus oleh Anda sebelumnya'),
          ),
        ),
      );
    });

    test('AdminReportController correctly filters and counts reports deleted by user', () async {
      final report = createTestReport(
        id: 'rep-006',
        authorId: 'user-006',
      ).copyWith(deletedByUser: true, deletedByUserAt: DateTime.now());
      repository.updateReport(report);

      final controller = AdminReportController(reportRepository: repository);
      await controller.fetchReports();

      expect(controller.deletedByUserCount, equals(1));
      final filtered = await repository.getAdminReports(
        filterStatus: 'deleted_by_user',
      );
      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('rep-006'));
    });
  });
}
