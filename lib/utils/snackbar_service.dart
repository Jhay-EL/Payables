import 'package:flutter/material.dart';

class SnackbarService {
  // Material 3 Expressive Snackbar Colors
  static const Color _successColor = Color(0xFF10B981);
  static const Color _errorColor = Color(0xFFEF4444);
  static const Color _warningColor = Color(0xFFF59E0B);
  static const Color _infoColor = Color(0xFF3B82F6);

  // Material 3 Expressive Snackbar Specifications
  static const double _borderRadius = 28.0; // 28dp radius for expressive design
  static const double _elevation = 3.0; // 3dp elevation
  static const EdgeInsets _margin = EdgeInsets.all(16.0);
  static const Duration _duration = Duration(seconds: 4);

  // Success Snackbar
  static void showSuccess(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: _successColor,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Error Snackbar
  static void showError(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: _errorColor,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Warning Snackbar
  static void showWarning(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: _warningColor,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Info Snackbar
  static void showInfo(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    _showSnackbar(
      context: context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: _infoColor,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  // Generic Snackbar with Material 3 Expressive Design
  static void _showSnackbar({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Icon with proper spacing
            Icon(
              icon,
              color: Colors.white,
              size: 24, // 24dp icon size per Material 3
            ),
            const SizedBox(width: 12), // 12dp spacing
            // Message text
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14, // 14sp body medium
                  fontWeight: FontWeight.w400,
                  height: 1.43, // 20sp line height
                ),
              ),
            ),
          ],
        ),
        // Action button (if provided)
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
        // Material 3 Expressive Design Properties
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        elevation: _elevation,
        margin: _margin,
        duration: _duration,
        // Accessibility
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  // Dismiss all snackbars
  static void dismissAll(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  // Show snackbar with custom duration
  static void showCustom(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? backgroundColor,
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                ),
              ),
            ),
          ],
        ),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed ?? () {},
              )
            : null,
        backgroundColor: backgroundColor ?? _infoColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
        ),
        elevation: _elevation,
        margin: _margin,
        duration: duration ?? _duration,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
