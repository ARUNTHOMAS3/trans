// import 'package:flutter/material.dart';

// typedef ZerpaiFieldBuilder =
//     Widget Function({
//       required String label,
//       bool? required,
//       String? helper,
//       String? tooltip,
//       double? maxWidth,
//       required Widget child,
//       Color? labelColor,
//     });

// typedef ZerpaiTextFieldBuilder =
//     Widget Function({
//       required TextEditingController controller,
//       String? hint,
//       TextInputType? keyboardType,
//       int? maxLines,
//       double? height,
//       bool? enabled,
//       String? errorText,
//     });

// typedef ZerpaiDropdownBuilder<T> =
//     Widget Function({
//       required T? value,
//       required List<T> items,
//       required ValueChanged<T?> onChanged,
//       String? hint,
//       Widget Function(T item, bool isSelected, bool isHovered)? itemBuilder,
//       String Function(T value)? displayStringForValue,
//       bool? showSettings,
//       String? settingsLabel,
//       VoidCallback? onSettingsTap,
//       bool? allowClear,
//       String? errorText,
//       bool? enabled,
//       bool? showSearch,
//       bool? showSearchIcon,
//     });
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
    });

class ZerpaiBuilders {
  static void showSuccessToast(BuildContext context, String message) {
    if (!context.mounted) return;

    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      double screenHeight = 800;
      try {
        screenHeight = MediaQuery.of(context).size.height;
      } catch (e) {
        // Fallback if MediaQuery lookup fails on deactivated widget
        debugPrint(
          'Safe Toast: MediaQuery lookup failed, using fallback height',
        );
      }

      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFF0FDF4),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: screenHeight - 100,
            left: 20,
            right: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Safe Toast: Failed to show snackbar - $e');
    }
  }
}
