import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';
import 'otp_verification_screen.dart';

/// Screen for initiating password reset by sending an OTP to the user's email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success = await auth.sendResetPasswordOtp(email);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OtpVerificationScreen(email: email)),
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
              title: const Text('Lupa Kata Sandi'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
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
                              FontAwesomeIcons.envelopeOpenText,
                              size: 28,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Reset Kata Sandi',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Masukkan email akun Anda. Kami akan mengirimkan 6 digit kode OTP untuk mengatur ulang kata sandi.',
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
                      const SizedBox(height: 24),

                      AppButton(
                        text: 'Kirim OTP',
                        isLoading: auth.isLoading,
                        onPressed: _handleSendOtp,
                      ),
                      const SizedBox(height: 20),

                      Center(
                        child: TextButton(
                          onPressed: auth.isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: const Text(
                            'Kembali ke Halaman Masuk',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
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
