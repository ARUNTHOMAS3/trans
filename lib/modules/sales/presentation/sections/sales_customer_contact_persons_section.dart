part of '../sales_customer_create.dart';

extension _ContactPersonsSection on _SalesCustomerCreateScreenState {
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
            onPressed: _addContactRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Contact Person'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactHeader() {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: AppTheme.textSecondary,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
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
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildContactRow(int index, _ContactPersonRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: FormDropdown<String>(
                height: _inputHeight,
                value: row.salutation,
                items: const ['Mr.', 'Mrs', 'Ms.', 'Dr.'],
                onChanged: (v) => _state(() => row.salutation = v ?? 'Mr.'),
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
            IconButton(
              onPressed: () =>
                  _state(() => contactRows.removeAt(index).dispose()),
              icon: const Icon(
                Icons.close,
                size: 18,
                color: AppTheme.errorRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addContactRow() {
    _state(() {
      contactRows.add(_ContactPersonRow());
    });
  }
}
