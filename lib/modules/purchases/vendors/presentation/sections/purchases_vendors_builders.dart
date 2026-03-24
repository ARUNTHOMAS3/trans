part of '../purchases_vendors_vendor_create.dart';

extension _PurchasesVendorsBuilders
    on _PurchasesVendorsVendorCreateScreenState {
  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool isRequired = false,
    bool showInfo = true,
    String? tooltip,
    bool hasError = false,
    double? customFieldWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: _fieldSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: (hasError || isRequired || label.contains('*'))
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
                if (label.contains('*') || isRequired)
                  const Text(' *', style: TextStyle(color: Color(0xFFDC2626))),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  ZTooltip(
                    message: tooltip ?? 'More info',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: customFieldWidth ?? _fieldWidth,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardLookupRow(
    String label,
    bool isSelected,
    bool isHovered, {
    String? sublabel,
  }) {
    Color bg = Colors.transparent;
    Color text = const Color(0xFF111827);
    Color subtext = const Color(0xFF6B7280);
    Color check = const Color(0xFF2563EB);

    if (isHovered) {
      // Hover now gets the prominent "Blue" style
      bg = const Color(0xFF3B82F6);
      text = Colors.white;
      subtext = Colors.white70;
      check = Colors.white;
    } else if (isSelected) {
      // Selection now gets the "Lite Blue" style
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF1D4ED8);
      subtext = const Color(0xFF1D4ED8);
      check = const Color(0xFF2563EB);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bg,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(fontSize: 12, color: subtext),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (isSelected) Icon(Icons.check, size: 16, color: check),
        ],
      ),
    );
  }

  Widget _buildPhoneRow({
    required String code,
    required ValueChanged<String> onCodeChanged,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: FormDropdown<String>(
            height: _inputHeight,
            value: code,
            items: _phoneCodesList,
            menuWidth: 240, // Match the wider design from the reference image
            displayStringForValue: (v) => v,
            searchStringForValue: (v) => v,
            padding: const EdgeInsets.only(left: 6, right: 2),
            iconSize: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            itemBuilder: (item, isSelected, isHovered) =>
                _buildPhonePrefixRow(item, isSelected, isHovered),
            onChanged: (v) {
              final nextCode = v ?? '+91';
              onCodeChanged(nextCode);
              _trimPhoneForCode(nextCode, controller);
            },
          ),
        ),
        Expanded(
          child: CustomTextField(
            height: _inputHeight,
            controller: controller,
            hintText: hintText,
            keyboardType: TextInputType.phone,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_phoneMaxLengthForCode(code)),
            ],
            forceUppercase: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPhonePrefixRow(String code, bool isSelected, bool isHovered) {
    // Get the name from DB map or fallback constants
    String name = _phoneCodeToLabel[code] ?? phonePrefixLabels[code] ?? '';

    // Clean up name (remove emojis and redundant codes like (+91))
    name = name
        .replaceAll(
          RegExp(
            r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
          ),
          '',
        )
        .trim();
    if (name.contains('(')) {
      name = name.split('(')[0].trim();
    }

    Color bg = Colors.transparent;
    Color textColor = const Color(0xFF1F2937); // Gray 800
    Color nameColor = const Color(0xFF6B7280); // Gray 500

    if (isSelected) {
      bg = const Color(0xFF3B82F6); // Blue 500
      textColor = Colors.white;
      nameColor = Colors.white.withValues(alpha: 0.9);
    } else if (isHovered) {
      bg = const Color(0xFFF3F4F6); // Gray 100
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bg,
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              code,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: nameColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyRow(
    CurrencyOption option,
    bool isSelected,
    bool isHovered,
  ) {
    return _buildStandardLookupRow(option.label, isSelected, isHovered);
  }

  Widget _buildPaymentTermRow(
    String termName,
    bool isSelected,
    bool isHovered,
  ) {
    return _buildStandardLookupRow(termName, isSelected, isHovered);
  }

  Widget _buildTdsRateRow(String label, bool isSelected, bool isHovered) {
    return _buildStandardLookupRow(label, isSelected, isHovered);
  }

  Future<void> _showConfigurePaymentTermsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ManagePaymentTermsDialog(
        items: _paymentTermsList,
        selectedId: _paymentTerms,
        onSelect: (term) {
          _state(() {
            _paymentTerms = term['id'];
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncPaymentTerms(items);

          _state(() {
            // If the currently selected term was a "new_" one, we need to find its new real ID
            if (_paymentTerms != null && _paymentTerms!.startsWith('new_')) {
              // Find the name of the term that was selected
              final oldTerm = items.firstWhere(
                (it) => it['id'] == _paymentTerms,
                orElse: () => {},
              );
              final termName = oldTerm['term_name'];

              if (termName != null) {
                // Find the same term in the updated list by name
                final newTerm = updated.firstWhere(
                  (it) => it['term_name'] == termName,
                  orElse: () => {},
                );
                if (newTerm.containsKey('id')) {
                  _paymentTerms = newTerm['id'];
                }
              }
            }

            _paymentTermsList = updated;
          });
          return updated;
        },
        onDeleteCheck: (item) async {
          if (item['id'] == null || item['id'].toString().startsWith('new_')) {
            return null;
          }

          try {
            final lookupsService = LookupsApiService();
            final usage = await lookupsService.checkLookupUsage(
              'payment-terms',
              item['id'].toString(),
            );

            if (usage['inUse'] == true) {
              return usage['message'] ??
                  'This payment term is in use and cannot be deleted.';
            }
          } catch (e) {
            AppLogger.error('Error checking payment term usage', error: e, module: 'purchases');
          }
          return null;
        },
      ),
    );
  }
}
