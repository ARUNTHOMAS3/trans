// lib/modules/items/composite_items/models/composite_item.dart

class CompositeItem {
  final String id;
  final String name;
  final String itemType; // 'Assembly Item' or 'Kit Item'
  final String sku;
  final String unit;
  final String category;
  final bool returnable;
  final String hsnCode;
  final String taxPreference;
  final String exemptionReason;
  final double sellingPrice;
  final double costPrice;
  final List<String> associateItems;
  bool isSelected;

  // Additional report columns
  final int reorderLevel;
  final String manufacturer;
  final String brand;
  final bool isActive;
  final int stockQuantity;
  final bool isGrouped;

  final String accountName;
  final String description;
  final String dimensions;
  final String mpn;
  final String purchaseAccountName;
  final String purchaseDescription;
  final double purchaseRate;
  final String upc;
  final String usageUnit;
  final double weight;
  final bool trackBinLocation;
  final bool isReturnable;
  final bool isLock;
  final bool pushToEcommerce;

  CompositeItem({
    required this.id,
    required this.name,
    required this.itemType,
    required this.sku,
    required this.unit,
    required this.category,
    this.returnable = true,
    required this.hsnCode,
    required this.taxPreference,
    this.exemptionReason = '',
    required this.sellingPrice,
    required this.costPrice,
    this.associateItems = const [],
    this.isSelected = false,
    this.reorderLevel = 0,
    this.manufacturer = '',
    this.brand = '',
    this.isActive = true,
    this.stockQuantity = 0,
    this.isGrouped = true,
    this.accountName = '',
    this.description = '',
    this.dimensions = '',
    this.mpn = '',
    this.purchaseAccountName = '',
    this.purchaseDescription = '',
    this.purchaseRate = 0.0,
    this.upc = '',
    this.usageUnit = '',
    this.weight = 0.0,
    this.trackBinLocation = false,
    this.isReturnable = true,
    this.isLock = false,
    this.pushToEcommerce = false,
  });

  factory CompositeItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) =>
        v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;
    int toInt(dynamic v) =>
        v == null ? 0 : int.tryParse(v.toString()) ?? 0;
    bool toBool(dynamic v) => v == true || v == 'true' || v == 1;

    return CompositeItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['product_name'] ?? '').toString(),
      itemType: (json['item_type'] ?? json['composite_type'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      unit: (json['unit'] ?? json['usage_unit'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      returnable: json['returnable'] == null ? true : toBool(json['returnable']),
      hsnCode: (json['hsn_code'] ?? '').toString(),
      taxPreference: (json['tax_preference'] ?? '').toString(),
      exemptionReason: (json['exemption_reason'] ?? '').toString(),
      sellingPrice: toDouble(json['selling_price']),
      costPrice: toDouble(json['cost_price']),
      reorderLevel: toInt(json['reorder_level']),
      manufacturer: (json['manufacturer'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      isActive: json['is_active'] == null ? true : toBool(json['is_active']),
      stockQuantity: toInt(json['stock_quantity']),
      isGrouped: json['is_grouped'] == null ? true : toBool(json['is_grouped']),
      accountName: (json['account_name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      dimensions: (json['dimensions'] ?? '').toString(),
      mpn: (json['mpn'] ?? '').toString(),
      purchaseAccountName: (json['purchase_account_name'] ?? '').toString(),
      purchaseDescription: (json['purchase_description'] ?? '').toString(),
      purchaseRate: toDouble(json['purchase_rate']),
      upc: (json['upc'] ?? '').toString(),
      usageUnit: (json['usage_unit'] ?? '').toString(),
      weight: toDouble(json['weight']),
      trackBinLocation: toBool(json['track_bin_location']),
      isReturnable: json['is_returnable'] == null
          ? true
          : toBool(json['is_returnable']),
      isLock: toBool(json['is_lock']),
      pushToEcommerce: toBool(json['push_to_ecommerce']),
    );
  }

  CompositeItem copyWith({
    String? id,
    String? name,
    String? itemType,
    String? sku,
    String? unit,
    String? category,
    bool? returnable,
    String? hsnCode,
    String? taxPreference,
    String? exemptionReason,
    double? sellingPrice,
    double? costPrice,
    List<String>? associateItems,
    bool? isSelected,
    int? reorderLevel,
    String? manufacturer,
    String? brand,
    bool? isActive,
    int? stockQuantity,
    bool? isGrouped,
    String? accountName,
    String? description,
    String? dimensions,
    String? mpn,
    String? purchaseAccountName,
    String? purchaseDescription,
    double? purchaseRate,
    String? upc,
    String? usageUnit,
    double? weight,
    bool? trackBinLocation,
    bool? isReturnable,
    bool? isLock,
    bool? pushToEcommerce,
  }) {
    return CompositeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      itemType: itemType ?? this.itemType,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      returnable: returnable ?? this.returnable,
      hsnCode: hsnCode ?? this.hsnCode,
      taxPreference: taxPreference ?? this.taxPreference,
      exemptionReason: exemptionReason ?? this.exemptionReason,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      associateItems: associateItems ?? this.associateItems,
      isSelected: isSelected ?? this.isSelected,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      manufacturer: manufacturer ?? this.manufacturer,
      brand: brand ?? this.brand,
      isActive: isActive ?? this.isActive,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isGrouped: isGrouped ?? this.isGrouped,
      accountName: accountName ?? this.accountName,
      description: description ?? this.description,
      dimensions: dimensions ?? this.dimensions,
      mpn: mpn ?? this.mpn,
      purchaseAccountName: purchaseAccountName ?? this.purchaseAccountName,
      purchaseDescription: purchaseDescription ?? this.purchaseDescription,
      purchaseRate: purchaseRate ?? this.purchaseRate,
      upc: upc ?? this.upc,
      usageUnit: usageUnit ?? this.usageUnit,
      weight: weight ?? this.weight,
      trackBinLocation: trackBinLocation ?? this.trackBinLocation,
      isReturnable: isReturnable ?? this.isReturnable,
      isLock: isLock ?? this.isLock,
      pushToEcommerce: pushToEcommerce ?? this.pushToEcommerce,
    );
  }
}
