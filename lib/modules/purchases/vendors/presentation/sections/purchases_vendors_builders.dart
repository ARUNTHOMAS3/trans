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
