// PATH: lib/modules/auth/services/permission_service.dart

import '../models/user_model.dart';

class PermissionService {
  /// Check if user has specific permission
  static bool hasPermission(User user, Permission permission) {
    final userPermissions = _getUserPermissions(user.role);
    return userPermissions.contains(permission);
  }

  /// Check if user has all required permissions
  static bool hasAllPermissions(User user, List<Permission> permissions) {
    final userPermissions = _getUserPermissions(user.role);
    return permissions.every((perm) => userPermissions.contains(perm));
  }

  /// Check if user has any of the specified permissions
  static bool hasAnyPermission(User user, List<Permission> permissions) {
    final userPermissions = _getUserPermissions(user.role);
    return permissions.any((perm) => userPermissions.contains(perm));
  }

  /// Get all permissions for a user's role
  static List<Permission> getUserPermissions(User user) {
    return _getUserPermissions(user.role);
  }

  /// Private method to get permissions by role
  static List<Permission> _getUserPermissions(String role) {
    switch (role) {
      case 'super_admin':
        return Permission.values; // All permissions

      case 'ho_admin':
        return [
          Permission.viewDashboard,
          Permission.manageUsers,
          Permission.manageOrganizations,
          Permission.manageOutlets,
          Permission.viewReports,
          Permission.exportData,
          Permission.manageProducts,
          Permission.manageCustomers,
          Permission.manageVendors,
          Permission.createSalesOrders,
          Permission.createPurchaseOrders,
          Permission.manageInventory,
          Permission.viewAccountant,
          Permission.createTransactions,
          Permission.manageChartOfAccounts,
          Permission.viewFinancialReports,
        ];

      case 'outlet_manager':
        return [
          Permission.viewDashboard,
          Permission.manageOutletUsers,
          Permission.viewOutletReports,
          Permission.manageProducts,
          Permission.manageCustomers,
          Permission.manageVendors,
          Permission.createSalesOrders,
          Permission.createPurchaseOrders,
          Permission.manageInventory,
          Permission.viewAccountant,
          Permission.createTransactions,
        ];

      case 'outlet_staff':
        return [
          Permission.viewDashboard,
          Permission.viewCustomers,
          Permission.createSalesOrders,
          Permission.viewInventory,
          Permission.viewAccountant,
        ];

      default:
        return [];
    }
  }
}

/// Enum representing all possible permissions in the system
enum Permission {
  // Dashboard & Analytics
  viewDashboard,

  // User Management
  manageUsers,
  manageOutletUsers,

  // Organization & Outlet Management
  manageOrganizations,
  manageOutlets,

  // Reporting
  viewReports,
  viewOutletReports,
  viewFinancialReports,
  exportData,

  // Product Management
  manageProducts,
  viewProducts,

  // Customer Management
  manageCustomers,
  viewCustomers,

  // Vendor Management
  manageVendors,
  viewVendors,

  // Sales Orders
  createSalesOrders,
  viewSalesOrders,
  editSalesOrders,
  deleteSalesOrders,

  // Purchase Orders
  createPurchaseOrders,
  viewPurchaseOrders,
  editPurchaseOrders,
  deletePurchaseOrders,

  // Inventory Management
  manageInventory,
  viewInventory,
  adjustInventory,
  transferInventory,

  // Accounts & Finance
  viewAccountant,
  createTransactions,
  manageChartOfAccounts,
  viewLedger,
  createJournalEntries,

  // Settings
  manageSystemSettings,
  manageOutletSettings,
}
