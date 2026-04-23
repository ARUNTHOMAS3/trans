enum CompositeItemsFilter { all, active, lowStock, inactive, assembly, kit }

class CompositeItemsFilterOption {
  final CompositeItemsFilter value;
  final String label;

  const CompositeItemsFilterOption(this.value, this.label);

  @override
  String toString() => label;
}

const List<CompositeItemsFilterOption> kCompositeItemsFilterOptions = [
  CompositeItemsFilterOption(CompositeItemsFilter.all, 'All Composite Items'),
  CompositeItemsFilterOption(CompositeItemsFilter.active, 'Active Items'),
  CompositeItemsFilterOption(CompositeItemsFilter.lowStock, 'Low Stock Items'),
  CompositeItemsFilterOption(CompositeItemsFilter.inactive, 'Inactive Items'),
  CompositeItemsFilterOption(CompositeItemsFilter.assembly, 'Assembly'),
  CompositeItemsFilterOption(CompositeItemsFilter.kit, 'Kit'),
];
