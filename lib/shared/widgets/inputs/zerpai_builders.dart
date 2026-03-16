import 'package:flutter/material.dart';

typedef ZerpaiFieldBuilder =
    Widget Function({
      required String label,
      bool required,
      String? helper,
      String? tooltip,
      required Widget child,
      Color? labelColor,
    });

typedef ZerpaiTextFieldBuilder =
    Widget Function({
      required TextEditingController controller,
      String? hint,
      TextInputType keyboardType,
      int maxLines,
      double height,
      bool enabled,
      String? errorText,
    });

typedef ZerpaiDropdownBuilder =
    Widget Function<T>({
      required T? value,
      required List<T> items,
      required ValueChanged<T?> onChanged,
      String? hint,
      Widget Function(T item, bool isSelected, bool isHovered)? itemBuilder,
      String Function(T value)? displayStringForValue,
      bool showSettings,
      String settingsLabel,
      VoidCallback? onSettingsTap,
      bool allowClear,
      String? errorText,
      bool enabled,
      bool showSearch,
      bool showSearchIcon,
      Future<List<T>> Function(String query)? onSearch,
    });

class ZerpaiBuilders {
  static String parseErrorMessage(dynamic e, String label) {
    String errorStr = e.toString().toLowerCase();

    // 1. Try to extract a clean message from Dio/Backend response JSON
    if (errorStr.contains('dioexception') || errorStr.contains('message:')) {
      try {
        final messageRegExp = RegExp(
          r'message: (.*?)(,|$|})',
          caseSensitive: false,
        );
        final match = messageRegExp.firstMatch(errorStr);
        if (match != null && match.group(1) != null) {
          final extracted = match.group(1)!.trim();
          if (extracted != 'null' && extracted.isNotEmpty) {
            errorStr = extracted.toLowerCase();
          }
        }
      } catch (_) {}
    }

    // 2. Pattern Match for user-friendly translations

    // Association / In use check
    if (errorStr.contains('associated with') ||
        errorStr.contains('in use') ||
        errorStr.contains('used in')) {
      // If the error message is already descriptive (starts with "Cannot delete"), return it as is
      if (errorStr.contains('cannot delete')) {
        return '${errorStr[0].toUpperCase()}${errorStr.substring(1)}';
      }
      return '${label[0].toUpperCase()}${label.substring(1)} cannot be deleted since it is associated with other records.';
    }

    // Subcategory check
    if (errorStr.contains('subcategories') || errorStr.contains('children')) {
      return 'You have to delete the subcategories first to delete the parent category.';
    }

    // Duplicate check
    if (errorStr.contains('already found') ||
        errorStr.contains('unique_violation') ||
        errorStr.contains('already exists')) {
      return '$label is already found.';
    }

    // Deactivated widget side effect
    if (errorStr.contains('deactivated widget')) {
      return 'Operation completed with a minor UI sync error. Please refresh.';
    }

    // If we have a clean extracted message that didn't match patterns, return it capitalized
    if (errorStr.length < 200 &&
        !errorStr.contains('dioexception') &&
        errorStr.isNotEmpty) {
      // Clean up internal technical names if they leaked through
      final clean = errorStr
          .replaceAll('reorder_terms', label)
          .replaceAll('_', ' ');
      return '${clean[0].toUpperCase()}${clean.substring(1)}';
    }

    return 'Error: ${e.toString()}';
  }

  static Widget buildErrorAlert({
    required BuildContext context,
    required String message,
    required VoidCallback onClose,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFEE2E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Color(0xFF991B1B), size: 16),
          ),
        ],
      ),
    );
  }

  static void showSuccessToast(BuildContext context, String message) {
    if (!context.mounted) return;

    final overlay = Overlay.of(context);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        onDismiss: () {
          if (entry != null && entry!.mounted) {
            entry!.remove();
            entry = null;
          }
        },
      ),
    );

    overlay.insert(entry!);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ToastWidget({required this.message, required this.onDismiss});

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Start exit animation after 2.6s (total 3s minus 400ms exit)
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Color(0xFF166534),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
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
