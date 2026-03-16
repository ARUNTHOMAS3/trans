part of '../sales_customer_overview.dart';

extension _OverviewActions on _SalesCustomerOverviewScreenState {
  Widget _buildNewTransactionDropdown() {
    return InkWell(
      onTap: () => context.push(AppRoutes.salesCustomersCreate),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF22C55E),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'New',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreDropdown() {
    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: _headerButton('More', LucideIcons.chevronDown),
        );
      },
      menuChildren: [
        _popupItem('Associate Templates'),
        _popupItem('Configure Customer Portal'),
        _popupItem('Stop All Reminders'),
        _popupItem('Link to Vendor'),
        _popupItem('Clone'),
        _popupItem('Merge Customers'),
        _popupItem('Mark as Inactive'),
        _popupItem('Delete'),
      ],
    );
  }

  Widget _headerButton(String label, IconData icon, {bool isIconOnly = false}) {
    return Container(
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: isIconOnly ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != LucideIcons.chevronDown || label.isNotEmpty)
            Icon(icon, size: 16, color: const Color(0xFF4B5563)),
          if (!isIconOnly && label.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
          ],
          if (icon == LucideIcons.chevronDown && label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: const Color(0xFF4B5563)),
          ],
        ],
      ),
    );
  }

  Widget _popupItem(String text) {
    return MenuItemButton(
      onPressed: () {
        // TODO: Handle action
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        ),
      ),
    );
  }

  Widget _attachmentsButton() {
    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          child: _headerButton('', LucideIcons.paperclip, isIconOnly: true),
        );
      },
      menuChildren: [
        Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No Files Attached',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(
                    color: const Color(0xFFD1D5DB),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.upload,
                          size: 18,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Upload your Files',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'You can upload a maximum of 10 files, 10MB each',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSettingsMenu() {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(
            LucideIcons.settings,
            size: 18,
            color: Color(0xFF6B7280),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            context.push('/sales/customers/create');
          },
          child: const Text('Edit', style: TextStyle(fontSize: 13)),
        ),
        MenuItemButton(
          onPressed: () {
            // TODO: Implement delete
          },
          child: const Text(
            'Delete',
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
        ),
      ],
    );
  }
}
