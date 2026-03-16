import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ZerpaiToast {
  // Track the active overlay so we can dismiss it before showing a new one.
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isInfo = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dismiss any existing toast immediately.
    _currentEntry?.remove();
    _currentEntry = null;

    Color bgColor;
    Color borderColor;
    Color iconBgColor;
    Color textColor;
    IconData icon;

    if (isError) {
      bgColor = const Color(0xFFFFF5F5);
      borderColor = const Color(0xFFFED7D7);
      iconBgColor = AppTheme.errorRed;
      textColor = const Color(0xFFC53030);
      icon = LucideIcons.alertCircle;
    } else if (isInfo) {
      bgColor = const Color(0xFFEFF6FF);
      borderColor = const Color(0xFFDBEAFE);
      iconBgColor = AppTheme.primaryBlue;
      textColor = const Color(0xFF1E40AF);
      icon = LucideIcons.info;
    } else {
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFDCFCE7);
      iconBgColor = const Color(0xFF5ED3B3);
      textColor = const Color(0xFF4B5563);
      icon = LucideIcons.check;
    }

    // Use the root navigator overlay so the toast renders above all routes & dialogs.
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null || !overlay.mounted) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ZerpaiToastWidget(
        message: message,
        bgColor: bgColor,
        borderColor: borderColor,
        iconBgColor: iconBgColor,
        textColor: textColor,
        icon: icon,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry?.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) {
    show(context, message, isError: false);
  }

  static void info(BuildContext context, String message) {
    show(context, message, isInfo: true);
  }

  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }
}

class _ZerpaiToastWidget extends StatefulWidget {
  final String message;
  final Color bgColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color textColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ZerpaiToastWidget({
    required this.message,
    required this.bgColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.textColor,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ZerpaiToastWidget> createState() => _ZerpaiToastWidgetState();
}

class _ZerpaiToastWidgetState extends State<_ZerpaiToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _ctrl.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _ctrl.reverse().then((_) => widget.onDismissed());
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.iconBgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
