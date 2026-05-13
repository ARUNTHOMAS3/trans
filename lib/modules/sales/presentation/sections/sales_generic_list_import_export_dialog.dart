part of '../sales_generic_list.dart';

extension _GenericListImportExportDialog on _SalesGenericListScreenState {
  void _showImportDialog() {
    String importEntity = 'Customers';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Import ${widget.title}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You can import contacts into Zerpai Inventory from a .CSV or .TSV or .XLS file.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      RadioGroup<String>(
                        groupValue: importEntity,
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => importEntity = v);
                          }
                        },
                        child: Column(
                          children: [
                            _buildDialogRadioTile(
                              label: 'Customers',
                              value: 'Customers',
                              onChanged: (v) =>
                                  setDialogState(() => importEntity = v!),
                            ),
                            _buildDialogRadioTile(
                              label: "Customer's Contact Persons",
                              value: 'Contact Persons',
                              onChanged: (v) =>
                                  setDialogState(() => importEntity = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    String module = 'Customers';
    String entityType = 'Customers';
    String period = 'All';
    String decimalFormat = '1234567.89';
    String fileFormat = 'CSV';
    bool includePii = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 650,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Export ${widget.title}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.info,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You can export your data from Zerpai Inventory in CSV, XLS or XLSX format.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Module*
                        const Text(
                          'Module*',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _simpleDialogDropdown(module, [
                          'Customers',
                        ], (v) => setDialogState(() => module = v!)),
                        const SizedBox(height: 16),

                        // Entity Radio group
                        RadioGroup<String>(
                          groupValue: entityType,
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => entityType = v);
                            }
                          },
                          child: Column(
                            children: [
                              _buildDialogRadioTile(
                                label: 'Customers',
                                value: 'Customers',
                                onChanged: (v) =>
                                    setDialogState(() => entityType = v!),
                              ),
                              _buildDialogRadioTile(
                                label: "Customer's Contact Persons",
                                value: 'Contact Persons',
                                onChanged: (v) =>
                                    setDialogState(() => entityType = v!),
                              ),
                              _buildDialogRadioTile(
                                label: "Customer's Addresses",
                                value: 'Addresses',
                                onChanged: (v) =>
                                    setDialogState(() => entityType = v!),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 32),

                        // Period Radio group
                        RadioGroup<String>(
                          groupValue: period,
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => period = v);
                            }
                          },
                          child: Column(
                            children: [
                              _buildDialogRadioTile(
                                label: 'All Customers',
                                value: 'All',
                                onChanged: (v) =>
                                    setDialogState(() => period = v!),
                              ),
                              _buildDialogRadioTile(
                                label: 'Specific Period',
                                value: 'Specific',
                                onChanged: (v) =>
                                    setDialogState(() => period = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Decimal Format*
                        const Text(
                          'Decimal Format*',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _simpleDialogDropdown(
                          decimalFormat,
                          ['1234567.89', '1,234,567.89'],
                          (v) => setDialogState(() => decimalFormat = v!),
                        ),
                        const SizedBox(height: 24),

                        // Export File Format*
                        const Text(
                          'Export File Format*',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 12),
                        RadioGroup<String>(
                          groupValue: fileFormat,
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => fileFormat = v);
                            }
                          },
                          child: Column(
                            children: [
                              _buildDialogRadioTile(
                                label: 'CSV (Comma Separated Value)',
                                value: 'CSV',
                                onChanged: (v) =>
                                    setDialogState(() => fileFormat = v!),
                              ),
                              _buildDialogRadioTile(
                                label:
                                    'XLS (Microsoft Excel 1997-2004 Compatible)',
                                value: 'XLS',
                                onChanged: (v) =>
                                    setDialogState(() => fileFormat = v!),
                              ),
                              _buildDialogRadioTile(
                                label: 'XLSX (Microsoft Excel)',
                                value: 'XLSX',
                                onChanged: (v) =>
                                    setDialogState(() => fileFormat = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PII Checkbox
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Checkbox(
                                value: includePii,
                                onChanged: (v) =>
                                    setDialogState(() => includePii = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Include Sensitive Personally Identifiable Information (PII) while exporting.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Password field
                        const Text(
                          'File Protection Password',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            suffixIcon: InkWell(
                              onTap: () => setDialogState(
                                () => obscurePassword = !obscurePassword,
                              ),
                              child: Icon(
                                obscurePassword
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your password must be at least 12 characters and include one uppercase letter, lowercase letter, number, and special character.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Note
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Note: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text:
                                    'You can export only the first 25,000 rows. If you have more rows, please initiate a backup for the data in your Zerpai Inventory organization, and download it. ',
                              ),
                              TextSpan(
                                text: 'Backup Your Data',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Export',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogRadioTile({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              activeColor: const Color(0xFF2563EB),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _simpleDialogDropdown(
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return FormDropdown<String>(
      height: 36,
      value: value,
      items: options,
      onChanged: onChanged,
    );
  }
}
