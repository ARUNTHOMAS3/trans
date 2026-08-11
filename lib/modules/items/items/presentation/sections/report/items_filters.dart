// FILE: lib/modules/items/presentation/items_filters.dart

// -----------------------------------------------------------
// ITEMS FILTER ENUM + OPTIONS
// -----------------------------------------------------------

enum ItemsFilter {
  all,
  active,
  inactive,
  service,
  noninventory,
  unconfirmed,
  marketplace,
  serialized,
  batch,
  bintracked,
  returnable,
  nonreturnable,
  nonsku,
  noncategory,
  composite,
  temperature,
  nontemperature,
  sales,
  purchase,
  inventory,
  nonbatch,
  lowstock,
  belowreorderpoint,
  abovereorderpoint,
  nonrackgoods,
  nonreorderpointgoods,
  scheduledrugs,
  nontaxable,
}

// Small wrapper so we can give filters nice labels
class ItemsFilterOption {
  final ItemsFilter value;
  final String label;

  const ItemsFilterOption(this.value, this.label);

  @override
  String toString() => label;
}

// Dropdown options matching screenshots 1, 2, 3
const List<ItemsFilterOption> kItemsFilterOptions = [
  ItemsFilterOption(ItemsFilter.all, 'All Items'),
  ItemsFilterOption(ItemsFilter.active, 'Active Items'),
  ItemsFilterOption(ItemsFilter.inactive, 'Ungrouped Items'),
  ItemsFilterOption(ItemsFilter.service, 'Services'),
  ItemsFilterOption(ItemsFilter.noninventory, 'Non-Inventory Items'),
  ItemsFilterOption(ItemsFilter.unconfirmed, 'Unconfirmed Items'),
  ItemsFilterOption(ItemsFilter.marketplace, 'Marketplace Items'),
  ItemsFilterOption(ItemsFilter.serialized, 'Serialized Items'),
  ItemsFilterOption(ItemsFilter.batch, 'Batch Tracked Items'),
  ItemsFilterOption(ItemsFilter.bintracked, 'Bin Tracked Items'),
  ItemsFilterOption(ItemsFilter.returnable, 'Returnable Items'),
  ItemsFilterOption(ItemsFilter.nonreturnable, 'Non Returnable Items'),
  ItemsFilterOption(ItemsFilter.nonsku, 'Non SKU Items'),
  ItemsFilterOption(ItemsFilter.noncategory, 'Uncategorized Items'),
];
