import '../models/role_permission_models.dart';

class RolePermissionScheme {
  static List<PermissionSectionMeta> getMetadata() {
    return [
      PermissionSectionMeta(
        title: 'CONTACTS',
        rows: [
          PermissionRowMeta(
            label: 'Customers',
            key: 'customers',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: [
              'Import Customers',
              'Export Customers',
              'Request review from customers',
              'Bulk Update',
            ],
            tooltip:
                'Control access to customer profiles and their interaction history.',
          ),
          PermissionRowMeta(
            label: 'Vendors',
            key: 'vendors',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Import Vendors', 'Export Vendors', 'Bulk Update'],
            tooltip:
                'Control access to vendor profiles and financial relations.',
            subRows: [
              PermissionRowMeta(
                label:
                    "Allow users to add, edit and delete vendor's bank account details.",
                key: 'vendor_bank_details',
                actions: ['view'],
                isSettingsList: true,
              ),
            ],
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'ITEMS',
        rows: [
          PermissionRowMeta(
            label: 'Item',
            key: 'item',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Import Items', 'Export Items', 'Adjust Stock'],
          ),
          PermissionRowMeta(
            label: 'Composite Items',
            key: 'composite_items',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Transfer Orders',
            key: 'transfer_orders',
            actions: ['view', 'create', 'edit', 'delete', 'approve'],
          ),
          PermissionRowMeta(
            label: 'Inventory Adjustments',
            key: 'inventory_adjustments',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Price List',
            key: 'price_list',
            actions: ['view', 'create', 'edit', 'delete', 'approve'],
          ),
          PermissionRowMeta(
            label: 'Stock Counting',
            key: 'stock_counting',
            actions: ['view', 'create', 'edit', 'delete', 'approve'],
            tooltip:
                'Users with this permission will be able to enter stock counts from the mobile app. To create an adjustment, the Stock Adjustment permission is needed.',
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'SALES',
        rows: [
          PermissionRowMeta(label: 'Sales Orders', key: 'sales_orders'),
          PermissionRowMeta(
            label: 'Invoices',
            key: 'invoices',
            overrides: [
              'Import Invoices',
              'Export Invoices',
              'Write-off Invoices',
            ],
          ),
          PermissionRowMeta(
            label: 'Customer Payments',
            key: 'customer_payments',
          ),
          PermissionRowMeta(label: 'Credit Notes', key: 'credit_notes'),
          PermissionRowMeta(label: 'Packages', key: 'packages'),
          PermissionRowMeta(label: 'Sales Shipments', key: 'sales_shipments'),
          PermissionRowMeta(
            label: 'Retainer Invoices',
            key: 'retainer_invoices',
          ),
          PermissionRowMeta(label: 'Sales Returns', key: 'sales_returns'),
        ],
      ),
      PermissionSectionMeta(
        title: 'PURCHASES',
        rows: [
          PermissionRowMeta(label: 'Purchase Orders', key: 'purchase_orders'),
          PermissionRowMeta(label: 'Bills', key: 'bills'),
          PermissionRowMeta(label: 'Vendor Payments', key: 'vendor_payments'),
          PermissionRowMeta(label: 'Vendor Credits', key: 'vendor_credits'),
          PermissionRowMeta(
            label: 'Purchase Receives',
            key: 'purchase_receives',
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'ACCOUNTANT/LOCATIONS/TASKS',
        rows: [
          PermissionRowMeta(
            label: 'Chart of Accounts',
            key: 'chart_of_accounts',
          ),
          PermissionRowMeta(label: 'Manual Journals', key: 'manual_journals'),
          PermissionRowMeta(label: 'Location management', key: 'locations'),
          PermissionRowMeta(label: 'Projects / Tasks', key: 'tasks'),
        ],
      ),
      PermissionSectionMeta(
        title: 'SETTINGS & COMPLIANCE',
        rows: [
          PermissionRowMeta(
            label: 'General Preferences',
            key: 'general_prefs',
            actions: ['view'],
            isSettingsList: true,
            infoTooltip:
                'Configure basic organizational settings and preferences.',
          ),
          PermissionRowMeta(
            label: 'Communication',
            key: 'communication_prefs',
            actions: ['view'],
            isSettingsList: true,
            tooltip:
                'Checking this option will allow the user to communicate through the enabled communication routes (Email).',
          ),
          PermissionRowMeta(
            label: 'Incoming Webhook',
            key: 'incoming_webhook',
            actions: ['view'],
            isSettingsList: true,
            tooltip:
                'Enabling webhooks allows external services to push data into Zerpai. Be cautious as this might expose your endpoint to unauthorized access.',
            infoTooltip:
                'Administrative warning: Ensure your secret keys are secured.',
          ),
          PermissionRowMeta(
            label: 'Users & Roles',
            key: 'users_roles',
            actions: ['view'],
            isSettingsList: true,
          ),
          PermissionRowMeta(
            label: 'Taxes',
            key: 'taxes',
            actions: ['view'],
            isSettingsList: true,
          ),
          PermissionRowMeta(
            label: 'Currencies',
            key: 'currencies',
            actions: ['view'],
            isSettingsList: true,
          ),
          PermissionRowMeta(
            label: 'Templates',
            key: 'templates',
            actions: ['view'],
            isSettingsList: true,
          ),
          PermissionRowMeta(
            label: 'Automation',
            key: 'automation',
            actions: ['view'],
            isSettingsList: true,
          ),
          PermissionRowMeta(
            label: 'e-Way Bill Settings',
            key: 'ewaybill_settings',
            actions: ['view'],
            isSettingsList: true,
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'ADDITIONAL SECTIONS',
        rows: [
          PermissionRowMeta(
            label: 'Documents',
            key: 'documents',
            actions: ['view'],
            isSettingsList: true,
          ),
          PermissionRowMeta(
            label: 'Dashboard charts',
            key: 'dashboard_charts',
            actions: ['view'],
            isSettingsList: true,
          ),
          PermissionRowMeta(
            label: 'e-Way Bill Permissions',
            key: 'ewaybill_perms',
            actions: ['view'],
            isSettingsList: true,
          ),
        ],
      ),
    ];
  }

  static Map<String, Set<String>> getDefaultPermissions() {
    final Map<String, Set<String>> perms = {};
    for (final section in getMetadata()) {
      for (final row in section.rows) {
        perms[row.key] = {'full', ...row.actions};
        if (row.subRows != null) {
          for (final sub in row.subRows!) {
            perms[sub.key] = {'full', ...sub.actions};
          }
        }
      }
    }
    return perms;
  }

  static Map<String, Set<String>> getDefaultReportPermissions() {
    return {
      'Sales': {'full_access', 'view', 'export', 'schedule', 'share'},
      'Inventory': {'full_access', 'view', 'export', 'schedule', 'share'},
      'Receivables': {'full_access', 'view', 'export', 'schedule', 'share'},
      'Payables': {'full_access', 'view', 'export', 'schedule', 'share'},
      'Purchases and Expenses': {
        'full_access',
        'view',
        'export',
        'schedule',
        'share',
      },
      'Taxes': {'full_access', 'view', 'export', 'schedule', 'share'},
      'Activity': {'full_access', 'view', 'export', 'schedule', 'share'},
    };
  }

  static List<String> getReportCategories() {
    return [
      'Sales',
      'Inventory',
      'Receivables',
      'Payables',
      'Purchases and Expenses',
      'Taxes',
      'Activity',
    ];
  }
}
