import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/widgets/user_avatar.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/main.dart';

void main() {
  group('End-to-End User Journey & Cross-Module Integration Tests', () {
    late AuthRepository authRepo;
    late ReportRepository reportRepo;

    setUp(() {
      authRepo = AuthRepository();
      reportRepo = ReportRepository();
    });

    testWidgets(
      'User Journey: Auth -> Feed -> ReportCard with Avatar/Username -> Vote Interaction -> Profile View',
      (WidgetTester tester) async {
        // 1. Inisialisasi Akun Pengguna Terautentikasi
        const testUser = UserProfileModel(
          id: 'usr-agent-001',
          email: 'dewa@laporin.id',
          fullName: 'Dewa Sukma',
          username: 'dewa_sukma',
          role: UserRole.user,
          avatarUrl: 'https://images.unsplash.com/photo-test.jpg',
        );
        authRepo.setCurrentUserProfileForTesting(testUser);

        // 2. Buat Laporan Uji Coba melalui ReportRepository
        final createdReport = await reportRepo.createReport(
          authorId: testUser.id,
          authorName: testUser.fullName,
          authorUsername: testUser.username,
          authorAvatarUrl: testUser.avatarUrl,
          title: 'Lubang Besar di Jalan Pandanaran',
          description: 'Ada lubang membahayakan pengendara sepeda motor di dekat simpang lima.',
          category: 'Infrastruktur',
          latitude: -6.9904,
          longitude: 110.4228,
          locationAddress: 'Jl. Pandanaran No. 12, Semarang',
        );

        expect(createdReport.id, isNotEmpty);
        expect(createdReport.displayAuthorUsername, equals('@dewa_sukma'));

        // 3. Mount Full Application dengan Repositories Terintegrasi
        await tester.pumpWidget(
          LaporinApp(authRepository: authRepo, reportRepository: reportRepo),
        );
        await tester.pumpAndSettle();

        // 4. Verifikasi Navigasi Utama Terbuka (Pengguna memiliki username)
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);

        // Verifikasi ReportCard di Feed menampilkan Data Laporan, Username, dan UserAvatar
        expect(find.text('Lubang Besar di Jalan Pandanaran'), findsOneWidget);
        expect(find.text('@dewa_sukma'), findsOneWidget);
        expect(find.byType(UserAvatar), findsWidgets);

        // 5. Interaksi Voting: Beri Upvote
        // Upvote dan downvote awalnya bernilai 0
        final zeroCountTexts = find.text('0');
        expect(zeroCountTexts, findsWidgets);

        // Tap Upvote button (elemen '0' pertama pada card)
        await tester.tap(zeroCountTexts.first);
        await tester.pump(); // Render optimistic UI

        // Verifikasi Optimistic Upvote (+1)
        expect(find.text('1'), findsWidgets);

        // 6. Navigasi ke Tab Profil
        final profilTab = find.text('Profil');
        await tester.tap(profilTab);
        await tester.pumpAndSettle();

        // Verifikasi Layar Profil menampilkan profil lengkap pengguna
        expect(find.text('Profil Saya'), findsOneWidget);
        expect(find.text('Dewa Sukma'), findsOneWidget);
        expect(find.text('@dewa_sukma'), findsOneWidget);

        // 7. Kembali ke Tab Beranda
        final berandaTab = find.text('Beranda');
        await tester.tap(berandaTab);
        await tester.pumpAndSettle();

        // 8. Interaksi Voting: Switch dari Upvote ke Downvote
        // Sekarang downvote adalah elemen '0' (karena upvote bernilai '1')
        final remainingZero = find.text('0');
        expect(remainingZero, findsWidgets);

        await tester.tap(remainingZero.first);
        await tester.pump(); // Render optimistic UI

        // Upvote berkurang kembali ke 0, Downvote bertambah 1
        expect(find.text('0'), findsWidgets);
        expect(find.text('1'), findsWidgets);
      },
    );

    testWidgets(
      'User Journey: Downvote Threshold triggers Held state and removes report from Feed',
      (WidgetTester tester) async {
        final reportRepo = ReportRepository();
        final authRepo = AuthRepository();

        const testUser = UserProfileModel(
          id: 'voter-10',
          email: 'voter@laporin.id',
          fullName: 'Voter User',
          username: 'voter_active',
          role: UserRole.user,
        );
        authRepo.setCurrentUserProfileForTesting(testUser);

        final initialReport = await reportRepo.createReport(
          authorId: 'author-orig',
          authorName: 'Pelapor Awal',
          authorUsername: 'pelapor_awal',
          title: 'Laporan Yang Di-Downvote Komunitas',
          description: 'Laporan ini terindikasi tidak valid oleh warga.',
          category: 'Ketertiban',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Jl. Pahlawan, Semarang',
        );

        // Simulasi 9 vote (3 up, 6 down)
        for (var i = 1; i <= 3; i++) {
          await reportRepo.voteReport(
            reportId: initialReport.id,
            userId: 'user-up-$i',
            voteType: 'up',
          );
        }
        for (var i = 1; i <= 6; i++) {
          await reportRepo.voteReport(
            reportId: initialReport.id,
            userId: 'user-down-$i',
            voteType: 'down',
          );
        }

        // Pada titik ini: total 9 vote (3 up, 6 down = 66.7%). Belum mencapai total 10.
        final feedController = FeedController(reportRepository: reportRepo);
        await feedController.fetchFeed();

        expect(
          feedController.reports.any((r) => r.id == initialReport.id),
          isTrue,
        );

        // Sekarang voter ke-10 memberikan downvote (sehingga total 10 vote, 7 downvote = 70.0%)
        await feedController.vote(initialReport.id, testUser.id, 'down');

        // Sesuai AGENTS.md 3.2 & 3.3: Laporan seketika lenyap dari feed publik karena status menjadi 'held'
        expect(
          feedController.reports.any((r) => r.id == initialReport.id),
          isFalse,
        );

        final detail = await reportRepo.getReportById(initialReport.id);
        expect(detail?.publicationState, equals(PublicationState.held));
        expect(detail?.isPubliclyVisible, isFalse);
      },
    );
  });
}
