import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

import '../../models/stock_count_model.dart';
import '../../providers/stock_count_provider.dart';

class StockCountPerformPage extends ConsumerStatefulWidget {
  final String countId;
  const StockCountPerformPage({super.key, required this.countId});

  @override
  ConsumerState<StockCountPerformPage> createState() =>
      _StockCountPerformPageState();
}

class _StockCountPerformPageState extends ConsumerState<StockCountPerformPage> {
  bool _isInitialized = false;
  late StockCount _currentCount;
  List<Map<String, dynamic>> _items = [];
  final Map<String, Set<String>> _binProductIdsByDivision = {};
  final Map<String, String> _binLabelsByDivision = {};
  final Map<String, double> _binStockQtyByDivisionProduct = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _activeTab = 0; // 0 = Uncounted Items, 1 = All Items
  final Map<String, TextEditingController> _countedQtyControllers = {};
  final Set<String> _initiallyUncountedItemNames = {};
  bool _showSearch = false;
  bool _isSearchFieldHovered = false;
  bool _isBinSearchFieldHovered = false;
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _binSearchFocusNode = FocusNode();

  // Divisions / Bins state
  String? _selectedDivision;
  int _activeBinTab = 0; // 0 = Uncounted Bins, 1 = All Bins
  final TextEditingController _binSearchController = TextEditingController();
  String _binSearchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _binSearchController.dispose();
    _searchFocusNode.dispose();
    _binSearchFocusNode.dispose();
    for (var c in _countedQtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _buildCountingSearchField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String currentQuery,
    required VoidCallback onClear,
    required FocusNode focusNode,
    required bool isHovered,
    required ValueChanged<bool> onHoverChanged,
  }) {
    return MouseRegion(
      onEnter: (_) => onHoverChanged(true),
      onExit: (_) => onHoverChanged(false),
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, _) {
          final isActive = isHovered || focusNode.hasFocus;
          return Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isActive
                    ? const Color(0xFF8BB8FF)
                    : const Color(0xFFD1D5DB),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    LucideIcons.search,
                    size: 15,
                    color: isActive
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                Expanded(
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      decoration: const InputDecoration(
                        hintText: 'Type to search.',
                        hintStyle: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 9),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
                if (currentQuery.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        LucideIcons.x,
                        size: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _initializeData(StockCount count) {
    _currentCount = count;
    _items = count.items.map((it) => Map<String, dynamic>.from(it)).toList();


    // Ensure unit field exists (box vs other units)
    for (var it in _items) {
      if (it['unit'] == null) {
        if (it['name'].toString().toLowerCase().contains('dolo')) {
          it['unit'] = 'box';
        } else {
          it['unit'] = 'pcs';
        }
      }
    }
    // Ensure track_batches field exists
    for (var it in _items) {
      if (it['track_batches'] == null) {
        final nameLower = it['name'].toString().toLowerCase();
        if (nameLower.contains('demo') || nameLower.contains('dolo')) {
          it['track_batches'] = false;
        } else {
          it['track_batches'] = true;
        }
      }
    }
    // Populate initially uncounted items list for tab stability
    _initiallyUncountedItemNames.clear();
    for (var it in _items) {
      if (it['countedQty'] == null) {
        _initiallyUncountedItemNames.add(it['name'] as String);
      }
    }
    // Initialize text controllers for non-batch tracked items
    for (var it in _items) {
      final name = it['name'] as String;
      final countedQty = it['countedQty'];
      _countedQtyControllers[name] = TextEditingController(
        text: countedQty != null ? countedQty.toString() : '',
      );
    }
    _loadBinDivisions();
    _isInitialized = true;
  }

  Future<void> _loadBinDivisions() async {
    final warehouseId = _currentCount.warehouseId?.trim();
    final trackedProductIds = _items
        .where((it) => (it['track_bin_location'] as bool? ?? false) == true)
        .map((it) => it['product_id']?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (warehouseId == null ||
        warehouseId.isEmpty ||
        trackedProductIds.isEmpty) {
      if (!mounted) return;
      setState(() {
        _binProductIdsByDivision.clear();
        _binLabelsByDivision.clear();
        _binStockQtyByDivisionProduct.clear();
      });
      return;
    }

    try {
      final client = Supabase.instance.client;
      final rows = await client
          .from('batch_stock_layers')
          .select('product_id, bin_id, bin_master(bin_code)')
          .eq('warehouse_id', warehouseId)
          .inFilter('product_id', trackedProductIds);
      final stockRows = await client
          .from('v_bin_wise_stock')
          .select('product_id, bin_id, stock_on_hand')
          .eq('warehouse_id', warehouseId)
          .inFilter('product_id', trackedProductIds);

      final productIdsByDivision = <String, Set<String>>{};
      final labelsByDivision = <String, String>{};
      final stockQtyByDivisionProduct = <String, double>{};

      for (final raw in rows as List<dynamic>) {
        final row = Map<String, dynamic>.from(raw as Map);
        final productId = row['product_id']?.toString().trim() ?? '';
        final binId = row['bin_id']?.toString().trim() ?? '';
        if (productId.isEmpty || binId.isEmpty) {
          continue;
        }

        final binData = row['bin_master'] as Map<String, dynamic>?;
        final binCode = (binData?['bin_code'] ?? '').toString().trim();
        final divisionKey = 'bin::$binId';
        productIdsByDivision.putIfAbsent(divisionKey, () => <String>{}).add(
          productId,
        );
        labelsByDivision[divisionKey] =
            binCode.isNotEmpty ? binCode : 'Unnamed Bin';
      }

      for (final raw in stockRows as List<dynamic>) {
        final row = Map<String, dynamic>.from(raw as Map);
        final productId = row['product_id']?.toString().trim() ?? '';
        final binId = row['bin_id']?.toString().trim() ?? '';
        if (productId.isEmpty || binId.isEmpty) {
          continue;
        }

        final divisionKey = 'bin::$binId';
        final stockOnHand =
            double.tryParse(row['stock_on_hand']?.toString() ?? '') ?? 0.0;
        stockQtyByDivisionProduct['$divisionKey::$productId'] = stockOnHand;
      }

      if (!mounted) return;
      setState(() {
        _binProductIdsByDivision
          ..clear()
          ..addAll(productIdsByDivision);
        _binLabelsByDivision
          ..clear()
          ..addAll(labelsByDivision);
        _binStockQtyByDivisionProduct
          ..clear()
          ..addAll(stockQtyByDivisionProduct);
      });
    } catch (e) {
      debugPrint('Error loading bin divisions: $e');
    }
  }

  String? _divisionBinId(String? divisionKey) {
    if (divisionKey == null || !divisionKey.startsWith('bin::')) {
      return null;
    }
    return divisionKey.substring('bin::'.length);
  }

  double? _countedQtyForDivision(
    Map<String, dynamic> item,
    String? divisionKey,
  ) {
    final countedQtyValue = item['countedQty'] as num?;
    final batches = (item['batches'] as List? ?? const [])
        .whereType<Map>()
        .map((batch) => Map<String, dynamic>.from(batch))
        .toList();
    if (batches.isEmpty) {
      return countedQtyValue?.toDouble();
    }

    final binId = _divisionBinId(divisionKey);
    if (binId == null) {
      return countedQtyValue?.toDouble();
    }

    double total = 0;
    bool found = false;
    for (final batch in batches) {
      final batchBinId = batch['bin_id']?.toString().trim() ?? '';
      if (batchBinId != binId) {
        continue;
      }
      total += (batch['qty'] as num? ?? 0).toDouble();
      found = true;
    }
    return found ? total : null;
  }

  Map<String, dynamic> _buildDivisionDisplayItem(
    Map<String, dynamic> item,
    String? divisionKey,
  ) {
    if (divisionKey == null || divisionKey == 'Non-Bin tracked Items') {
      return item;
    }

    final productId = item['product_id']?.toString().trim() ?? '';
    final binSystemQty =
        _binStockQtyByDivisionProduct['$divisionKey::$productId'] ??
        (item['systemQty'] as num? ?? 0).toDouble();
    final divisionCountedQty = _countedQtyForDivision(item, divisionKey);

    return {
      ...item,
      'systemQty': binSystemQty,
      'countedQty': divisionCountedQty,
    };
  }

  void _saveDraft() {
    final updatedCount = _currentCount.copyWith(
      items: _items,
      status: StockCountStatus.inProgress,
    );
    ref.read(stockCountsProvider.notifier).updateCount(updatedCount);
    setState(() {
      _selectedDivision = null;
      _searchController.clear();
      _searchQuery = '';
      _binSearchController.clear();
      _binSearchQuery = '';
      _showSearch = false;
      
      // Refresh the uncounted items snapshot so saved items now leave the list
      _initiallyUncountedItemNames.clear();
      for (var it in _items) {
        if (it['countedQty'] == null) {
          _initiallyUncountedItemNames.add(it['name'] as String);
        }
      }
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Draft saved successfully.')));
  }

  void _submitForApprovalDirect() {
    final updatedCount = _currentCount.copyWith(
      items: _items,
      status: StockCountStatus.pendingApproval,
    );
    ref.read(stockCountsProvider.notifier).updateCount(updatedCount);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock count submitted for approval.')),
    );
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    context.go(
      '/$orgId${AppRoutes.stockCountsDetail.replaceAll(':id', _currentCount.id)}',
    );
  }

  void _submitUncountedAsZero() {
    setState(() {
      for (var it in _items) {
        if (it['countedQty'] == null) {
          it['countedQty'] = 0.0;
        }
      }
    });
    _submitForApprovalDirect();
  }

  void _submitForApproval() {
    final hasUncounted = _items.any((it) => it['countedQty'] == null);
    if (hasUncounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            alignment: Alignment.topCenter,
            insetPadding: const EdgeInsets.only(top: 0),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Uncounted Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Icon(
                            LucideIcons.x,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Some items in your stock count are uncounted. Do you want to mark them with a quantity of zero and submit?',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Warning banner
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.info,
                                size: 14,
                                color: Color(0xFFEA580C),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9A3412),
                                      height: 1.4,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'NOTE: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: "Once you submit this stock count, you'll not be able to edit it.",
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Actions
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6DCBA6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Resume Counting',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _submitUncountedAsZero();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'Mark Uncounted as Zero & Submit',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      _submitForApprovalDirect();
    }
  }

  void _openAddBatchesDialog(int index) async {
    final item = _items[index];
    final currentBatches = List<Map<String, dynamic>>.from(
      item['batches'] ?? [],
    );
    final selectedBinId = _divisionBinId(_selectedDivision);
    final selectedBinCode =
        selectedBinId == null ? null : _binLabelsByDivision[_selectedDivision!];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return _AddBatchesDialog(
          itemName: item['name'],
          productId: item['product_id']?.toString(),
          warehouseId: _currentCount.warehouseId,
          initialBatches: currentBatches,
          trackBinLocation: item['track_bin_location'] as bool? ?? false,
          selectedBinId: selectedBinId,
          selectedBinCode: selectedBinCode,
          systemQty: (item['systemQty'] as num? ?? 0).toInt(),
          locationName:
              _currentCount.location ?? 'ZABNIX PRIVATE LIMITED',
          initialMarkZero: item['countedQty'] == 0.0,
        );
      },
    );

    if (result != null) {
      setState(() {
        final batches = result['batches'] as List<Map<String, dynamic>>;
        final markZero = result['markZero'] as bool;
        final hasInvalidBatch = result['hasInvalidBatch'] as bool? ?? false;
        double totalCounted = 0;
        for (var b in batches) {
          totalCounted += (b['qty'] as num? ?? 0).toDouble();
        }
        _items[index]['batches'] = batches;
        _items[index]['hasInvalidBatch'] = hasInvalidBatch;
        if (markZero) {
          _items[index]['countedQty'] = 0.0;
        } else {
          _items[index]['countedQty'] = batches.isEmpty ? null : totalCounted;
        }
      });
    }
  }

  Widget _buildCountedQtyInput(int globalIndex, Map<String, dynamic> item) {
    final name = item['name'] as String;
    if (!_countedQtyControllers.containsKey(name)) {
      final countedQty = item['countedQty'];
      _countedQtyControllers[name] = TextEditingController(
        text: countedQty != null ? countedQty.toString() : '',
      );
    }
    final controller = _countedQtyControllers[name]!;

    return SizedBox(
      width: 120,
      height: 36,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937)),
        onChanged: (val) {
          setState(() {
            final parsed = double.tryParse(val);
            _items[globalIndex]['countedQty'] = parsed;
          });
        },
        decoration: InputDecoration(
          hintText: 'Enter Qty',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFF2563EB)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final countsState = ref.watch(stockCountsProvider);
    final count = countsState.counts.firstWhere(
      (c) => c.id == widget.countId || c.stockCountNum == widget.countId,
      orElse: () => StockCount(
        id: widget.countId,
        stockCountNum: widget.countId.startsWith('D') ? widget.countId : 'D46',
        assignedTo: 'zabnixprivatelimited',
        status: StockCountStatus.yetToStart,
        countDate: DateTime.now(),
        totalItems: 6,
      ),
    );

    if (!_isInitialized) {
      _initializeData(count);
    }

    // Bins division lists
    final nonBinTracked = _items
        .where((it) => (it['track_bin_location'] as bool? ?? false) == false)
        .toList();
    final trackedBinItems = _items
        .where((it) => (it['track_bin_location'] as bool? ?? false) == true)
        .toList();
    final binDivisionEntries = _binProductIdsByDivision.entries
        .map((entry) {
          final divisionItems = trackedBinItems
              .where((item) {
                final productId = item['product_id']?.toString().trim() ?? '';
                return entry.value.contains(productId);
              })
              .map((item) => _buildDivisionDisplayItem(item, entry.key))
              .toList();
          return MapEntry(entry.key, divisionItems);
        })
        .where((entry) => entry.value.isNotEmpty)
        .toList()
      ..sort((a, b) {
        final aLabel = _binLabelsByDivision[a.key] ?? a.key;
        final bLabel = _binLabelsByDivision[b.key] ?? b.key;
        return aLabel.compareTo(bLabel);
      });

    final nonBinUncounted = nonBinTracked
        .where((it) => it['countedQty'] == null)
        .length;
    final binUncountedCounts = <String, int>{
      for (final entry in binDivisionEntries)
        entry.key: entry.value.where((it) => it['countedQty'] == null).length,
    };

    // Filter divisions by search query
    final binSearch = _binSearchQuery.toLowerCase().trim();
    bool showNonBin = true;
    final visibleBinKeys = <String>{};
    if (binSearch.isNotEmpty) {
      showNonBin =
          'non-bin tracked items'.contains(binSearch) ||
          nonBinTracked.any(
            (it) => (it['name'] as String).toLowerCase().contains(binSearch),
          );
      for (final entry in binDivisionEntries) {
        final label =
            (_binLabelsByDivision[entry.key] ?? entry.key).toLowerCase();
        final matches = label.contains(binSearch) ||
            entry.value.any(
              (it) => (it['name'] as String).toLowerCase().contains(binSearch),
            );
        if (matches) {
          visibleBinKeys.add(entry.key);
        }
      }
    } else {
      visibleBinKeys.addAll(binDivisionEntries.map((entry) => entry.key));
    }

    // Filter divisions by tab (Uncounted Bins)
    if (_activeBinTab == 0) {
      if (nonBinUncounted == 0) showNonBin = false;
      visibleBinKeys.removeWhere(
        (key) => (binUncountedCounts[key] ?? 0) == 0,
      );
    }

    final uncountedBinsCount =
        (nonBinUncounted > 0 ? 1 : 0) +
        binUncountedCounts.values.where((count) => count > 0).length;
    final allBinsCount =
        (nonBinTracked.isNotEmpty ? 1 : 0) + binDivisionEntries.length;

    // First item name in nonBinTracked for "demo composit item 1, + 1 Items" style
    final nonBinFirstItemName = nonBinTracked.isNotEmpty
        ? nonBinTracked[0]['name']
        : '';
    final nonBinRemainingCount = nonBinTracked.length - 1;

    // If a division is selected, we filter the items table to only show that division's items
    List<Map<String, dynamic>> divisionItems = _items;
    if (_selectedDivision != null) {
      if (_selectedDivision == 'Non-Bin tracked Items') {
        divisionItems = nonBinTracked;
      } else {
        divisionItems =
            binDivisionEntries
                .firstWhere(
                  (entry) => entry.key == _selectedDivision,
                  orElse: () => const MapEntry('', <Map<String, dynamic>>[]),
                )
                .value;
      }
    }
    final selectedDivisionLabel =
        _selectedDivision == null
            ? null
            : (_selectedDivision == 'Non-Bin tracked Items'
                  ? _selectedDivision
                  : _binLabelsByDivision[_selectedDivision!] ??
                      _selectedDivision);

    // Filter logic on divisionItems (by search query)
    final query = _searchQuery.toLowerCase().trim();
    List<Map<String, dynamic>> filteredItems = divisionItems.where((it) {
      final name = (it['name'] as String? ?? '').toLowerCase();
      return name.contains(query);
    }).toList();

    // Tab split: Uncounted = initially uncounted items; All = everything
    final uncountedList = filteredItems
        .where((it) => _initiallyUncountedItemNames.contains(it['name'] as String))
        .toList();
    final allList = filteredItems;

    final displayedList = _activeTab == 0 ? uncountedList : allList;

    // Totals for tab headers based on ALL filtered items (before active tab split)
    final uncountedTotalCount = divisionItems
        .where((it) => it['countedQty'] == null)
        .length;
    final allTotalCount = divisionItems.length;

    return ZerpaiLayout(
      pageTitle: '',
      useTopPadding: false,
      useHorizontalPadding: false,
      enableBodyScroll: true,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Location and title row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: _selectedDivision != null ? 40 : 0,
                          ),
                          child: Text(
                            _selectedDivision != null
                                ? 'From Stock Count: ${count.stockCountNum}'
                                : 'Location: ZABNIX PRIVATE LIMITED',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (_selectedDivision != null) ...[
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDivision = null;
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    LucideIcons.chevronLeft,
                                    size: 18,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _selectedDivision != null
                                  ? selectedDivisionLabel!
                                  : 'Stock Count# ${count.stockCountNum}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) {
                              if (_selectedDivision == null) {
                                _binSearchController.clear();
                                _binSearchQuery = '';
                              } else {
                                _searchController.clear();
                                _searchQuery = '';
                              }
                            }
                          });
                        },
                        child: Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            LucideIcons.filter,
                            size: 16,
                            color: _showSearch
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selectedDivision != null) ...[
                        OutlinedButton(
                          onPressed: _saveDraft,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF22B378),
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF22B378)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            'Save as Draft',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (_selectedDivision == null) ...[
                        ElevatedButton(
                          onPressed: _submitForApproval,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22B378),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            'Submit for Approval',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: Color(0xFF4B5563),
                        ),
                        onPressed: () => context.go(
                          '/$orgId${AppRoutes.stockCountsDetail.replaceAll(':id', count.id)}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Toggle rendering between Divisions list and Items table
            if (_selectedDivision == null) ...[
              // Bins / Divisions List view (the screenshot view)
              if (_showSearch) ...[
                Container(
                  color: const Color(0xFFF9F9FB),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      // Search input
                      SizedBox(
                        width: 500,
                        child: _buildCountingSearchField(
                          controller: _binSearchController,
                          onChanged: (val) {
                            setState(() {
                              _binSearchQuery = val;
                            });
                          },
                          currentQuery: _binSearchQuery,
                          onClear: () {
                            setState(() {
                              _binSearchController.clear();
                              _binSearchQuery = '';
                            });
                          },
                          focusNode: _binSearchFocusNode,
                          isHovered: _isBinSearchFieldHovered,
                          onHoverChanged: (value) {
                            setState(() {
                              _isBinSearchFieldHovered = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _binSearchQuery = _binSearchController.text;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6DCBA6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _binSearchController.clear();
                            _binSearchQuery = '';
                            _showSearch = false;
                          });
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF9CA3AF)),
                            color: const Color(0xFFF3F4F6),
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            size: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Bins Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildBinTab('Uncounted Bins ($uncountedBinsCount)', 0),
                    const SizedBox(width: 16),
                    _buildBinTab('All Bins ($allBinsCount)', 1),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
              const SizedBox(height: 16),

              // Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (showNonBin && nonBinTracked.isNotEmpty) ...[
                      _buildBinCard(
                        titleWidget: _buildDivisionTag('Non-Bin tracked Items'),
                        descriptionText: nonBinRemainingCount > 0
                            ? '$nonBinFirstItemName, + $nonBinRemainingCount Items'
                            : nonBinFirstItemName,
                        subtext:
                            '$nonBinUncounted/${nonBinTracked.length} Items Uncounted',
                        onTap: () {
                          setState(() {
                            _selectedDivision = 'Non-Bin tracked Items';
                            _activeTab = 0; // default to uncounted
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    for (final entry in binDivisionEntries)
                      if (visibleBinKeys.contains(entry.key)) ...[
                        _buildBinCard(
                          titleWidget: Text(
                            _binLabelsByDivision[entry.key] ?? 'Unnamed Bin',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          descriptionText: '',
                          subtext:
                              '${binUncountedCounts[entry.key] ?? 0}/${entry.value.length} Items Uncounted',
                          onTap: () {
                            setState(() {
                              _selectedDivision = entry.key;
                              _activeTab = 0; // default to uncounted
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    if (!showNonBin && visibleBinKeys.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No bins found matching search criteria.',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // Search row — shown only when filter icon is active
              if (_showSearch)
                Stack(
                  children: [
                    Container(
                      color: const Color(0xFFF9F9FB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          // Search input
                          SizedBox(
                            width: 500,
                            child: _buildCountingSearchField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              currentQuery: _searchQuery,
                              onClear: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                              focusNode: _searchFocusNode,
                              isHovered: _isSearchFieldHovered,
                              onHoverChanged: (value) {
                                setState(() {
                                  _isSearchFieldHovered = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Apply button
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = _searchController.text;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6DCBA6),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          // Spacer pushes dismiss X to far right
                          const Spacer(),
                          // Dismiss / close button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _showSearch = false;
                              });
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF9CA3AF),
                                ),
                                color: const Color(0xFFF3F4F6),
                              ),
                              child: const Icon(
                                LucideIcons.x,
                                size: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildTab('Uncounted Items ($uncountedTotalCount)', 0),
                    const SizedBox(width: 16),
                    _buildTab('All Items ($allTotalCount)', 1),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Divider(height: 1, color: Color(0xFFE5E7EB)),
              ),
              const SizedBox(height: 16),

              // Table Container
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFEEEFF1),
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Table Header
                    Container(
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            const Expanded(
                              flex: 3,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'ITEM DETAILS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 0.5,
                              color: const Color(0xFFDEE0E4),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'SYSTEM QUANTITY',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4B5563),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    ZTooltip(
                                      message:
                                          'System Quantity is the physical stock in Zoho Inventory that is available in hand when the stock count is initiated.',
                                      child: const Icon(
                                        LucideIcons.helpCircle,
                                        size: 14,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 0.5,
                              color: const Color(0xFFDEE0E4),
                            ),
                            const Expanded(
                              flex: 3,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'COUNTED SERIALS/BATCHES',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 0.5,
                              color: const Color(0xFFDEE0E4),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'COUNTED QTY',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 0.5,
                              color: const Color(0xFFDEE0E4),
                            ),
                            const Expanded(
                              flex: 2,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'DIFFERENCE',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: const Color(0xFFDEE0E4),
                    ),

                    // Table Body
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayedList.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 0.5,
                        thickness: 0.5,
                        color: Color(0xFFDEE0E4),
                      ),
                      itemBuilder: (context, index) {
                        final item = displayedList[index];
                        final systemQty = (item['systemQty'] as num? ?? 0)
                            .toInt();
                        final countedQty = (item['countedQty'] as num?)
                            ?.toDouble();
                        final difference = countedQty != null
                            ? (countedQty - systemQty)
                            : null;
                        final globalIndex = _items.indexWhere(
                          (it) => it['name'] == item['name'],
                        );

                        return IntrinsicHeight(
                          child: Row(
                            children: [
                              // Item details
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F4F6),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.image,
                                          size: 18,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 0.5,
                                color: const Color(0xFFDEE0E4),
                              ),
                              // System qty
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$systemQty',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const Text(
                                        'pcs',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: 0.5,
                                color: const Color(0xFFDEE0E4),
                              ),
                              // Counted serials/batches link
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: (item['track_batches'] as bool? ?? true)
                                        ? InkWell(
                                            onTap: () =>
                                                _openAddBatchesDialog(globalIndex),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  (item['batches'] as List? ?? [])
                                                          .isEmpty
                                                      ? '+ Add Batches'
                                                      : '${(item['batches'] as List? ?? []).length} Batches',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF2563EB),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if ((item['batches'] as List? ?? [])
                                                    .isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(
                                                    LucideIcons.pencil,
                                                    size: 13,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          )
                                        : const Text(
                                            '-',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 0.5,
                                color: const Color(0xFFDEE0E4),
                              ),
                              // Counted qty
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: (item['track_batches'] as bool? ?? true)
                                      ? Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              countedQty != null
                                                  ? countedQty.toStringAsFixed(0)
                                                  : '-',
                                              textAlign: TextAlign.right,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1F2937),
                                              ),
                                            ),
                                            if (countedQty != null)
                                              const Text(
                                                'pcs',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                          ],
                                        )
                                      : Align(
                                          alignment: Alignment.centerRight,
                                          child: _buildCountedQtyInput(globalIndex, item),
                                        ),
                                ),
                              ),
                              Container(
                                width: 0.5,
                                color: const Color(0xFFDEE0E4),
                              ),
                              // Difference
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  child: difference != null
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${difference.abs().toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: difference == 0
                                                        ? const Color(
                                                            0xFF1F2937,
                                                          )
                                                        : (difference > 0
                                                              ? const Color(
                                                                  0xFFEF4444,
                                                                )
                                                              : const Color(
                                                                  0xFFEF4444,
                                                                )),
                                                  ),
                                                ),
                                                if (difference != 0) ...[
                                                  const SizedBox(width: 3),
                                                  Icon(
                                                    difference > 0
                                                        ? LucideIcons.arrowUp
                                                        : LucideIcons.arrowDown,
                                                    size: 14,
                                                    color: difference > 0
                                                        ? const Color(
                                                            0xFFEF4444,
                                                          )
                                                        : const Color(
                                                            0xFFEF4444,
                                                          ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              'pcs',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: difference == 0
                                                    ? const Color(0xFF1F2937)
                                                    : (difference > 0
                                                          ? const Color(
                                                              0xFFEF4444,
                                                            )
                                                          : const Color(
                                                              0xFFEF4444,
                                                            )),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '-',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBinTab(String label, int index) {
    final isSelected = _activeBinTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeBinTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _buildDivisionTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8D9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFD97706),
        ),
      ),
    );
  }

  Widget _buildBinCard({
    required Widget titleWidget,
    required String descriptionText,
    required String subtext,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 8),
                    if (descriptionText.isNotEmpty) ...[
                      Text(
                        descriptionText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      subtext,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      'View Items',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _activeTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = index;
          if (index == 0) {
            _initiallyUncountedItemNames.clear();
            for (var it in _items) {
              if (it['countedQty'] == null) {
                _initiallyUncountedItemNames.add(it['name'] as String);
              }
            }
          }
        });
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? const Color(0xFF111827)
                    : const Color(0xFF4B5563),
              ),
            ),
          ),
          Container(
            height: 2,
            width: 80,
            color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _AddBatchesDialog extends StatefulWidget {
  final String itemName;
  final String? productId;
  final String? warehouseId;
  final List<Map<String, dynamic>> initialBatches;
  final bool trackBinLocation;
  final String? selectedBinId;
  final String? selectedBinCode;
  final int systemQty;
  final String locationName;
  final bool initialMarkZero;

  const _AddBatchesDialog({
    required this.itemName,
    this.productId,
    this.warehouseId,
    required this.initialBatches,
    this.trackBinLocation = false,
    this.selectedBinId,
    this.selectedBinCode,
    this.systemQty = 0,
    this.locationName = 'ZABNIX PRIVATE LIMITED',
    this.initialMarkZero = false,
  });

  @override
  State<_AddBatchesDialog> createState() => _AddBatchesDialogState();
}

class _AddBatchesDialogState extends State<_AddBatchesDialog> {
  List<Map<String, dynamic>> _batches = [];
  bool _markCountAsZero = false;
  final List<TextEditingController> _batchNoControllers = [];
  final List<TextEditingController> _binCodeControllers = [];
  final List<TextEditingController> _qtyControllers = [];
  bool _showZeroCountWarning = false;
  List<Map<String, dynamic>> _dbBatches = [];
  bool _isLoadingBatches = true;

  bool get _shouldShowBinInput =>
      widget.trackBinLocation && widget.selectedBinId == null;

  double get _totalQty => _batches.fold(
    0.0,
    (sum, b) => sum + ((b['qty'] as num?) ?? 0).toDouble(),
  );

  @override
  void initState() {
    super.initState();
    _markCountAsZero = widget.initialMarkZero;
    _batches = widget.initialBatches
        .map((b) => Map<String, dynamic>.from(b))
        .toList();
    if (_batches.isEmpty) {
      _batches.add({
        'batchNo': '',
        'binCode': widget.selectedBinCode ?? '',
        'bin_id': widget.selectedBinId,
        'qty': 0,
      });
    }
    for (final b in _batches) {
      if (widget.selectedBinId != null) {
        b['bin_id'] = widget.selectedBinId;
        b['binCode'] = widget.selectedBinCode ?? b['binCode'] ?? '';
      }
      _batchNoControllers.add(
        TextEditingController(text: b['batchNo'] as String? ?? ''),
      );
      _binCodeControllers.add(
        TextEditingController(text: b['binCode'] as String? ?? ''),
      );
      _qtyControllers.add(
        TextEditingController(
          text: (b['qty'] as num? ?? 0) == 0 ? '' : b['qty'].toString(),
        ),
      );
    }
    _loadDbBatches();
  }

  Future<void> _loadDbBatches() async {
    if (widget.productId == null || widget.productId!.isEmpty) {
      if (mounted) {
        setState(() => _isLoadingBatches = false);
      }
      return;
    }
    try {
      final supabase = Supabase.instance.client;
      final normalizedWarehouseId = widget.warehouseId?.trim();
      var binWiseQuery = supabase
          .from('v_bin_wise_stock')
          .select('bin_id, stock_on_hand')
          .eq('product_id', widget.productId!);
      if (normalizedWarehouseId != null && normalizedWarehouseId.isNotEmpty) {
        binWiseQuery = binWiseQuery.eq('warehouse_id', normalizedWarehouseId);
      }
      if (widget.selectedBinId != null && widget.selectedBinId!.isNotEmpty) {
        binWiseQuery = binWiseQuery.eq('bin_id', widget.selectedBinId!);
      }

      final binWiseResponse = await binWiseQuery;
      final physicalStockByBinId = <String, double>{};
      for (final row in binWiseResponse as List) {
        final map = Map<String, dynamic>.from(row as Map);
        final binId = map['bin_id']?.toString() ?? '';
        if (binId.isEmpty) {
          continue;
        }
        final stockOnHand =
            double.tryParse(map['stock_on_hand']?.toString() ?? '') ?? 0.0;
        physicalStockByBinId[binId] =
            (physicalStockByBinId[binId] ?? 0.0) + stockOnHand;
      }

      var layersQuery = supabase
          .from('batch_stock_layers')
          .select('batch_id, bin_id, qty, batch_master(batch_no), bin_master(bin_code)')
          .eq('product_id', widget.productId!);
      if (normalizedWarehouseId != null && normalizedWarehouseId.isNotEmpty) {
        layersQuery = layersQuery.eq('warehouse_id', normalizedWarehouseId);
      }
      if (widget.selectedBinId != null && widget.selectedBinId!.isNotEmpty) {
        layersQuery = layersQuery.eq('bin_id', widget.selectedBinId!);
      }

      final response = await layersQuery;

      final List<Map<String, dynamic>> loaded = [];
      final aggregated = <String, Map<String, dynamic>>{};
      for (final r in response as List) {
        final bMap = Map<String, dynamic>.from(r as Map);
        final batchId = bMap['batch_id']?.toString() ?? '';
        final binId = bMap['bin_id']?.toString() ?? '';
        if (batchId.isEmpty) {
          continue;
        }
        final batchData = bMap['batch_master'] as Map<String, dynamic>?;
        final binData = bMap['bin_master'] as Map<String, dynamic>?;
        final batchNo = (batchData?['batch_no'] ?? '').toString().trim();
        final binCode = (binData?['bin_code'] ?? '').toString().trim();
        final aggregateKey = '$batchId::$binId';
        final qty = double.tryParse(bMap['qty']?.toString() ?? '') ?? 0.0;
        final balance = binId.isNotEmpty
            ? (physicalStockByBinId[binId] ?? qty)
            : qty;
        aggregated.update(
          aggregateKey,
          (existing) => {
            ...existing,
            'balance': (existing['balance'] as double? ?? 0.0) + balance,
          },
          ifAbsent: () => {
            'id': batchId,
            'batchNo': batchNo,
            'binId': binId,
            'binCode': binCode,
            'balance': balance,
          },
        );
      }
      loaded.addAll(aggregated.values);
      loaded.sort((a, b) {
        final batchCompare = (a['batchNo'] as String? ?? '')
            .compareTo(b['batchNo'] as String? ?? '');
        if (batchCompare != 0) {
          return batchCompare;
        }
        return (a['binCode'] as String? ?? '')
            .compareTo(b['binCode'] as String? ?? '');
      });

      for (final row in _batches) {
        if ((row['binCode'] as String? ?? '').trim().isNotEmpty) {
          continue;
        }
        final batchNo = (row['batchNo'] as String? ?? '').trim().toLowerCase();
        if (batchNo.isEmpty) {
          continue;
        }
        final matches = loaded
            .where(
              (dbBatch) =>
                  (dbBatch['batchNo'] as String? ?? '').trim().toLowerCase() ==
                  batchNo,
            )
            .toList();
        if (matches.length == 1) {
          row['binCode'] = matches.first['binCode'] ?? '';
          row['bin_id'] = matches.first['binId'] ?? '';
        }
      }

      if (mounted) {
        setState(() {
          _dbBatches = loaded;
          _isLoadingBatches = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading db batches: $e');
      if (mounted) {
        setState(() => _isLoadingBatches = false);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _batchNoControllers) c.dispose();
    for (final c in _binCodeControllers) c.dispose();
    for (final c in _qtyControllers) c.dispose();
    super.dispose();
  }

  void _addNewRow() {
    setState(() {
      _batches.add({
        'batchNo': '',
        'binCode': widget.selectedBinCode ?? '',
        'bin_id': widget.selectedBinId,
        'qty': 0,
      });
      _batchNoControllers.add(TextEditingController());
      _binCodeControllers.add(
        TextEditingController(text: widget.selectedBinCode ?? ''),
      );
      _qtyControllers.add(TextEditingController());
    });
  }

  void _removeRow(int index) {
    setState(() {
      _batches.removeAt(index);
      _batchNoControllers[index].dispose();
      _binCodeControllers[index].dispose();
      _qtyControllers[index].dispose();
      _batchNoControllers.removeAt(index);
      _binCodeControllers.removeAt(index);
      _qtyControllers.removeAt(index);
    });
  }

  Widget _buildBatchField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      textAlign: hint == 'Enter Qty' ? TextAlign.right : TextAlign.left,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 11,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: Color(0xFF2A85FB)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, minHeight: 480),
        child: _isLoadingBatches
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2A85FB)),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // ── Title bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              child: Row(
                children: [
                  const Text(
                    'Add Batches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Location row (grey strip) ─────────────────────────
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.building2,
                    size: 15,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Location :',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.locationName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Item name (left) + Total Qty & checkbox (right) ─────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: item name
                  Text(
                    widget.itemName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  // Right: qty + checkbox stacked
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Quantity : ${_totalQty.toStringAsFixed(0)} pcs',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: _markCountAsZero,
                              onChanged: (val) {
                                setState(() {
                                  _markCountAsZero = val ?? false;
                                  if (_markCountAsZero) {
                                    _showZeroCountWarning = false;
                                  }
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              activeColor: AppTheme.primaryBlueDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Mark Count Quantity as Zero',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const ZTooltip(
                            message:
                                'Check this box to confirm that the quantity counted for this item is zero.',
                            child: Icon(
                              LucideIcons.helpCircle,
                              size: 15,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            if (_showZeroCountWarning) ...[
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'You are updating the counted quantity to zero for this item. Check the box Mark Count Quantity as Zero to update the counted quantity to zero.',
                        style: TextStyle(
                          color: Color(0xFFB91C1C),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showZeroCountWarning = false;
                        });
                      },
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ],

            // ── Column headers (grey background) ─────────────────────
            Container(
              color: const Color(0xFFF9FAFB),
              padding: const EdgeInsets.fromLTRB(24, 10, 56, 10),
              child: Row(
                children: [
                  Expanded(
                    flex: _shouldShowBinInput ? 4 : 5,
                    child: Text(
                      'BATCH REFERENCE#',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (_shouldShowBinInput) ...const [
                    SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'BIN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'QUANTITY',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Batch input rows ─────────────────────────────────────
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                  child: Column(
                    children: [
                      for (int i = 0; i < _batches.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: _shouldShowBinInput ? 4 : 5,
                                child: _buildBatchField(
                                  controller: _batchNoControllers[i],
                                  hint: 'Enter Batch#',
                                  onChanged: (val) =>
                                      _batches[i]['batchNo'] = val,
                                ),
                              ),
                              if (_shouldShowBinInput) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: _buildBatchField(
                                    controller: _binCodeControllers[i],
                                    hint: 'Enter Bin',
                                    onChanged: (val) =>
                                        _batches[i]['binCode'] = val,
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: _buildBatchField(
                                  controller: _qtyControllers[i],
                                  hint: 'Enter Qty',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setState(() {
                                      _batches[i]['qty'] =
                                          double.tryParse(val) ?? 0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _removeRow(i),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    LucideIcons.xCircle,
                                    size: 20,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── + New Batch | Batches added: N ───────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _addNewRow,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plus,
                          size: 18,
                          color: Color(0xFF2A85FB),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'New Batch',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF2A85FB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Batches added: ${_batches.length}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // ── Action buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 50, 24, 22),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Synchronize controllers with batches state list
                      for (int idx = 0; idx < _batches.length; idx++) {
                        _batches[idx]['batchNo'] = _batchNoControllers[idx].text;
                        _batches[idx]['binCode'] = widget.selectedBinCode ??
                            _binCodeControllers[idx].text;
                        _batches[idx]['bin_id'] = widget.selectedBinId ??
                            _batches[idx]['bin_id'];
                        _batches[idx]['qty'] = double.tryParse(_qtyControllers[idx].text) ?? 0.0;
                      }

                      final validBatches = _batches
                          .where(
                            (b) =>
                                (b['batchNo'] as String).trim().isNotEmpty &&
                                (b['qty'] as num) > 0,
                          )
                          .toList();

                      if (validBatches.isEmpty && !_markCountAsZero) {
                        setState(() {
                          _showZeroCountWarning = true;
                        });
                        return;
                      }

                      // Check if all validBatches have a matching batch name in the DB
                      bool hasInvalidBatch = false;
                      for (var b in validBatches) {
                        final batchNo = b['batchNo'].toString().trim().toLowerCase();
                        final binCode = (widget.selectedBinCode ?? b['binCode'])
                            .toString()
                            .trim()
                            .toLowerCase();
                        final selectedBinId = widget.selectedBinId;

                        final matches = _dbBatches.where((dbB) {
                          final batchMatch =
                              dbB['batchNo'].toString().trim().toLowerCase() ==
                                  batchNo;
                          if (!batchMatch) {
                            return false;
                          }
                          if (selectedBinId != null && selectedBinId.isNotEmpty) {
                            return dbB['binId'].toString().trim() == selectedBinId;
                          }
                          if (!widget.trackBinLocation) {
                            return true;
                          }
                          return dbB['binCode']
                                  .toString()
                                  .trim()
                                  .toLowerCase() ==
                              binCode;
                        }).toList();
                        final dbMatch = matches.isNotEmpty
                            ? matches.first
                            : <String, dynamic>{};

                        if (dbMatch.isEmpty) {
                          hasInvalidBatch = true;
                        } else {
                          b['batch_id'] = dbMatch['id'];
                          b['batch_no'] = dbMatch['batchNo'];
                          b['bin_id'] = dbMatch['binId'];
                          b['bin_code'] = dbMatch['binCode'];
                        }
                      }

                      Navigator.of(context).pop({
                        'batches': validBatches,
                        'markZero': _markCountAsZero,
                        'hasInvalidBatch': hasInvalidBatch,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22A95E),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
