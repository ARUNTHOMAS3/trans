part of '../sales_customer_create.dart';

extension _AttributesSection on _SalesCustomerCreateScreenState {
  Widget _buildAttributes() {
    final staffOptions = <_StaffOption>[
      const _StaffOption(id: 'S-1001', name: 'Arun Rao', phone: '9876543210'),
      const _StaffOption(id: 'S-1002', name: 'Meera Das', phone: '9123456780'),
      const _StaffOption(id: 'S-1003', name: 'Nitin Shah', phone: '9988776655'),
    ];

    final referralOptions = <_ReferralOption>[
      const _ReferralOption(
        type: _ReferralType.customer,
        id: 'C-2001',
        name: 'Asha Traders',
        phone: '9000000011',
      ),
      const _ReferralOption(
        type: _ReferralType.staff,
        id: 'S-1002',
        name: 'Meera Das',
        phone: '9123456780',
      ),
      const _ReferralOption(
        type: _ReferralType.business,
        id: 'B-3001',
        name: 'BlueSky Logistics',
        phone: '9888001122',
      ),
    ];

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
          SizedBox(height: _fieldSpacing),
          _buildFormRow(
            label: 'Referred By',
            showInfo: true,
            tooltip: 'Track who referred this customer.',
            child: FormDropdown<_ReferralOption>(
              height: _inputHeight,
              value: referredBy,
              items: referralOptions,
              hint: 'Select referrer',
              displayStringForValue: (v) => v.displayLabel,
              onChanged: (v) => _state(() => referredBy = v),
              allowClear: true,
            ),
          ),
        ],
      ),
    );
  }
}
