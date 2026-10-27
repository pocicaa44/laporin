import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../controllers/auth_controller.dart';
import '../widgets/username_text_field.dart';
import 'app_gate.dart';

/// Screen for creating a new user account with username, email, password, and confirm password.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_isUsernameAvailable || _isCheckingUsername) return;

    final success = await auth.signUpWithEmail(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      try {
        context.read<NavigationController>().resetToHome();
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Akun berhasil didaftarkan! Selamat datang di Laporin.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppGate()),
        (route) => false,
      );
    }
  }

  Future<void> _handleGoogleRegister() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;

    final success = await auth.signInWithGoogle();

    if (success && mounted) {
      try {
        context.read<NavigationController>().resetToHome();
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
            appBar: AppBar(title: const Text('Daftar Akun')),
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
                        'Buat Akun Laporin',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Daftarkan diri Anda untuk mulai berpartisipasi dan memantau penanganan masalah publik.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 28),

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

                      // 1. Username Field with debounced live uniqueness check
                      UsernameTextField(
                        controller: _usernameController,
                        enabled: !auth.isLoading,
                        onAvailabilityChanged: (available, checking) {
                          setState(() {
                            _isUsernameAvailable = available;
                            _isCheckingUsername = checking;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 2. Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !auth.isLoading,
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

                      // 3. Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        enabled: !auth.isLoading,
                        decoration: InputDecoration(
                          labelText: 'Kata Sandi',
                          hintText: 'Minimal 8 karakter',
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
                      const SizedBox(height: 16),

                      // 4. Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        enabled: !auth.isLoading,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Kata Sandi',
                          hintText: 'Ulangi kata sandi Anda',
                          prefixIcon: const Center(
                            widthFactor: 1.0,
                            heightFactor: 1.0,
                            child: FaIcon(FontAwesomeIcons.lock, size: 16),
                          ),
                          suffixIcon: IconButton(
                            icon: FaIcon(
                              _obscureConfirmPassword
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              size: 16,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        validator: (val) =>
                            AppValidators.validateConfirmPassword(
                              val,
                              _passwordController.text,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      AppButton(
                        text: 'Daftar Sekarang',
                        isLoading: auth.isLoading,
                        onPressed:
                            (_isUsernameAvailable && !_isCheckingUsername)
                            ? _handleRegister
                            : null,
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
                        text: 'Daftar dengan Google',
                        variant: AppButtonVariant.secondary,
                        iconWidget: const FaIcon(
                          FontAwesomeIcons.google,
                          size: 18,
                        ),
                        isLoading: auth.isLoading,
                        onPressed: _handleGoogleRegister,
                      ),
                      const SizedBox(height: 24),

                      // Link to Login
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Sudah punya akun? ',
                            style: AppTextStyles.bodySecondary,
                          ),
                          GestureDetector(
                            onTap: () {
                              context
                                  .read<AuthController>()
                                  .clearErrorMessage();
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Masuk di sini',
                              style: TextStyle(
                                color: AppColors.primary,
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
