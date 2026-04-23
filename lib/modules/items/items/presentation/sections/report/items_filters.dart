// FILE: lib/modules/items/presentation/items_filters.dart

// -----------------------------------------------------------
// ITEMS FILTER ENUM + OPTIONS
// -----------------------------------------------------------

enum ItemsFilter {
  all,
  service,
  composite,
  active,
  inactive,
  returnable,
  nonreturnable,
  temperature,
  nontemperature,
  sales,
  purchase,
  inventory,
  noninventory,
  batch,
  nonbatch,
  lowstock,
  belowreorderpoint,
  abovereorderpoint,
  nonrackgoods,
  nonreorderpointgoods,
  scheduledrugs,
  nontaxable,
  noncategory,
  nonsku,
}

// Small wrapper so we can give filters nice labels
class ItemsFilterOption {
  final ItemsFilter value;
  final String label;

  const ItemsFilterOption(this.value, this.label);

  @override
  String toString() => label;
}

// You can extend/rename labels later – all logic is in the enum above
const List<ItemsFilterOption> kItemsFilterOptions = [
  ItemsFilterOption(ItemsFilter.all, 'All Items'),
  ItemsFilterOption(ItemsFilter.service, 'Service Items'),
  ItemsFilterOption(ItemsFilter.composite, 'Composite Items'),
  ItemsFilterOption(ItemsFilter.active, 'Active Items'),
  ItemsFilterOption(ItemsFilter.inactive, 'Inactive Items'),
  ItemsFilterOption(ItemsFilter.returnable, 'Returnable Items'),
  ItemsFilterOption(ItemsFilter.nonreturnable, 'Non-returnable Items'),
  ItemsFilterOption(ItemsFilter.temperature, 'Temperature-controlled Items'),
  ItemsFilterOption(ItemsFilter.nontemperature, 'Non-Temperature Items'),
  ItemsFilterOption(ItemsFilter.sales, 'Sales Items'),
  ItemsFilterOption(ItemsFilter.purchase, 'Purchase Items'),
  ItemsFilterOption(ItemsFilter.inventory, 'Inventory Items'),
  ItemsFilterOption(ItemsFilter.noninventory, 'Non-Inventory Items'),
  ItemsFilterOption(ItemsFilter.batch, 'Batch-tracked Items'),
  ItemsFilterOption(ItemsFilter.nonbatch, 'Non-Batch Items'),
  ItemsFilterOption(ItemsFilter.lowstock, 'Low-Stock Items'),
  ItemsFilterOption(ItemsFilter.belowreorderpoint, 'Below Reorder Point'),
  ItemsFilterOption(ItemsFilter.abovereorderpoint, 'Above Reorder Point'),
  ItemsFilterOption(ItemsFilter.nonrackgoods, 'Non-Rack Goods'),
  ItemsFilterOption(ItemsFilter.nonreorderpointgoods, 'No Reorder Point'),
  ItemsFilterOption(ItemsFilter.scheduledrugs, 'Scheduled Drugs'),
  ItemsFilterOption(ItemsFilter.nontaxable, 'Non-Taxable Items'),
  ItemsFilterOption(ItemsFilter.noncategory, 'Items Without Category'),
  ItemsFilterOption(ItemsFilter.nonsku, 'Items Without SKU'),
];
