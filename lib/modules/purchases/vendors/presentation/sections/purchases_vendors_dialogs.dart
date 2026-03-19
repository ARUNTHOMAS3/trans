part of '../purchases_vendors_vendor_create.dart';

extension _PurchasesVendorsDialogs on _PurchasesVendorsVendorCreateScreenState {
  void _openGstinPrefillDialog() {
    bool isLoading = false;
    String? errorMessage;
    GstinLookupResult? lookupResult;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleFetch() async {
              final gstin = _gstinPrefillCtrl.text.trim();
              if (gstin.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Enter a GSTIN/UIN to fetch details.';
                });
                return;
              }

              setDialogState(() {
                isLoading = true;
                errorMessage = null;
                lookupResult = null;
              });

              try {
                final result = await _gstinLookupService.fetchGstin(gstin);
                if (!mounted) return;
                setDialogState(() {
                  lookupResult = result;
                });
              } catch (error) {
                if (!mounted) return;
                setDialogState(() {
                  errorMessage = error.toString();
                });
              } finally {
                if (mounted) {
                  setDialogState(() {
                    isLoading = false;
                  });
                }
              }
            }

            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Prefill Vendor Details From GST Portal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GSTIN/UIN*',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  height: 36,
                                  controller: TextEditingController(
                                    text: _panCtrl.text,
                                  ),
                                  hintText: 'Enter GSTIN',
                                  onChanged: (v) => _panCtrl.text = v,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: isLoading ? null : handleFetch,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Fetch'),
                              ),
                            ],
                          ),
                          if (errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (lookupResult != null)
                      Container(
                        padding: const EdgeInsets.all(24),
                        color: Colors.grey[50],
                        child: Column(
                          children: [
                            _prefillInfoTile(
                              title: 'Legal Name',
                              value: lookupResult!.legalName,
                            ),
                            const SizedBox(height: 12),
                            _prefillInfoTile(
                              title: 'Trade Name',
                              value: lookupResult!.tradeName,
                            ),
                            const SizedBox(height: 12),
                            _prefillInfoTile(
                              title: 'Status',
                              value: lookupResult!.status,
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: lookupResult == null
                                ? null
                                : () {
                                    _applyGstinPrefill(lookupResult!, null);
                                    Navigator.pop(dialogContext);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Prefill Details'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openVendorNumberPreferences() async {
    await _syncVendorNumberPreferences();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        String? duplicateError;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildVendorNumberDialogHeader(dialogContext),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    if (duplicateError != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: AppTheme.errorBgBorder,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppTheme.errorRed,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                duplicateError!,
                                style: const TextStyle(
                                  color: AppTheme.errorRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () =>
                                  setDialogState(() => duplicateError = null),
                              child: const Icon(
                                Icons.close,
                                color: AppTheme.errorRed,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vendor numbers will be auto-generated based on the '
                            'preferences below. For each new vendor that is '
                            'created, the number after the prefix will be '
                            'incremented by 1.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 140,
                                child: CustomTextField(
                                  height: _inputHeight,
                                  controller: _vendorNumberPrefixCtrl,
                                  label: 'Prefix',
                                  onChanged: (_) => setDialogState(
                                    () => duplicateError = null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  height: _inputHeight,
                                  controller: _vendorNumberNextCtrl,
                                  label: 'Next Number',
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setDialogState(
                                    () => duplicateError = null,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warningBg,
                              border: Border.all(
                                color: const Color(0xFFFED7AA),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Note: If you want to change only this vendor's "
                              'number without affecting the current series, you '
                              'can edit it directly from the Vendor Number '
                              'field after closing this popup.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.warningTextDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: isSaving
                                    ? null
                                    : () async {
                                        setDialogState(() {
                                          isSaving = true;
                                          duplicateError = null;
                                        });
                                        bool numberExists = false;
                                        try {
                                          final prefix =
                                              _vendorNumberPrefixCtrl.text;
                                          final nextNum =
                                              _vendorNumberNextCtrl.text;
                                          // Format with 6-digit padding as per rule 5
                                          final formatted =
                                              '$prefix${nextNum.padLeft(6, '0')}';

                                          numberExists =
                                              await LookupsApiService()
                                                  .checkDuplicateNumber(
                                                    'vendor',
                                                    formatted,
                                                  );

                                          if (numberExists) {
                                            setDialogState(() {
                                              duplicateError =
                                                  'The vendor number "$formatted" already exists.';
                                              isSaving = false;
                                            });
                                            return;
                                          }

                                          await _applyVendorNumberPreferences();
                                          if (context.mounted) {
                                            Navigator.of(dialogContext).pop();
                                          }
                                        } catch (e) {
                                          setDialogState(() {
                                            duplicateError = 'Error: $e';
                                            isSaving = false;
                                          });
                                        } finally {
                                          if (context.mounted &&
                                              !numberExists) {
                                            setDialogState(
                                              () => isSaving = false,
                                            );
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: AppTheme.successGreen,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: isSaving
                                    ? null
                                    : () => Navigator.of(dialogContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVendorNumberDialogHeader(BuildContext dialogContext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
      child: Row(
        children: [
          const Text(
            'Configure Vendor Numbers Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            icon: const Icon(Icons.close, size: 18, color: AppTheme.errorRed),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
