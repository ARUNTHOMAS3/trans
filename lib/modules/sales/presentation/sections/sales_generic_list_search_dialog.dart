part of '../sales_generic_list.dart';

extension _GenericListSearchDialog on _SalesGenericListScreenState {
  void _openAdvancedSearchDialog() {
    String selectedModule = 'Customers';
    String selectedFilterAdv = 'All Customers';

    // Stable controllers for text fields to prevent focus loss on rebuild
    final Map<String, TextEditingController> controllers = {
      'Customer Number': TextEditingController(),
      'Display Name': TextEditingController(),
      'First Name': TextEditingController(),
      'Last Name': TextEditingController(),
      'Email': TextEditingController(),
      'Company Name': TextEditingController(),
      'Phone': TextEditingController(),
      'PAN': TextEditingController(),
      'Address': TextEditingController(),
      'Notes': TextEditingController(),
    };

    String selectedCustomerType = 'All';
    String selectedPlaceOfSupply = 'Select a value';
    String selectedSchedule = 'Select a value';
    String selectedStatus = 'All';
    String gstTreatType = 'Specify';
    String selectedGstTreatment = 'Registered Business - Regular';

    final List<Map<String, String>> gstTreatments = [
      {
        'label': 'Registered Business - Regular',
        'desc': 'Business that is registered under GST',
      },
      {
        'label': 'Registered Business - Composition',
        'desc':
            'Business that is registered under the Composition Scheme in GST',
      },
      {
        'label': 'Unregistered Business',
        'desc': 'Business that has not been registered under GST',
      },
      {'label': 'Consumer', 'desc': 'Individual or consumer'},
    ];

    final List<String> customerTypes = ['All', 'Business', 'Individual'];
    final List<String> states = [
      'Andaman and Nicobar Islands',
      'Andhra Pradesh',
      'Arunachal Pradesh',
      'Assam',
      'Bihar',
      'Chandigarh',
      'Chhattisgarh',
    ];
    final List<String> schedules = ['Select a value', 'H', 'H1'];

    final List<String> modules = [
      'Customers',
      'Items',
      'Composite Items',
      'Assemblies',
      'Price Lists',
      'Inventory Adjustments',
      'Transfer Orders',
      'Retainer Invoices',
      'Sales Orders',
      'Picklists',
      'Packages',
      'Shipments',
      'Delivery Challans',
      'Invoices',
      'Payments Received',
      'Sales Returns',
      'Credit Notes',
      'Vendors',
      'Purchase Orders',
      'Purchase Receives',
      'Bills',
      'Payments Made',
      'Vendor Credits',
      'Documents',
      'Tasks',
    ];

    final List<String> filters = [
      'All Customers',
      'Active Customers',
      'CRM Customers',
      'Duplicate Customers',
      'Inactive Customers',
      'Overdue Customers',
      'Unpaid Customers',
      'Credit Limit Exceeded',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            child: Container(
              width: 900,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Text(
                              'Search',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FormDropdown<String>(
                              height: 32,
                              value: selectedModule,
                              items: modules,
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => selectedModule = v);
                                }
                              },
                            ),
                            const SizedBox(width: 40),
                            const Text(
                              'Filter',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FormDropdown<String>(
                              height: 32,
                              value: selectedFilterAdv,
                              items: filters,
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => selectedFilterAdv = v);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _dialogTextField(
                                      'Customer Number',
                                      controllers['Customer Number']!,
                                    ),
                                    _searchableDialogDropdown(
                                      'Customer Type',
                                      selectedCustomerType,
                                      customerTypes,
                                      (val) => _state(
                                        () => selectedCustomerType = val,
                                      ),
                                    ),
                                    _dialogTextField(
                                      'First Name',
                                      controllers['First Name']!,
                                    ),
                                    _dialogTextField(
                                      'Email',
                                      controllers['Email']!,
                                    ),
                                    _dialogTextField(
                                      'Phone',
                                      controllers['Phone']!,
                                    ),
                                    _dialogTextField(
                                      'PAN',
                                      controllers['PAN']!,
                                    ),
                                    _searchableDialogDropdown(
                                      'Place of Supply',
                                      selectedPlaceOfSupply,
                                      states,
                                      (val) => _state(
                                        () => selectedPlaceOfSupply = val,
                                      ),
                                    ),
                                    _searchableDialogDropdown(
                                      'Schedule',
                                      selectedSchedule,
                                      schedules,
                                      (val) =>
                                          _state(() => selectedSchedule = val),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 48),
                              Expanded(
                                child: Column(
                                  children: [
                                    _dialogTextField(
                                      'Display Name',
                                      controllers['Display Name']!,
                                    ),
                                    _dialogTextField(
                                      'Company Name',
                                      controllers['Company Name']!,
                                    ),
                                    _dialogTextField(
                                      'Last Name',
                                      controllers['Last Name']!,
                                    ),
                                    _searchableDialogDropdown(
                                      'Status',
                                      selectedStatus,
                                      ['All', 'Active', 'Inactive'],
                                      (val) =>
                                          _state(() => selectedStatus = val),
                                    ),
                                    _dialogTextField(
                                      'Address',
                                      controllers['Address']!,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 150,
                                            child: Text(
                                              'GST Treatment',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                          ),
                                          FormDropdown<String>(
                                            height: 36,
                                            value: gstTreatType,
                                            items: const [
                                              'Specify',
                                              'Unassigned',
                                            ],
                                            onChanged: (v) {
                                              if (v != null) {
                                                _state(() => gstTreatType = v);
                                              }
                                            },
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(4),
                                                  bottomLeft: Radius.circular(
                                                    4,
                                                  ),
                                                ),
                                          ),
                                          Expanded(
                                            child: _searchableDialogDropdown(
                                              '',
                                              selectedGstTreatment,
                                              gstTreatments
                                                  .map((e) => e['label']!)
                                                  .toList(),
                                              (val) => _state(
                                                () =>
                                                    selectedGstTreatment = val,
                                              ),
                                              subtitles: gstTreatments
                                                  .map((e) => e['desc']!)
                                                  .toList(),
                                              hideLabel: true,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topRight: Radius.circular(
                                                      4,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(4),
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _dialogTextField(
                                      'Notes',
                                      controllers['Notes']!,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Searching with applied filters..'),
                              backgroundColor: Color(0xFF22C55E),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          foregroundColor: const Color(0xFF374151),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // Clean up controllers
      for (var controller in controllers.values) {
        controller.dispose();
      }
    });
  }

  Widget _dialogTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchableDialogDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged, {
    List<String>? subtitles,
    bool hideLabel = false,
    BorderRadius? borderRadius,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: hideLabel ? 0 : 16),
      child: Row(
        children: [
          if (!hideLabel)
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
            ),
          Expanded(
            child: FormDropdown<String>(
              height: 36,
              value: value.isEmpty || value == 'Select a value' ? null : value,
              hint: 'Select a value',
              items: options,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              borderRadius: borderRadius,
              itemBuilder: (item, isSelected, isHovered) {
                final int index = options.indexOf(item);
                final String? subtitle =
                    (subtitles != null &&
                        index >= 0 &&
                        index < subtitles.length)
                    ? subtitles[index]
                    : null;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: isSelected
                      ? const Color(0xFFEFF6FF)
                      : isHovered
                      ? const Color(0xFFF9FAFB)
                      : Colors.transparent,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          LucideIcons.check,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
