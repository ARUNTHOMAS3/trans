import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/items/composite_items/providers/items_composite_item_provider.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'items_composite_filters.dart';
import 'items_composite_filter_dropdown.dart';

class CompositeItemsListScreen extends ConsumerStatefulWidget {
  final String? initialItemId;
  const CompositeItemsListScreen({super.key, this.initialItemId});

  @override
  ConsumerState<CompositeItemsListScreen> createState() =>
      _CompositeItemsListScreenState();
}

class _CompositeItemsListScreenState
    extends ConsumerState<CompositeItemsListScreen> {
  CompositeItemsFilter _selectedView = CompositeItemsFilter.all;
  final Set<String> _selectedIds = {};

  void _toggleSelectAll(List<CompositeItem> items, bool checked) {
    setState(() {
      if (checked) {
        _selectedIds.addAll(items.map((e) => e.id ?? ''));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final compositeItems = ref.watch(compositeItemsProvider);
    final itemsState = ref.watch(itemsControllerProvider);

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useTopPadding: false,
      useHorizontalPadding: false,
      child: compositeItems.when(
        loading: () => const SizedBox.shrink(),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          final filteredItems = items.where((item) {
            switch (_selectedView) {
              case CompositeItemsFilter.active:
                return item.isActive;
              case CompositeItemsFilter.inactive:
                return !item.isActive;
              case CompositeItemsFilter.lowStock:
                return false;
              case CompositeItemsFilter.assembly:
                return item.type.toLowerCase() == 'assembly';
              case CompositeItemsFilter.kit:
                return item.type.toLowerCase() == 'kit';
              case CompositeItemsFilter.all:
                return true;
            }
          }).toList();

          final categoryMap = {
            for (var c in itemsState.categories) c['id']: c['name'],
          };
          final manufacturerMap = {
            for (var m in itemsState.manufacturers) m['id']: m['name'],
          };
          final brandMap = {
            for (var b in itemsState.brands) b['id']: b['name'],
          };

          final allSelected =
              filteredItems.isNotEmpty &&
              filteredItems.every((item) => _selectedIds.contains(item.id));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_selectedIds.isEmpty)
                _buildViewSelector(context)
              else
                _buildBulkActionsToolbar(),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              _buildTableHeader(allSelected, filteredItems),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No composite items found for ${_selectedView.name}',
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _CompositeItemRow(
                            item: item,
                            categoryName: categoryMap[item.categoryId] ?? '-',
                            manufacturerName:
                                manufacturerMap[item.manufacturerId] ?? '-',
                            brandName: brandMap[item.brandId] ?? '-',
                            isSelected: _selectedIds.contains(item.id),
                            onSelectionChanged: (v) =>
                                _toggleSelection(item.id ?? ''),
                          );
                        },
                      ),
              ),
              _buildTableFooter(filteredItems.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBulkActionsToolbar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _BulkButton(
            label: 'Mark as Active',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final count = await ref
                  .read(itemsControllerProvider.notifier)
                  .updateCompositeItemsBulk(_selectedIds, {'is_active': true});

              if (!mounted) return;

              if (count > 0) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('$count items marked as active'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() => _selectedIds.clear());
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update items'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          _BulkButton(
            label: 'Mark as Inactive',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final count = await ref
                  .read(itemsControllerProvider.notifier)
                  .updateCompositeItemsBulk(_selectedIds, {'is_active': false});

              if (!mounted) return;

              if (count > 0) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('$count items marked as inactive'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() => _selectedIds.clear());
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update items'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          _BulkButton(
            label: 'Mark as Returnable',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final count = await ref
                  .read(itemsControllerProvider.notifier)
                  .updateCompositeItemsBulk(_selectedIds, {
                    'is_returnable': true,
                  });

              if (!mounted) return;

              if (count > 0) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('$count items marked as returnable'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() => _selectedIds.clear());
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update items'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          _BulkButton(
            label: 'Enable Bin location',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final count = await ref
                  .read(itemsControllerProvider.notifier)
                  .updateCompositeItemsBulk(_selectedIds, {
                    'track_bin_location': true,
                  });

              if (!mounted) return;

              if (count > 0) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Bin location enabled for $count items'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() => _selectedIds.clear());
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update items'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          _BulkButton(
            label: 'Disable Bin location',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final count = await ref
                  .read(itemsControllerProvider.notifier)
                  .updateCompositeItemsBulk(_selectedIds, {
                    'track_bin_location': false,
                  });

              if (!mounted) return;

              if (count > 0) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Bin location disabled for $count items'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() => _selectedIds.clear());
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update items'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'More Actions',
            offset: const Offset(0, 40),
            padding: EdgeInsets.zero,
            onSelected: (value) async {
              if (value == 'delete') {
                final messenger = ScaffoldMessenger.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete'),
                    content: Text(
                      'Are you sure you want to delete ${_selectedIds.length} items?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final count = await ref
                      .read(itemsControllerProvider.notifier)
                      .deleteCompositeItemsBulk(_selectedIds);

                  if (!mounted) return;

                  if (count > 0) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('$count items deleted'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    setState(() => _selectedIds.clear());
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete items'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'delete',
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.more_horiz,
                size: 18,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_selectedIds.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selectedIds.clear()),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            label: const Text(
              'Esc',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildViewSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          CompositeItemsFilterDropdown(
            currentFilter: _selectedView,
            onFilterChanged: (filter) {
              setState(() => _selectedView = filter);
            },
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.compositeItemsCreate),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, color: Color(0xFF6B7280)),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(
    bool allSelected,
    List<CompositeItem> filteredItems,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 16, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: allSelected,
              onChanged: (v) => _toggleSelectAll(filteredItems, v ?? false),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          _HeaderCell(label: 'NAME', flex: 3, showSort: true),
          _HeaderCell(label: 'COMPOSITION TYPE', flex: 2),
          _HeaderCell(label: 'SKU', flex: 2),
          _HeaderCell(
            label: 'REORDER LEVEL',
            flex: 2,
            alignment: Alignment.centerRight,
          ),
          _HeaderCell(label: 'CATEGORY', flex: 2),
          _HeaderCell(label: 'MANUFACTURER', flex: 2),
          _HeaderCell(label: 'BRAND', flex: 2),
          const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  Widget _buildTableFooter(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Text(
            'Total Count: ',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'View',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.settings_outlined,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                const Text(
                  '10 per page',
                  style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            children: [
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              const Text(
                '1 - 10',
                style: TextStyle(fontSize: 12, color: Color(0xFF374151)),
              ),
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BulkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool showSort;
  final Alignment alignment;

  const _HeaderCell({
    required this.label,
    required this.flex,
    this.showSort = false,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showSort) ...[
              const SizedBox(width: 4),
              const Icon(Icons.unfold_more, size: 14, color: Color(0xFF9CA3AF)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CompositeItemRow extends StatefulWidget {
  final CompositeItem item;
  final String categoryName;
  final String manufacturerName;
  final String brandName;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const _CompositeItemRow({
    required this.item,
    required this.categoryName,
    required this.manufacturerName,
    required this.brandName,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  State<_CompositeItemRow> createState() => _CompositeItemRowState();
}

class _CompositeItemRowState extends State<_CompositeItemRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasParts = widget.item.parts?.isNotEmpty == true;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              const SizedBox(width: 24),
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: widget.isSelected,
                  onChanged: widget.onSelectionChanged,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: hasParts
                    ? () => setState(() => _isExpanded = !_isExpanded)
                    : null,
                child: Icon(
                  _isExpanded
                      ? Icons.folder_open_outlined
                      : Icons.folder_outlined,
                  size: 18,
                  color: widget.item.isActive
                      ? const Color(0xFF3B82F6)
                      : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: InkWell(
                    onTap: () {
                      context.push(
                        AppRoutes.compositeItemsDetail.replaceAll(
                          ':id',
                          widget.item.id ?? '',
                        ),
                      );
                    },
                    child: Text(
                      widget.item.productName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.item.isActive
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.item.type.capitalize(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.item.sku ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.item.reorderPoint > 0
                        ? widget.item.reorderPoint.toStringAsFixed(2)
                        : '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.categoryName == '-' ? '' : widget.categoryName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.manufacturerName == '-'
                        ? ''
                        : widget.manufacturerName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    widget.brandName == '-' ? '' : widget.brandName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
        if (_isExpanded && hasParts)
          Padding(
            padding: const EdgeInsets.only(left: 64), // Align with folder icon
            child: Column(
              children: [
                for (int i = 0; i < (widget.item.parts?.length ?? 0); i++)
                  _buildPartRow(
                    widget.item.parts![i],
                    i == (widget.item.parts?.length ?? 0) - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPartRow(CompositePart part, bool isLast) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Stack(
              children: [
                Positioned(
                  left: 9,
                  top: 0,
                  bottom: isLast ? 22 : 0,
                  child: Container(width: 1, color: const Color(0xFFE5E7EB)),
                ),
                Positioned(
                  left: 9,
                  top: 22,
                  child: Container(
                    width: 16,
                    height: 1,
                    color: const Color(0xFFE5E7EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                children: [
                  TextSpan(
                    text: (part.product?.productName ?? "Unknown Part")
                        .toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' ( ${part.quantity.toStringAsFixed(0)} pcs )',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (part.product?.sku != null ||
                      part.product?.itemCode != null)
                    TextSpan(
                      text:
                          ' | SKU : ${part.product?.sku ?? part.product?.itemCode}',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
