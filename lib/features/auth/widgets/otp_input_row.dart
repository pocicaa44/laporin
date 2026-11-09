import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Formatter to ensure each box never holds more than 1 character,
/// while seamlessly supporting pasting a multi-digit OTP.
class _OtpDigitFormatter extends TextInputFormatter {
  final int index;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final ValueChanged<String> onChanged;

  _OtpDigitFormatter({
    required this.index,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return oldValue;
    }

    // Pasted multiple digits (e.g. 6-digit OTP from clipboard)
    if (digits.length > 1) {
      // If user typed 1 char while box already had 1 char (length == 2):
      if (oldValue.text.length == 1 && digits.length == 2) {
        final newChar = digits.endsWith(oldValue.text)
            ? digits.substring(0, 1)
            : digits.substring(1, 2);
        return TextEditingValue(
          text: newChar,
          selection: const TextSelection.collapsed(offset: 1),
        );
      }

      // Pasted full OTP code
      for (int i = 0; i < 6 && i < digits.length; i++) {
        controllers[i].text = digits[i];
      }
      final targetIndex = digits.length < 6 ? digits.length : 5;
      focusNodes[targetIndex].requestFocus();
      onChanged(controllers.map((c) => c.text).join());

      final currentBoxChar = (index < digits.length)
          ? digits[index]
          : digits[0];
      return TextEditingValue(
        text: currentBoxChar,
        selection: const TextSelection.collapsed(offset: 1),
      );
    }

    // Strictly 1 character
    return TextEditingValue(
      text: digits[0],
      selection: const TextSelection.collapsed(offset: 1),
    );
  }
}

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
          maxLength: 1,
          style: AppTextStyles.pageTitle.copyWith(
            fontSize: 20,
            color: hasError ? AppColors.danger : AppColors.textPrimary,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _OtpDigitFormatter(
              index: index,
              controllers: controllers,
              focusNodes: focusNodes,
              onChanged: onChanged,
            ),
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(
                color: borderColor,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(
                color: borderColor,
                width: hasError ? 1.5 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
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
