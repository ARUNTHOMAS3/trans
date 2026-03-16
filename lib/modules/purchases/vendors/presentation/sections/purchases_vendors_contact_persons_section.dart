part of '../purchases_vendors_vendor_create.dart';

extension _ContactPersonsSection on _PurchasesVendorsVendorCreateScreenState {
  Widget _buildContactPersons() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactHeader(),
          const SizedBox(height: 8),
          Column(
            children: contactRows
                .asMap()
                .entries
                .map((entry) => _buildContactRow(entry.key, entry.value))
                .toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: addContactRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Contact Person'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactHeader() {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Color(0xFF6B7280),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              'SALUTATION',
              style: headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'FIRST NAME',
              style: headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'LAST NAME',
              style: headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'EMAIL ADDRESS',
              style: headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'WORK PHONE',
              style: headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'MOBILE',
              style: headerStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildContactRow(int index, _ContactPersonRow row) {
    return StatefulBuilder(
      builder: (context, setRowState) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: MouseRegion(
            onEnter: (_) => setRowState(() => row.isHovered = true),
            onExit: (_) => setRowState(() => row.isHovered = false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FormDropdown<String>(
                      height: _inputHeight,
                      value: row.salutation,
                      items: const ['Mr.', 'Mrs.', 'Ms.', 'Dr.'],
                      onChanged: (v) =>
                          _state(() => row.salutation = v ?? 'Mr.'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      height: _inputHeight,
                      controller: row.firstNameCtrl,
                      forceUppercase: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      height: _inputHeight,
                      controller: row.lastNameCtrl,
                      forceUppercase: false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      height: _inputHeight,
                      controller: row.emailCtrl,
                      forceUppercase: false,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _buildPhoneRow(
                      code: row.workCode,
                      onCodeChanged: (v) => _state(() => row.workCode = v),
                      controller: row.workPhoneCtrl,
                      hintText: '',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: _buildPhoneRow(
                      code: row.mobileCode,
                      onCodeChanged: (v) => _state(() => row.mobileCode = v),
                      controller: row.mobilePhoneCtrl,
                      hintText: '',
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (index > 0 && row.isHovered)
                    IconButton(
                      onPressed: () => removeContactRow(index),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    )
                  else
                    const SizedBox(
                      width: 32,
                    ), // Placeholder to maintain alignment
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void addContactRow() {
    _state(() {
      contactRows.add(_ContactPersonRow());
    });
  }

  void removeContactRow(int index) {
    _state(() {
      contactRows.removeAt(index).dispose();
    });
  }
}
