import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

/// Screen for entering new password and confirmation after OTP verification.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final success = await auth.updatePassword(_passwordController.text);

    if (success && mounted) {
      // End recovery session and redirect user to Login screen
      await auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kata sandi berhasil diperbarui. Silakan masuk dengan kata sandi baru Anda.',
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 4),
        ),
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
            appBar: AppBar(
              title: const Text('Buat Kata Sandi Baru'),
              automaticallyImplyLeading: false,
            ),
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
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.lockOpen,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Masukkan Kata Sandi Baru',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pastikan kata sandi baru Anda kuat dan mudah diingat.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 28),

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

                      // Password baru field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'masukkan password baru',
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

                      // Konfirmasi password baru field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'konfirmasi password',
                          hintText: 'Ketik ulang kata sandi baru',
                          prefixIcon: const Center(
                            widthFactor: 1.0,
                            heightFactor: 1.0,
                            child: FaIcon(FontAwesomeIcons.check, size: 16),
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
                        validator: (value) =>
                            AppValidators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                      ),
                      const SizedBox(height: 28),

                      AppButton(
                        text: 'Perbarui password',
                        isLoading: auth.isLoading,
                        onPressed: _handleUpdatePassword,
                      ),
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
