import '../models/role_permission_models.dart';

class RolePermissionScheme {
  static List<PermissionSectionMeta> getMetadata() {
    return [
      PermissionSectionMeta(
        title: 'ITEMS',
        rows: [
          PermissionRowMeta(
            label: 'All Items',
            key: 'item',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Import Items', 'Export Items'],
          ),
          PermissionRowMeta(
            label: 'Composite Items',
            key: 'composite_items',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Item Groups',
            key: 'item_groups',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Price Lists',
            key: 'price_list',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Item Mapping',
            key: 'item_mapping',
            actions: ['view', 'edit'],
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'INVENTORY',
        rows: [
          PermissionRowMeta(
            label: 'Assemblies',
            key: 'assemblies',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Adjustments',
            key: 'inventory_adjustments',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Picklists',
            key: 'picklists',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Packages',
            key: 'packages',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Shipments',
            key: 'shipments',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Transfer Orders',
            key: 'transfer_orders',
            actions: ['view', 'create', 'edit', 'delete', 'approve'],
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'SALES',
        rows: [
          PermissionRowMeta(
            label: 'Customers',
            key: 'customers',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: [
              'Import Customers',
              'Export Customers',
              'Invite to Portal',
              'Merge Customers',
              'Mark Active/Inactive',
              'Request GST',
              'Bulk Update',
            ],
          ),
          PermissionRowMeta(
            label: 'Quotations',
            key: 'quotations',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: [
              'Export Quotations',
              'Clone Quotation',
              'Convert to Sales Order',
              'Convert to Invoice',
            ],
          ),
          PermissionRowMeta(
            label: 'Sales Orders',
            key: 'sales_orders',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: [
              'Export Sales Orders',
              'Clone Sales Order',
              'Convert to Invoice',
              'Convert to Challan',
              'Package / Ship',
            ],
          ),
          PermissionRowMeta(
            label: 'Invoices',
            key: 'invoices',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: [
              'Export Invoices',
              'Send by Email',
              'Record Payment',
              'Clone Invoice',
            ],
          ),
          PermissionRowMeta(
            label: 'Delivery Challans',
            key: 'delivery_challans',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Delivery Challans'],
          ),
          PermissionRowMeta(
            label: 'Payments Received',
            key: 'customer_payments',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Customer Payments', 'Bulk Update'],
          ),
          PermissionRowMeta(
            label: 'Returns',
            key: 'sales_returns',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Sales Returns'],
          ),
          PermissionRowMeta(
            label: 'Credit Notes',
            key: 'credit_notes',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Credit Notes', 'Apply to Invoices'],
          ),
          PermissionRowMeta(
            label: 'Retainer Invoices',
            key: 'retainer_invoices',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Retainer Invoices'],
          ),
          PermissionRowMeta(
            label: 'e-Way Bills',
            key: 'ewaybill_perms',
            actions: ['view', 'create', 'delete'],
            overrides: ['Generate from Invoice', 'Generate from Challan'],
          ),
          PermissionRowMeta(
            label: 'Payment Links',
            key: 'payment_links',
            actions: ['view', 'create', 'delete'],
            overrides: ['Resend Link'],
          ),
          PermissionRowMeta(
            label: 'Recurring Invoices',
            key: 'recurring_invoices',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'PURCHASES',
        rows: [
          PermissionRowMeta(
            label: 'Vendors',
            key: 'vendors',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: [
              'Import Vendors',
              'Export Vendors',
              'Mark Active/Inactive',
              'Merge Vendors',
              'Bulk Update',
            ],
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
          PermissionRowMeta(
            label: 'Expenses',
            key: 'expenses',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Expenses', 'Mark as Billable'],
          ),
          PermissionRowMeta(
            label: 'Recurring Expenses',
            key: 'recurring_expenses',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Purchase Orders',
            key: 'purchase_orders',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Purchase Orders'],
          ),
          PermissionRowMeta(
            label: 'Purchase Receives',
            key: 'purchase_receives',
            actions: ['view', 'create', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Bills',
            key: 'bills',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Bills', 'Pay Bill', 'Clone Bill'],
          ),
          PermissionRowMeta(
            label: 'Payments Made',
            key: 'vendor_payments',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Vendor Payments', 'Bulk Update'],
          ),
          PermissionRowMeta(
            label: 'Vendor Credits',
            key: 'vendor_credits',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Export Vendor Credits', 'Apply to Bills'],
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'ACCOUNTANT/LOCATIONS/TASKS',
        rows: [
          PermissionRowMeta(
            label: 'Chart of Accounts',
            key: 'chart_of_accounts',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Import Chart of Accounts', 'Export Chart of Accounts'],
          ),
          PermissionRowMeta(
            label: 'Manual Journals',
            key: 'manual_journals',
            actions: ['view', 'create', 'edit', 'delete'],
            overrides: ['Publish Journals', 'Reverse Journals'],
          ),
          PermissionRowMeta(
            label: 'Journal Templates',
            key: 'journal_templates',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Opening Balances',
            key: 'opening_balances',
            actions: ['view', 'edit'],
          ),
          PermissionRowMeta(
            label: 'Bulk Update',
            key: 'bulk_update',
            actions: ['view', 'edit'],
          ),
          PermissionRowMeta(
            label: 'Transaction Locking',
            key: 'transaction_locking',
            actions: ['view', 'edit'],
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'SETTINGS & COMPLIANCE',
        rows: [
          PermissionRowMeta(
            label: 'Org Profile',
            key: 'general_prefs',
            actions: ['view', 'edit'],
            tooltip:
                'Edit organization profile, branding, and basic preferences.',
          ),
          PermissionRowMeta(
            label: 'Branches',
            key: 'branches',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Warehouses',
            key: 'warehouses',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Zones & Bins',
            key: 'zones',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Users',
            key: 'users_roles',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Roles',
            key: 'users_roles',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Taxes / Compliance',
            key: 'general_prefs',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
          PermissionRowMeta(
            label: 'Configurations',
            key: 'general_prefs',
            actions: ['view', 'edit'],
          ),
          PermissionRowMeta(
            label: 'Automation',
            key: 'general_prefs',
            actions: ['view', 'create', 'edit', 'delete'],
          ),
        ],
      ),
      PermissionSectionMeta(
        title: 'REPORTS',
        rows: [
          PermissionRowMeta(
            label: 'Report Center',
            key: 'reports',
            actions: ['view'],
          ),
          PermissionRowMeta(
            label: 'Sales Reports',
            key: 'reports',
            actions: ['view', 'export'],
          ),
          PermissionRowMeta(
            label: 'Financial Statements',
            key: 'reports',
            actions: ['view', 'export'],
          ),
          PermissionRowMeta(
            label: 'Inventory Reports',
            key: 'reports',
            actions: ['view', 'export'],
          ),
          PermissionRowMeta(
            label: 'Audit Logs',
            key: 'audit_logs',
            actions: ['view'],
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
