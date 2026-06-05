import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

Future<void> showCreditNoteBulkUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppTheme.textPrimary.withValues(alpha: 0.68),
    useSafeArea: false,
    builder: (context) => const CreditNoteBulkUpdateDialog(),
  );
}

class CreditNoteBulkUpdateDialog extends StatefulWidget {
  const CreditNoteBulkUpdateDialog({super.key});

  @override
  State<CreditNoteBulkUpdateDialog> createState() =>
      _CreditNoteBulkUpdateDialogState();
}

class _CreditNoteBulkUpdateDialogState
    extends State<CreditNoteBulkUpdateDialog> {
  static const _fieldOptions = <String>[
    'Sales Person',
    'Reference#',
    'Billing Address',
    'Shipping Address',
    'Billing and Shipping Address',
    'PDF Template',
    'Customer Notes',
    'Terms and Conditions',
  ];

  static const _salesPersonOptions = <String>[
    'ALTHAF',
    'MUHAMMED',
    'RASHID',
    'MUHAMMED SHABIN',
  ];

  static const _pdfTemplateOptions = <String>[
    'Spreadsheet Template',
    'Standard Template',
  ];

  static const _addresses = <Map<String, dynamic>>[
    {
      'name': 'ZABNIX PRIVATE LIMITED',
      'lines': [
        'malayanakath(h)',
        'vengoor (po)',
        'perinthalmanna',
        'Kerala 679322',
        'India',
        'Phone: +91-9895357101',
      ],
    },
    {
      'name': 'ZABNIX PRIVATE LIMITED (Branch)',
      'lines': [
        'malayanakath(h)',
        'vengoor',
        'PERINTHALMANNA',
        'perinthalmanna, Kerala',
        'India , 679322',
        'Phone: +91-08606259910',
      ],
    },
  ];

  final _valueController = TextEditingController();
  final _valueFocusNode = FocusNode();
  String? _selectedField;
  String? _selectedSalesPerson;
  String? _selectedPdfTemplate;
  int? _selectedAddressIndex;

  bool get _isAddressField =>
      _selectedField == 'Billing Address' ||
      _selectedField == 'Shipping Address' ||
      _selectedField == 'Billing and Shipping Address';

  bool get _isTextAreaField =>
      _selectedField == 'Customer Notes' ||
      _selectedField == 'Terms and Conditions';

  @override
  void dispose() {
    _valueController.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                child: Row(
                  children: [
                    const Text(
                      'Bulk Update Credit Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a field from the dropdown and update with new information.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isAddressField) ...[
                    // Address layout: field dropdown on top row, form section below
                    SizedBox(
                      width: 220,
                      child: _buildFieldDropdown(),
                    ),
                    const SizedBox(height: 12),
                    _BulkAddressFormSection(
                      addresses: _addresses,
                      selectedIndex: _selectedAddressIndex,
                      customerName: 'CUS-1',
                      onSelected: (i) => setState(() => _selectedAddressIndex = i),
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 220,
                          child: _buildFieldDropdown(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectedField == 'Sales Person'
                              ? FormDropdown<String>(
                                  value: _selectedSalesPerson,
                                  items: _salesPersonOptions,
                                  hint: 'Select sales person',
                                  height: 36,
                                  showSearch: false,
                                  menuMaxHeight: 200,
                                  fillColor: AppTheme.backgroundColor,
                                  displayStringForValue: (v) => v,
                                  itemBuilder: (val, isSelected, isHovered) => Container(
                                    height: 36,
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    alignment: Alignment.centerLeft,
                                    color: isHovered ? AppTheme.primaryBlue : Colors.white,
                                    child: Text(
                                      val,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isHovered ? Colors.white : AppTheme.textPrimary,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) => setState(() => _selectedSalesPerson = val),
                                )
                              : _selectedField == 'PDF Template'
                                  ? FormDropdown<String>(
                                      value: _selectedPdfTemplate,
                                      items: _pdfTemplateOptions,
                                      hint: 'Select template',
                                      height: 36,
                                      showSearch: false,
                                      menuMaxHeight: 120,
                                      fillColor: AppTheme.backgroundColor,
                                      displayStringForValue: (v) => v,
                                      itemBuilder: (val, isSelected, isHovered) => Container(
                                        height: 36,
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        alignment: Alignment.centerLeft,
                                        color: isHovered ? AppTheme.primaryBlue : Colors.white,
                                        child: Text(
                                          val,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isHovered ? Colors.white : AppTheme.textPrimary,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) => setState(() => _selectedPdfTemplate = val),
                                    )
                                  : _isTextAreaField
                                      ? TextField(
                                          controller: _valueController,
                                          focusNode: _valueFocusNode,
                                          autofocus: true,
                                          maxLines: 5,
                                          minLines: 5,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: AppTheme.backgroundColor,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4),
                                              borderSide: const BorderSide(color: AppTheme.borderColor),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4),
                                              borderSide: const BorderSide(color: AppTheme.borderColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(4),
                                              borderSide: const BorderSide(color: AppTheme.primaryBlue),
                                            ),
                                          ),
                                        )
                                      : CustomTextField(
                                          controller: _valueController,
                                          focusNode: _valueFocusNode,
                                          autoFocus: true,
                                          height: 36,
                                          hintText: '',
                                          fillColor: AppTheme.backgroundColor,
                                          borderRadius: BorderRadius.circular(4),
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppTheme.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: 'Note: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              'All the selected credit notes will be updated with the new information and you cannot undo this action.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    _BulkDialogActionButton(
                      label: 'Update',
                      primary: true,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    _BulkDialogActionButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldDropdown() {
    return FormDropdown<String>(
      value: _selectedField,
      items: _fieldOptions,
      hint: 'Select a field',
      height: 36,
      showSearch: false,
      menuWidth: 260,
      menuMaxHeight: 240,
      fillColor: AppTheme.backgroundColor,
      displayStringForValue: (value) => value,
      itemBuilder: (val, isSelected, isHovered) => Container(
        height: 36,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        color: isHovered ? AppTheme.primaryBlue : Colors.white,
        child: Text(
          val,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: isHovered ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
      onChanged: (value) {
        setState(() {
          _selectedField = value;
          _selectedSalesPerson = null;
          _selectedPdfTemplate = null;
          _selectedAddressIndex = null;
          _valueController.clear();
        });
        if (value != 'Sales Person' &&
            value != 'PDF Template' &&
            value != 'Billing Address' &&
            value != 'Shipping Address' &&
            value != 'Billing and Shipping Address') {
          _valueFocusNode.requestFocus();
        }
      },
    );
  }
}

// ─── Address Form Section (compact, with overlay popup) ─────────────────────────

class _BulkAddressFormSection extends StatefulWidget {
  final List<Map<String, dynamic>> addresses;
  final int? selectedIndex;
  final String customerName;
  final ValueChanged<int> onSelected;

  const _BulkAddressFormSection({
    required this.addresses,
    required this.selectedIndex,
    required this.customerName,
    required this.onSelected,
  });

  @override
  State<_BulkAddressFormSection> createState() =>
      _BulkAddressFormSectionState();
}

class _BulkAddressFormSectionState extends State<_BulkAddressFormSection> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;

  void _openPicker() {
    _overlay?.remove();
    final entry = OverlayEntry(builder: (ctx) {
      return Stack(children: [
        GestureDetector(
          onTap: _closePicker,
          behavior: HitTestBehavior.translucent,
          child: const SizedBox.expand(),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 4),
          child: Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 360,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textPrimary.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...widget.addresses.asMap().entries.map((entry) {
                      final i = entry.key;
                      final addr = entry.value;
                      final isSelected = i == widget.selectedIndex;
                      return _BulkAddressCard(
                        address: addr,
                        isSelected: isSelected,
                        onSelected: () {
                          widget.onSelected(i);
                          _closePicker();
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]);
    });

    _overlay = entry;
    Overlay.of(context).insert(entry);
    setState(() {});
  }

  void _closePicker() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedIndex != null
        ? widget.addresses[widget.selectedIndex!]
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CREDIT NOTES ADDRESS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Customer Name: ',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              Text(
                widget.customerName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (widget.selectedIndex == null) ...[
                const SizedBox(width: 10),
                CompositedTransformTarget(
                  link: _layerLink,
                  child: GestureDetector(
                    onTap: _overlay == null ? _openPicker : _closePicker,
                    child: Text(
                      'Choose existing address',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                        decoration: TextDecoration.underline,
                        decorationColor: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
              ] else
                CompositedTransformTarget(link: _layerLink, child: const SizedBox.shrink()),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 10),
            Text(
              selected['name'] as String? ?? '',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            ...(selected['lines'] as List<dynamic>? ?? const []).map(
              (line) => Text(
                line as String,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Address Card (used in overlay popup) ────────────────────────────────────────

class _BulkAddressCard extends StatefulWidget {
  final Map<String, dynamic> address;
  final bool isSelected;
  final VoidCallback onSelected;

  const _BulkAddressCard({
    required this.address,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<_BulkAddressCard> createState() => _BulkAddressCardState();
}

class _BulkAddressCardState extends State<_BulkAddressCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.address['lines'] as List<dynamic>? ?? const <String>[];
    final bgColor = _hovered
        ? AppTheme.primaryBlue
        : widget.isSelected
            ? AppTheme.bgDisabled
            : AppTheme.backgroundColor;
    final titleColor = _hovered ? AppTheme.backgroundColor : AppTheme.textPrimary;
    final detailColor = _hovered
        ? AppTheme.backgroundColor.withValues(alpha: 0.82)
        : AppTheme.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address['name'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...lines.map(
                      (line) => Text(
                        line as String,
                        style: TextStyle(fontSize: 12, color: detailColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    LucideIcons.pencil,
                    size: 14,
                    color: _hovered ? AppTheme.backgroundColor : AppTheme.primaryBlue,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dialog Action Button ─────────────────────────────────────────────────────────

class _BulkDialogActionButton extends StatefulWidget {
  const _BulkDialogActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_BulkDialogActionButton> createState() =>
      _BulkDialogActionButtonState();
}

class _BulkDialogActionButtonState extends State<_BulkDialogActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.primary
        ? AppTheme.accentGreen
        : _hovered
            ? AppTheme.bgLight
            : AppTheme.backgroundColor;
    final textColor =
        widget.primary ? AppTheme.backgroundColor : AppTheme.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: EdgeInsets.symmetric(horizontal: widget.primary ? 14 : 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(4),
            border: widget.primary
                ? null
                : Border.all(color: AppTheme.borderColor),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
