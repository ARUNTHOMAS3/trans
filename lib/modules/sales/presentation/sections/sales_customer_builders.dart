part of '../sales_customer_create.dart';

extension _SalesCustomerBuilders on _SalesCustomerCreateScreenState {
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
            menuWidth: 240,
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
    Color nameColor = AppTheme.textSecondary; // Gray 500

    if (isSelected) {
      bg = AppTheme.infoBlue; // Blue 500
      textColor = Colors.white;
      nameColor = Colors.white.withValues(alpha: 0.9);
    } else if (isHovered) {
      bg = AppTheme.bgDisabled; // Gray 100
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

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool required = false,
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
                      color: (hasError || required || label.contains('*'))
                          ? const Color(0xFFDC2626)
                          : AppTheme.textBody,
                    ),
                  ),
                ),
                if (required || label.contains('*'))
                  const Text(' *', style: TextStyle(color: Color(0xFFDC2626))),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  ZTooltip(
                    message: tooltip ?? 'More info',
                    child: const Icon(
                      LucideIcons.helpCircle,
                      size: 14,
                      color: AppTheme.textMuted,
                    ),
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
    Color subtext = AppTheme.textSecondary;
    Color check = AppTheme.primaryBlueDark;

    if (isHovered) {
      bg = AppTheme.infoBlue;
      text = Colors.white;
      subtext = Colors.white70;
      check = Colors.white;
    } else if (isSelected) {
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF1D4ED8);
      subtext = const Color(0xFF1D4ED8);
      check = AppTheme.primaryBlueDark;
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

  Widget _buildGstTreatmentRow(
    _GstTreatmentOption option,
    bool isSelected,
    bool isHovered,
  ) {
    return _buildStandardLookupRow(
      option.label,
      isSelected,
      isHovered,
      sublabel: option.description,
    );
  }

  List<String> _buildDisplayNameOptions(
    String currentSalutation,
    String firstName,
    String lastName,
    String companyName,
  ) {
    final salutationText = currentSalutation.trim();
    final first = firstName.trim();
    final last = lastName.trim();
    final company = companyName.trim();

    final fullName = [first, last].where((name) => name.isNotEmpty).join(' ');
    final options = <String>[];

    if (salutationText.isNotEmpty && fullName.isNotEmpty) {
      options.add('$salutationText $fullName');
    }
    if (fullName.isNotEmpty) {
      options.add(fullName);
    }
    if (first.isNotEmpty && last.isNotEmpty) {
      options.add('$last, $first');
    }
    if (company.isNotEmpty) {
      options.add(company);
    }

    return options
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  Widget _buildAmountRow(TextEditingController ctrl, String currencyCode) {
    return Row(
      children: [
        Container(
          width: 75,
          height: _inputHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            currencyCode,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textBody,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomTextField(
            height: _inputHeight,
            controller: ctrl,
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildPrefillBanner() {
    return GstinPrefillBanner(
      entityLabel: 'Customer',
      onPrefill: _openGstinPrefillDialog,
    );
  }

  Widget _buildCustomerNumberDialogHeader(BuildContext dialogContext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
      child: Row(
        children: [
          const Text(
            'Configure Customer Numbers Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFE11D48)),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSquareIconButton(
    IconData icon, {
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          height: _inputHeight,
          width: _inputHeight,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryBlueDark),
        ),
      ),
    );

    if (tooltip == null || tooltip.isEmpty) {
      return button;
    }

    return ZTooltip(message: tooltip, child: button);
  }

  Widget _buildGreenSearchButton({VoidCallback? onPressed}) {
    return Material(
      color: const Color(0xFF22C55E), // Green from UI
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(6),
        bottomRight: Radius.circular(6),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
        child: Container(
          height: _inputHeight,
          width: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: const Icon(Icons.search, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _labeledInlineField(String label, Widget field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppTheme.textBody,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _fieldWidth),
                child: field,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _saveCustomer,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: AppTheme.primaryBlueDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRoutes.salesCustomers);
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection({
    required List<PlatformFile> files,
    required VoidCallback onPick,
    required void Function(PlatformFile) onRemove,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Upload Button
            Container(
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: onPick,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.upload,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Upload File',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Attachment Count Badge
            if (files.isNotEmpty)
              _buildAttachmentCountBadge(files: files, onRemove: onRemove),
          ],
        ),
        if (hintText != null) ...[
          const SizedBox(height: 12),
          Text(
            hintText,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentCountBadge({
    required List<PlatformFile> files,
    required void Function(PlatformFile) onRemove,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: PopupMenuButton<PlatformFile>(
        offset: const Offset(0, 40),
        position: PopupMenuPosition.under,
        tooltip: 'Show attachments',
        padding: EdgeInsets.zero,
        surfaceTintColor: Colors.white,
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.infoBlue,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.paperclip, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                '${files.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        itemBuilder: (context) {
          return files.map((file) {
            return PopupMenuItem<PlatformFile>(
              enabled: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                constraints: const BoxConstraints(minWidth: 280),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDisabled,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getFileIcon(file.extension),
                        size: 20,
                        color: AppTheme.infoBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'File Size: ${_formatFileSize(file.size)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onRemove(file);
                      },
                      icon: const Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
        },
      ),
    );
  }

  IconData _getFileIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return LucideIcons.fileText;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return LucideIcons.image;
      case 'docx':
      case 'doc':
        return LucideIcons.fileText;
      case 'xlsx':
      case 'xls':
        return LucideIcons.fileSpreadsheet;
      default:
        return LucideIcons.file;
    }
  }

  Widget _buildPaymentTermRow(
    String termName,
    bool isSelected,
    bool isHovered,
  ) {
    return _buildStandardLookupRow(termName, isSelected, isHovered);
  }

  Future<void> _showConfigurePaymentTermsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => ManagePaymentTermsDialog(
        items: _paymentTermsList,
        selectedId: paymentTerms,
        onSelect: (term) {
          _state(() {
            paymentTerms = term['id'];
          });
        },
        onSave: (items) async {
          final lookupsService = LookupsApiService();
          final updated = await lookupsService.syncPaymentTerms(items);

          _state(() {
            // Find its new real ID if it was new
            if (paymentTerms.startsWith('new_')) {
              final oldTerm = items.firstWhere(
                (it) => it['id'] == paymentTerms,
                orElse: () => {},
              );
              final termName = oldTerm['term_name'];

              if (termName != null) {
                final newTerm = updated.firstWhere(
                  (it) => it['term_name'] == termName,
                  orElse: () => {},
                );
                if (newTerm.containsKey('id')) {
                  paymentTerms = newTerm['id'];
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
            AppLogger.error('Error checking usage', error: e);
          }
          return null;
        },
      ),
    );
  }
}
