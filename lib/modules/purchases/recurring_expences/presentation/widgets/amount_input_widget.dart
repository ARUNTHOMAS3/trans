import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

class AmountInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String selectedCurrency;
  final List<CurrencyLookupModel> currencies;
  final bool isLoadingCurrencies;
  final ValueChanged<String> onCurrencyChanged;
  final FormFieldValidator<String>? validator;
  final String hintText;
  final bool enableCurrencySelection;

  const AmountInputWidget({
    super.key,
    required this.controller,
    required this.selectedCurrency,
    required this.currencies,
    this.isLoadingCurrencies = false,
    required this.onCurrencyChanged,
    this.validator,
    this.hintText = '',
    this.enableCurrencySelection = true,
  });

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  static const double _maxBorderWidth = 1.5;
  static const double _outerFieldHeight = 32.0;

  bool _isHovered = false;
  late FocusNode _focusNode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _focusNode.hasFocus;
    final hasError = _errorText != null;
    final borderWidth = hasFocus ? _maxBorderWidth : 1.0;

    // Border color logic following AppTheme standard
    Color borderColor = AppTheme.borderColor;
    if (hasError) {
      borderColor = AppTheme.errorRed;
    } else if (hasFocus) {
      borderColor = AppTheme.primaryBlueDark;
    } else if (_isHovered) {
      borderColor = AppTheme.infoBlue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: SizedBox(
            height: _outerFieldHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      // Prefix Currency Button Section
                      widget.enableCurrencySelection
                          ? PopupMenuButton<String>(
                              tooltip: 'Select Currency',
                              initialValue: widget.selectedCurrency,
                              onSelected: (val) {
                                widget.onCurrencyChanged(val);
                              },
                              offset: const Offset(0, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: AppTheme.borderLight,
                                ),
                              ),
                              elevation: 4,
                              padding: EdgeInsets.zero,
                              itemBuilder: (context) {
                                return [
                                  PopupMenuItem<String>(
                                    enabled: false,
                                    padding: EdgeInsets.zero,
                                    child: _CurrencyDropdownContent(
                                      currentCurrency: widget.selectedCurrency,
                                      currencies: widget.currencies,
                                      isLoading: widget.isLoadingCurrencies,
                                      onSelected: (val) {
                                        Navigator.pop(context, val);
                                      },
                                    ),
                                  ),
                                ];
                              },
                              child: _currencyPrefixSection(
                                showDropdownIcon: true,
                              ),
                            )
                          : _currencyPrefixSection(showDropdownIcon: true),
                      // Text Field Input Section
                      Expanded(
                        child: Container(
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                          child: CustomTextField(
                            focusNode: _focusNode,
                            controller: widget.controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (val) {
                              final err = widget.validator?.call(val);
                              if (err != _errorText) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() => _errorText = err);
                                });
                              }
                              return err;
                            },
                            hintText: widget.hintText,
                            hideBorderDefault: true,
                            fillColor: Colors.transparent,
                            border: Border.all(
                              color: Colors.transparent,
                              width: 0,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: borderColor,
                          width: borderWidth,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            _errorText!,
            style: AppTextStyles.helper.copyWith(
              color: AppTheme.errorRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _currencyPrefixSection({required bool showDropdownIcon}) {
    return Container(
      width: 70,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(3),
          bottomLeft: Radius.circular(3),
        ),
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.selectedCurrency,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          if (showDropdownIcon) ...[
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrencyDropdownContent extends StatefulWidget {
  final String currentCurrency;
  final List<CurrencyLookupModel> currencies;
  final bool isLoading;
  final ValueChanged<String> onSelected;

  const _CurrencyDropdownContent({
    required this.currentCurrency,
    required this.currencies,
    required this.isLoading,
    required this.onSelected,
  });

  @override
  State<_CurrencyDropdownContent> createState() =>
      _CurrencyDropdownContentState();
}

class _CurrencyDropdownContentState extends State<_CurrencyDropdownContent> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: widget.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppTheme.space12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZBone(height: 14),
                        SizedBox(height: AppTheme.space10),
                        ZBone(width: 110, height: 14),
                        SizedBox(height: AppTheme.space10),
                        ZBone(width: 96, height: 14),
                        SizedBox(height: AppTheme.space10),
                        ZBone(width: 120, height: 14),
                      ],
                    ),
                  )
                : widget.currencies.isEmpty
                ? Center(
                    child: Text(
                      'No currencies found',
                      style: AppTextStyles.body.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    thickness: 4,
                    radius: const Radius.circular(2),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: widget.currencies.length,
                      itemBuilder: (context, index) {
                        final currency = widget.currencies[index];
                        final isSelected =
                            currency.code == widget.currentCurrency;
                        final isHovered = _hoveredIndex == index;

                        Color bg = Colors.transparent;
                        Color textCol = AppTheme.textPrimary;
                        if (isHovered) {
                          bg = AppTheme.infoBlue;
                          textCol = AppTheme.backgroundColor;
                        } else if (isSelected) {
                          bg = AppTheme.bgHover;
                          textCol = AppTheme.textPrimary;
                        }

                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: GestureDetector(
                            onTap: () => widget.onSelected(currency.code),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              color: bg,
                              child: Text(
                                currency.displayLabel,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: textCol,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class AddCurrencyDialog extends StatefulWidget {
  final ValueChanged<String> onAdded;
  final List<CurrencyLookupModel> currencies;

  const AddCurrencyDialog({
    super.key,
    required this.onAdded,
    required this.currencies,
  });

  @override
  State<AddCurrencyDialog> createState() => _AddCurrencyDialogState();
}

class _AddCurrencyDialogState extends State<AddCurrencyDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCode;
  final _symbolCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String? _selectedDecimalPlaces;
  String? _selectedFormat;

  static const _decimalOptions = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];
  static const _formatOptions = [
    '1,234,567.89',
    '1.234.567,89',
    '1 234 567.89',
  ];

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final currencyCodes = widget.currencies
        .map((option) => option.code)
        .toList(growable: false);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: screenH - 40),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'New Currency',
                            style: AppTextStyles.title.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),

                  // ── Form content ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Currency Code*
                        _verticalFormField(
                          label: 'Currency Code',
                          required: true,
                          child: FormDropdown<String>(
                            height: 32,
                            value: _selectedCode,
                            hint: 'Select',
                            items: currencyCodes,
                            onChanged: (val) {
                              setState(() => _selectedCode = val);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Currency Symbol*
                        _verticalFormField(
                          label: 'Currency Symbol',
                          required: true,
                          child: CustomTextField(
                            controller: _symbolCtrl,
                            hintText: '',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Currency Symbol is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Currency Name*
                        _verticalFormField(
                          label: 'Currency Name',
                          required: true,
                          child: CustomTextField(
                            controller: _nameCtrl,
                            hintText: '',
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Currency Name is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Decimal Places
                        _verticalFormField(
                          label: 'Decimal Places',
                          required: false,
                          child: FormDropdown<String>(
                            height: 32,
                            value: _selectedDecimalPlaces,
                            items: _decimalOptions,
                            hint: '',
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedDecimalPlaces = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Format
                        _verticalFormField(
                          label: 'Format',
                          required: false,
                          child: FormDropdown<String>(
                            height: 32,
                            value: _selectedFormat,
                            items: _formatOptions,
                            hint: '',
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedFormat = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: AppTheme.borderLight),

                  // ── Footer ──────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Theme(
                          data: AppTheme.themedWith(
                            AppTheme.accentGreen,
                          ), // matching success green
                          child: ZButton.primary(
                            label: 'Save and Select',
                            onPressed: () {
                              if (_selectedCode == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select a Currency Code',
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_formKey.currentState?.validate() ?? false) {
                                widget.onAdded(_selectedCode!);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ZButton.secondary(
                          label: 'Cancel',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
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

  Widget _verticalFormField({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style:
                (required ? AppTextStyles.labelRequired : AppTextStyles.label)
                    .copyWith(
                      fontWeight: required
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
            children: required
                ? [TextSpan(text: '*', style: AppTextStyles.labelRequired)]
                : [],
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
