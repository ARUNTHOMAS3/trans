import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages which columns are visible in the Items Report table
/// Persists user preferences in localStorage
class ColumnVisibilityManager extends ChangeNotifier {
  static const String _storageKey = 'items_report_visible_columns';

  // Default visible columns
  static const Set<String> _defaultVisibleColumns = {
    'name',
    'sku',
    'hsn',
    'category',
    'ean',
    'brand',
    'stockOnHand',
    'reorderLevel',
    'accountName',
    'description',
  };

  Set<String> _visibleColumns = Set.from(_defaultVisibleColumns);

  Set<String> get visibleColumns => Set.unmodifiable(_visibleColumns);

  ColumnVisibilityManager() {
    _loadFromStorage();
  }

  /// Load saved column visibility from localStorage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);

      if (saved != null) {
        final List<dynamic> decoded = jsonDecode(saved);
        _visibleColumns = Set<String>.from(decoded);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading column visibility: $e');
      // Fall back to defaults
      _visibleColumns = Set.from(_defaultVisibleColumns);
    }
  }

  /// Save column visibility to localStorage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_visibleColumns.toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving column visibility: $e');
    }
  }

  /// Check if a column is visible
  bool isVisible(String columnKey) {
    return _visibleColumns.contains(columnKey);
  }

  /// Toggle a column's visibility
  void toggleColumn(String columnKey) {
    if (_visibleColumns.contains(columnKey)) {
      _visibleColumns.remove(columnKey);
    } else {
      _visibleColumns.add(columnKey);
    }
    _saveToStorage();
    notifyListeners();
  }

  /// Set multiple columns' visibility at once
  void setVisibleColumns(Set<String> columns) {
    _visibleColumns = Set.from(columns);
    _saveToStorage();
    notifyListeners();
  }

  /// Reset to default columns
  void resetToDefaults() {
    _visibleColumns = Set.from(_defaultVisibleColumns);
    _saveToStorage();
    notifyListeners();
  }

  /// Get all available column definitions
  static List<ColumnDefinition> getAllColumns() {
    return [
      // Basic Information
      const ColumnDefinition(
        key: 'name',
        label: 'Name',
        group: 'Basic Information',
        isRequired: true,
      ),
      const ColumnDefinition(
        key: 'billingName',
        label: 'Billing Name',
        group: 'Basic Information',
      ),
      const ColumnDefinition(
        key: 'itemCode',
        label: 'Item Code',
        group: 'Basic Information',
      ),
      const ColumnDefinition(
        key: 'typeDisplay',
        label: 'Type',
        group: 'Basic Information',
      ),
      const ColumnDefinition(
        key: 'taxPreference',
        label: 'Tax Preference',
        group: 'Basic Information',
      ),
      const ColumnDefinition(
        key: 'hsn',
        label: 'HSN/SAC',
        group: 'Basic Information',
      ),
      const ColumnDefinition(
        key: 'sku',
        label: 'SKU',
        group: 'Basic Information',
      ),
      const ColumnDefinition(
        key: 'ean',
        label: 'EAN',
        group: 'Basic Information',
      ),
      const ColumnDefinition(
        key: 'brand',
        label: 'Brand',
        group: 'Basic Information',
      ),
      const ColumnDefinition(
        key: 'category',
        label: 'Category',
        group: 'Basic Information',
      ),

      // Sales Information
      const ColumnDefinition(
        key: 'sellingPrice',
        label: 'Selling Price',
        group: 'Sales Information',
      ),
      const ColumnDefinition(
        key: 'mrp',
        label: 'MRP',
        group: 'Sales Information',
      ),
      const ColumnDefinition(
        key: 'ptr',
        label: 'PTR',
        group: 'Sales Information',
      ),
      const ColumnDefinition(
        key: 'salesAccount',
        label: 'Sales Account',
        group: 'Sales Information',
      ),
      const ColumnDefinition(
        key: 'description',
        label: 'Sales Description',
        group: 'Sales Information',
      ),

      // Purchase Information
      const ColumnDefinition(
        key: 'costPrice',
        label: 'Cost Price',
        group: 'Purchase Information',
      ),
      const ColumnDefinition(
        key: 'purchaseAccount',
        label: 'Purchase Account',
        group: 'Purchase Information',
      ),
      const ColumnDefinition(
        key: 'preferredVendor',
        label: 'Preferred Vendor',
        group: 'Purchase Information',
      ),
      const ColumnDefinition(
        key: 'purchaseDescription',
        label: 'Purchase Description',
        group: 'Purchase Information',
      ),

      // Formulation
      const ColumnDefinition(
        key: 'length',
        label: 'Length',
        group: 'Formulation',
      ),
      const ColumnDefinition(
        key: 'width',
        label: 'Width',
        group: 'Formulation',
      ),
      const ColumnDefinition(
        key: 'height',
        label: 'Height',
        group: 'Formulation',
      ),
      const ColumnDefinition(
        key: 'weight',
        label: 'Weight',
        group: 'Formulation',
      ),
      const ColumnDefinition(
        key: 'manufacturer',
        label: 'Manufacturer/Patent',
        group: 'Formulation',
      ),
      const ColumnDefinition(key: 'mpn', label: 'MPN', group: 'Formulation'),
      const ColumnDefinition(key: 'upc', label: 'UPC', group: 'Formulation'),
      const ColumnDefinition(key: 'isbn', label: 'ISBN', group: 'Formulation'),

      // Inventory
      const ColumnDefinition(
        key: 'stockOnHand',
        label: 'Stock on Hand',
        group: 'Inventory',
      ),
      const ColumnDefinition(
        key: 'reorderLevel',
        label: 'Reorder Level',
        group: 'Inventory',
      ),
      const ColumnDefinition(
        key: 'inventoryValuationMethod',
        label: 'Inventory Valuation Method',
        group: 'Inventory',
      ),
      const ColumnDefinition(
        key: 'storageLocation',
        label: 'Storage Location',
        group: 'Inventory',
      ),
      const ColumnDefinition(
        key: 'reorderTerm',
        label: 'Reorder Term',
        group: 'Inventory',
      ),

      // Composition
      const ColumnDefinition(
        key: 'buyingRule',
        label: 'Buying Rule',
        group: 'Composition',
      ),
      const ColumnDefinition(
        key: 'scheduleOfDrug',
        label: 'Schedule of Drug',
        group: 'Composition',
      ),

      // Legacy
      const ColumnDefinition(
        key: 'accountName',
        label: 'Account Name',
        group: 'Basic Information',
      ),
    ];
  }
}

/// Definition of a column
class ColumnDefinition {
  final String key;
  final String label;
  final String group;
  final bool isRequired;

  const ColumnDefinition({
    required this.key,
    required this.label,
    required this.group,
    this.isRequired = false,
  });
}
