part of '../purchases_vendors_vendor_create.dart';

extension _PurchasesVendorsHelpers on _PurchasesVendorsVendorCreateScreenState {
  Widget _prefillInfoTile({required String title, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyGstinPrefill(GstinLookupResult result, GstinAddress? address) {
    _state(() {
      _companyNameCtrl.text = result.legalName;
      _gstinPrefillCtrl.text = result.gstin;

      // Set default GST treatment for successful GSTIN lookup
      _gstTreatment = _gstTreatmentOptions.firstWhere(
        (o) => o.label == 'Registered Business - Regular',
      );

      _displayNameCtrl.text = (result.tradeName.isNotEmpty
          ? result.tradeName
          : result.legalName);

      if (_panCtrl.text.isEmpty && result.gstin.length >= 12) {
        _panCtrl.text = result.gstin.substring(2, 12);
      }

      if (address != null) {
        _billingCountry = address.country.isEmpty ? 'India' : address.country;
        _billingStreet1Ctrl.text = address.line1;
        _billingStreet2Ctrl.text = address.line2;
        _billingCityCtrl.text = address.city;
        _billingState = address.state.isEmpty ? _billingState : address.state;
        _billingPinCtrl.text = address.pinCode;

        // Try to match source of supply
        if (_billingState != null && _billingState!.isNotEmpty) {
          for (var opt in _sourceOfSupplyList) {
            if (opt.contains(_billingState!)) {
              _sourceOfSupply = opt;
              break;
            }
          }
        }
      }
      _refreshDisplayNameOptions();
    });
  }


  Future<void> _syncVendorNumberPreferences() async {
    try {
      final lookupsService = LookupsApiService();
      // Disable cache to always get the latest settings
      final data = await lookupsService.getSequenceSettings('vendor');

      if (mounted) {
        _state(() {
          if (data != null) {
            _vendorNumberPrefixCtrl.text = data['prefix'] ?? 'VEN-';
            _vendorNumberNextCtrl.text = data['next_number']?.toString() ?? '1';
          } else {
            // Fallback defaults if API fails or returns null
            _vendorNumberPrefixCtrl.text = 'VEN-';
            _vendorNumberNextCtrl.text = '1';
          }
        });
      }
    } catch (e) {
      AppLogger.error('Error syncing vendor number preferences', error: e, module: 'purchases');
      if (mounted) {
        _state(() {
          _vendorNumberPrefixCtrl.text = 'VEN-';
          _vendorNumberNextCtrl.text = '1';
        });
      }
    }
  }

  Future<void> _applyVendorNumberPreferences() async {
    final prefix = _vendorNumberPrefixCtrl.text.trim();
    final nextNumberStr = _vendorNumberNextCtrl.text.trim();
    final nextNumber = int.tryParse(nextNumberStr);

    if (nextNumber == null) return;

    try {
      // 1. Update backend settings
      await LookupsApiService().updateSequenceSettings('vendor', {
        'prefix': prefix,
        'nextNumber': nextNumber,
        'padding': 6,
      });

      // 2. Fetch new formatted number
      final nextFormatted = await LookupsApiService().getNextSequence('vendor');
      if (nextFormatted != null && mounted) {
        _state(() {
          _vendorNumberCtrl.text = nextFormatted;
        });
      }
    } catch (e) {
      AppLogger.error('Error applying vendor number preferences', error: e, module: 'purchases');
    }
  }

  void _refreshDisplayNameOptions() {
    final options = _generateDisplayNameOptions(
      _salutation,
      _firstNameCtrl.text,
      _lastNameCtrl.text,
      _companyNameCtrl.text,
    );
    final current = _displayNameCtrl.text.trim();
    final bool shouldAutoSet =
        current.isEmpty || _displayNameOptions.contains(current);

    if (!mounted) return;
    _state(() {
      _displayNameOptions = options;
      if (shouldAutoSet && options.isNotEmpty) {
        _displayNameCtrl.text = options.first;
      }
    });
  }

  List<String> _generateDisplayNameOptions(
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

  bool _shouldHideGstRegistrationFields() {
    if (_gstTreatment == null) return true;
    final label = _gstTreatment!.label;
    final allowedToShow = [
      'Registered Business - Regular',
      'Registered Business - Composition',
      'Overseas',
      'Special Economic Zone',
      'Deemed Export',
      'Tax Deductor',
      'SEZ Developer',
    ];
    return !allowedToShow.contains(label);
  }

  bool _shouldHideSourceOfSupply() {
    if (_gstTreatment == null) return false;
    final label = _gstTreatment!.label;
    final allowedToShow = [
      'Registered Business - Regular',
      'Registered Business - Composition',
      'Unregistered Business',
      'Special Economic Zone',
      'Deemed Export',
      'Tax Deductor',
      'SEZ Developer',
    ];
    return !allowedToShow.contains(label);
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null && result.files.isNotEmpty) {
        _state(() {
          final currentCount = _attachedFiles.length;
          final availableSlots = 10 - currentCount;

          if (availableSlots > 0) {
            final filesToAdd = result.files.take(availableSlots).toList();
            _attachedFiles.addAll(filesToAdd);
          } else {
            ZerpaiToast.error(context, 'You can upload a maximum of 10 files');
          }
        });
      }
    } catch (e) {
      AppLogger.error('Error picking files', error: e, module: 'purchases');
    }
  }

  void _removeFile(int index) {
    _state(() {
      if (index >= 0 && index < _attachedFiles.length) {
        _attachedFiles.removeAt(index);
        if (_attachedFiles.isEmpty) {
          _removeAttachedFilesOverlay();
        } else {
          _attachedFilesOverlayEntry?.markNeedsBuild();
        }
      }
    });
  }

  void _toggleAttachedFilesList() {
    if (_attachedFilesOverlayEntry != null) {
      _removeAttachedFilesOverlay();
    } else {
      _showAttachedFilesOverlay();
    }
  }

  void _showAttachedFilesOverlay() {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    _attachedFilesOverlayEntry = OverlayEntry(
      builder: (context) => _buildAttachedFilesOverlay(),
    );

    overlay.insert(_attachedFilesOverlayEntry!);
  }

  void _removeAttachedFilesOverlay() {
    _attachedFilesOverlayEntry?.remove();
    _attachedFilesOverlayEntry = null;
  }
}
