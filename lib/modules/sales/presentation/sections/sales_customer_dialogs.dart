part of '../sales_customer_create.dart';

extension _SalesCustomerDialogs on _SalesCustomerCreateScreenState {
  void _openGstinPrefillDialog() {
    gstinPrefillCtrl.text = gstinPrefillCtrl.text.trim();

    bool isLoading = false;
    String? errorMessage;
    GstinLookupResult? lookupResult;
    int selectedAddressIndex = 0;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleFetch() async {
              final gstin = gstinPrefillCtrl.text.trim();
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
                selectedAddressIndex = 0;
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

            final addresses = lookupResult?.addresses ?? const [];

            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Prefill Customer Details From the GST Portal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppTheme.errorRed,
                            ),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GSTIN/UIN*',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  height: 36,
                                  controller: gstinPrefillCtrl,
                                  hintText: 'Enter GSTIN',
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp('[A-Za-z0-9]'),
                                    ),
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : handleFetch,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: AppTheme.primaryBlueDark,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: Skeleton(
                                            height: 16,
                                            width: 16,
                                          ),
                                        )
                                      : const Text('Fetch'),
                                ),
                              ),
                            ],
                          ),
                          if (errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (lookupResult != null)
                      Container(
                        width: double.infinity,
                        color: AppTheme.bgLight,
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Business Details',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textBody,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _prefillInfoTile(
                                    title: 'Company Name',
                                    value: lookupResult!.legalName,
                                  ),
                                ),
                                Expanded(
                                  child: _prefillInfoTile(
                                    title: 'GSTIN/UIN status',
                                    value: lookupResult!.status,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _prefillInfoTile(
                                    title: 'Taxpayer Type',
                                    value: lookupResult!.taxpayerType,
                                  ),
                                ),
                                Expanded(
                                  child: _prefillInfoTile(
                                    title: 'Business Trade Name',
                                    value: lookupResult!.tradeName,
                                  ),
                                ),
                              ],
                            ),
                            if (addresses.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Available Addresses',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 200,
                                child: RadioGroup<int>(
                                  groupValue: selectedAddressIndex,
                                  onChanged: (v) {
                                    if (v != null) {
                                      setDialogState(() {
                                        selectedAddressIndex = v;
                                      });
                                    }
                                  },
                                  child: ListView.separated(
                                    itemCount: addresses.length,
                                    separatorBuilder: (_, unused) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final address = addresses[index];
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(
                                            color: AppTheme.borderColor,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              selectedAddressIndex = index;
                                            });
                                          },
                                          child: Row(
                                            children: [
                                              Radio<int>(
                                                value: index,
                                                activeColor: const Color(
                                                  0xFF2563EB,
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  address.displayLabel,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: lookupResult == null
                                ? null
                                : () {
                                    final address = addresses.isNotEmpty
                                        ? addresses[selectedAddressIndex]
                                        : null;
                                    _applyGstinPrefill(lookupResult!, address);
                                    Navigator.of(dialogContext).pop();
                                  },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppTheme.successGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('Prefill Details'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
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

  void _openCustomerNumberPreferences() {
    _syncCustomerNumberPreferences();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCustomerNumberDialogHeader(dialogContext),
                const Divider(height: 1, color: AppTheme.borderColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer numbers will be auto-generated based on the '
                        'preferences below. For each new customer that is '
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
                              controller: customerNumberPrefixCtrl,
                              label: 'Prefix',
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp('-')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              height: _inputHeight,
                              controller: customerNumberNextCtrl,
                              label: 'Next Number',
                              keyboardType: TextInputType.number,
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
                          border: Border.all(color: const Color(0xFFFED7AA)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "Note: If you want to change only this customer's "
                          'number without affecting the current series, you '
                          'can edit it directly from the Customer Number '
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
                            onPressed: () {
                              _applyCustomerNumberPreferences();
                              Navigator.of(dialogContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppTheme.successGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
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
  }
}
