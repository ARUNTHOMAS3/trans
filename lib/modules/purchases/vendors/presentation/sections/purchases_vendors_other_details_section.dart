part of '../purchases_vendors_vendor_create.dart';

extension _OtherDetailsSection on _PurchasesVendorsVendorCreateScreenState {
  Widget _buildOtherDetails() {
    final hideGstRegistrationFields = _shouldHideGstRegistrationFields();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          _buildFormRow(
            label: 'GST Treatment',
            isRequired: true,
            showInfo: false,
            tooltip: 'GST classification for this vendor.',
            child: FormDropdown<_GstTreatmentOption>(
              height: _inputHeight,
              value: _gstTreatment,
              items: _gstTreatmentOptions,
              hint: 'Select a GST treatment',
              displayStringForValue: (v) => v.label,
              searchStringForValue: (v) => '${v.label} ${v.description}',
              itemBuilder: (item, isSelected, isHovered) =>
                  _buildGstTreatmentRow(item, isSelected, isHovered),
              onChanged: (v) => _state(() => _gstTreatment = v),
            ),
          ),

          if (!hideGstRegistrationFields) ...[
            _buildFormRow(
              label: 'GSTIN / UIN',
              isRequired: true,
              showInfo: true,
              tooltip: 'GST registration number for this vendor.',
              customFieldWidth: _fieldWidth + 150,
              child: Row(
                children: [
                  SizedBox(
                    width: _fieldWidth,
                    child: CustomTextField(
                      height: _inputHeight,
                      controller: _gstinPrefillCtrl,
                      forceUppercase: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () {
                      if (_gstinPrefillCtrl.text.trim().isEmpty) {
                        ZerpaiToast.info(context, 'Enter a GSTIN to fetch details.');
                        return;
                      }
                      _openGstinPrefillDialog();
                    },
                    child: const Text(
                      'Get Taxpayer details',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!_shouldHideSourceOfSupply()) ...[
            _buildFormRow(
              label: 'Source of Supply*',
              isRequired: true,
              tooltip: 'State used for GST source of supply.',
              child: FormDropdown<String>(
                height: _inputHeight,
                value: _sourceOfSupply,
                items: _sourceOfSupplyList,
                hint: 'Select source of supply',
                itemBuilder: (item, isSelected, isHovered) =>
                    _buildStandardLookupRow(item, isSelected, isHovered),
                onChanged: (val) => _state(() => _sourceOfSupply = val),
              ),
            ),
          ],

          _buildFormRow(
            label: 'PAN',
            tooltip: 'Permanent Account Number for the vendor.',
            child: CustomTextField(
              height: _inputHeight,
              controller: _panCtrl,
              forceUppercase: true,
            ),
          ),

          _buildFormRow(
            label: 'Currency',
            tooltip: 'Default currency for transactions with this vendor.',
            child: FormDropdown<CurrencyOption>(
              height: _inputHeight,
              value: _currency,
              items: _localCurrencyOptions,
              onSearch: (q) async {
                return await ref.read(currenciesProvider(q).future);
              },
              displayStringForValue: (v) => v.label,
              searchStringForValue: (v) => '${v.code} ${v.name}',
              itemBuilder: (item, isSelected, isHovered) =>
                  _buildCurrencyRow(item, isSelected, isHovered),
              onChanged: (val) => _state(() => _currency = val ?? _currency),
            ),
          ),

          _buildFormRow(
            label: 'Payment Terms',
            tooltip: 'Default payment terms for bills from this vendor.',
            child: FormDropdown<String>(
              height: _inputHeight,
              value: _paymentTerms,
              items: _paymentTermsList.map((t) => t['id'] as String).toList(),
              showSettings: true,
              settingsLabel: 'Configure Terms',
              onSettingsTap: _showConfigurePaymentTermsDialog,
              displayStringForValue: (id) {
                final term = _paymentTermsList.firstWhere(
                  (t) => t['id'] == id,
                  orElse: () => {'term_name': ''},
                );
                return term['term_name'] ?? '';
              },
              searchStringForValue: (id) {
                final term = _paymentTermsList.firstWhere(
                  (t) => t['id'] == id,
                  orElse: () => {'term_name': ''},
                );
                return term['term_name'] ?? '';
              },
              itemBuilder: (id, isSelected, isHovered) {
                final term = _paymentTermsList.firstWhere(
                  (t) => t['id'] == id,
                  orElse: () => {'term_name': '', 'number_of_days': 0},
                );
                return _buildPaymentTermRow(
                  term['term_name'] ?? '',
                  isSelected,
                  isHovered,
                );
              },
              onChanged: (val) => _state(() => _paymentTerms = val),
            ),
          ),

          _buildFormRow(
            label: 'TDS',
            tooltip: 'Tax Deducted at Source settings for this vendor.',
            child: FormDropdown<String>(
              height: _inputHeight,
              value: _tdsRateId,
              items: _tdsRatesList.map((t) => t['id'] as String).toList(),
              hint: 'Select a Tax',
              displayStringForValue: (id) {
                final rate = _tdsRatesList.firstWhere(
                  (t) => t['id'] == id,
                  orElse: () => {'tax_name': ''},
                );
                final name = rate['tax_name'] ?? '';
                final baseRate = rate['base_rate'] ?? rate['tax_rate'];
                if (baseRate != null) {
                  return '$name [$baseRate%]';
                }
                return name;
              },
              itemBuilder: (id, isSelected, isHovered) {
                final rate = _tdsRatesList.firstWhere(
                  (t) => t['id'] == id,
                  orElse: () => {'tax_name': ''},
                );
                final name = rate['tax_name'] ?? '';
                final baseRate = rate['base_rate'] ?? rate['tax_rate'];
                final label = baseRate != null ? '$name [$baseRate%]' : name;
                return _buildTdsRateRow(label, isSelected, isHovered);
              },
              onChanged: (val) => _state(() => _tdsRateId = val),
            ),
          ),
          _buildFormRow(
            label: 'Price List',
            isRequired: false,
            tooltip: 'Default price list for this vendor.',
            child: FormDropdown<String>(
              height: _inputHeight,
              value: _priceListId,
              items: _priceListsList.map((p) => p['id'] as String).toList(),
              hint: 'Select a Price List',
              displayStringForValue: (id) {
                final pl = _priceListsList.firstWhere(
                  (p) => p['id'] == id,
                  orElse: () => {'name': ''},
                );
                return pl['name'] ?? '';
              },
              itemBuilder: (id, isSelected, isHovered) {
                final pl = _priceListsList.firstWhere(
                  (p) => p['id'] == id,
                  orElse: () => {'name': ''},
                );
                return _buildStandardLookupRow(
                  pl['name'] ?? '',
                  isSelected,
                  isHovered,
                );
              },
              onChanged: (val) => _state(() => _priceListId = val),
            ),
          ),

          _buildFormRow(
            label: 'Enable Portal?',
            tooltip: 'Allow portal access for this vendor.',
            child: Row(
              children: [
                Checkbox(
                  value: _enablePortal,
                  onChanged: (val) => _state(() => _enablePortal = val!),
                  activeColor: const Color(0xFF2563EB),
                ),
                Expanded(
                  child: Text(
                    _enablePortal
                        ? 'Allow portal access for this vendor ( Email address is mandatory )'
                        : 'Allow portal access for this vendor',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          _buildFormRow(
            label: 'Documents',
            tooltip: 'Upload relevant documents for this vendor.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    DottedBorder(
                      color: const Color(0xFF3B82F6),
                      strokeWidth: 1,
                      dashPattern: const [4, 2],
                      borderType: BorderType.RRect,
                      radius: const Radius.circular(4),
                      child: Container(
                        height: _inputHeight,
                        constraints: const BoxConstraints(minWidth: 140),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _pickFiles,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.upload,
                                      size: 16,
                                      color: Color(0xFF6B7280),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Upload File',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: const Color(0xFFE5E7EB),
                            ),
                            InkWell(
                              onTap: () {},
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_attachedFiles.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      CompositedTransformTarget(
                        link: _attachedFilesLink,
                        child: Material(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(4),
                          child: InkWell(
                            onTap: _toggleAttachedFilesList,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.paperclip,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_attachedFiles.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'You can upload a maximum of 10 files, 10MB each',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  _state(() => _showMoreDetails = !_showMoreDetails),
              icon: Icon(_showMoreDetails ? Icons.remove : Icons.add, size: 16),
              label: Text(
                _showMoreDetails ? 'Hide more details' : 'Add more details',
              ),
            ),
          ),

          if (_showMoreDetails) ...[
            const SizedBox(height: 16),
            _buildAdditionalDetails(),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalDetails() {
    return Column(
      children: [
        _buildFormRow(
          label: 'Website URL',
          child: CustomTextField(
            height: _inputHeight,
            controller: _websiteUrlCtrl,
            prefixIcon: LucideIcons.globe,
            prefixBox: true,
            hintText: 'ex: www.zylker.com',
          ),
        ),
        _buildFormRow(
          label: 'Department',
          child: CustomTextField(
            height: _inputHeight,
            controller: _departmentCtrl,
          ),
        ),
        _buildFormRow(
          label: 'Designation',
          child: CustomTextField(
            height: _inputHeight,
            controller: _designationCtrl,
          ),
        ),
        _buildFormRow(
          label: 'X (formerly Twitter)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                height: _inputHeight,
                controller: _xHandleCtrl,
                prefixBox: true,
                prefixWidget: SvgPicture.string(
                  _PurchasesVendorsVendorCreateScreenState._xSvg,
                  width: 20,
                  height: 20,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'https://x.com/',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
        _buildFormRow(
          label: 'WhatsApp',
          child: CustomTextField(
            height: _inputHeight,
            controller: _whatsappCtrl,
            prefixBox: true,
            prefixWidget: SvgPicture.string(
              _PurchasesVendorsVendorCreateScreenState._whatsappSvg,
              width: 24,
              height: 24,
            ),
          ),
        ),
        _buildFormRow(
          label: 'Facebook',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                height: _inputHeight,
                controller: _facebookCtrl,
                prefixBox: true,
                prefixWidget: SvgPicture.string(
                  _PurchasesVendorsVendorCreateScreenState._facebookSvg,
                  width: 22,
                  height: 22,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'http://www.facebook.com/',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  Widget _buildAttachedFilesOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _removeAttachedFilesOverlay,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: _attachedFilesLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _attachedFiles.asMap().entries.map((entry) {
                    return _FileItemWidget(
                      file: entry.value,
                      onDelete: () => _removeFile(entry.key),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FileItemWidget extends StatefulWidget {
  final PlatformFile file;
  final VoidCallback onDelete;

  const _FileItemWidget({required this.file, required this.onDelete});

  @override
  State<_FileItemWidget> createState() => _FileItemWidgetState();
}

class _FileItemWidgetState extends State<_FileItemWidget> {
  bool _isHovered = false;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              Icons.image_outlined,
              size: 20,
              color: _isHovered ? Colors.white : const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isHovered
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'File Size: ${_formatSize(widget.file.size)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isHovered
                          ? Colors.white70
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (_isHovered)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: widget.onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}
