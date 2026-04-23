import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/utils/console_error_reporter.dart';
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
      bgColor = AppTheme.errorBg;
      borderColor = AppTheme.errorBgBorder;
      iconBgColor = AppTheme.errorRed;
      textColor = AppTheme.errorTextDark;
      icon = LucideIcons.alertCircle;
    } else if (isInfo) {
      bgColor = AppTheme.infoBg;
      borderColor = AppTheme.infoBgBorder;
      iconBgColor = AppTheme.primaryBlue;
      textColor = AppTheme.infoTextDark;
      icon = LucideIcons.info;
    } else {
      bgColor = const Color(0xFFF3FCF7);
      borderColor = AppTheme.successBg;
      iconBgColor = AppTheme.successGreen;
      textColor = AppTheme.successTextDark;
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

  static void saved(BuildContext context, String subject) {
    success(context, '$subject saved successfully');
  }

  static void deleted(BuildContext context, String subject) {
    success(context, '$subject deleted successfully');
  }

  static void info(BuildContext context, String message) {
    show(context, message, isInfo: true);
  }

  static void error(BuildContext context, String message) {
    ConsoleErrorReporter.log(
      'ZerpaiToast.error',
      details: {'message': message},
    );
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
      begin: const Offset(0, -0.12),
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
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
          child: FadeTransition(
            opacity: _opacity,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(14),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: widget.iconBgColor,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.textColor,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => widget.onDismissed(),
                          child: Icon(
                            LucideIcons.x,
                            size: 16,
                            color: widget.textColor.withValues(alpha: 0.85),
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
