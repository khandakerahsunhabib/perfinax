import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { success, delete, info, error }

/// A sleek floating toast notification that displays above the docked floating button
/// without triggering Scaffold layout shifts or moving the floating action button.
class AppToast {
  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(milliseconds: 2600),
    IconData? icon,
  }) {
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Overlay.maybeOf(context);
    if (overlay == null) return;

    final IconData effectiveIcon = icon ?? _getDefaultIcon(type);
    final Color bgColor = _getBackgroundColor(type);
    final Color borderColor = _getBorderColor(type);
    final Color iconColor = _getIconColor(type);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ToastOverlayWidget(
        message: message,
        icon: effectiveIcon,
        bgColor: bgColor,
        borderColor: borderColor,
        iconColor: iconColor,
        duration: duration,
        onDismiss: () {
          if (_activeEntry == entry) {
            _activeEntry?.remove();
            _activeEntry = null;
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    if (_activeEntry != null) {
      _activeEntry?.remove();
      _activeEntry = null;
    }
  }

  static IconData _getDefaultIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.delete:
        return Icons.delete_outline_rounded;
      case ToastType.error:
        return Icons.error_outline_rounded;
      case ToastType.info:
        return Icons.info_outline_rounded;
    }
  }

  static Color _getBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF064E3B).withValues(alpha: 0.95);
      case ToastType.delete:
        return const Color(0xFF4C0519).withValues(alpha: 0.95);
      case ToastType.error:
        return const Color(0xFF450A0A).withValues(alpha: 0.95);
      case ToastType.info:
        return const Color(0xFF0F172A).withValues(alpha: 0.95);
    }
  }

  static Color _getBorderColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF10B981).withValues(alpha: 0.6);
      case ToastType.delete:
        return const Color(0xFFF43F5E).withValues(alpha: 0.6);
      case ToastType.error:
        return const Color(0xFFEF4444).withValues(alpha: 0.6);
      case ToastType.info:
        return const Color(0xFF06B6D4).withValues(alpha: 0.6);
    }
  }

  static Color _getIconColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF34D399);
      case ToastType.delete:
        return const Color(0xFFFB7185);
      case ToastType.error:
        return const Color(0xFFF87171);
      case ToastType.info:
        return const Color(0xFF38BDF8);
    }
  }
}

class _ToastOverlayWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastOverlayWidget({
    required this.message,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlayWidget> createState() => _ToastOverlayWidgetState();
}

class _ToastOverlayWidgetState extends State<_ToastOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _dismissTimer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 88, // Hovering right above the docked center floating action button
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: _handleTap,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: widget.borderColor, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, size: 18, color: widget.iconColor),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
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
      ),
    );
  }
}
