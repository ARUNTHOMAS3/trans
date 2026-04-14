part of '../sales_customer_create.dart';

extension _AttributesSection on _SalesCustomerCreateScreenState {
  Widget _buildAttributes() {
    // Live customer data
    final customersAsync = ref.watch(salesCustomersProvider);

    final staffOptions = <_StaffOption>[
      const _StaffOption(id: 'S-1001', name: 'Arun Rao', phone: '9876543210'),
      const _StaffOption(id: 'S-1002', name: 'Meera Das', phone: '9123456780'),
      const _StaffOption(id: 'S-1003', name: 'Nitin Shah', phone: '9988776655'),
    ];

    // Static referral options removed in favor of live data

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          _buildFormRow(
            label: 'Assigned To',
            showInfo: true,
            tooltip: 'Assign a staff member to this customer.',
            child: FormDropdown<_StaffOption>(
              height: _inputHeight,
              value: assignedStaff,
              items: staffOptions,
              hint: 'Select staff',
              displayStringForValue: (v) => v.name,
              onChanged: (v) => _state(() => assignedStaff = v),
              allowClear: true,
            ),
          ),
          _buildFormRow(
            label: 'Referred By',
            showInfo: true,
            tooltip: 'Track who referred this customer.',
            child: Row(
              children: [
                Expanded(
                  child: customersAsync.when(
                    data: (customers) {
                      final referralOptions = <_ReferralOption>[];

                      // 1. Add Staff (Users)
                      for (var s in staffOptions) {
                        referralOptions.add(
                          _ReferralOption(
                            type: _ReferralType.staff,
                            id: s.id,
                            name: s.name,
                            phone: s.phone,
                          ),
                        );
                      }

                      // 2. Add Customers from DB
                      for (var c in customers) {
                        final isIndividual =
                            c.customerType?.toLowerCase() == 'individual';
                        referralOptions.add(
                          _ReferralOption(
                            type: isIndividual
                                ? _ReferralType.customer
                                : _ReferralType.business,
                            id: c.id,
                            name: c.displayName,
                            phone: c.mobilePhone ?? c.phone ?? '',
                          ),
                        );
                      }

                      return FormDropdown<_ReferralOption>(
                        height: _inputHeight,
                        value: referredBy,
                        items: referralOptions,
                        hint: 'Select referrer',
                        displayStringForValue: (v) => v.name,
                        onChanged: (v) => _state(() => referredBy = v),
                        allowClear: true,
                        itemBuilder: (item, isSelected, isHovered) {
                          final bool active = isSelected || isHovered;
                          return Container(
                            height: 36,
                            padding: const EdgeInsets.only(left: 28, right: 12),
                            color: active
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: active
                                          ? Colors.white
                                          : const Color(0xFF374151),
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                              ],
                            ),
                          );
                        },
                        listBuilder: (items, itemBuilder) {
                          final grouped =
                              <_ReferralType, List<_ReferralOption>>{};
                          for (var item in items) {
                            grouped.putIfAbsent(item.type, () => []).add(item);
                          }

                          return ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              if (grouped.containsKey(
                                _ReferralType.customer,
                              )) ...[
                                _buildGroupHeader('Customers'),
                                ...grouped[_ReferralType.customer]!.map(
                                  itemBuilder,
                                ),
                              ],
                              if (grouped.containsKey(_ReferralType.staff)) ...[
                                _buildGroupHeader('User'),
                                ...grouped[_ReferralType.staff]!.map(
                                  itemBuilder,
                                ),
                              ],
                              if (grouped.containsKey(
                                _ReferralType.business,
                              )) ...[
                                _buildGroupHeader('Business'),
                                ...grouped[_ReferralType.business]!.map(
                                  itemBuilder,
                                ),
                              ],
                            ],
                          );
                        },
                      );
                    },
                    loading: () => FormDropdown<_ReferralOption>(
                      isLoading: true,
                      height: _inputHeight,
                      value: null,
                      items: const [],
                      onChanged: (_) {},
                    ),
                    error: (e, __) => const Text(
                      'Error loading customers',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ),
                _buildGreenSearchButton(
                  onPressed: () {
                    _openAdvancedCustomerSearchDialog((v) {
                      _state(() {
                        referredBy = v;
                      });
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: Colors.white,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
