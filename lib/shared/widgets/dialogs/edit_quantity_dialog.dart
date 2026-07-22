import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/providers/purchases_purchase_orders_provider.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

class ReceiveSplitAllocation {
  final Map<String, dynamic> receive;
  final double quantity;
  final String receiveItemId;

  ReceiveSplitAllocation({
    required this.receive,
    required this.quantity,
    required this.receiveItemId,
  });
}

class QuantitySplitResult {
  final double unreceivedQuantity;
  final List<ReceiveSplitAllocation> receiveSplits;

  QuantitySplitResult({
    required this.unreceivedQuantity,
    required this.receiveSplits,
  });
}

class EditQuantityDialog extends ConsumerStatefulWidget {
  final String itemName;
  final String productId;
  final double currentUnreceivedAllocated;

  // Initial selection if any
  final String? initialPurchaseReceiveId;
  final String? initialPurchaseReceiveNumber;
  final double initialPurchaseReceiveQty;
  final String? initialPurchaseReceiveItemId;
  final String? description;

  final String? poId;
  final String poNum;
  final String? vendorId;
  final String? billId;
  final bool isReceiveMode;

  const EditQuantityDialog({
    super.key,
    required this.itemName,
    required this.productId,
    required this.currentUnreceivedAllocated,
    this.initialPurchaseReceiveId,
    this.initialPurchaseReceiveNumber,
    this.initialPurchaseReceiveQty = 0.0,
    this.initialPurchaseReceiveItemId,
    this.description,
    required this.poId,
    required this.poNum,
    required this.vendorId,
    this.billId,
    this.isReceiveMode = false,
  });

  @override
  ConsumerState<EditQuantityDialog> createState() => _EditQuantityDialogState();
}

class _SplitRow {
  Map<String, dynamic>? selectedReceive;
  final TextEditingController qtyCtrl = TextEditingController(text: '0');
  double rxTotalQty = 0.0;
  double billedQty = 0.0;
  double unbilledQty = 0.0;
  double billedOther = 0.0;
  bool isLoadingBilled = false;
  String? receiveItemId;
  final double initialQty;

  _SplitRow({this.selectedReceive, this.initialQty = 0.0, this.receiveItemId}) {
    qtyCtrl.text = initialQty % 1 == 0
        ? initialQty.toInt().toString()
        : initialQty.toString();
  }

  void dispose() {
    qtyCtrl.dispose();
  }
}

class _EditQuantityDialogState extends ConsumerState<EditQuantityDialog> {
  final TextEditingController _unreceivedCtrl = TextEditingController(
    text: '0',
  );
  final List<_SplitRow> _splits = [];
  double _totalQty = 0.0;
  bool _isLoading = true;
  double _initialUnreceivedQty = 0.0;
  List<Map<String, dynamic>> _poReceives = [];
  String? _poId;
  PurchaseOrderItem? _resolvedPoItem;

  @override
  void initState() {
    super.initState();
    _unreceivedCtrl.text = widget.currentUnreceivedAllocated.toInt().toString();
    _unreceivedCtrl.addListener(_updateTotal);
    _loadData();
  }

  @override
  void dispose() {
    _unreceivedCtrl.dispose();
    for (final row in _splits) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      _poId = widget.poId;
      String poNum = widget.poNum.trim();
      String? rxNum = widget.initialPurchaseReceiveNumber;

      // 1. Resolve PO ID/number from purchase receive number if provided and poId is empty
      if (rxNum != null &&
          rxNum.isNotEmpty &&
          (_poId == null || _poId!.isEmpty)) {
        try {
          final supabase = Supabase.instance.client;
          final rxData = await supabase
              .from('purchase_receives')
              .select('purchase_order_id, purchase_order_number')
              .eq('purchase_receive_number', rxNum)
              .eq('is_delete', false)
              .maybeSingle();
          if (rxData != null) {
            _poId = rxData['purchase_order_id']?.toString();
            final resolvedPoNum =
                rxData['purchase_order_number']?.toString() ?? '';
            if (resolvedPoNum.isNotEmpty) {
              poNum = resolvedPoNum;
            }
          }
        } catch (e) {
          debugPrint('Error looking up PO via receive number: $e');
        }
      }

      if ((_poId == null || _poId!.isEmpty) && poNum.isNotEmpty) {
        final po = await _fetchPoByNumber(poNum, widget.productId);
        if (po != null) {
          _poId = po.id;
        }
      }

      if (_poId == null || _poId!.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final repository = ref.read(purchaseOrderRepositoryProvider);
      final po = await repository.getPurchaseOrder(_poId!);
      if (po == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      List<Map<String, dynamic>> poReceives = [];
      if (widget.isReceiveMode) {
        poReceives = await _fetchBillsForPo(poNum);
      } else {
        poReceives = await _fetchReceivesForPo(_poId!);
      }

      // Find initial rxItem if we have initial rx info
      Map<String, dynamic>? initialRxItem;
      if (widget.initialPurchaseReceiveId != null ||
          (widget.initialPurchaseReceiveNumber != null &&
              widget.initialPurchaseReceiveNumber!.isNotEmpty)) {
        final rx = poReceives.firstWhere(
          (r) =>
              (widget.initialPurchaseReceiveId != null &&
                  r['id']?.toString() == widget.initialPurchaseReceiveId) ||
              (widget.initialPurchaseReceiveNumber != null &&
                  r[widget.isReceiveMode
                              ? 'bill_number'
                              : 'purchase_receive_number']
                          ?.toString() ==
                      widget.initialPurchaseReceiveNumber),
          orElse: () => <String, dynamic>{},
        );
        if (rx.isNotEmpty) {
          final rxItems = widget.isReceiveMode
              ? (rx['bill_items'] as List<dynamic>? ?? [])
              : (rx['purchase_receive_items'] as List<dynamic>? ?? []);
          initialRxItem = rxItems.firstWhere(
            (item) => widget.initialPurchaseReceiveItemId != null
                ? item['id']?.toString() == widget.initialPurchaseReceiveItemId
                : false,
            orElse: () => null,
          );
          if (initialRxItem == null) {
            initialRxItem = rxItems.firstWhere(
              (item) =>
                  (widget.isReceiveMode
                          ? item['product_id']
                          : item['item_id']) ==
                      widget.productId &&
                  (((double.tryParse(
                                        (widget.isReceiveMode
                                                    ? item['quantity']
                                                    : item['quantity_to_receive'])
                                                ?.toString() ??
                                            '',
                                      ) ??
                                      0.0) -
                                  widget.initialPurchaseReceiveQty)
                              .abs() <
                          0.001 ||
                      ((double.tryParse(
                                        (widget.isReceiveMode
                                                    ? item['quantity']
                                                    : item['ordered'])
                                                ?.toString() ??
                                            '',
                                      ) ??
                                      0.0) -
                                  widget.initialPurchaseReceiveQty)
                              .abs() <
                          0.001) &&
                  (item['description']?.toString() ?? '').trim() ==
                      (widget.description ?? '').trim(),
              orElse: () => null,
            );
          }
          if (initialRxItem == null) {
            initialRxItem = rxItems.firstWhere(
              (item) =>
                  (widget.isReceiveMode
                          ? item['product_id']
                          : item['item_id']) ==
                      widget.productId &&
                  (((double.tryParse(
                                        (widget.isReceiveMode
                                                    ? item['quantity']
                                                    : item['quantity_to_receive'])
                                                ?.toString() ??
                                            '',
                                      ) ??
                                      0.0) -
                                  widget.initialPurchaseReceiveQty)
                              .abs() <
                          0.001 ||
                      ((double.tryParse(
                                        (widget.isReceiveMode
                                                    ? item['quantity']
                                                    : item['ordered'])
                                                ?.toString() ??
                                            '',
                                      ) ??
                                      0.0) -
                                  widget.initialPurchaseReceiveQty)
                              .abs() <
                          0.001),
              orElse: () => null,
            );
          }
          initialRxItem ??= rxItems.firstWhere(
            (item) =>
                (widget.isReceiveMode ? item['product_id'] : item['item_id']) ==
                widget.productId,
            orElse: () => null,
          );
        }
      }

      // Resolve poItem with description/quantity mapping, falling back to first match
      PurchaseOrderItem? poItem;
      if (initialRxItem != null) {
        final rxOrdered =
            double.tryParse(
              (widget.isReceiveMode
                          ? initialRxItem['quantity']
                          : initialRxItem['ordered'])
                      ?.toString() ??
                  '',
            ) ??
            0.0;
        final rxDesc = initialRxItem['description']?.toString() ?? '';
        poItem = po.items
            .where(
              (i) =>
                  !i.isHeader &&
                  i.productId == widget.productId &&
                  (i.quantity - rxOrdered).abs() < 0.001 &&
                  (i.description ?? '').trim() == rxDesc.trim(),
            )
            .firstOrNull;
      }
      poItem ??= po.items
          .where((i) => !i.isHeader && i.productId == widget.productId)
          .firstOrNull;
      _resolvedPoItem = poItem;
      final orderedQty = poItem?.quantity ?? 0.0;

      double initialUnreceivedQty = 0.0;
      if (widget.isReceiveMode) {
        // In receive mode, initialUnreceivedQty is the unbilled quantity: orderedQty - totalBilled
        double totalBilled = 0.0;
        for (final bill in poReceives) {
          final billItems = bill['bill_items'] as List<dynamic>? ?? [];
          for (final billItem in billItems) {
            if (billItem['product_id'] == widget.productId) {
              totalBilled +=
                  double.tryParse(billItem['quantity']?.toString() ?? '0.0') ??
                  0.0;
            }
          }
        }
        initialUnreceivedQty = (orderedQty - totalBilled) > 0
            ? (orderedQty - totalBilled)
            : 0.0;
      } else {
        // Sum received quantity for this product/poItem across all received receives (excluding FOC)
        double totalReceived = 0.0;
        for (final rx in poReceives) {
          if (rx['status']?.toString().toLowerCase() == 'received') {
            final rxItems =
                rx['purchase_receive_items'] as List<dynamic>? ?? [];
            for (final rxItem in rxItems) {
              // Match receive items that belong to the resolved poItem
              final rxItemOrdered =
                  double.tryParse(rxItem['ordered']?.toString() ?? '') ?? 0.0;
              final rxItemDesc = rxItem['description']?.toString() ?? '';
              final isMatch =
                  rxItem['item_id'] == widget.productId &&
                  (poItem == null ||
                      (((rxItemOrdered - poItem.quantity).abs() < 0.001) &&
                          rxItemDesc.trim() ==
                              (poItem.description ?? '').trim()));

              if (isMatch) {
                final batches =
                    rxItem['purchase_receive_item_batches'] as List<dynamic>? ??
                    [];
                if (batches.isNotEmpty) {
                  for (final b in batches) {
                    totalReceived +=
                        double.tryParse(b['quantity']?.toString() ?? '0.0') ??
                        0.0;
                  }
                } else {
                  final qty =
                      double.tryParse(
                        rxItem['quantity_to_receive']?.toString() ??
                            rxItem['received']?.toString() ??
                            '0.0',
                      ) ??
                      0.0;
                  totalReceived += qty;
                }
              }
            }
          }
        }
        initialUnreceivedQty = (orderedQty - totalReceived) > 0
            ? (orderedQty - totalReceived)
            : 0.0;
      }

      if (mounted) {
        setState(() {
          _initialUnreceivedQty = initialUnreceivedQty;
          _unreceivedCtrl.text = widget.currentUnreceivedAllocated % 1 == 0
              ? widget.currentUnreceivedAllocated.toInt().toString()
              : widget.currentUnreceivedAllocated.toString();
          _poReceives = poReceives;

          _splits.clear();
          if (widget.initialPurchaseReceiveId != null ||
              (widget.initialPurchaseReceiveNumber != null &&
                  widget.initialPurchaseReceiveNumber!.isNotEmpty)) {
            // Find full rx/bill object
            final rx = _poReceives.firstWhere(
              (r) =>
                  (widget.initialPurchaseReceiveId != null &&
                      r['id']?.toString() == widget.initialPurchaseReceiveId) ||
                  (widget.initialPurchaseReceiveNumber != null &&
                      r[widget.isReceiveMode
                                  ? 'bill_number'
                                  : 'purchase_receive_number']
                              ?.toString() ==
                          widget.initialPurchaseReceiveNumber),
              orElse: () => {
                'id': widget.initialPurchaseReceiveId,
                widget.isReceiveMode
                        ? 'bill_number'
                        : 'purchase_receive_number':
                    widget.initialPurchaseReceiveNumber,
              },
            );

            final rxItems = widget.isReceiveMode
                ? (rx['bill_items'] as List<dynamic>? ?? [])
                : (rx['purchase_receive_items'] as List<dynamic>? ?? []);
            dynamic rxItem;
            if (widget.initialPurchaseReceiveItemId != null) {
              rxItem = rxItems.firstWhere(
                (item) =>
                    item['id']?.toString() ==
                    widget.initialPurchaseReceiveItemId,
                orElse: () => null,
              );
            }
            if (rxItem == null && _resolvedPoItem != null) {
              rxItem = rxItems.firstWhere(
                (item) =>
                    (widget.isReceiveMode
                            ? item['product_id']
                            : item['item_id']) ==
                        widget.productId &&
                    ((double.tryParse(
                                      (widget.isReceiveMode
                                                  ? item['quantity']
                                                  : item['ordered'])
                                              ?.toString() ??
                                          '',
                                    ) ??
                                    0.0) -
                                _resolvedPoItem!.quantity)
                            .abs() <
                        0.001 &&
                    (item['description']?.toString() ?? '').trim() ==
                        (_resolvedPoItem!.description ?? '').trim(),
                orElse: () => null,
              );
            }
            if (rxItem == null) {
              rxItem = rxItems.firstWhere(
                (item) =>
                    (widget.isReceiveMode
                            ? item['product_id']
                            : item['item_id']) ==
                        widget.productId &&
                    (((double.tryParse(
                                          (widget.isReceiveMode
                                                      ? item['quantity']
                                                      : item['quantity_to_receive'])
                                                  ?.toString() ??
                                              '',
                                        ) ??
                                        0.0) -
                                    widget.initialPurchaseReceiveQty)
                                .abs() <
                            0.001 ||
                        ((double.tryParse(
                                          (widget.isReceiveMode
                                                      ? item['quantity']
                                                      : item['ordered'])
                                                  ?.toString() ??
                                              '',
                                        ) ??
                                        0.0) -
                                    widget.initialPurchaseReceiveQty)
                                .abs() <
                            0.001) &&
                    (item['description']?.toString() ?? '').trim() ==
                        (widget.description ?? '').trim(),
                orElse: () => null,
              );
            }
            if (rxItem == null) {
              rxItem = rxItems.firstWhere(
                (item) =>
                    (widget.isReceiveMode
                            ? item['product_id']
                            : item['item_id']) ==
                        widget.productId &&
                    (((double.tryParse(
                                          (widget.isReceiveMode
                                                      ? item['quantity']
                                                      : item['quantity_to_receive'])
                                                  ?.toString() ??
                                              '',
                                        ) ??
                                        0.0) -
                                    widget.initialPurchaseReceiveQty)
                                .abs() <
                            0.001 ||
                        ((double.tryParse(
                                          (widget.isReceiveMode
                                                      ? item['quantity']
                                                      : item['ordered'])
                                                  ?.toString() ??
                                              '',
                                        ) ??
                                        0.0) -
                                    widget.initialPurchaseReceiveQty)
                                .abs() <
                            0.001),
                orElse: () => null,
              );
            }
            rxItem ??= rxItems.firstWhere(
              (item) =>
                  (widget.isReceiveMode
                      ? item['product_id']
                      : item['item_id']) ==
                  widget.productId,
              orElse: () => null,
            );
            final rxItemId = rxItem?['id']?.toString() ?? '';

            final row = _SplitRow(
              selectedReceive: rx,
              initialQty: widget.initialPurchaseReceiveQty,
              receiveItemId: rxItemId,
            );
            row.qtyCtrl.addListener(_updateTotal);
            _splits.add(row);
            if (rxItemId.isNotEmpty) {
              _fetchDetailsForSelectedReceive(
                row,
                rx,
                widget.productId,
                isInitial: true,
              );
            }
          }

          _isLoading = false;
        });
        _updateTotal();
      }
    } catch (e) {
      debugPrint('Error loading dialog data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<PurchaseOrder?> _fetchPoByNumber(
    String poNum,
    String productId,
  ) async {
    try {
      final repository = ref.read(purchaseOrderRepositoryProvider);
      final vendorId = widget.vendorId;
      if (vendorId != null) {
        final allOrders = await repository.getPurchaseOrders(
          vendorId: vendorId,
        );

        final parts = poNum
            .split(',')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        for (final part in parts) {
          final match = allOrders
              .where(
                (o) =>
                    o.orderNumber == part ||
                    (o.referenceNumber != null &&
                        o.referenceNumber!.trim().toLowerCase() ==
                            part.toLowerCase()),
              )
              .firstOrNull;

          if (match != null) {
            final detailed = await repository.getPurchaseOrder(match.id!);
            if (detailed != null) {
              final hasProduct = detailed.items.any(
                (i) => !i.isHeader && i.productId == productId,
              );
              if (hasProduct) {
                return detailed;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching PO by number: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchReceivesForPo(String poId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('purchase_receives')
          .select(
            'id, purchase_receive_number, received_date, status, purchase_order_id, purchase_order_number, bill_no, purchase_receive_items(id, item_id, quantity_to_receive, ordered, description, purchase_receive_item_batches(quantity, foc_qty))',
          )
          .eq('purchase_order_id', poId)
          .eq('is_delete', false)
          .order('created_at', ascending: true);
      return (response as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('Error fetching PO receives: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _fetchBillsForPo(String poNum) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('bills')
          .select(
            'id, bill_number, order_number, status, bill_items(id, product_id, quantity, description, rate, bill_item_batches(quantity))',
          )
          .or('order_number.ilike.%${poNum.trim()}%')
          .neq('status', 'void')
          .order('created_at', ascending: true);
      final list = (response as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final normalizedPoNum = poNum.trim().toLowerCase();
      return list.where((b) {
        final orderNumStr = (b['order_number'] ?? '').toString().toLowerCase();
        final parts = orderNumStr.split(',').map((p) => p.trim()).toList();
        return parts.contains(normalizedPoNum);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching PO bills: $e');
    }
    return [];
  }

  void _updateTotal() {
    double total = double.tryParse(_unreceivedCtrl.text) ?? 0.0;
    for (final row in _splits) {
      final currentQty = double.tryParse(row.qtyCtrl.text) ?? 0.0;
      total += currentQty;
      row.billedQty = row.billedOther + currentQty;
      row.unbilledQty = (row.rxTotalQty - row.billedOther - currentQty) > 0
          ? (row.rxTotalQty - row.billedOther - currentQty)
          : 0.0;
    }
    setState(() {
      _totalQty = total;
    });
  }

  Future<void> _fetchDetailsForSelectedReceive(
    _SplitRow row,
    Map<String, dynamic> rx,
    String productId, {
    bool isInitial = false,
  }) async {
    if (widget.isReceiveMode) {
      final rxItems = rx['bill_items'] as List<dynamic>? ?? [];
      dynamic rxItem;
      if (row.receiveItemId != null && row.receiveItemId!.isNotEmpty) {
        rxItem = rxItems.firstWhere(
          (item) => item['id']?.toString() == row.receiveItemId,
          orElse: () => null,
        );
      }
      rxItem ??= rxItems.firstWhere(
        (item) => item['product_id'] == productId,
        orElse: () => null,
      );
      if (rxItem == null) return;
      final String rxItemId = rxItem['id']?.toString() ?? '';
      final double totalRxQty =
          double.tryParse(rxItem['quantity']?.toString() ?? '0.0') ?? 0.0;

      setState(() {
        row.isLoadingBilled = true;
        row.rxTotalQty = totalRxQty;
        row.receiveItemId = rxItemId;
      });

      try {
        final supabase = Supabase.instance.client;
        final billNoStr = rx['bill_number']?.toString() ?? '';
        final response = await supabase
            .from('purchase_receives')
            .select(
              'id, status, purchase_receive_items(item_id, quantity_to_receive, purchase_receive_item_batches(quantity))',
            )
            .eq('purchase_order_id', _poId ?? '')
            .eq('bill_no', billNoStr)
            .eq('is_delete', false);

        double totalReceivedOther = 0.0;
        for (final rxDoc in response) {
          final rxDocId = rxDoc['id']?.toString();
          if (widget.billId != null &&
              rxDocId != null &&
              rxDocId.toLowerCase() == widget.billId!.toLowerCase()) {
            continue;
          }
          if (rxDoc['status']?.toString().toLowerCase() != 'received') {
            continue;
          }
          final itemsList =
              rxDoc['purchase_receive_items'] as List<dynamic>? ?? [];
          for (final item in itemsList) {
            if (item['item_id']?.toString() == productId) {
              double itemQty = 0.0;
              final batches =
                  item['purchase_receive_item_batches'] as List<dynamic>? ??
                  [];
              if (batches.isNotEmpty) {
                for (final b in batches) {
                  itemQty +=
                      double.tryParse(b['quantity']?.toString() ?? '0.0') ??
                      0.0;
                }
              } else {
                itemQty =
                    double.tryParse(
                      item['quantity_to_receive']?.toString() ?? '0.0',
                    ) ??
                    0.0;
              }
              totalReceivedOther += itemQty;
            }
          }
        }
      
        if (mounted) {
          setState(() {
            row.rxTotalQty = totalRxQty;
            row.billedOther = totalReceivedOther;

            final double valToSet = isInitial ? row.initialQty : 0.0;
            row.qtyCtrl.text = valToSet % 1 == 0
                ? valToSet.toInt().toString()
                : valToSet.toString();

            row.billedQty = totalReceivedOther + valToSet;
            row.unbilledQty = (totalRxQty - totalReceivedOther - valToSet) > 0
                ? (totalRxQty - totalReceivedOther - valToSet)
                : 0.0;
            row.isLoadingBilled = false;
          });
          _updateTotal();
        }
      } catch (e) {
        debugPrint('Error loading received quantity: $e');
        if (mounted) {
          setState(() {
            row.isLoadingBilled = false;
          });
        }
      }
      return;
    }

    final rxItems = rx['purchase_receive_items'] as List<dynamic>? ?? [];

    dynamic rxItem;
    if (row.receiveItemId != null && row.receiveItemId!.isNotEmpty) {
      rxItem = rxItems.firstWhere(
        (item) => item['id']?.toString() == row.receiveItemId,
        orElse: () => null,
      );
    }

    if (rxItem == null && _resolvedPoItem != null) {
      rxItem = rxItems.firstWhere(
        (item) =>
            item['item_id'] == productId &&
            ((double.tryParse(item['ordered']?.toString() ?? '') ?? 0.0) -
                        _resolvedPoItem!.quantity)
                    .abs() <
                0.001 &&
            (item['description']?.toString() ?? '').trim() ==
                (_resolvedPoItem!.description ?? '').trim(),
        orElse: () => null,
      );
    }

    // Quantity-based fallback using initialPurchaseReceiveQty
    if (rxItem == null && widget.initialPurchaseReceiveQty > 0) {
      rxItem = rxItems.firstWhere(
        (item) =>
            item['item_id'] == productId &&
            ((double.tryParse(item['ordered']?.toString() ?? '') ?? 0.0) -
                        widget.initialPurchaseReceiveQty)
                    .abs() <
                0.001,
        orElse: () => null,
      );
    }

    rxItem ??= rxItems.firstWhere(
      (item) => item['item_id'] == productId,
      orElse: () => null,
    );

    if (rxItem == null) return;

    final String rxItemId = rxItem['id']?.toString() ?? '';

    final batches =
        rxItem['purchase_receive_item_batches'] as List<dynamic>? ?? [];
    double totalRxQty = 0.0;
    if (batches.isNotEmpty) {
      for (final b in batches) {
        totalRxQty +=
            double.tryParse(b['quantity']?.toString() ?? '0.0') ?? 0.0;
      }
    } else {
      totalRxQty =
          double.tryParse(rxItem['quantity_to_receive']?.toString() ?? '0') ??
          0.0;
    }

    setState(() {
      row.isLoadingBilled = true;
      row.rxTotalQty = totalRxQty;
      row.receiveItemId = rxItemId;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('bill_items')
          .select('quantity, bill_id, bills!inner(status)')
          .eq('purchase_receive_item_id', rxItemId)
          .neq('bills.status', 'void');

      double totalBilledOther = 0.0;
      double totalBilledCurrent = 0.0;
      for (final item in response) {
        final qty =
            double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
        final itemBillId = item['bill_id']?.toString();
        if (widget.billId != null &&
            itemBillId != null &&
            itemBillId.toLowerCase() == widget.billId!.toLowerCase()) {
          totalBilledCurrent += qty;
        } else {
          totalBilledOther += qty;
        }
      }
    
      if (mounted) {
        setState(() {
          row.rxTotalQty = totalRxQty;
          row.billedOther = totalBilledOther;

          final double valToSet = isInitial ? row.initialQty : 0.0;
          row.qtyCtrl.text = valToSet % 1 == 0
              ? valToSet.toInt().toString()
              : valToSet.toString();

          row.billedQty = totalBilledOther + valToSet;
          row.unbilledQty = (totalRxQty - totalBilledOther - valToSet) > 0
              ? (totalRxQty - totalBilledOther - valToSet)
              : 0.0;
          row.isLoadingBilled = false;
        });
        _updateTotal();
      }
    } catch (e) {
      debugPrint('Error loading billed quantity: $e');
      if (mounted) {
        setState(() {
          row.isLoadingBilled = false;
        });
      }
    }
  }

  void _addNewRow() {
    if (_isLoading) return;
    final newRow = _SplitRow();
    newRow.qtyCtrl.addListener(_updateTotal);
    setState(() {
      _splits.add(newRow);
    });
  }

  void _removeRow(int index) {
    if (_isLoading) return;
    setState(() {
      _splits[index].dispose();
      _splits.removeAt(index);
    });
    _updateTotal();
  }

  List<Map<String, dynamic>> _getAvailableReceivesForIndex(
    int index,
    List<_SplitRow> splits,
  ) {
    if (_isLoading) {
      return [
        {
          'id': 'dummy',
          widget.isReceiveMode ? 'bill_number' : 'purchase_receive_number':
              widget.isReceiveMode ? 'BILL-XXXXX' : 'PR-XXXXX',
        },
      ];
    }
    final selectedIds = <String>{};
    for (int i = 0; i < splits.length; i++) {
      if (i != index) {
        final selectedRx = splits[i].selectedReceive;
        if (selectedRx != null && selectedRx['id'] != null) {
          selectedIds.add(selectedRx['id'].toString());
        }
      }
    }
    return _poReceives
        .where((rx) => !selectedIds.contains(rx['id']?.toString()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2937);
    const textSecondary = Color(0xFF4B5563);
    const borderCol = Color(0xFFE5E7EB);
    const headerBg = Color(0xFFF9FAFB);

    final displaySplits = _isLoading
        ? [
            _SplitRow(
              selectedReceive: {
                'id': 'dummy',
                widget.isReceiveMode
                    ? 'bill_number'
                    : 'purchase_receive_number': widget.isReceiveMode
                    ? 'BILL-XXXXX'
                    : 'PR-XXXXX',
              },
              initialQty: 0,
              receiveItemId: 'dummy',
            ),
          ]
        : _splits;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        top: 0,
        left: 40,
        right: 40,
        bottom: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: borderCol),

              Skeletonizer(
                enabled: _isLoading,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Item description
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        widget.itemName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),

                    // Table header
                    Container(
                      color: headerBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.isReceiveMode ? 'BILL' : 'RECEIVE',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                          const Text(
                            'QUANTITY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: borderCol),

                    // Row 1: Unreceived Quantity / Unbilled Quantity
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.isReceiveMode
                                  ? 'Unbilled Quantity'
                                  : 'Unreceived Quantity',
                              style: const TextStyle(
                                fontSize: 14,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: CustomTextField(
                              controller: _unreceivedCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.right,
                              height: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: borderCol),

                    // Splits Rows
                    if (displaySplits.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displaySplits.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: borderCol),
                        itemBuilder: (context, index) {
                          final row = displaySplits[index];
                          return Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: FormDropdown<Map<String, dynamic>>(
                                        height: 32,
                                        value: row.selectedReceive,
                                        items: _getAvailableReceivesForIndex(
                                          index,
                                          displaySplits,
                                        ),
                                        hint: widget.isReceiveMode
                                            ? 'Select Bill'
                                            : 'Select Receive',
                                        displayStringForValue: (rx) {
                                          return widget.isReceiveMode
                                              ? (rx['bill_number']
                                                        ?.toString() ??
                                                    '')
                                              : (rx['purchase_receive_number']
                                                        ?.toString() ??
                                                    '');
                                        },
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              row.selectedReceive = val;
                                              row.qtyCtrl.text = '0';
                                              row.receiveItemId = null;
                                            });
                                            _fetchDetailsForSelectedReceive(
                                              row,
                                              val,
                                              widget.productId,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (row.selectedReceive != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 6,
                                            ),
                                            child: Builder(
                                              builder: (context) {
                                                final currentQty =
                                                    double.tryParse(
                                                      row.qtyCtrl.text,
                                                    ) ??
                                                    0.0;
                                                final maxQty =
                                                    row.rxTotalQty -
                                                    row.billedOther;
                                                final bool isFilled =
                                                    currentQty >= maxQty;
                                                return InkWell(
                                                  onTap: isFilled
                                                      ? null
                                                      : () {
                                                          row.qtyCtrl.text =
                                                              maxQty
                                                                  .toInt()
                                                                  .toString();
                                                          _updateTotal();
                                                        },
                                                  child: Text(
                                                    'Auto-fill Total Qty',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isFilled
                                                          ? const Color(
                                                              0xFF0088FF,
                                                            ).withOpacity(0.4)
                                                          : const Color(
                                                              0xFF0088FF,
                                                            ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        SizedBox(
                                          width: 120,
                                          child: CustomTextField(
                                            controller: row.qtyCtrl,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            textAlign: TextAlign.right,
                                            height: 32,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 32,
                                      child: Center(
                                        child: IconButton(
                                          icon: const Icon(
                                            LucideIcons.x,
                                            color: Color(0xFFEF4444),
                                            size: 18,
                                          ),
                                          onPressed: () => _removeRow(index),
                                          splashRadius: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (row.selectedReceive != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: row.isLoadingBilled
                                            ? const SizedBox(
                                                height: 12,
                                                width: 12,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.5,
                                                      ),
                                                ),
                                              )
                                            : Text(
                                                'Quantity: ${row.rxTotalQty % 1 == 0 ? row.rxTotalQty.toInt().toString() : row.rxTotalQty.toString()}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: textSecondary,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      if (!row.isLoadingBilled)
                                        SizedBox(
                                          width: 220,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              right: 40,
                                            ),
                                            child: Text(
                                              widget.isReceiveMode
                                                  ? 'Received: ${row.billedQty % 1 == 0 ? row.billedQty.toInt().toString() : row.billedQty.toString()} | Unreceived: ${row.unbilledQty % 1 == 0 ? row.unbilledQty.toInt().toString() : row.unbilledQty.toString()}'
                                                  : 'Billed: ${row.billedQty % 1 == 0 ? row.billedQty.toInt().toString() : row.billedQty.toString()} | Unbilled: ${row.unbilledQty % 1 == 0 ? row.unbilledQty.toInt().toString() : row.unbilledQty.toString()}',
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    const Divider(height: 1, color: borderCol),

                    // Add Row Button Row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: _addNewRow,
                            child: const Row(
                              children: [
                                Icon(
                                  LucideIcons.plus,
                                  color: Color(0xFF0088FF),
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'New Row',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0088FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.isReceiveMode
                                ? 'Bill added: ${displaySplits.length}'
                                : 'Receive added: ${displaySplits.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Total container
                    Container(
                      color: headerBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            _totalQty.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: borderCol),

                    // Action buttons footer
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Update
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22A95E),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (_isLoading) return;

                              final unreceivedVal =
                                  double.tryParse(_unreceivedCtrl.text) ?? 0.0;
                              if (unreceivedVal > _initialUnreceivedQty) {
                                final limitLabel = widget.isReceiveMode
                                    ? 'unbilled'
                                    : 'unreceived';
                                ZerpaiToast.error(
                                  context,
                                  'Value cannot exceed maximum available $limitLabel quantity (${_initialUnreceivedQty % 1 == 0 ? _initialUnreceivedQty.toInt().toString() : _initialUnreceivedQty.toString()})',
                                );
                                return;
                              }

                              // Filter allocations
                              final list = <ReceiveSplitAllocation>[];
                              for (final row in _splits) {
                                if (row.selectedReceive != null) {
                                  final qty =
                                      double.tryParse(row.qtyCtrl.text) ?? 0.0;
                                  if (qty > 0) {
                                    final maxQty =
                                        row.rxTotalQty - row.billedOther;
                                    if (qty > maxQty) {
                                      final rxNum = widget.isReceiveMode
                                          ? (row.selectedReceive!['bill_number']
                                                    ?.toString() ??
                                                '')
                                          : (row.selectedReceive!['purchase_receive_number']
                                                    ?.toString() ??
                                                '');
                                      final sourceLabel = widget.isReceiveMode
                                          ? 'bill'
                                          : 'receive';
                                      ZerpaiToast.error(
                                        context,
                                        'Quantity for $sourceLabel $rxNum cannot exceed available quantity (${maxQty % 1 == 0 ? maxQty.toInt().toString() : maxQty.toString()})',
                                      );
                                      return;
                                    }
                                    list.add(
                                      ReceiveSplitAllocation(
                                        receive: row.selectedReceive!,
                                        quantity: qty,
                                        receiveItemId: row.receiveItemId ?? '',
                                      ),
                                    );
                                  }
                                }
                              }
                              Navigator.pop(
                                context,
                                QuantitySplitResult(
                                  unreceivedQuantity: unreceivedVal,
                                  receiveSplits: list,
                                ),
                              );
                            },
                            child: const Text(
                              'Update',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Cancel
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: borderCol),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
