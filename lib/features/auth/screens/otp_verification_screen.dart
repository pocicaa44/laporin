import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_input_row.dart';
import 'reset_password_screen.dart';

/// Screen for entering 6-digit OTP code with countdown timer and error handling.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsRemaining = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  Future<void> _handleConfirm() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) return;

    final otp = _currentOtp;
    if (otp.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Harap masukkan 6 digit kode OTP secara lengkap.';
      });
      return;
    }

    final success = await auth.verifyRecoveryOtp(email: widget.email, otp: otp);

    if (!mounted) return;

    if (success) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: widget.email),
        ),
      );
    } else {
      setState(() {
        _hasError = true;
        _errorMessage =
            auth.errorMessage ?? 'Kode OTP tidak valid atau sudah kedaluwarsa.';
      });
    }
  }

  Future<void> _handleResendOtp() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading || _secondsRemaining > 0) return;

    setState(() {
      _hasError = false;
      _errorMessage = null;
      for (final controller in _controllers) {
        controller.clear();
      }
    });

    final success = await auth.sendResetPasswordOtp(widget.email);
    if (success && mounted) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP baru telah dikirimkan ke email Anda.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
              title: const Text('Verifikasi OTP'),
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
                            FontAwesomeIcons.shieldHalved,
                            size: 28,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Masukkan Kode OTP',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle,
                    ),
                    const SizedBox(height: 8),

                    // Required text from prompt: "kode OTP terkirim. silahkan buka email anda"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF7F0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 20,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'kode OTP terkirim. silahkan buka email anda',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B6E3F),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2C7D4E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 6-digit OTP input row
                    OtpInputRow(
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                      hasError: _hasError,
                      onChanged: (val) {
                        if (_hasError) {
                          setState(() {
                            _hasError = false;
                            _errorMessage = null;
                          });
                        }
                      },
                    ),

                    // Error message row directly below OTP input row
                    if (_hasError && _errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 15,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Countdown timer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        if (_secondsRemaining > 0)
                          Text(
                            'Waktu tersisa: ${_formatTimer(_secondsRemaining)}',
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        else
                          const Text(
                            'Kode OTP kedaluwarsa',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Konfirmasi button
                    AppButton(
                      text: 'Konfirmasi',
                      isLoading: auth.isLoading,
                      onPressed: _handleConfirm,
                    ),
                    const SizedBox(height: 16),

                    // Resend OTP button
                    Center(
                      child: TextButton(
                        onPressed: (_secondsRemaining > 0 || auth.isLoading)
                            ? null
                            : _handleResendOtp,
                        child: Text(
                          _secondsRemaining > 0
                              ? 'Kirim ulang dalam ${_formatTimer(_secondsRemaining)}'
                              : 'Kirim Ulang OTP',
                          style: TextStyle(
                            color: _secondsRemaining > 0
                                ? AppColors.disabled
                                : AppColors.primary,
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
    );
  }
}
