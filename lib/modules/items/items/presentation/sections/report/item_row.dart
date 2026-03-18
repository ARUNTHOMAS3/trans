// FILE: lib/modules/items/presentation/sections/report/item_row.dart

// -----------------------------------------------------------
// DUMMY DATA MODEL FOR ITEMS REPORT
// -----------------------------------------------------------

class ItemRow {
  final String? id;
  // Core display fields
  final String name;
  final String accountName;

  // Basic Information
  final String? billingName;
  final String? itemCode;
  final String? typeDisplay; // "Goods" or "Service"
  final String? taxPreference; // "Taxable", "Non-Taxable", "Exempt"
  final String? hsn;
  final String? sku;
  final String? ean;
  final String? brand;
  final String? category;

  // Sales Information
  final String? sellingPrice;
  final String? mrp;
  final String? ptr;
  final String? salesAccount;
  final String? salesDescription;

  // Purchase Information
  final String? costPrice;
  final String? purchaseAccount;
  final String? preferredVendor;
  final String? purchaseDescription;

  // Formulation
  final String? length;
  final String? width;
  final String? height;
  final String? weight;
  final String? manufacturer;
  final String? mpn;
  final String? upc;
  final String? isbn;

  // Inventory
  final String? stockOnHand;
  final String? reorderLevel;
  final String? inventoryValuationMethod;
  final String? storageLocation;
  final String? reorderTerm;

  // Composition
  final String? buyingRule;
  final String? scheduleOfDrug;

  final String? description; // Maps to salesDescription
  final String itemType; // 'service' or 'goods' (for filtering)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Flags for filters
  final bool trackActiveIngredients;
  final bool isActive;
  final bool isLock;
  final bool isReturnable;
  final bool pushToEcommerce;
  final bool isTemperatureControlled;
  final bool isSalesItem;
  final bool isPurchaseItem;
  final bool isInventoryItem;
  final bool usesBatch;
  final bool isRackItem;
  final bool hasReorderPoint;
  final bool isScheduledDrug;
  final bool isTaxable;
  final bool hasCategory;
  final bool hasSku;
  final String? imageUrl;

  const ItemRow({
    this.id,
    // Core
    required this.name,
    required this.accountName,

    // Basic Information
    this.billingName,
    this.itemCode,
    this.typeDisplay,
    this.taxPreference,
    this.hsn,
    this.sku,
    this.ean,
    this.brand,
    this.category,

    // Sales Information
    this.sellingPrice,
    this.mrp,
    this.ptr,
    this.salesAccount,
    this.salesDescription,

    // Purchase Information
    this.costPrice,
    this.purchaseAccount,
    this.preferredVendor,
    this.purchaseDescription,

    // Formulation
    this.length,
    this.width,
    this.height,
    this.weight,
    this.manufacturer,
    this.mpn,
    this.upc,
    this.isbn,

    // Inventory
    this.stockOnHand,
    this.reorderLevel,
    this.inventoryValuationMethod,
    this.storageLocation,
    this.reorderTerm,

    // Composition
    this.buyingRule,
    this.scheduleOfDrug,

    // Legacy
    this.description,
    this.itemType = 'goods',
    this.createdAt,
    this.updatedAt,

    // Flags
    this.trackActiveIngredients = false,
    this.isActive = true,
    this.isLock = false,
    this.isReturnable = true,
    this.pushToEcommerce = false,
    this.isTemperatureControlled = false,
    this.isSalesItem = true,
    this.isPurchaseItem = true,
    this.isInventoryItem = true,
    this.usesBatch = true,
    this.isRackItem = true,
    this.hasReorderPoint = true,
    this.isScheduledDrug = false,
    this.isTaxable = true,
    this.hasCategory = true,
    this.hasSku = true,
    this.imageUrl,
  });

  String get selectionId => id ?? name;
}
