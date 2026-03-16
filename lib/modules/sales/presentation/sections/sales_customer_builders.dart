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
          width: 80,
          child: FormDropdown<String>(
            height: _inputHeight,
            value: code,
            fillColor: const Color(0xFFF9FAFB),
            showRightBorder: true,
            items: const ['+91', '+1', '+44', '+971', '+61', '+974'],
            displayStringForValue: (v) => v,
            searchStringForValue: (v) => v,
            padding: const EdgeInsets.only(left: 12, right: 4),
            iconSize: 14,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            itemBuilder: (item, isSelected, isHovered) =>
                _buildPhonePrefixRow(item, isSelected, isHovered),
            onChanged: (v) {
              final nextCode = v ?? phonePrefixOptions.first;
              onCodeChanged(nextCode);
            },
          ),
        ),
        Expanded(
          child: CustomTextField(
            height: _inputHeight,
            controller: controller,
            hintText: hintText,
            keyboardType: TextInputType.phone,
            showLeftBorder: false,
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
    final label = phonePrefixLabels[code] ?? '';
    Color bg = Colors.transparent;
    Color text = const Color(0xFF111827);
    Color subtext = const Color(0xFF6B7280);
    Color check = const Color(0xFF2563EB);

    if (isSelected) {
      bg = const Color(0xFF3B82F6);
      text = Colors.white;
      subtext = Colors.white70;
      check = Colors.white;
    } else if (isHovered) {
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF1D4ED8);
      subtext = const Color(0xFF1D4ED8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: bg,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              code,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: subtext),
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
    Color bg = Colors.transparent;
    Color text = const Color(0xFF111827);
    Color subtext = const Color(0xFF6B7280);
    Color check = const Color(0xFF2563EB);

    if (isSelected) {
      bg = const Color(0xFF3B82F6);
      text = Colors.white;
      subtext = Colors.white70;
      check = Colors.white;
    } else if (isHovered) {
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF1D4ED8);
      subtext = const Color(0xFF1D4ED8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: bg,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              option.code,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: subtext),
            ),
          ),
          if (isSelected) Icon(Icons.check, size: 16, color: check),
        ],
      ),
    );
  }

  Widget _buildGstTreatmentRow(
    _GstTreatmentOption option,
    bool isSelected,
    bool isHovered,
  ) {
    Color bg = Colors.transparent;
    Color title = const Color(0xFF111827);
    Color subtitle = const Color(0xFF6B7280);
    Color check = const Color(0xFF2563EB);

    if (isSelected) {
      bg = const Color(0xFF3B82F6);
      title = Colors.white;
      subtitle = Colors.white70;
      check = Colors.white;
    } else if (isHovered) {
      bg = const Color(0xFFEFF6FF);
      title = const Color(0xFF1D4ED8);
      subtitle = const Color(0xFF1D4ED8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: subtitle),
                ),
              ],
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Icon(Icons.check, size: 16, color: check),
            ),
        ],
      ),
    );
  }

  List<String> _buildDisplayNameOptions(
    String currentSalutation,
    String firstName,
    String lastName,
  ) {
    final salutationText = currentSalutation.trim();
    final first = firstName.trim();
    final last = lastName.trim();

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

    return options
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  Widget _buildAmountRow(TextEditingController ctrl, String currencyCode) {
    return Row(
      children: [
        SizedBox(
          width: 75,
          child: FormDropdown<String>(
            height: _inputHeight,
            value: currencyCode,
            items: [currencyCode],
            padding: const EdgeInsets.only(left: 8, right: 2),
            iconSize: 14,
            onChanged: (_) {},
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.file_download_outlined,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text:
                      'Prefill Customer details from the GST portal using the '
                      "Customer's GSTIN. ",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1D4ED8),
                  ),
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: InkWell(
                        onTap: _openGstinPrefillDialog,
                        child: const Text(
                          'Prefill >',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
          child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        ),
      ),
    );

    if (tooltip == null || tooltip.isEmpty) {
      return button;
    }

    return Tooltip(message: tooltip, child: button);
  }

  Widget _labeledInlineField(String label, Widget field) {
    return Padding(
      padding: EdgeInsets.only(bottom: _fieldSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 24), // Match _buildFormRow gap
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool required = false,
    bool showInfo = false,
    String? tooltip,
    bool hasError = false,
    Widget? trailing,
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
                      color: hasError
                          ? const Color(0xFFDC2626)
                          : (required
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF374151)),
                    ),
                  ),
                ),
                if (required)
                  const Text(' *', style: TextStyle(color: Color(0xFFDC2626))),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: tooltip ?? 'More info',
                    triggerMode: TooltipTriggerMode.tap,
                    preferBelow: false,
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12), // Reduced gap for tighter design
          Expanded(
            child: Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _fieldWidth),
                    child: Container(
                      decoration: hasError
                          ? BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFDC2626),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: child,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing],
              ],
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
              backgroundColor: const Color(0xFF2563EB),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
            color: const Color(0xFF3B82F6),
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
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getFileIcon(file.extension),
                        size: 20,
                        color: const Color(0xFF3B82F6),
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
                              color: Color(0xFF6B7280),
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
}
