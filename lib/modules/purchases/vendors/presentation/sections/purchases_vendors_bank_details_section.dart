part of '../purchases_vendors_vendor_create.dart';

extension _BankDetailsSection on _PurchasesVendorsVendorCreateScreenState {
  Widget _buildBankDetails() {
    if (bankRows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add your vendor's bank details and make payments.",
                style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  _state(() {
                    bankRows.add(_BankDetailRow());
                  });
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text(
                      'Add Bank Account',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...bankRows.asMap().entries.map((entry) {
            int index = entry.key;
            var row = entry.value;
            bool isFirst = index == 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isFirst) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Divider(color: Color(0xFFE5E7EB)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BANK ${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _state(() {
                            bankRows.removeAt(index);
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildFormRow(
                            label: 'Account Holder Name',
                            child: CustomTextField(
                              height: _inputHeight,
                              controller: row.holderNameCtrl,
                            ),
                          ),
                          _buildFormRow(
                            label: 'Bank Name',
                            child: CustomTextField(
                              height: _inputHeight,
                              controller: row.bankNameCtrl,
                            ),
                          ),
                          _buildFormRow(
                            label: 'Account Number*',
                            isRequired: true,
                            showInfo: true,
                            tooltip: 'Enter the bank account number.',
                            child: CustomTextField(
                              height: _inputHeight,
                              controller: row.accountNumberCtrl,
                              obscureText: !row.showAccountNumber,
                              suffixWidget: InkWell(
                                onTap: () => _state(
                                  () => row.showAccountNumber =
                                      !row.showAccountNumber,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Icon(
                                    row.showAccountNumber
                                        ? LucideIcons.eyeOff
                                        : LucideIcons.eye,
                                    size: 16,
                                    color: row.showAccountNumber
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildFormRow(
                            label: 'Re-enter Account Number*',
                            isRequired: true,
                            showInfo: true,
                            tooltip: 'Re-verify the bank account number.',
                            child: CustomTextField(
                              height: _inputHeight,
                              controller: row.reEnterAccountNumberCtrl,
                              obscureText: !row.showReEnterAccountNumber,
                              suffixWidget: InkWell(
                                onTap: () => _state(
                                  () => row.showReEnterAccountNumber =
                                      !row.showReEnterAccountNumber,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Icon(
                                    row.showReEnterAccountNumber
                                        ? LucideIcons.eyeOff
                                        : LucideIcons.eye,
                                    size: 16,
                                    color: row.showReEnterAccountNumber
                                        ? const Color(0xFF2563EB)
                                        : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildFormRow(
                            label: 'IFSC*',
                            isRequired: true,
                            showInfo: true,
                            tooltip: 'Enter the 11-digit IFSC code.',
                            child: CustomTextField(
                              height: _inputHeight,
                              controller: row.ifscCtrl,
                              forceUppercase: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _state(() {
                bankRows.add(_BankDetailRow());
              });
            },
            icon: const Icon(Icons.add, size: 16, color: Color(0xFF2563EB)),
            label: const Text(
              'Add New Bank',
              style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
