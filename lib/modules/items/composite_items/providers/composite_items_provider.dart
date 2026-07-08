// lib/modules/items/composite_items/providers/composite_items_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/composite_item.dart';
import '../models/composite_item_history_model.dart';

class CompositeItemsState {
  final List<CompositeItem> records;
  final String sortField;
  final bool sortAscending;
  final String searchFilter;
  final String activeFilterValue; // 'all', 'assembly', 'kit'
  final bool isLoading;
  final Map<String, List<CompositeItemHistory>> historyByItemId;

  CompositeItemsState({
    required this.records,
    this.sortField = 'name',
    this.sortAscending = true,
    this.searchFilter = '',
    this.activeFilterValue = 'all',
    this.isLoading = false,
    this.historyByItemId = const {},
  });

  CompositeItemsState copyWith({
    List<CompositeItem>? records,
    String? sortField,
    bool? sortAscending,
    String? searchFilter,
    String? activeFilterValue,
    bool? isLoading,
    Map<String, List<CompositeItemHistory>>? historyByItemId,
  }) {
    return CompositeItemsState(
      records: records ?? this.records,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      searchFilter: searchFilter ?? this.searchFilter,
      activeFilterValue: activeFilterValue ?? this.activeFilterValue,
      isLoading: isLoading ?? this.isLoading,
      historyByItemId: historyByItemId ?? this.historyByItemId,
    );
  }
}

class CompositeItemsNotifier extends StateNotifier<CompositeItemsState> {
  CompositeItemsNotifier()
      : super(
          CompositeItemsState(
            records: _seedRecords,
            historyByItemId: {
              for (final item in _seedRecords)
                item.id: [
                  CompositeItemHistory(
                    occurredAt: DateTime(2026, 6, 20, 9, 3),
                    details: 'created by',
                    actor: 'zabnixprivatelimited',
                  ),
                ],
            },
          ),
        );

  static final List<CompositeItem> _seedRecords = [
    CompositeItem(
      id: 'CMP-001',
      name: 'Computer Assembly Unit',
      itemType: 'Assembly Item',
      sku: 'CPU-INTEL-I5',
      unit: 'pcs',
      category: 'Assemblies',
      hsnCode: '84713010',
      taxPreference: 'Taxable',
      sellingPrice: 45000.00,
      costPrice: 32000.00,
      reorderLevel: 5,
      manufacturer: 'Intel Corp',
      brand: 'Intel',
      isActive: true,
      stockQuantity: 3,   // below reorderLevel=5 → low stock
      isGrouped: true,
      associateItems: ['Intel Core i5', 'DDR4 RAM 8GB', 'SSD 500GB', 'Cabinet Box'],
      accountName: 'Sales',
      description: 'High performance computer assembly unit with i5 processor.',
      dimensions: '45 x 20 x 42 cm',
      mpn: 'MPN-INT-I5',
      purchaseAccountName: 'Cost of Goods Sold',
      purchaseDescription: 'Purchase of CPU, RAM, SSD and cabinet parts.',
      purchaseRate: 31000.00,
      upc: '735858348782',
      usageUnit: 'pcs',
      weight: 8.5,
    ),
    CompositeItem(
      id: 'CMP-002',
      name: 'Developer Kit Pack',
      itemType: 'Kit Item',
      sku: 'KIT-DEV-BOX',
      unit: 'pcs',
      category: 'Kits',
      hsnCode: '85235100',
      taxPreference: 'Taxable',
      sellingPrice: 1500.00,
      costPrice: 900.00,
      reorderLevel: 10,
      manufacturer: 'Logitech',
      brand: 'Logitech',
      isActive: true,
      stockQuantity: 25,
      isGrouped: false, // ungrouped
      associateItems: ['Mechanical Keyboard', 'Wired Mouse', 'Mouse Pad'],
      accountName: 'Sales',
      description: 'Logitech developer gear bundle kit.',
      dimensions: '50 x 25 x 10 cm',
      mpn: 'MPN-LOG-DEV',
      purchaseAccountName: 'Cost of Goods Sold',
      purchaseDescription: 'Bulk input purchases of Logitech accessories.',
      purchaseRate: 850.00,
      upc: '097855112233',
      usageUnit: 'box',
      weight: 2.1,
    ),
    CompositeItem(
      id: 'CMP-003',
      name: 'Standard Packaging Box',
      itemType: 'Assembly Item',
      sku: 'BOX-PKG-STD',
      unit: 'pcs',
      category: 'Packaging',
      hsnCode: '48191000',
      taxPreference: 'Taxable',
      sellingPrice: 150.00,
      costPrice: 95.00,
      reorderLevel: 50,
      manufacturer: 'PackCo',
      brand: 'PackCo',
      isActive: true,
      stockQuantity: 40,  // below reorderLevel=50 → low stock
      isGrouped: true,
      associateItems: ['Cardboard Sheets', 'Wrapping Paper', 'Adhesive Tape'],
      accountName: 'Sales',
      description: 'Standard corrugated cardboard shipping boxes.',
      dimensions: '30 x 30 x 30 cm',
      mpn: 'MPN-PKG-STD',
      purchaseAccountName: 'Cost of Goods Sold',
      purchaseDescription: 'Cardboard stock and tape materials purchase.',
      purchaseRate: 90.00,
      upc: '884488332211',
      usageUnit: 'pcs',
      weight: 0.45,
    ),
    CompositeItem(
      id: 'CMP-004',
      name: 'Office Starter Kit',
      itemType: 'Kit Item',
      sku: 'KIT-OFFICE-01',
      unit: 'set',
      category: 'Office Supplies',
      hsnCode: '96089900',
      taxPreference: 'Taxable',
      sellingPrice: 3200.00,
      costPrice: 2100.00,
      reorderLevel: 8,
      manufacturer: 'OfficeMax',
      brand: 'OfficeMax',
      isActive: false, // inactive
      stockQuantity: 15,
      isGrouped: true,
      associateItems: ['A4 Notepad', 'Ballpoint Pens x5', 'Stapler', 'Scissors'],
      accountName: 'Sales',
      description: 'Essential office desk supplies set.',
      dimensions: '35 x 28 x 15 cm',
      mpn: 'MPN-OFF-STARTER',
      purchaseAccountName: 'Cost of Goods Sold',
      purchaseDescription: 'Purchase of stationery kits in bulk.',
      purchaseRate: 2000.00,
      upc: '642112233445',
      usageUnit: 'set',
      weight: 1.8,
    ),
    CompositeItem(
      id: 'CMP-005',
      name: 'Network Switch Bundle',
      itemType: 'Assembly Item',
      sku: 'NET-SWITCH-24P',
      unit: 'pcs',
      category: 'Networking',
      hsnCode: '85176200',
      taxPreference: 'Taxable',
      sellingPrice: 12500.00,
      costPrice: 9200.00,
      reorderLevel: 3,
      manufacturer: 'Cisco',
      brand: 'Cisco',
      isActive: true,
      stockQuantity: 8,
      isGrouped: true,
      associateItems: ['24-Port Switch', 'Rack Mount Kit', 'Patch Cables x24'],
      accountName: 'Sales',
      description: 'Cisco 24-Port managed switch with cables.',
      dimensions: '48 x 25 x 4.4 cm',
      mpn: 'MPN-CIS-24P',
      purchaseAccountName: 'Cost of Goods Sold',
      purchaseDescription: 'Cisco switch network hardware parts.',
      purchaseRate: 9000.00,
      upc: '747120300900',
      usageUnit: 'pcs',
      weight: 3.2,
    ),
    CompositeItem(
      id: 'CMP-006',
      name: 'First Aid Cabinet',
      itemType: 'Kit Item',
      sku: 'MED-FAC-STD',
      unit: 'pcs',
      category: 'Safety',
      hsnCode: '30049099',
      taxPreference: 'Exempt',
      sellingPrice: 2800.00,
      costPrice: 1750.00,
      reorderLevel: 4,
      manufacturer: 'SafeGuard',
      brand: 'SafeGuard',
      isActive: false, // inactive
      stockQuantity: 2,  // below reorderLevel=4 → low stock
      isGrouped: false, // ungrouped
      associateItems: ['Bandages', 'Antiseptic', 'Gloves', 'Scissors', 'Thermometer'],
      accountName: 'Sales',
      description: 'Standard wall-mountable medical first aid kit.',
      dimensions: '40 x 30 x 12 cm',
      mpn: 'MPN-MED-SAFE',
      purchaseAccountName: 'Cost of Goods Sold',
      purchaseDescription: 'Medical box contents and cabinet casing.',
      purchaseRate: 1600.00,
      upc: '810023456789',
      usageUnit: 'pcs',
      weight: 2.5,
    ),
  ];

  void addRecord(CompositeItem record) {
    final history = Map<String, List<CompositeItemHistory>>.from(
      state.historyByItemId,
    );
    history[record.id] = [
      CompositeItemHistory(
        occurredAt: DateTime.now(),
        details: 'created by',
        actor: 'zabnixprivatelimited',
      ),
    ];
    state = state.copyWith(
      records: [...state.records, record],
      historyByItemId: history,
    );
  }

  void removeRecord(String id) {
    state = state.copyWith(
      records: state.records.where((r) => r.id != id).toList(),
    );
  }

  void updateRecord(CompositeItem record) {
    state = state.copyWith(
      records: state.records.map((r) => r.id == record.id ? record : r).toList(),
    );
  }

  void markActive(String id, bool active) {
    final matchingRecords = state.records.where((item) => item.id == id);
    if (matchingRecords.isEmpty) return;
    final record = matchingRecords.first;
    if (record.isActive == active) return;
    updateRecord(record.copyWith(isActive: active));
    recordHistory(id, active ? 'marked as active' : 'marked as inactive');
  }

  void recordHistory(String itemId, String details) {
    final history = Map<String, List<CompositeItemHistory>>.from(
      state.historyByItemId,
    );
    history[itemId] = [
      CompositeItemHistory(
        occurredAt: DateTime.now(),
        details: details,
        actor: 'zabnixprivatelimited',
      ),
      ...?history[itemId],
    ];
    state = state.copyWith(historyByItemId: history);
  }

  void sort(String field, bool ascending) {
    final sorted = List<CompositeItem>.from(state.records);
    sorted.sort((a, b) {
      dynamic valA, valB;
      switch (field) {
        case 'name':
          valA = a.name;
          valB = b.name;
          break;
        case 'sku':
          valA = a.sku;
          valB = b.sku;
          break;
        case 'itemType':
          valA = a.itemType;
          valB = b.itemType;
          break;
        case 'category':
          valA = a.category;
          valB = b.category;
          break;
        case 'reorderLevel':
          valA = a.reorderLevel;
          valB = b.reorderLevel;
          break;
        case 'manufacturer':
          valA = a.manufacturer;
          valB = b.manufacturer;
          break;
        case 'brand':
          valA = a.brand;
          valB = b.brand;
          break;
        case 'sellingPrice':
          valA = a.sellingPrice;
          valB = b.sellingPrice;
          break;
        case 'costPrice':
          valA = a.costPrice;
          valB = b.costPrice;
          break;
        default:
          valA = a.id;
          valB = b.id;
      }
      return ascending ? valA.compareTo(valB) : valB.compareTo(valA);
    });

    state = state.copyWith(
      records: sorted,
      sortField: field,
      sortAscending: ascending,
    );
  }

  void toggleSelectAll(bool val, int startIndex, int endIndex) {
    final updated = List<CompositeItem>.from(state.records);
    for (int i = startIndex; i < endIndex && i < updated.length; i++) {
      updated[i].isSelected = val;
    }
    state = state.copyWith(records: updated);
  }

  void toggleRecordSelect(int absoluteIndex, bool val) {
    final updated = List<CompositeItem>.from(state.records);
    if (absoluteIndex < updated.length) {
      updated[absoluteIndex].isSelected = val;
    }
    state = state.copyWith(records: updated);
  }

  void deleteSelected() {
    state = state.copyWith(
      records: state.records.where((r) => !r.isSelected).toList(),
    );
  }

  void bulkUpdate(String field, String value) {
    final updated = state.records.map((r) {
      if (!r.isSelected) return r;
      switch (field) {
        case 'Category':
          return r.copyWith(category: value);
        case 'Reorder Level':
          return r.copyWith(reorderLevel: int.tryParse(value) ?? r.reorderLevel);
        case 'Manufacturer':
          return r.copyWith(manufacturer: value);
        case 'Brand':
          return r.copyWith(brand: value);
        case 'Returnable':
          return r.copyWith(returnable: value.toUpperCase() == 'YES' || value.toUpperCase() == 'TRUE');
        case 'Tax Preference':
          return r.copyWith(taxPreference: value);
        default:
          return r;
      }
    }).toList();
    state = state.copyWith(records: updated);
  }

  void bulkMarkActive(bool active) {
    final selectedIds = state.records
        .where((record) => record.isSelected && record.isActive != active)
        .map((record) => record.id)
        .toList();
    state = state.copyWith(
      records: state.records
          .map((r) => r.isSelected ? r.copyWith(isActive: active) : r)
          .toList(),
    );
    for (final id in selectedIds) {
      recordHistory(id, active ? 'marked as active' : 'marked as inactive');
    }
  }

  void bulkAddGroup() {
    state = state.copyWith(
      records: state.records
          .map((r) => r.isSelected ? r.copyWith(isGrouped: true) : r)
          .toList(),
    );
  }

  void bulkMarkReturnable(bool returnable) {
    state = state.copyWith(
      records: state.records
          .map(
            (r) =>
                r.isSelected ? r.copyWith(returnable: returnable) : r,
          )
          .toList(),
    );
  }

  void bulkEnableBinLocation(bool enable) {
    state = state.copyWith(
      records: state.records
          .map(
            (r) =>
                r.isSelected ? r.copyWith(trackBinLocation: enable) : r,
          )
          .toList(),
    );
  }

  void setSearchFilter(String filter) {
    state = state.copyWith(searchFilter: filter);
  }

  void setFilterValue(String value) {
    state = state.copyWith(activeFilterValue: value);
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));
    state = state.copyWith(isLoading: false);
  }
}

final compositeItemsProvider =
    StateNotifierProvider<CompositeItemsNotifier, CompositeItemsState>((ref) {
  return CompositeItemsNotifier();
});
