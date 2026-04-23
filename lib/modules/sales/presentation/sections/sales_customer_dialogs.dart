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
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              alignment: Alignment.topCenter,
              insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFFE11D48),
                            ),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
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
                              color: Color(0xFFEF4444),
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
                                    backgroundColor: const Color(0xFF2563EB),
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
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (lookupResult != null)
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFF9FAFB),
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Business Details',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
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
                                  color: Color(0xFF6B7280),
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
                                            color: const Color(0xFFE5E7EB),
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
                              backgroundColor: const Color(0xFF22C55E),
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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCustomerNumberDialogHeader(dialogContext),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
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
                          color: Color(0xFF6B7280),
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
                          color: const Color(0xFFFFF7ED),
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
                            color: Color(0xFF92400E),
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
                              backgroundColor: const Color(0xFF22C55E),
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

  void _openAdvancedCustomerSearchDialog(
    void Function(_ReferralOption) onSelect,
  ) {
    String searchQuery = '';
    String searchType = 'Customer Number';
    int currentPage = 1;
    final int itemsPerPage = 5;
    final searchCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              alignment: Alignment.topCenter,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Consumer(
                  builder: (context, ref, _) {
                    final customersAsync = ref.watch(salesCustomersProvider);
                    final allCustomers = customersAsync.value ?? [];

                    // Filter logic
                    final filtered = allCustomers.where((c) {
                      if (searchQuery.isEmpty) return true;
                      final q = searchQuery.toLowerCase();
                      switch (searchType) {
                        case 'Customer Number':
                          return (c.customerNumber ?? '')
                              .toLowerCase()
                              .contains(q);
                        case 'Display Name':
                          return c.displayName.toLowerCase().contains(q);
                        case 'Company Name':
                          return (c.companyName ?? '').toLowerCase().contains(
                            q,
                          );
                        case 'First Name':
                          return (c.firstName ?? '').toLowerCase().contains(q);
                        case 'Last Name':
                          return (c.lastName ?? '').toLowerCase().contains(q);
                        case 'Email':
                          return (c.email ?? '').toLowerCase().contains(q);
                        case 'Phone':
                          return (c.phone ?? '').toLowerCase().contains(q) ||
                              (c.mobilePhone ?? '').contains(q);
                        case 'Privilege Card Number':
                          return (c.privilegeCardNumber ?? '')
                              .toLowerCase()
                              .contains(q);
                        case 'GST Number':
                          return (c.gstin ?? '').toLowerCase().contains(q);
                        default:
                          return false;
                      }
                    }).toList();

                    final totalPages = (filtered.length / itemsPerPage).ceil();
                    final start = (currentPage - 1) * itemsPerPage;
                    final end = math.min(start + itemsPerPage, filtered.length);
                    final paged =
                        (filtered.isNotEmpty && start < filtered.length)
                        ? filtered.sublist(start, end)
                        : <SalesCustomer>[];

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        _buildAdvancedSearchHeader(dialogContext),
                        const Divider(height: 1),

                        // Search Filters
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 160,
                                child: FormDropdown<String>(
                                  height: 36,
                                  value: searchType,
                                  items: const [
                                    'Customer Number',
                                    'Display Name',
                                    'Company Name',
                                    'First Name',
                                    'Last Name',
                                    'Email',
                                    'Phone',
                                    'Privilege Card Number',
                                    'GST Number',
                                  ],
                                  onChanged: (v) =>
                                      setDialogState(() => searchType = v!),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomTextField(
                                  height: 36,
                                  controller: searchCtrl,
                                  hintText: 'Search...',
                                  onChanged: (v) {
                                    // Optional: live search
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  setDialogState(() {
                                    searchQuery = searchCtrl.text.trim();
                                    currentPage = 1;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22C55E),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text('Search'),
                              ),
                            ],
                          ),
                        ),

                        // Table
                        _buildAdvancedSearchTable(
                          paged,
                          onSelect: (customer) {
                            final option = _ReferralOption(
                              type: _ReferralType.customer,
                              id: customer.id,
                              name: customer.displayName,
                              phone:
                                  customer.phone ?? customer.mobilePhone ?? '',
                            );
                            onSelect(option);
                            Navigator.pop(dialogContext);
                          },
                        ),

                        // Pagination
                        _buildAdvancedSearchPagination(
                          currentPage: currentPage,
                          totalPages: totalPages,
                          onPageChanged: (p) =>
                              setDialogState(() => currentPage = p),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdvancedSearchHeader(BuildContext dialogContext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Advanced Customer Search',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(dialogContext),
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Color(0xFFEF4444),
              ),
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSearchTable(
    List<SalesCustomer> customers, {
    required Function(SalesCustomer) onSelect,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        children: [
          // Table Headers
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: const [
                Expanded(flex: 4, child: _TableHeader(label: 'DISPLAY NAME')),
                Expanded(flex: 3, child: _TableHeader(label: 'PHONE')),
                Expanded(flex: 4, child: _TableHeader(label: 'EMAIL')),
              ],
            ),
          ),
          // Table Body
          if (customers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(48.0),
              child: Text(
                'No results found',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          else
            ...customers.map((c) => _buildSearchRow(c, onSelect)),
        ],
      ),
    );
  }

  Widget _buildSearchRow(SalesCustomer c, Function(SalesCustomer) onSelect) {
    return InkWell(
      onTap: () => onSelect(c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                c.phone ?? c.mobilePhone ?? '-',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
            Expanded(
              flex: 4,
              child: Text(
                c.email ?? '-',
                style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSearchPagination({
    required int currentPage,
    required int totalPages,
    required ValueChanged<int> onPageChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: currentPage > 1
                      ? () => onPageChanged(currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                Container(
                  width: 50,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Text(
                    '$currentPage - $totalPages',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  const _TableHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4B5563),
      ),
    );
  }
}
