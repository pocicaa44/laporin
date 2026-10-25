import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// 6-digit OTP input row widget with error state styling.
class OtpInputRow extends StatelessWidget {
  const OtpInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    this.hasError = false,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final ValueChanged<String> onChanged;
  final bool hasError;

  void _handleChanged(BuildContext context, String value, int index) {
    if (value.length > 1) {
      // User pasted multiple characters (e.g. 6-digit OTP from clipboard)
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        controllers[i].text = digits[i];
      }
      final nextIndex = digits.length < 6 ? digits.length : 5;
      focusNodes[nextIndex].requestFocus();
      onChanged(controllers.map((c) => c.text).join());
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        focusNodes[index + 1].requestFocus();
      } else {
        focusNodes[index].unfocus();
      }
    }

    onChanged(controllers.map((c) => c.text).join());
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return _buildDigitBox(context, index);
      }),
    );
  }

  Widget _buildDigitBox(BuildContext context, int index) {
    final controller = controllers[index];
    final focusNode = focusNodes[index];

    final borderColor = hasError ? AppColors.danger : AppColors.border;
    final backgroundColor = hasError
        ? const Color(0xFFFDECEE)
        : AppColors.surface;

    return SizedBox(
      width: 44,
      height: 52,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty &&
              index > 0) {
            focusNodes[index - 1].requestFocus();
            controllers[index - 1].clear();
            onChanged(controllers.map((c) => c.text).join());
          }
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(
            fontSize: 20,
            color: hasError ? AppColors.danger : AppColors.textPrimary,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(
              6,
            ), // Allow paste of up to 6 digits
          ],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: borderColor,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: borderColor,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: hasError ? AppColors.danger : AppColors.primary,
                width: 2.0,
              ),
            ),
          ),
          onChanged: (value) => _handleChanged(context, value, index),
        ),
      ),
    );
  }
}
