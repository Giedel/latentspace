import 'dart:async';

import 'package:flutter/material.dart';

/// Shared app feedback that floats directly above the docked centre action
/// button. Leaving [SnackBar.margin] unset lets Scaffold position it around
/// the FAB instead of applying an additional, overly large offset.
class AppFeedback {
  static const _themeColor = Color(0xFF6B4FA0);

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle_rounded,
    String? actionLabel,
    Future<void> Function()? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 3,
        duration: duration,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _themeColor.withValues(alpha: 0.18)),
        ),
        content: SizedBox(
          height: 40,
          child: Row(
            children: [
              Icon(icon, color: _themeColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    unawaited(onAction());
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _themeColor,
                    minimumSize: const Size(48, 32),
                    maximumSize: const Size(72, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
