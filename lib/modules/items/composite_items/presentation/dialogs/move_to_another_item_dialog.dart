import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import '../composite_item_visual_theme.dart';

class MoveToAnotherItemDialog extends StatefulWidget {
  final String existingItemName;
  final List<String> destinationItems;

  const MoveToAnotherItemDialog({
    super.key,
    required this.existingItemName,
    required this.destinationItems,
  });

  @override
  State<MoveToAnotherItemDialog> createState() => _MoveToAnotherItemDialogState();
}

class _MoveToAnotherItemDialogState extends State<MoveToAnotherItemDialog> {
  String? _selectedDestination;

  @override
  Widget build(BuildContext context) {
    return CompositeItemVisualTheme(
      child: Dialog(
        alignment: Alignment.topCenter,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
        child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Move your variant "${widget.existingItemName}" to another item!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    hoverColor: AppTheme.bgHover,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            
            // Body Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Existing Item
                  const Text(
                    'Existing Item',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CustomTextField(
                    enabled: false,
                    hintText: widget.existingItemName,
                  ),
                  
                  // Downward Arrow Indicator
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF3B7CFF), width: 1),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_downward,
                          size: 16,
                          color: Color(0xFF3B7CFF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Select Destination Item
                  const Text(
                    'Select Destination Item*',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: FormDropdown<String>(
                      value: _selectedDestination,
                      hint: 'Choose item',
                      items: widget.destinationItems,
                      onChanged: (val) {
                        setState(() => _selectedDestination = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Footer Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_selectedDestination == null) {
                        ZerpaiToast.error(context, 'Please choose a destination item.');
                        return;
                      }
                      ZerpaiToast.success(context, 'Variant moved successfully.');
                      Navigator.of(context).pop(_selectedDestination);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Move',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.borderColor),
                      minimumSize: const Size(80, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
