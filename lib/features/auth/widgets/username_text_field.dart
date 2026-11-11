import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_validators.dart';
import '../controllers/auth_controller.dart';

/// Reusable Username Text Field with Debounced Uniqueness Check
class UsernameTextField extends StatefulWidget {
  const UsernameTextField({
    super.key,
    required this.controller,
    this.onAvailabilityChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final void Function(bool isAvailable, bool isChecking)? onAvailabilityChanged;
  final bool enabled;

  @override
  State<UsernameTextField> createState() => _UsernameTextFieldState();
}

class _UsernameTextFieldState extends State<UsernameTextField> {
  Timer? _debounceTimer;
  bool _isChecking = false;
  bool? _isAvailable;
  String? _statusMessage;
  String _lastCheckedText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    if (widget.controller.text.trim().isNotEmpty) {
      _triggerCheck(widget.controller.text.trim());
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim().toLowerCase();
    if (text == _lastCheckedText && _isAvailable != null) return;

    _debounceTimer?.cancel();

    if (text.isEmpty) {
      setState(() {
        _isChecking = false;
        _isAvailable = null;
        _statusMessage = null;
        _lastCheckedText = '';
      });
      widget.onAvailabilityChanged?.call(false, false);
      return;
    }

    final formatError = AppValidators.validateUsername(text);
    if (formatError != null) {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _statusMessage = formatError;
        _lastCheckedText = text;
      });
      widget.onAvailabilityChanged?.call(false, false);
      return;
    }

    // Set checking state & start debounce
    setState(() {
      _isChecking = true;
      _isAvailable = null;
      _statusMessage = 'Memeriksa ketersediaan username...';
    });
    widget.onAvailabilityChanged?.call(false, true);

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _triggerCheck(text);
    });
  }

  Future<void> _triggerCheck(String username) async {
    if (!mounted) return;
    final authController = context.read<AuthController>();

    try {
      final available = await authController.checkUsernameAvailability(
        username,
      );
      if (!mounted) return;

      // Only apply if text hasn't changed since request began
      if (widget.controller.text.trim().toLowerCase() == username) {
        setState(() {
          _isChecking = false;
          _isAvailable = available;
          _lastCheckedText = username;
          _statusMessage = available
              ? 'Username tersedia'
              : 'Username sudah digunakan';
        });
        widget.onAvailabilityChanged?.call(available, false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isChecking = false;
        _isAvailable = null;
        _statusMessage = 'Gagal memeriksa ketersediaan';
      });
      widget.onAvailabilityChanged?.call(false, false);
    }
  }

  Widget? _buildSuffixIcon(bool isDark) {
    if (_isChecking) {
      return Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
          ),
        ),
      );
    }

    if (_isAvailable == true) {
      return Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: FaIcon(
          FontAwesomeIcons.circleCheck,
          color: isDark ? AppColors.darkSuccess : AppColors.success,
          size: 16,
        ),
      );
    }

    if (_isAvailable == false) {
      return Center(
        widthFactor: 1.0,
        heightFactor: 1.0,
        child: FaIcon(
          FontAwesomeIcons.circleXmark,
          color: isDark ? AppColors.darkDanger : AppColors.danger,
          size: 16,
        ),
      );
    }

    return null;
  }

  Color _getStatusColor(bool isDark) {
    if (_isChecking) {
      return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    }
    if (_isAvailable == true) {
      return isDark ? AppColors.darkSuccess : AppColors.success;
    }
    if (_isAvailable == false) {
      return isDark ? AppColors.darkDanger : AppColors.danger;
    }
    return isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Username',
            hintText: 'contoh: budi_laporin',
            prefixIcon: const Center(
              widthFactor: 1.0,
              heightFactor: 1.0,
              child: FaIcon(FontAwesomeIcons.at, size: 16),
            ),
            suffixIcon: _buildSuffixIcon(isDark),
          ),
          validator: AppValidators.validateUsername,
        ),
        if (_statusMessage != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                if (_isAvailable == true) ...[
                  FaIcon(
                    FontAwesomeIcons.check,
                    color: isDark ? AppColors.darkSuccess : AppColors.success,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                ] else if (_isAvailable == false && !_isChecking) ...[
                  FaIcon(
                    FontAwesomeIcons.triangleExclamation,
                    color: isDark ? AppColors.darkDanger : AppColors.danger,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    _statusMessage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
