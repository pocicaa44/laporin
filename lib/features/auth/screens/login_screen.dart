import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../controllers/auth_controller.dart';
import 'app_gate.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Login screen matching DESIGN.md Section 5.2
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthController>().clearErrorMessage();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final success = await auth.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      try {
        context.read<NavigationController>().resetToHome();
      } catch (_) {}
      try {
        context.read<FeedController>().fetchFeed(auth.currentUser?.id, true);
      } catch (_) {}
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppGate()),
        (route) => false,
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;

    final success = await auth.signInWithGoogle();

    if (success && mounted) {
      try {
        context.read<NavigationController>().resetToHome();
      } catch (_) {}
      try {
        context.read<FeedController>().fetchFeed(auth.currentUser?.id, true);
      } catch (_) {}
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppGate()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Container(
      color: const Color(0xFFF0F2F5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border.symmetric(
              vertical: BorderSide(color: AppColors.border, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 24,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Scaffold(
            appBar: AppBar(title: const Text('Masuk')),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [AppColors.cardShadow],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo_laporin.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Selamat Datang Kembali',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Masuk untuk memantau status laporan dan berdiskusi dengan komunitas.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 32),

                      // Error alert
                      if (auth.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDECEE),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.danger),
                          ),
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Email',
                          hintText: 'nama@domain.com',
                          prefixIcon: Center(
                            widthFactor: 1.0,
                            heightFactor: 1.0,
                            child: FaIcon(FontAwesomeIcons.envelope, size: 16),
                          ),
                        ),
                        validator: AppValidators.validateEmail,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          prefixIcon: const Center(
                            widthFactor: 1.0,
                            heightFactor: 1.0,
                            child: FaIcon(FontAwesomeIcons.lock, size: 16),
                          ),
                          suffixIcon: IconButton(
                            icon: FaIcon(
                              _obscurePassword
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              size: 16,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: AppValidators.validatePassword,
                      ),
                      const SizedBox(height: 8),

                      // Lupa Password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () {
                                  auth.clearErrorMessage();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Lupa password?',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      AppButton(
                        text: 'Masuk Sekarang',
                        isLoading: auth.isLoading,
                        onPressed: _handleEmailLogin,
                      ),
                      const SizedBox(height: 20),

                      // Divider "atau"
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('atau', style: AppTextStyles.caption),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Google Sign In
                      AppButton(
                        text: 'Masuk dengan Google',
                        variant: AppButtonVariant.secondary,
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.google,
                          size: 18,
                        ),
                        isLoading: auth.isLoading,
                        onPressed: _handleGoogleLogin,
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: AppTextStyles.bodySecondary,
                          ),
                          GestureDetector(
                            onTap: auth.isLoading
                                ? null
                                : () {
                                    auth.clearErrorMessage();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterScreen(),
                                      ),
                                    );
                                  },
                            child: Text(
                              'Daftar Sekarang',
                              style: TextStyle(
                                color: auth.isLoading
                                    ? AppColors.textSecondary
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
