import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/sales/sales_return/providers/sales_return_provider.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/bulk_items_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/advanced_customer_search_modal.dart';
import 'package:zerpai_erp/modules/sales/sales_return/models/sales_return_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:intl/intl.dart';

class SalesReturnEditItem {
  final String name;
  final String productId;
  final String returnQty;
  final String shipped;
  final String returned;
  final String creditOnlyQty;
  final String description;
  final String hsnCode;
  final String rate;

  const SalesReturnEditItem({
    required this.name,
    required this.productId,
    required this.returnQty,
    required this.shipped,
    required this.returned,
    required this.creditOnlyQty,
    required this.description,
    required this.hsnCode,
    required this.rate,
  });
}

class SalesReturnEditData {
  final String id;
  final String rmaNumber;

  /// Preferred over [customerName] when resolving the customer — display names
  /// are not unique and can be edited.
  final String? customerId;
  final String customerName;
  final String referenceNumber;
  final String date;
  final bool creditOnlyGoods;
  final String? warehouseId;
  final String? warehouseName;
  final String reason;
  final String status;
  final List<SalesReturnEditItem> items;

  const SalesReturnEditData({
    required this.id,
    required this.rmaNumber,
    this.customerId,
    required this.customerName,
    required this.referenceNumber,
    required this.date,
    required this.creditOnlyGoods,
    this.warehouseId,
    this.warehouseName,
    required this.reason,
    required this.status,
    required this.items,
  });
}

/// Sales Return Add Page
class SalesReturnsCreatePage extends ConsumerStatefulWidget {
  final SalesReturnEditData? editData;

  /// Comma-separated RMA numbers to pre-fill this form from.
  ///
  /// Carried as a query parameter rather than `state.extra` because the app's
  /// top-level redirect rewrites every path to add the org system id, and
  /// GoRouter drops `extra` across a redirect. A query param also survives a
  /// browser refresh, which `extra` never did.
  final String? fromRmaNumbers;

  /// Id of an existing return to edit in place. Saving updates that record
  /// instead of creating a new one, and its RMA# is preserved.
  final String? editId;

  const SalesReturnsCreatePage({
    super.key,
    this.editData,
    this.fromRmaNumbers,
    this.editId,
  });

  @override
  ConsumerState<SalesReturnsCreatePage> createState() =>
      _SalesReturnsCreatePageState();
}

class _SalesReturnsCreatePageState
    extends ConsumerState<SalesReturnsCreatePage> {
  static const double _tableFieldHeight = 44;
  // --- Form State ---
  SalesCustomer? _selectedCustomerObj;
  String? _selectedCustomer;
  /// Free text. `sales_returns.reason` is a nullable `text` column that stores
  /// the reason itself, so the field is typed rather than picked from a list.
  late final TextEditingController _reasonController;
  late final TextEditingController _referenceNumberController;

  late final TextEditingController _rmaNumberController;
  late final TextEditingController _rmaDateController;
  final _rmaDateKey = GlobalKey();
  DateTime _rmaDate = DateTime.now();
  bool _creditOnlyGoods = false;

  Warehouse? _selectedWarehouse;

  /// Set when the form is editing an existing return. Save then updates that
  /// record rather than inserting — reusing its RMA# on an insert would violate
  /// the unique (entity_id, rma_number) index.
  String? _editingId;

  bool _rmaAutoGenerate = true;
  late final TextEditingController _rmaPrefixController;
  late final TextEditingController _rmaNextNumberController;

  bool _showItemDetailsPanel = false;
  _SalesReturnItem? _detailsItem;

  static const double _labelWidth = 150.0;
  static const double _rowMaxWidth = 1100.0;
  static const double _gapWidth = 16.0;
  static const double _fieldHeight = 32.0;
  static const double _customerFieldWidth = 500.0;

  final List<_SalesReturnItem> _items = [];

  @override
  void initState() {
    super.initState();
    final edit = widget.editData;

    _reasonController = TextEditingController(text: edit?.reason ?? '');
    _referenceNumberController =
        TextEditingController(text: edit?.referenceNumber ?? '');
    _rmaNumberController =
        TextEditingController(text: edit?.rmaNumber ?? 'RMA-00001');
    if (edit != null) {
      _rmaDate = _parseEditDate(edit.date) ?? _rmaDate;
      _creditOnlyGoods = edit.creditOnlyGoods;
      _rmaAutoGenerate = false; // an incoming RMA# must not be overwritten
    }
    _rmaDateController = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(_rmaDate),
    );
    _rmaPrefixController = TextEditingController(text: 'RMA-');
    _rmaNextNumberController = TextEditingController(text: '00001');

    _items.clear();
    if (edit != null && edit.items.isNotEmpty) {
      _prefillItems(edit);
    } else {
      _addItem();
    }

    final fromRma = widget.fromRmaNumbers;
    final isConverting = fromRma != null && fromRma.trim().isNotEmpty;
    final editId = widget.editId;
    final isEditing = editId != null && editId.trim().isNotEmpty;
    if (isEditing) _editingId = editId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A conversion still needs its own RMA#: it creates a new row and
      // (entity_id, rma_number) is unique, so reusing the source number would
      // collide. An edit updates in place and keeps its number.
      if (edit == null && !isEditing) _fetchNextRmaNumber();
      ref.read(itemsControllerProvider.notifier).loadLookupData();

      if (edit != null) {
        _applyEditSelections(edit);
      } else if (isEditing) {
        _loadForEdit(editId);
      } else if (isConverting) {
        _loadFromRmaNumbers(fromRma);
      }
    });
  }

  /// Accepts both the `dd-MM-yyyy` the report renders and the raw ISO date the
  /// API returns, since converted returns can arrive in either form.
  DateTime? _parseEditDate(String raw) {
    if (raw.isEmpty) return null;
    final iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    try {
      return DateFormat('dd-MM-yyyy').parseStrict(raw);
    } catch (_) {
      return null;
    }
  }

  /// Seeds the grid from a converted return. Runs in initState so the table is
  /// populated on first paint rather than flashing an empty row.
  void _prefillItems(SalesReturnEditData edit) {
    for (final line in edit.items) {
      _items.add(
        _SalesReturnItem(
          name: line.name,
          description: line.description,
          shipped: line.shipped,
          returned: line.returned,
          returnQty: line.returnQty,
          creditOnlyQty: line.creditOnlyQty,
          stock: '0 pcs',
          hsnCode: line.hsnCode,
          rate: line.rate,
        )..productId = line.productId,
      );
    }
  }

  /// Pre-fills the form from one or more existing returns, identified by RMA#.
  ///
  /// The form is a single document for a single customer, so a multi-selection
  /// is only merged when every return belongs to the same customer; mixed
  /// customers are refused rather than attributing lines to the wrong account.
  Future<void> _loadFromRmaNumbers(String raw) async {
    final wanted = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    if (wanted.isEmpty) return;

    try {
      final returns = await ref.read(salesReturnsListProvider(null).future);
      if (!mounted) return;

      final selected =
          returns.where((r) => wanted.contains(r.rmaNumber)).toList();
      if (selected.isEmpty) {
        ZerpaiToast.show(context, 'Could not load the selected returns.',
            isError: true);
        return;
      }

      if (selected.map((r) => r.customerId).toSet().length > 1) {
        ZerpaiToast.show(
          context,
          'Selected returns belong to different customers — convert one customer at a time.',
          isError: true,
        );
        return;
      }

      final first = selected.first;

      // Product master supplies what sales_return_items does not carry:
      // display name, HSN and rate.
      final products = ref.read(itemsControllerProvider).items;
      final productById = {
        for (final p in products)
          if (p.id != null) p.id!: p,
      };

      final items = <_SalesReturnItem>[];
      for (final r in selected) {
        for (final line in r.items) {
          final product = productById[line.productId];
          items.add(
            _SalesReturnItem(
              name: product?.productName ?? line.productId,
              description: line.remarks ?? '',
              shipped: _qtyText(line.invoicedQty),
              returned: _qtyText(line.alreadyReturnedQty),
              returnQty: _qtyText(line.returnQty),
              creditOnlyQty: _qtyText(line.creditOnlyQty),
              stock: '0 pcs',
              hsnCode: product?.hsnCode ?? '',
              rate: (product?.sellingPrice ?? 0).toStringAsFixed(2),
            )..productId = line.productId,
          );
        }
      }

      if (!mounted) return;
      setState(() {
        // The source RMA#(s) go in Reference so the new document traces back;
        // the document's own RMA# stays auto-generated (see initState).
        _referenceNumberController.text =
            selected.map((r) => r.rmaNumber).join(', ');
        _applyHeaderFields(first, items);
      });

      _applyReturnReason(first.reason);
      await _applyEditSelections(
        SalesReturnEditData(
          id: first.id,
          rmaNumber: first.rmaNumber,
          customerId: first.customerId,
          customerName: '',
          referenceNumber: first.referenceNumber ?? '',
          date: first.returnDate,
          creditOnlyGoods: first.containsCreditOnlyGoods,
          warehouseId: first.warehouseId,
          reason: first.reason ?? '',
          status: first.status,
          items: const [],
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to pre-fill sales return from RMA numbers',
          error: e, module: 'SalesReturnCreate');
      if (mounted) {
        ZerpaiToast.show(context, 'Could not load the selected returns.',
            isError: true);
      }
    }
  }

  static String _qtyText(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  /// Provider key for the selected customer, or null when none is picked.
  ({String customerId, String? excludeReturnId})? get _historyKey {
    final customerId = _selectedCustomerObj?.id ?? '';
    if (customerId.isEmpty) return null;
    return (customerId: customerId, excludeReturnId: _editingId);
  }

  /// Cached history for the selected customer, empty until it resolves.
  Map<String, CustomerItemHistory> get _customerHistory {
    final key = _historyKey;
    if (key == null) return const {};
    return ref.read(customerItemHistoryProvider(key)).valueOrNull ?? const {};
  }

  /// Fills a row's INVOICED / RETURNED cells from what this customer has been
  /// invoiced and has already sent back for that product. A product with no
  /// history reads as 0 rather than being left blank.
  void _applyHistoryToItem(
    _SalesReturnItem item,
    Map<String, CustomerItemHistory> history,
  ) {
    final productId = item.productId;
    if (productId == null || productId.isEmpty) return;
    final entry = history[productId];
    item.shipped = _qtyText(entry?.invoicedQty ?? 0);
    item.returned = _qtyText(entry?.returnedQty ?? 0);

    // The row is usually filled in before the lookup lands, and a converted
    // return can carry a quantity larger than what is still open. Pull both
    // boxes back inside the allowance now that it is known.
    final allowance = _returnableFor(item);
    if (!allowance.isFinite) return;

    final returnQty = double.tryParse(item.returnQtyController.text) ?? 0;
    if (returnQty > allowance) {
      item.returnQtyController.text = _qtyText(allowance);
    }
    final creditQty = double.tryParse(item.creditOnlyQtyController.text) ?? 0;
    final creditAllowance =
        allowance - (double.tryParse(item.returnQtyController.text) ?? 0);
    if (creditQty > creditAllowance) {
      item.creditOnlyQtyController.text = _qtyText(
        creditAllowance < 0 ? 0 : creditAllowance,
      );
    }
  }

  /// Applies the parts of a return that are identical whether it is being
  /// edited or converted: date, credit-only flag and the line set.
  ///
  /// Must be called inside a `setState`. Identity fields (RMA#, Reference) are
  /// deliberately left to the caller — they are exactly what differs between
  /// editing a document and raising a new one from it.
  void _applyHeaderFields(SalesReturn source, List<_SalesReturnItem> items) {
    _creditOnlyGoods = source.containsCreditOnlyGoods;

    final parsed = _parseEditDate(source.returnDate);
    if (parsed != null) {
      _rmaDate = parsed;
      _rmaDateController.text = DateFormat('dd-MM-yyyy').format(parsed);
    }

    if (items.isNotEmpty) {
      for (final existing in _items) {
        existing.dispose();
      }
      _items
        ..clear()
        ..addAll(items);
    }
  }

  /// Builds editable grid rows from a return's stored lines.
  ///
  /// `sales_return_items` carries no name, HSN or rate, so those come from the
  /// product master; rate is the product's current selling price.
  List<_SalesReturnItem> _itemsFromReturn(SalesReturn r) {
    final products = ref.read(itemsControllerProvider).items;
    final productById = {
      for (final p in products)
        if (p.id != null) p.id!: p,
    };

    return [
      for (final line in r.items)
        _SalesReturnItem(
          name: productById[line.productId]?.productName ?? line.productId,
          description: line.remarks ?? '',
          shipped: _qtyText(line.invoicedQty),
          returned: _qtyText(line.alreadyReturnedQty),
          returnQty: _qtyText(line.returnQty),
          creditOnlyQty: _qtyText(line.creditOnlyQty),
          stock: '0 pcs',
          hsnCode: productById[line.productId]?.hsnCode ?? '',
          rate: (productById[line.productId]?.sellingPrice ?? 0)
              .toStringAsFixed(2),
        )..productId = line.productId,
    ];
  }

  /// Loads an existing return for in-place editing.
  ///
  /// Unlike a conversion this keeps the record's own RMA# and Reference, and
  /// leaves `_editingId` set so save issues a PUT instead of a POST.
  Future<void> _loadForEdit(String id) async {
    try {
      final returns = await ref.read(salesReturnsListProvider(null).future);
      if (!mounted) return;

      final source = returns.where((r) => r.id == id).firstOrNull;
      if (source == null) {
        ZerpaiToast.show(context, 'Could not load this return for editing.',
            isError: true);
        return;
      }

      final items = _itemsFromReturn(source);
      if (!mounted) return;

      setState(() {
        _rmaNumberController.text = source.rmaNumber;
        _referenceNumberController.text = source.referenceNumber ?? '';
        _rmaAutoGenerate = false;
        _applyHeaderFields(source, items);
      });

      _applyReturnReason(source.reason);
      await _applyEditSelections(
        SalesReturnEditData(
          id: source.id,
          rmaNumber: source.rmaNumber,
          customerId: source.customerId,
          customerName: '',
          referenceNumber: source.referenceNumber ?? '',
          date: source.returnDate,
          creditOnlyGoods: source.containsCreditOnlyGoods,
          warehouseId: source.warehouseId,
          reason: source.reason ?? '',
          status: source.status,
          items: const [],
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to load sales return for editing',
          error: e, module: 'SalesReturnCreate');
      if (mounted) {
        ZerpaiToast.show(context, 'Could not load this return for editing.',
            isError: true);
      }
    }
  }

  /// Carries the source return's reason across on conversion.
  ///
  /// `sales_returns.reason` stores the text itself, so it maps straight onto the
  /// field — no lookup against a reason master, and nothing to drop when the
  /// wording does not match a predefined option.
  void _applyReturnReason(String? reasonName) {
    final name = reasonName?.trim();
    if (name == null || name.isEmpty) return;
    _reasonController.text = name;
  }

  /// Resolves the customer and warehouse for a converted return.
  ///
  /// Both masters are awaited rather than read as a snapshot: on a cold open the
  /// lists are still in flight during the first post-frame callback, and a
  /// snapshot read would silently leave the customer field blank.
  Future<void> _applyEditSelections(SalesReturnEditData edit) async {
    if (edit.customerId != null ||
        edit.customerName.isNotEmpty) {
      try {
        final customers = await ref.read(salesCustomersProvider.future);
        if (!mounted) return;

        // Match on id first — display names are not unique and are editable.
        final match = customers
                .where((c) => c.id == edit.customerId)
                .firstOrNull ??
            customers
                .where((c) => c.displayName == edit.customerName)
                .firstOrNull;

        if (match != null) {
          setState(() {
            _selectedCustomerObj = match;
            _selectedCustomer = match.displayName;
          });
        } else {
          AppLogger.warning(
            'Converted return customer not found in the customer master',
            module: 'SalesReturnCreate',
            data: {
              'customerId': edit.customerId,
              'customerName': edit.customerName,
            },
          );
        }
      } catch (e) {
        AppLogger.error('Failed to resolve customer for converted return',
            error: e, module: 'SalesReturnCreate');
      }
    }

    final warehouseId = edit.warehouseId;
    if (warehouseId != null && warehouseId.isNotEmpty) {
      try {
        final warehouses = await ref.read(salesReturnsWarehousesProvider.future);
        if (!mounted) return;
        final match = warehouses.where((w) => w.id == warehouseId).firstOrNull;
        if (match != null) setState(() => _selectedWarehouse = match);
      } catch (e) {
        AppLogger.error('Failed to resolve warehouse for converted return',
            error: e, module: 'SalesReturnCreate');
      }
    }
  }

  Future<void> _fetchNextRmaNumber() async {
    try {
      final repo = ref.read(salesReturnRepositoryProvider);
      final next = await repo.getNextRmaNumber(
        prefix: _rmaPrefixController.text,
      );
      if (mounted) {
        setState(() {
          _rmaNumberController.text = next;
          // Extract the numeric part for the next-number field
          final numPart = next.replaceAll(_rmaPrefixController.text, '');
          _rmaNextNumberController.text = numPart;
        });
      }
    } catch (_) {
      // fallback stays as RMA-00001
    }
  }

  void _addItem() {
    setState(() {
      _items.add(
        _SalesReturnItem(
          name: '',
          shipped: '0',
          returned: '0',
          returnQty: '1',
          stock: '0 pcs',
          rate: '0.00',
        ),
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      final removed = _items.removeAt(index);

      // The details panel holds a direct reference to the row, so it has to be
      // closed before the controllers behind it are disposed.
      if (_detailsItem == removed) {
        _showItemDetailsPanel = false;
        _detailsItem = null;
      }
      removed.dispose();

      // The grid always keeps one blank row so the user can pick the next item.
      if (_items.isEmpty) {
        _items.add(
          _SalesReturnItem(
            name: '',
            shipped: '0',
            returned: '0',
            returnQty: '1',
            stock: '0 pcs',
            rate: '0.00',
          ),
        );
      }
    });
  }

  void _showBulkItemsDialog() {
    final products = ref.read(itemsControllerProvider).items;
    final key = _historyKey;
    final List<Item> customerProducts;
    if (key != null) {
      final history = ref.read(customerItemHistoryProvider(key)).valueOrNull;
      if (history != null) {
        final customerProductIds = history.keys.toSet();
        customerProducts = products.where((p) {
          if (!customerProductIds.contains(p.id)) return false;
          final h = history[p.id]!;
          return (h.invoicedQty - h.returnedQty) > 0;
        }).toList();
      } else {
        customerProducts = const [];
      }
    } else {
      customerProducts = const [];
    }
    showDialog(
      context: context,
      builder: (ctx) => BulkItemsDialog(
        products: customerProducts,
        onItemsSelected: (selectedWithQty) {
          setState(() {
            _items.removeWhere((item) => item.name.isEmpty);
            for (final entry in selectedWithQty.entries) {
              _items.add(
                _SalesReturnItem(
                  name: entry.key.productName,
                  shipped: '0',
                  returned: '0',
                  returnQty: entry.value.toString(),
                  stock: '0',
                  hsnCode: entry.key.hsnCode ?? '',
                ),
              );
            }
            if (_items.isEmpty) _addItem();
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _referenceNumberController.dispose();
    _rmaNumberController.dispose();
    _rmaDateController.dispose();
    _rmaPrefixController.dispose();
    _rmaNextNumberController.dispose();
    for (var item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _updateRmaDate(DateTime date) {
    setState(() {
      _rmaDate = date;
      _rmaDateController.text = DateFormat('dd-MM-yyyy').format(date);
    });
  }

  void _openItemDetails(_SalesReturnItem item) {
    setState(() {
      _showItemDetailsPanel = true;
      _detailsItem = item;
    });
  }

  void _showRmaPreferencesDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'RMA Preferences',
      barrierColor: Colors.black54,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.zero,
          child: Material(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: _RmaPreferencesDialog(
              prefix: _rmaPrefixController.text,
              nextNumber: _rmaNextNumberController.text,
              autoGenerate: _rmaAutoGenerate,
              onSave: (prefix, nextNumber, autoGenerate) {
                setState(() {
                  _rmaAutoGenerate = autoGenerate;
                  _rmaPrefixController.text = prefix;
                  _rmaNextNumberController.text = nextNumber;
                });
                if (autoGenerate) _fetchNextRmaNumber();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSalesReturn(String status) async {
    if (_selectedCustomerObj == null || _selectedCustomerObj!.id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a customer')));
      return;
    }

    final validItems = _items
        .where((item) => item.productId != null && item.productId!.isNotEmpty)
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    for (final item in validItems) {
      final allowance = _returnableFor(item);
      final returnQty = double.tryParse(item.returnQtyController.text) ?? 0.0;
      final creditQty = double.tryParse(item.creditOnlyQtyController.text) ?? 0.0;
      if (allowance.isFinite && (returnQty + creditQty > allowance)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item "${item.name}" return quantity exceeds the invoiced quantity.',
            ),
          ),
        );
        return;
      }
    }

    final payload = CreateSalesReturnPayload(
      customerId: _selectedCustomerObj!.id,
      rmaNumber: _rmaNumberController.text.trim(),
      returnDate: DateFormat('yyyy-MM-dd').format(_rmaDate),
      warehouseId: _selectedWarehouse?.id,
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      referenceNumber: _referenceNumberController.text.trim().isEmpty
          ? null
          : _referenceNumberController.text.trim(),
      containsCreditOnlyGoods: _creditOnlyGoods,
      status: status,
      items: validItems.map((item) {
        final returnQty = double.tryParse(item.returnQtyController.text) ?? 0.0;
        final creditOnlyQty =
            double.tryParse(item.creditOnlyQtyController.text) ?? 0.0;
        final remarks = item.descriptionController.text.trim();
        // `shipped` and `returned` are loaded from invoiced_qty and
        // already_returned_qty when editing, so they must be sent back. The
        // server replaces the whole line set on update — omitting them here
        // rewrote both columns to 0 on every edit.
        return SalesReturnItem(
          productId: item.productId!,
          invoicedQty: double.tryParse(item.shipped) ?? 0.0,
          alreadyReturnedQty: double.tryParse(item.returned) ?? 0.0,
          returnQty: returnQty,
          creditOnlyQty: creditOnlyQty,
          remarks: remarks.isEmpty ? null : remarks,
        );
      }).toList(),
    );

    // Editing updates the existing row. Creating instead would reuse its RMA#
    // and violate the unique (entity_id, rma_number) index.
    final editingId = _editingId;
    final result = editingId != null
        ? await ref
            .read(salesReturnProvider.notifier)
            .updateSalesReturn(editingId, payload)
        : await ref
            .read(salesReturnProvider.notifier)
            .createSalesReturn(payload);

    if (!mounted) return;

    if (result != null) {
      ref.invalidate(salesReturnsListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'draft'
                ? 'Sales return saved as draft'
                : 'Sales return approved successfully',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      // Surface what the server actually rejected — a generic retry prompt hid
      // validation failures (bad UUID, duplicate RMA#) with no way to diagnose.
      final reason = ref.read(salesReturnProvider.notifier).lastError;

      // Try to identify which item triggered a quantity validation rejection
      // so we can highlight its field red. The backend embeds the product UUID
      // in the message: "...for product <uuid> (Invoiced: N, ...)".
      if (reason != null && reason.isNotEmpty) {
        final uuidPattern = RegExp(
          r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
          caseSensitive: false,
        );
        final uuidMatch = uuidPattern.firstMatch(reason);
        if (uuidMatch != null) {
          final failedProductId = uuidMatch.group(0);
          // Build a clean message: extract the parenthesised detail if present.
          final detailMatch = RegExp(r'\(([^)]+)\)').firstMatch(reason);
          final detail = detailMatch?.group(1);
          final cleanMsg = detail != null
              ? 'Return quantity exceeds invoiced limit. ($detail)'
              : 'Return quantity exceeds the allowed invoiced limit.';
          setState(() {
            for (final item in _items) {
              if (item.productId == failedProductId) {
                item.backendError = cleanMsg;
              }
            }
          });
        }
      }

      final displayMessage = _cleanBackendMessage(reason);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          duration: const Duration(seconds: 7),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  /// Converts a raw backend validation message into a user-facing string.
  /// Strips product UUIDs and reformats quantity details cleanly.
  String _cleanBackendMessage(String? raw) {
    if (raw == null || raw.isEmpty) {
      return 'Failed to save sales return. Please try again.';
    }
    // Extract parenthesised detail "(Invoiced: N, Already Returned: M)" if present
    final detailMatch = RegExp(r'\(([^)]+)\)').firstMatch(raw);
    if (detailMatch != null) {
      return 'Return quantity exceeds the allowed invoiced limit.\n${detailMatch.group(1)}';
    }
    // Strip any embedded UUIDs from the message before showing
    final cleaned = raw.replaceAll(
      RegExp(
        r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
        caseSensitive: false,
      ),
      '[item]',
    );
    return cleaned;
  }


  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(salesCustomersProvider);
    final customers = customersAsync.value ?? [];

    // Rows are usually picked before the lookup lands, and the customer can be
    // swapped after items are on the table. Re-applying after every frame
    // covers both; the pass is a no-op once the cells already match, so it
    // cannot loop.
    final historyKey = _historyKey;
    if (historyKey != null) {
      final history = ref
          .watch(customerItemHistoryProvider(historyKey))
          .valueOrNull;
      if (history != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          var changed = false;
          for (final item in _items) {
            final before = '${item.shipped}/${item.returned}';
            _applyHistoryToItem(item, history);
            if ('${item.shipped}/${item.returned}' != before) changed = true;
          }
          if (changed) setState(() {});
        });
      }
    }

    final products = ref.watch(itemsControllerProvider).items;
    final List<Item> customerProducts;
    if (historyKey != null) {
      final history = ref.watch(customerItemHistoryProvider(historyKey)).valueOrNull;
      if (history != null) {
        final customerProductIds = history.keys.toSet();
        customerProducts = products.where((p) => customerProductIds.contains(p.id)).toList();
      } else {
        customerProducts = const [];
      }
    } else {
      customerProducts = const [];
    }
    final warehouses = ref.watch(salesReturnsWarehousesProvider).valueOrNull ?? [];
    final srCustomerNames = customers.map((c) => c.displayName).toList();
    final srCustomerDetails = <String, _SrCustomerDropdownDetails>{
      for (final c in customers)
        c.displayName: _SrCustomerDropdownDetails(
          code: c.customerNumber ?? '',
          addressLine:
              [
                c.billingAddressCity,
                c.billingAddressZip,
              ].where((p) => p != null && p.isNotEmpty).join(', ').isNotEmpty
              ? [
                  c.billingAddressCity,
                  c.billingAddressZip,
                ].where((p) => p != null && p.isNotEmpty).join(', ')
              : c.companyName ?? c.displayName,
        ),
    };
    return Stack(
      children: [
        Container(
          color: Colors.white,
          child: ZerpaiLayout(
            pageTitle: 'New Sales Return',
            enableBodyScroll: true,
            onSave: () => _saveSalesReturn('draft'),
            useHorizontalPadding: true,
            footer: Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: MaxWidthContainer(
                maxWidth: _rowMaxWidth,
                child: Row(
                  children: [
                    ZButton.primary(
                      label: 'Save as Draft',
                      onPressed: () => _saveSalesReturn('draft'),
                    ),
                    const SizedBox(width: 12),
                    ZButton.secondary(
                      label: 'Save and Approve',
                      onPressed: () => _saveSalesReturn('approved'),
                    ),
                    const SizedBox(width: 12),
                    ZButton.secondary(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: MaxWidthContainer(
                maxWidth: _rowMaxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // --- Header Fields ---
                    _CompactFormRow(
                      label: 'Customer Name',
                      required: true,
                      fieldWidth: _selectedCustomer == null
                          ? _customerFieldWidth
                          : _rowMaxWidth - _labelWidth - _gapWidth,
                      child: Row(
                        children: [
                          SizedBox(
                            width: _customerFieldWidth,
                            child: Row(
                              children: [
                                Expanded(
                                  child: FormDropdown<String>(
                                    value: _selectedCustomer,
                                    items: srCustomerNames,
                                    hint: 'Select a customer',
                                    placeholder: 'Search',
                                    height: _fieldHeight,
                                    menuMaxHeight: 300,
                                    itemHeight: 72,
                                    displayStringForValue: (customer) =>
                                        customer,
                                    searchStringForValue: (customer) {
                                      final details =
                                          srCustomerDetails[customer];
                                      return [
                                        customer,
                                        if (details != null) details.code,
                                        if (details != null)
                                          details.addressLine,
                                      ].join(' ');
                                    },
                                    itemBuilder:
                                        (customer, isSelected, isHovered) {
                                          final details =
                                              srCustomerDetails[customer];
                                          return _SrCustomerDropdownItem(
                                            customerName: customer,
                                            customerCode:
                                                details?.code ?? 'CUS-00000',
                                            addressLine:
                                                details?.addressLine ??
                                                customer,
                                            highlighted:
                                                isSelected || isHovered,
                                          );
                                        },
                                    allowClear: true,
                                    showRightBorder: false,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCustomer = val;
                                        _selectedCustomerObj = val == null
                                            ? null
                                            : customers.firstWhere(
                                                (c) => c.displayName == val,
                                                orElse: () => SalesCustomer(
                                                  id: '',
                                                  displayName: val,
                                                ),
                                              );
                                        for (final item in _items) {
                                          item.dispose();
                                        }
                                        _items.clear();
                                        _addItem();
                                      });
                                    },
                                  ),
                                ),
                                Container(
                                  width: _fieldHeight,
                                  height: _fieldHeight,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.successGreen,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                    ),
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      LucideIcons.search,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      List<SalesCustomer> customers;
                                      try {
                                        customers = await ref.read(
                                          salesCustomersProvider.future,
                                        );
                                      } catch (_) {
                                        customers =
                                            ref
                                                .read(salesCustomersProvider)
                                                .valueOrNull ??
                                            [];
                                      }
                                      if (!mounted) return;
                                      // The modal returns the chosen customer's
                                      // display name; resolve it back to the
                                      // object to update the form.
                                      final name =
                                          await AdvancedCustomerSearchModal.show(
                                        // ignore: use_build_context_synchronously
                                        context,
                                        customers: customers,
                                      );
                                      if (!mounted || name == null) return;
                                      SalesCustomer? match;
                                      for (final c in customers) {
                                        if (c.displayName == name) {
                                          match = c;
                                          break;
                                        }
                                      }
                                      if (match == null) return;
                                      setState(() {
                                        _selectedCustomer = match!.displayName;
                                        _selectedCustomerObj = match;
                                        for (final item in _items) {
                                          item.dispose();
                                        }
                                        _items.clear();
                                        _addItem();
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedCustomer != null) ...[
                            const SizedBox(width: 12),
                            const _SrCurrencyBadge(),
                          ],
                        ],
                      ),
                    ),
                    if (_selectedCustomerObj != null) ...[
                      _SrCustomerAddressPanel(
                        customer: _selectedCustomerObj!,
                        onCustomerUpdated: (updated) =>
                            setState(() => _selectedCustomerObj = updated),
                        width: _customerFieldWidth,
                      ),
                    _CompactFormRow(
                      label: 'Reason',
                      fieldWidth: 330,
                      child: CustomTextField(
                        controller: _reasonController,
                        hintText: 'Enter reason',
                        height: _fieldHeight,
                      ),
                    ),
                    _CompactFormRow(
                      label: 'Reference#',
                      fieldWidth: 330,
                      child: CustomTextField(
                        controller: _referenceNumberController,
                        hintText: 'Enter reference number',
                        height: _fieldHeight,
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Divider(color: AppTheme.borderLight),
                    ),

                    // --- RMA Section ---
                    _CompactFormRow(
                      label: 'RMA#',
                      required: true,
                      fieldWidth: 330,
                      child: CustomTextField(
                        controller: _rmaNumberController,
                        suffixWidget: GestureDetector(
                          onTap: _showRmaPreferencesDialog,
                          child: const Icon(
                            LucideIcons.settings,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        height: _fieldHeight,
                      ),
                    ),
                    _CompactFormRow(
                      label: 'Date',
                      required: true,
                      fieldWidth: 330,
                      child: CustomTextField(
                        key: _rmaDateKey,
                        controller: _rmaDateController,
                        readOnly: true,
                        onTap: () async {
                          final picked = await ZerpaiDatePicker.show(
                            context,
                            initialDate: _rmaDate,
                            targetKey: _rmaDateKey,
                          );
                          if (picked != null) _updateRmaDate(picked);
                        },
                        suffixWidget: const Icon(
                          LucideIcons.calendar,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        height: _fieldHeight,
                      ),
                    ),
                    _CompactFormRow(
                      label: '',
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _creditOnlyGoods,
                              onChanged: (val) => setState(
                                () => _creditOnlyGoods = val ?? false,
                              ),
                              activeColor: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'This sales return contains credit-only goods',
                            style: TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 6),
                          const _HelpPopover(
                            child: Icon(
                              LucideIcons.helpCircle,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- Item Table Toolbar ---
                    _ItemTableToolbar(
                      selectedWarehouse: _selectedWarehouse,
                      warehouseOptions: warehouses,
                      onWarehouseChanged: (w) =>
                          setState(() => _selectedWarehouse = w),
                    ),
                    const SizedBox(height: 16),

                    // --- Items Grid ---
                    _SalesReturnItemsGrid(
                      items: _items,
                      products: customerProducts,
                      creditOnly: _creditOnlyGoods,
                      warehouse: _selectedWarehouse?.name,
                      warehouseOptions: warehouses,
                      onRemoveItem: _removeItem,
                      onAddItem: _addItem,
                      onAddBulkItems: _showBulkItemsDialog,
                      onItemSelected: (index) {
                        setState(
                          () => _applyHistoryToItem(
                            _items[index],
                            _customerHistory,
                          ),
                        );
                        if (index == _items.length - 1) {
                          _addItem();
                        }
                      },
                      onViewItemDetails: _openItemDetails,
                    ),
                    const SizedBox(height: 32),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: Text(
                          'Please select a customer to start entering return details.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showItemDetailsPanel && _detailsItem != null)
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: 380,
            child: _ItemDetailsSidePanel(
              item: _detailsItem!,
              onClose: () => setState(() {
                _showItemDetailsPanel = false;
                _detailsItem = null;
              }),
            ),
          ),
      ],
    );
  }
}

class _SalesReturnItem {
  String name;
  String? productId;
  String description;
  String shipped;
  String returned;
  TextEditingController returnQtyController;
  TextEditingController creditOnlyQtyController;
  TextEditingController descriptionController;
  TextEditingController rateController;
  TextEditingController discountController;
  bool discountIsPercent;
  String stock;
  String hsnCode;
  String? locationName;
  String? discount;
  String? reportingTag;
  String? account;
  String? tax;
  Map<String, String?> selectedTagValues = {};

  /// Set after a backend 400 rejection so the quantity field shows a red
  /// border with the server's validation reason.
  String? backendError;

  _SalesReturnItem({
    required this.name,
    this.description = '',
    required this.shipped,
    required this.returned,
    required String returnQty,
    String creditOnlyQty = '0',
    required this.stock,
    this.hsnCode = '',
    // ignore: unused_element_parameter
    this.discount,
    // ignore: unused_element_parameter
    this.reportingTag,
    // ignore: unused_element_parameter
    this.account,
    // ignore: unused_element_parameter
    this.tax,
    String rate = '0.00',
    String discountValue = '0',
    // ignore: unused_element_parameter
    this.discountIsPercent = true,
  }) : returnQtyController = TextEditingController(text: returnQty),
       creditOnlyQtyController = TextEditingController(text: creditOnlyQty),
       descriptionController = TextEditingController(text: description),
       rateController = TextEditingController(text: rate),
       discountController = TextEditingController(text: discountValue);

  void dispose() {
    returnQtyController.dispose();
    creditOnlyQtyController.dispose();
    descriptionController.dispose();
    rateController.dispose();
    discountController.dispose();
  }
}

/// Units still open to return on a row: invoiced minus what the customer has
/// already sent back.
///
/// Returns [double.infinity] when the product has no invoice history for this
/// customer — capping those at zero would make the row impossible to fill in,
/// and returns are raised against products with no recorded invoice today.
double _returnableFor(_SalesReturnItem item) {
  final invoiced = double.tryParse(item.shipped) ?? 0;
  if (invoiced <= 0) return double.infinity;
  final returned = double.tryParse(item.returned) ?? 0;
  final remaining = invoiced - returned;
  return remaining < 0 ? 0 : remaining;
}



/// Custom Compact Form Row with Overflow Fixes
class _CompactFormRow extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final double? fieldWidth;

  const _CompactFormRow({
    required this.label,
    this.required = false,
    required this.child,
    this.fieldWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: label.isEmpty
                ? const SizedBox.shrink()
                : RichText(
                    text: TextSpan(
                      text: label,
                      style: TextStyle(
                        fontSize: 13,
                        color: required
                            ? AppTheme.errorRed
                            : AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        if (required)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: fieldWidth ?? 434, child: child),
        ],
      ),
    );
  }
}

class _HelpPopover extends StatefulWidget {
  final Widget child;
  const _HelpPopover({required this.child});

  @override
  State<_HelpPopover> createState() => _HelpPopoverState();
}

class _HelpPopoverState extends State<_HelpPopover> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();

  void _togglePopover() {
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
    } else {
      _entry = _createOverlayEntry();
      Overlay.of(context).insert(_entry!);
    }
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePopover,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: 280,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.topRight,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(10, -40),
              child: Material(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBulletRow(
                            'Enable this option if your sales return contains items that are damaged or expired.',
                          ),
                          const SizedBox(height: 12),
                          _buildBulletRow(
                            'The quantity specified under this category will not be brought back into stock.',
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -8,
                      top: 40,
                      child: CustomPaint(
                        size: const Size(8, 12),
                        painter: _PopoverArrowPainter(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 6, color: Colors.black),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(onTap: _togglePopover, child: widget.child),
    );
  }
}

class _WarehouseStockPopover extends StatefulWidget {
  final Widget child;
  final String currentWarehouse;
  final ValueChanged<String> onWarehouseSelected;

  const _WarehouseStockPopover({
    required this.child,
    required this.currentWarehouse,
    required this.onWarehouseSelected,
  });

  @override
  State<_WarehouseStockPopover> createState() => _WarehouseStockPopoverState();
}

class _WarehouseStockPopoverState extends State<_WarehouseStockPopover> {
  OverlayEntry? _entry;
  bool _isAccountingStock = true;
  String _selectedView = 'Available for Sale';
  final LayerLink _layerLink = LayerLink();

  void _togglePopover() {
    if (_entry != null) {
      _removePopover();
    } else {
      _entry = _createOverlayEntry();
      Overlay.of(context).insert(_entry!);
      setState(() {});
    }
  }

  void _removePopover() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setOverlayState) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removePopover,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.black.withValues(alpha: 0.1)),
              ),
            ),
            Positioned(
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topRight,
                followerAnchor: Alignment.bottomRight,
                offset: const Offset(0, -8),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  child: SizedBox(
                    width: 750,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                            child: Row(
                              children: [
                                const Text(
                                  'Warehouse Locations',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                const Text(
                                  'View: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  initialValue: _selectedView,
                                  onSelected: (val) {
                                    setOverlayState(() => _selectedView = val);
                                  },
                                  itemBuilder: (context) =>
                                      [
                                            'Available for Sale',
                                            'Stock on Hand',
                                            'Commited Stock',
                                          ]
                                          .map(
                                            (v) => PopupMenuItem(
                                              value: v,
                                              child: Text(
                                                v,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.borderColor,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          _selectedView,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Toggle
                                Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.primaryBlue,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => setOverlayState(
                                          () => _isAccountingStock = true,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _isAccountingStock
                                                ? AppTheme.primaryBlue
                                                : Colors.white,
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                  left: Radius.circular(3),
                                                ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Accounting Stock',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _isAccountingStock
                                                  ? Colors.white
                                                  : AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => setOverlayState(
                                          () => _isAccountingStock = false,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: !_isAccountingStock
                                                ? AppTheme.primaryBlue
                                                : Colors.white,
                                            borderRadius:
                                                const BorderRadius.horizontal(
                                                  right: Radius.circular(3),
                                                ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            'Physical Stock',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: !_isAccountingStock
                                                  ? Colors.white
                                                  : AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: _removePopover,
                                  icon: const Icon(
                                    Icons.close,
                                    size: 20,
                                    color: AppTheme.errorRed,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderColor),
                          // Table Header
                          Container(
                            color: const Color(0xFFF9FAFB),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: const [
                                          Text(
                                            'Location Name ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          Icon(
                                            Icons.search,
                                            size: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(
                                    width: 1,
                                    color: AppTheme.borderColor,
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      children: [
                                        Container(
                                          height: 32,
                                          alignment: Alignment.center,
                                          child: Text(
                                            _isAccountingStock
                                                ? 'Accounting Stock'
                                                : 'Physical Stock',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                        const Divider(
                                          height: 1,
                                          color: AppTheme.borderColor,
                                        ),
                                        IntrinsicHeight(
                                          child: Row(
                                            children: [
                                              _buildSubHeader('Stock on Hand'),
                                              const VerticalDivider(
                                                width: 1,
                                                color: AppTheme.borderColor,
                                              ),
                                              _buildSubHeader(
                                                'Committed Stock',
                                              ),
                                              const VerticalDivider(
                                                width: 1,
                                                color: AppTheme.borderColor,
                                              ),
                                              _buildSubHeader(
                                                'Available for Sale',
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
                          const Divider(height: 1, color: AppTheme.borderColor),
                          // Table Rows
                          _buildRow(
                            'ZABNIX PRIVATE LIMITED',
                            '13.00',
                            '51.00',
                            '-38.00',
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildRow(
                            'DEMO WAREHOUSE 1 (Warehouse)',
                            '2.00',
                            '5.00',
                            '-3.00',
                          ),
                          const SizedBox(height: 24),
                          // Footer Notes
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Stock on Hand : This is calculated based on Bills and Invoices.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Committed Stock : Stock that is committed to sales order(s) but not yet invoiced',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Available for Sale : Stock on Hand - Committed Stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubHeader(String label) {
    return Expanded(
      child: Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildRow(
    String name,
    String soh,
    String committed,
    String available,
  ) {
    final bool isSelected = widget.currentWarehouse == name;
    return InkWell(
      onTap: () {
        widget.onWarehouseSelected(name);
        _removePopover();
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textDisabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      soh,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      committed,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      available,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(onTap: _togglePopover, child: widget.child),
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SrGridHeader extends StatelessWidget {
  final String label;
  final bool center;

  const _SrGridHeader({required this.label, this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _SalesReturnItemsGrid extends StatefulWidget {
  final bool creditOnly;
  final String? warehouse;
  final List<Warehouse> warehouseOptions;
  final List<_SalesReturnItem> items;
  final List<Item> products;
  final VoidCallback onAddItem;
  final VoidCallback onAddBulkItems;
  final Function(int) onRemoveItem;
  final Function(int) onItemSelected;
  final Function(_SalesReturnItem) onViewItemDetails;

  const _SalesReturnItemsGrid({
    required this.creditOnly,
    required this.warehouse,
    required this.warehouseOptions,
    required this.items,
    required this.products,
    required this.onAddItem,
    required this.onAddBulkItems,
    required this.onRemoveItem,
    required this.onItemSelected,
    required this.onViewItemDetails,
  });

  @override
  State<_SalesReturnItemsGrid> createState() => _SalesReturnItemsGridState();
}

class _SalesReturnItemsGridState extends State<_SalesReturnItemsGrid> {
  Widget _buildAddRowButton() {
    return InkWell(
      onTap: widget.onAddItem,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.plusCircle,
              size: 18,
              color: AppTheme.primaryBlueDark,
            ),
            SizedBox(width: 8),
            Text(
              'Add New Row',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkAddButton() {
    return InkWell(
      onTap: widget.onAddBulkItems,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.plusCircle,
              size: 18,
              color: AppTheme.primaryBlueDark,
            ),
            SizedBox(width: 8),
            Text(
              'Add Items in Bulk',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildInfoItem(
    IconData icon,
    String label,
    List<String> items,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppTheme.borderLight),
      ),
      color: Colors.white,
      elevation: 4,
      tooltip: '',
      onSelected: onSelected,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            LucideIcons.chevronDown,
            size: 12,
            color: AppTheme.textSecondary,
          ),
        ],
      ),
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bs = BorderSide(color: AppTheme.borderLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // â”€â”€ HEADER â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        _HoverableRowSlot(
          showX: false,
          onDelete: null,
          content: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: AppTheme.tableHeaderBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: const _SrGridHeader(label: 'ITEMS & DESCRIPTION'),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Container(
                    width: 160,
                    color: AppTheme.tableHeaderBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    alignment: Alignment.center,
                    child: const _SrGridHeader(label: 'INVOICED', center: true),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Container(
                    width: 140,
                    color: AppTheme.tableHeaderBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    alignment: Alignment.center,
                    child: const _SrGridHeader(label: 'RETURNED', center: true),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  if (widget.creditOnly)
                    Container(
                      width: 260,
                      color: AppTheme.tableHeaderBg,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: const _SrGridHeader(
                              label: 'RETURN DETAILS',
                              center: true,
                            ),
                          ),
                          const Divider(height: 1, color: AppTheme.borderLight),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: const _SrGridHeader(
                                      label: 'RECEIVABLE\nQUANTITY',
                                      center: true,
                                    ),
                                  ),
                                ),
                                const VerticalDivider(
                                  width: 1,
                                  color: AppTheme.borderLight,
                                ),
                                Expanded(
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const _SrGridHeader(
                                          label: 'CREDIT-ONLY ',
                                          center: true,
                                        ),
                                        ZTooltip(
                                          message:
                                              'The quantity specified under this category will not be received. You can only provide credits.',
                                          child: const Icon(
                                            LucideIcons.helpCircle,
                                            size: 14,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 200,
                      color: AppTheme.tableHeaderBg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      alignment: Alignment.centerRight,
                      child: widget.warehouse != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const _SrGridHeader(label: 'RETURN QUANTITY'),
                                const SizedBox(height: 2),
                                Text(
                                  widget.warehouse!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            )
                          : const _SrGridHeader(label: 'RETURN QUANTITY'),
                    ),
                ],
              ),
            ),
          ),
        ),

        // â”€â”€ DATA ROWS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        ...List.generate(widget.items.length, (index) {
          final item = widget.items[index];
          final bool hasItem = item.name.isNotEmpty;
          return _HoverableRowSlot(
            // A row with an item selected is always removable, including the
            // first one; blank spare rows only expose the icon on hover.
            showX: hasItem || index != 0,
            alwaysShowX: hasItem,
            onDelete: () => widget.onRemoveItem(index),
            content: Container(
              decoration: BoxDecoration(
                border: Border(left: bs, right: bs, bottom: bs),
              ),
              child: _ItemRowWidget(
                item: item,
                warehouse: widget.warehouse,
                warehouseOptions: widget.warehouseOptions,
                creditOnly: widget.creditOnly,
                products: widget.products,
                onItemSelected: () => widget.onItemSelected(index),
              ),
            ),
          );
        }),

        // â”€â”€ TABLE BOTTOM CAP â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        // Right inset matches the row-action gutter so the cap stays flush with
        // the table borders above it.
        Padding(
          padding: const EdgeInsets.only(right: _kRowActionSlotWidth),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: bs, right: bs, bottom: bs),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            height: 4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildAddRowButton(),
            const SizedBox(width: 12),
            _buildBulkAddButton(),
          ],
        ),
      ],
    );
  }
}

/// Width of the action gutter kept to the right of the items grid. The close
/// icon lives here so it sits outside the table instead of inside a column.
const double _kRowActionSlotWidth = 36.0;

class _HoverableRowSlot extends StatefulWidget {
  final Widget content;

  /// Whether this row can be removed at all (the header row cannot).
  final bool showX;

  /// Keeps the icon visible without hovering — used for rows that already have
  /// an item selected, so the remove affordance is always discoverable.
  final bool alwaysShowX;
  final VoidCallback? onDelete;

  const _HoverableRowSlot({
    required this.content,
    required this.showX,
    this.alwaysShowX = false,
    this.onDelete,
  });

  @override
  State<_HoverableRowSlot> createState() => _HoverableRowSlotState();
}

class _HoverableRowSlotState extends State<_HoverableRowSlot> {
  bool _isHovered = false;
  bool _iconHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool showIcon =
        widget.showX &&
        widget.onDelete != null &&
        (widget.alwaysShowX || _isHovered);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _iconHovered = false;
      }),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: widget.content),
            SizedBox(
              width: _kRowActionSlotWidth,
              child: showIcon
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _buildRemoveButton(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoveButton() {
    return ZTooltip(
      message: 'Remove this item from the table',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _iconHovered = true),
        onExit: (_) => setState(() => _iconHovered = false),
        child: GestureDetector(
          onTap: widget.onDelete,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _iconHovered
                  ? AppTheme.errorRed.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              LucideIcons.x,
              size: 16,
              color: _iconHovered ? AppTheme.errorRed : AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemRowWidget extends StatefulWidget {
  final _SalesReturnItem item;
  final String? warehouse;
  final List<Warehouse> warehouseOptions;
  final bool creditOnly;
  final List<Item> products;
  final VoidCallback? onItemSelected;

  const _ItemRowWidget({
    required this.item,
    required this.warehouse,
    required this.warehouseOptions,
    required this.creditOnly,
    required this.products,
    this.onItemSelected,
  });

  @override
  State<_ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<_ItemRowWidget> {
  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final allowance = _returnableFor(item);
    final returnQty = double.tryParse(item.returnQtyController.text) ?? 0.0;
    final creditQty = double.tryParse(item.creditOnlyQtyController.text) ?? 0.0;
    final isQtyInvalid = allowance.isFinite && (returnQty + creditQty > allowance);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ITEMS & DESCRIPTION
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: item.name.isEmpty
                  ? FormDropdown<String>(
                      value: null,
                      items: widget.products
                          .take(10)
                          .map((p) => p.productName)
                          .toList(),
                      hint: 'Type or click to select an item.',
                      height: _SalesReturnsCreatePageState._tableFieldHeight,
                      hideBorderDefault: true,
                      onChanged: (val) {
                        if (val != null) {
                          final matched = widget.products.firstWhere(
                            (p) => p.productName == val,
                            orElse: () => widget.products.first,
                          );
                          setState(() {
                            item.name = val;
                            item.productId = matched.id;
                            item.rateController.text =
                                matched.sellingPrice?.toStringAsFixed(2) ??
                                '0.00';
                            item.hsnCode = matched.hsnCode ?? '';
                          });
                          widget.onItemSelected?.call();
                        }
                      },
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (item.descriptionController.text.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.descriptionController.text,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // INVOICED â€” read-only, centered
          SizedBox(
            width: 160,
            child: Center(
              child: Text(
                item.shipped,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // RETURNED â€” read-only, centered
          SizedBox(
            width: 140,
            child: Center(
              child: Text(
                item.returned,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.borderLight),
          // RETURN QUANTITY / RETURN DETAILS
          if (widget.creditOnly)
            SizedBox(
              width: 260,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomTextField(
                            controller: item.returnQtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (val) {
                              setState(() {
                                item.backendError = null;
                              });
                              widget.onItemSelected?.call();
                            },
                            errorText: item.backendError ?? (isQtyInvalid ? 'Exceeds invoiced qty' : null),
                            textAlign: TextAlign.right,
                            hideBorderDefault: !isQtyInvalid && item.backendError == null,
                            height: 32,
                            contentCase: ContentCase.none,
                          ),
                          const SizedBox(height: 4),
                          Builder(
                            builder: (btnCtx) => GestureDetector(
                              onTap: () {
                                const dialogWidth = 420.0;
                                final box =
                                    btnCtx.findRenderObject() as RenderBox;
                                final triggerPos = box.localToGlobal(
                                  Offset.zero,
                                );
                                final triggerSize = box.size;
                                final screen = MediaQuery.of(btnCtx).size;

                                double left =
                                    triggerPos.dx +
                                    triggerSize.width -
                                    dialogWidth;
                                if (left < 8) left = 8;
                                if (left + dialogWidth > screen.width - 8) {
                                  left = screen.width - dialogWidth - 8;
                                }
                                double top =
                                    triggerPos.dy + triggerSize.height + 6;
                                if (top + 220 > screen.height - 8) {
                                  top = triggerPos.dy - 220 - 6;
                                }

                                showGeneralDialog<void>(
                                  context: btnCtx,
                                  barrierDismissible: true,
                                  barrierLabel: '',
                                  barrierColor: Colors.transparent,
                                  transitionDuration: Duration.zero,
                                  pageBuilder: (ctx, _, __) => Stack(
                                    children: [
                                      Positioned(
                                        left: left,
                                        top: top,
                                        width: dialogWidth,
                                        child: Material(
                                          color: Colors.transparent,
                                          child: _WarehouseLocationsForm(
                                            warehouses: widget.warehouseOptions,
                                            onLocationSelected: (name) {
                                              setState(
                                                () => item.locationName = name,
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Icon(
                                    LucideIcons.warehouse,
                                    size: 13,
                                    color: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.locationName ??
                                          widget.warehouse ??
                                          'Select warehouse',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            (item.locationName ??
                                                    widget.warehouse) !=
                                                null
                                            ? AppTheme.primaryBlue
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: item.creditOnlyQtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (val) {
                              setState(() {
                                item.backendError = null;
                              });
                              widget.onItemSelected?.call();
                            },
                            errorText: item.backendError ?? (isQtyInvalid ? 'Exceeds invoiced qty' : null),
                            textAlign: TextAlign.right,
                            hideBorderDefault: !isQtyInvalid && item.backendError == null,
                            height: 32,
                            contentCase: ContentCase.none,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomTextField(
                      controller: item.returnQtyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (val) {
                        setState(() {
                          item.backendError = null;
                        });
                        widget.onItemSelected?.call();
                      },
                      errorText: item.backendError ?? (isQtyInvalid ? 'Exceeds invoiced qty' : null),
                      textAlign: TextAlign.right,
                      hideBorderDefault: !isQtyInvalid && item.backendError == null,
                      height: 32,
                      contentCase: ContentCase.none,
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (btnCtx) => GestureDetector(
                        onTap: () {
                          const dialogWidth = 420.0;
                          final box = btnCtx.findRenderObject() as RenderBox;
                          final triggerPos = box.localToGlobal(Offset.zero);
                          final triggerSize = box.size;
                          final screen = MediaQuery.of(btnCtx).size;

                          double left =
                              triggerPos.dx + triggerSize.width - dialogWidth;
                          if (left < 8) left = 8;
                          if (left + dialogWidth > screen.width - 8) {
                            left = screen.width - dialogWidth - 8;
                          }
                          double top = triggerPos.dy + triggerSize.height + 6;
                          if (top + 220 > screen.height - 8) {
                            top = triggerPos.dy - 220 - 6;
                          }

                          showGeneralDialog<void>(
                            context: btnCtx,
                            barrierDismissible: true,
                            barrierLabel: '',
                            barrierColor: Colors.transparent,
                            transitionDuration: Duration.zero,
                            pageBuilder: (ctx, _, __) => Stack(
                              children: [
                                Positioned(
                                  left: left,
                                  top: top,
                                  width: dialogWidth,
                                  child: Material(
                                    color: Colors.transparent,
                                    child: _WarehouseLocationsForm(
                                      warehouses: widget.warehouseOptions,
                                      onLocationSelected: (name) {
                                        setState(
                                          () => item.locationName = name,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              LucideIcons.warehouse,
                              size: 13,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                item.locationName ??
                                    widget.warehouse ??
                                    'Select warehouse',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      (item.locationName ?? widget.warehouse) !=
                                          null
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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

class _ItemDetailsSidePanel extends StatefulWidget {
  final _SalesReturnItem item;
  final VoidCallback onClose;

  const _ItemDetailsSidePanel({required this.item, required this.onClose});

  @override
  State<_ItemDetailsSidePanel> createState() => _ItemDetailsSidePanelState();
}

class _ItemDetailsSidePanelState extends State<_ItemDetailsSidePanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(left: BorderSide(color: AppTheme.borderLight)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: widget.onClose,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.errorRed),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Item card
          Container(
            color: const Color(0xFFEFF6FF),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: const Icon(
                    LucideIcons.image,
                    size: 28,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Inventory Items',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.item.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.externalLink,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'pcs',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                _PanelTabButton(
                  label: 'ITEM DETAILS',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _PanelTabButton(
                  label: 'STOCK LOCATIONS',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                _PanelTabButton(
                  label: 'TRANSACTIONS',
                  selected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _tab == 0
                  ? _buildItemDetailsTab()
                  : _tab == 1
                  ? _buildStockLocationsTab()
                  : _buildTransactionsTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelSectionHeading('Sales Information'),
        const SizedBox(height: 12),
        const _PanelDetailRow(label: 'Price', value: 'Ã¢â€šÂ¹115.00'),
        const SizedBox(height: 8),
        const _PanelDetailRow(label: 'Account', value: 'Sales'),
        const SizedBox(height: 24),
        const _PanelSectionHeading('Purchase Information'),
        const SizedBox(height: 12),
        const _PanelDetailRow(label: 'Price', value: 'Ã¢â€šÂ¹100.00'),
        const SizedBox(height: 8),
        const _PanelDetailRow(label: 'Account', value: 'Cost of Goods Sold'),
        const SizedBox(height: 24),
        const _PanelSectionHeading('Other Details'),
      ],
    );
  }

  Widget _buildStockLocationsTab() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          'No stock location data available.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          'No transactions available.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _PanelTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PanelTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: selected ? AppTheme.primaryBlue : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PanelSectionHeading extends StatelessWidget {
  final String text;
  const _PanelSectionHeading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}

class _PanelDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _PanelDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Item Table Toolbar â€” above the items grid
// ---------------------------------------------------------------------------

class _ItemTableToolbar extends StatelessWidget {
  const _ItemTableToolbar({
    required this.selectedWarehouse,
    required this.warehouseOptions,
    required this.onWarehouseChanged,
  });

  final Warehouse? selectedWarehouse;
  final List<Warehouse> warehouseOptions;
  final ValueChanged<Warehouse?> onWarehouseChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Warehouse location - left side
          const Text(
            'Warehouse Location',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: FormDropdown<Warehouse>(
              value: selectedWarehouse,
              items: warehouseOptions,
              hint: 'Select Warehouse',
              height: 36,
              hideBorderDefault: true,
              allowClear: true,
              displayStringForValue: (w) => w.name,
              searchStringForValue: (w) => w.name,
              onChanged: onWarehouseChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _RmaPreferencesDialog extends StatefulWidget {
  final String prefix;
  final String nextNumber;
  final bool autoGenerate;
  final void Function(String prefix, String nextNumber, bool autoGenerate)
  onSave;

  const _RmaPreferencesDialog({
    required this.prefix,
    required this.nextNumber,
    required this.autoGenerate,
    required this.onSave,
  });

  @override
  State<_RmaPreferencesDialog> createState() => _RmaPreferencesDialogState();
}

class _RmaPreferencesDialogState extends State<_RmaPreferencesDialog> {
  late bool _autoGenerate;
  late final TextEditingController _prefixController;
  late final TextEditingController _nextNumberController;

  @override
  void initState() {
    super.initState();
    _autoGenerate = widget.autoGenerate;
    _prefixController = TextEditingController(text: widget.prefix);
    _nextNumberController = TextEditingController(text: widget.nextNumber);
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _nextNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 560,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Configure RMA Number Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.errorRed),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Location / Series table
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Associated Series',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'ZABNIX PRIVATE LIMITED',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Default Transaction Series',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Info text
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Your RMA numbers are set on auto-generate mode to save your time.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Are you sure about changing this setting?',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Radio options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option 1: Auto-generate
                InkWell(
                  onTap: () => setState(() => _autoGenerate = true),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        // ignore: deprecated_member_use
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        // ignore: deprecated_member_use
                        onChanged: (val) =>
                            setState(() => _autoGenerate = val ?? true),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text(
                        'Continue auto-generating RMA numbers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        LucideIcons.info,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
                if (_autoGenerate)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, top: 8, bottom: 8),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prefix',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 120,
                              child: CustomTextField(
                                controller: _prefixController,
                                height: 32,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Number',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 220,
                              child: CustomTextField(
                                controller: _nextNumberController,
                                height: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Option 2: Manual
                InkWell(
                  onTap: () => setState(() => _autoGenerate = false),
                  child: Row(
                    children: [
                      Radio<bool>(
                        value: false,
                        // ignore: deprecated_member_use
                        groupValue: _autoGenerate,
                        activeColor: AppTheme.primaryBlue,
                        // ignore: deprecated_member_use
                        onChanged: (val) =>
                            setState(() => _autoGenerate = val ?? false),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text(
                        'Enter RMA numbers manually',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Row(
              children: [
                ZButton.primary(
                  label: 'Save',
                  onPressed: () {
                    widget.onSave(
                      _prefixController.text,
                      _nextNumberController.text,
                      _autoGenerate,
                    );
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MaxWidthContainer extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidthContainer({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class _BulkMenuHoverItem extends StatefulWidget {
  final String label;
  const _BulkMenuHoverItem({required this.label});

  @override
  State<_BulkMenuHoverItem> createState() => _BulkMenuHoverItemState();
}

class _BulkMenuHoverItemState extends State<_BulkMenuHoverItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _hovered ? const Color(0xFFEEF2FF) : Colors.transparent,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            color: _hovered ? AppTheme.primaryBlue : AppTheme.textPrimary,
            fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _BulkUpdateActionButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool hasDropdown;
  final VoidCallback onTap;
  final VoidCallback? onDropdownTap;

  const _BulkUpdateActionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    // ignore: unused_element_parameter
    this.hasDropdown = false,
    // ignore: unused_element_parameter
    this.onDropdownTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isSelected
        ? Border.all(color: AppTheme.primaryBlue, width: 2)
        : null;

    if (!hasDropdown) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.successGreen,
            borderRadius: BorderRadius.circular(6),
            border: border,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    // Split button: label on left, vertical divider, chevron on right
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.successGreen,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              color: Colors.transparent,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 30, color: Colors.white.withAlpha(100)),
          GestureDetector(
            onTap: onDropdownTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              color: Colors.transparent,
              child: const Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulkUpdateLineItemsDialog extends StatefulWidget {
  // ignore: unused_element_parameter
  const _BulkUpdateLineItemsDialog({super.key});

  @override
  State<_BulkUpdateLineItemsDialog> createState() =>
      _BulkUpdateLineItemsDialogState();
}

class _BulkUpdateLineItemsDialogState
    extends State<_BulkUpdateLineItemsDialog> {
  String? _selectedAdgf = 'None';
  String? _selectedShedule = 'None';
  String? _selectedDemoTag = 'None';

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SizedBox(width: 600, child: _buildContent(context)),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bulk Update Line Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.errorRed),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    size: 14,
                    color: AppTheme.errorRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select an option in the reporting tags to update them for all the selected line items.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADGF',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<String>(
                      value: _selectedAdgf,
                      items: const ['None', 'Option 1', 'Option 2'],
                      hint: 'None',
                      height: 36,
                      onChanged: (val) => setState(() => _selectedAdgf = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'shedule',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormDropdown<String>(
                      value: _selectedShedule,
                      items: const ['None', 'Option 1', 'Option 2'],
                      hint: 'None',
                      height: 36,
                      onChanged: (val) =>
                          setState(() => _selectedShedule = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'demo adavced reporting tag',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 280,
                child: FormDropdown<String>(
                  value: _selectedDemoTag,
                  items: const ['None', 'Option 1', 'Option 2'],
                  hint: 'None',
                  height: 36,
                  onChanged: (val) => setState(() => _selectedDemoTag = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Note: Only the reporting tags you select will be updated in the line items. Other tags will not be updated.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: AppTheme.textPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulkUpdateAccountDialog extends StatefulWidget {
  // ignore: unused_element_parameter
  const _BulkUpdateAccountDialog({super.key});

  @override
  State<_BulkUpdateAccountDialog> createState() =>
      _BulkUpdateAccountDialogState();
}

class _BulkUpdateAccountDialogState extends State<_BulkUpdateAccountDialog> {
  String? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SizedBox(
        width: 600,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bulk Update Line Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.errorRed),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Select an account for the selected line items.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              // Form Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose Account',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 280,
                    child: FormDropdown<String>(
                      value: _selectedAccount,
                      items: const [
                        'Select an account',
                        'Account 1',
                        'Account 2',
                      ],
                      hint: 'Select an account',
                      height: 36,
                      onChanged: (val) =>
                          setState(() => _selectedAccount = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Success green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF374151),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
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
      ),
    );
  }
}

class _BulkUpdateDiscountAccountDialog extends StatefulWidget {
  // ignore: unused_element_parameter
  const _BulkUpdateDiscountAccountDialog({super.key});

  @override
  State<_BulkUpdateDiscountAccountDialog> createState() =>
      _BulkUpdateDiscountAccountDialogState();
}

class _BulkUpdateDiscountAccountDialogState
    extends State<_BulkUpdateDiscountAccountDialog> {
  int _selectedValue = 0; // 0 for same account, 1 for choose account
  String? _selectedAccount;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SizedBox(
        width: 600,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bulk Update Line Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.errorRed),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose a discount account for the selected line items.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              // Radio Buttons
              Row(
                children: [
                  Radio<int>(
                    value: 0,
                    // ignore: deprecated_member_use
                    groupValue: _selectedValue,
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => _selectedValue = val!),
                    activeColor: AppTheme.primaryBlue,
                  ),
                  const Text(
                    "Use the same account as each item's sales account",
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  Radio<int>(
                    value: 1,
                    // ignore: deprecated_member_use
                    groupValue: _selectedValue,
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => _selectedValue = val!),
                    activeColor: AppTheme.primaryBlue,
                  ),
                  const Text(
                    "Choose Account",
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              if (_selectedValue == 1) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: SizedBox(
                    width: 280,
                    child: FormDropdown<String>(
                      value: _selectedAccount,
                      items: const [
                        'Select an account',
                        'Account 1',
                        'Account 2',
                      ],
                      hint: 'Select an account',
                      height: 36,
                      onChanged: (val) =>
                          setState(() => _selectedAccount = val),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Success green
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF374151),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancel',
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
      ),
    );
  }
}

// ignore: unused_element
class _ReportingTagsForm extends StatelessWidget {
  const _ReportingTagsForm();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 650,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Reporting Tags',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ADGF',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FormDropdown<String>(
                            value: 'None',
                            items: const ['None', 'Option 1', 'Option 2'],
                            hint: 'None',
                            height: 36,
                            onChanged: (val) {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'shedule',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FormDropdown<String>(
                            value: 'None',
                            items: const ['None', 'Option 1', 'Option 2'],
                            hint: 'None',
                            height: 36,
                            onChanged: (val) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'demo adavced reporting tag',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 280,
                      child: FormDropdown<String>(
                        value: 'None',
                        items: const ['None', 'Option 1', 'Option 2'],
                        hint: 'None',
                        height: 36,
                        onChanged: (val) {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Success green
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF374151),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarehouseLocationsForm extends StatefulWidget {
  final List<Warehouse> warehouses;
  final ValueChanged<String> onLocationSelected;

  const _WarehouseLocationsForm({
    required this.warehouses,
    required this.onLocationSelected,
  });

  @override
  State<_WarehouseLocationsForm> createState() =>
      _WarehouseLocationsFormState();
}

class _WarehouseLocationsFormState extends State<_WarehouseLocationsForm> {
  String? _selectedLocation;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.warehouses
        .where((w) => w.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Text(
                  'Warehouse Locations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.errorRed, width: 1.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      LucideIcons.x,
                      size: 14,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search location',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No warehouses found',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: filtered
                      .map(
                        (w) => RadioListTile<String>(
                          value: w.name,
                          // ignore: deprecated_member_use
                          groupValue: _selectedLocation,
                          // ignore: deprecated_member_use
                          onChanged: (val) {
                            setState(() => _selectedLocation = val);
                            widget.onLocationSelected(val!);
                            Navigator.of(context).pop();
                          },
                          activeColor: AppTheme.primaryBlue,
                          title: Text(
                            w.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Customer Dropdown Data â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SrCustomerDropdownDetails {
  final String code;
  final String addressLine;

  const _SrCustomerDropdownDetails({
    required this.code,
    required this.addressLine,
  });
}

// â”€â”€â”€ Customer Dropdown Item Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SrCustomerDropdownItem extends StatelessWidget {
  final String customerName;
  final String customerCode;
  final String addressLine;
  final bool highlighted;

  const _SrCustomerDropdownItem({
    required this.customerName,
    required this.customerCode,
    required this.addressLine,
    required this.highlighted,
  });

  String get _initial {
    final trimmed = customerName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = highlighted
        ? AppTheme.backgroundColor
        : AppTheme.textBody;
    final secondaryColor = highlighted
        ? AppTheme.backgroundColor
        : AppTheme.textSecondary;

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: highlighted ? AppTheme.primaryBlue : AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.bgDisabled,
              shape: BoxShape.circle,
              border: highlighted
                  ? Border.all(color: AppTheme.backgroundColor, width: 1.5)
                  : null,
            ),
            child: Text(
              _initial,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '|',
                        style: TextStyle(fontSize: 14, color: secondaryColor),
                      ),
                    ),
                    Text(
                      customerCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      LucideIcons.building2,
                      size: 14,
                      color: secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        addressLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: secondaryColor,
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
    );
  }
}

// â”€â”€â”€ Currency Badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SrCurrencyBadge extends StatelessWidget {
  const _SrCurrencyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _SalesReturnsCreatePageState._fieldHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.badgeDollarSign,
            size: 16,
            color: AppTheme.successGreen,
          ),
          SizedBox(width: 6),
          Text(
            'INR',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Customer Details Tag â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SrCustomerAddressPanel extends ConsumerStatefulWidget {
  final SalesCustomer customer;
  final ValueChanged<SalesCustomer>? onCustomerUpdated;
  final double? width;

  const _SrCustomerAddressPanel({
    required this.customer,
    this.onCustomerUpdated,
    this.width,
  });

  @override
  ConsumerState<_SrCustomerAddressPanel> createState() =>
      _SrCustomerAddressPanelState();
}

class _SrCustomerAddressPanelState
    extends ConsumerState<_SrCustomerAddressPanel> {
  bool get _hasBilling =>
      widget.customer.billingAddressStreet1?.isNotEmpty == true ||
      widget.customer.billingAddressCity?.isNotEmpty == true;

  bool get _hasShipping =>
      widget.customer.shippingAddressStreet1?.isNotEmpty == true ||
      widget.customer.shippingAddressCity?.isNotEmpty == true;

  List<String> get _billingLines => [
    widget.customer.billingAddressStreet1,
    widget.customer.billingAddressStreet2,
    widget.customer.billingAddressCity,
    widget.customer.billingAddressZip,
    if (widget.customer.billingAddressPhone?.isNotEmpty == true)
      'Ph: ${widget.customer.billingAddressPhone}',
  ].where((s) => s != null && s.isNotEmpty).cast<String>().toList();

  List<String> get _shippingLines => [
    widget.customer.shippingAddressStreet1,
    widget.customer.shippingAddressStreet2,
    widget.customer.shippingAddressCity,
    widget.customer.shippingAddressZip,
    if (widget.customer.shippingAddressPhone?.isNotEmpty == true)
      'Ph: ${widget.customer.shippingAddressPhone}',
  ].where((s) => s != null && s.isNotEmpty).cast<String>().toList();

  void _openDialog({required bool isBilling}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _SrAddressFormDialog(
        isBilling: isBilling,
        customer: widget.customer,
        onSaved: (updated) {
          widget.onCustomerUpdated?.call(updated);
          ref.invalidate(salesCustomersProvider);
        },
      ),
    );
  }

  Widget _buildAddressColumn({
    required String title,
    required bool hasAddress,
    required List<String> lines,
    required bool isBilling,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            if (hasAddress) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _openDialog(isBilling: isBilling),
                child: const Icon(
                  LucideIcons.pencil,
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        if (!hasAddress)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _openDialog(isBilling: isBilling),
              child: const Text(
                'New Address',
                style: TextStyle(fontSize: 13, color: AppTheme.primaryBlue),
              ),
            ),
          )
        else ...[
          Text(
            widget.customer.displayName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 166, bottom: 8, top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: widget.width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAddressColumn(
                  title: 'BILLING ADDRESS',
                  hasAddress: _hasBilling,
                  lines: _billingLines,
                  isBilling: true,
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildAddressColumn(
                  title: 'SHIPPING ADDRESS',
                  hasAddress: _hasShipping,
                  lines: _shippingLines,
                  isBilling: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Address Form Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SrAddressFormDialog extends ConsumerStatefulWidget {
  final bool isBilling;
  final SalesCustomer customer;
  final ValueChanged<SalesCustomer>? onSaved;

  const _SrAddressFormDialog({
    required this.isBilling,
    required this.customer,
    this.onSaved,
  });

  @override
  ConsumerState<_SrAddressFormDialog> createState() =>
      _SrAddressFormDialogState();
}

class _SrAddressFormDialogState extends ConsumerState<_SrAddressFormDialog> {
  late final TextEditingController _attentionCtrl;
  late final TextEditingController _street1;
  late final TextEditingController _street2;
  late final TextEditingController _city;
  late final TextEditingController _zip;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _faxCtrl;
  String? _country;
  String? _state;
  bool _saving = false;

  static const _countries = ['India', 'United States', 'United Kingdom', 'UAE'];
  static const _states = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu & Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    if (widget.isBilling) {
      _attentionCtrl = TextEditingController(text: c.displayName);
      _street1 = TextEditingController(text: c.billingAddressStreet1 ?? '');
      _street2 = TextEditingController(text: c.billingAddressStreet2 ?? '');
      _city = TextEditingController(text: c.billingAddressCity ?? '');
      _zip = TextEditingController(text: c.billingAddressZip ?? '');
      _phoneCtrl = TextEditingController(text: c.billingAddressPhone ?? '');
    } else {
      _attentionCtrl = TextEditingController(text: c.displayName);
      _street1 = TextEditingController(text: c.shippingAddressStreet1 ?? '');
      _street2 = TextEditingController(text: c.shippingAddressStreet2 ?? '');
      _city = TextEditingController(text: c.shippingAddressCity ?? '');
      _zip = TextEditingController(text: c.shippingAddressZip ?? '');
      _phoneCtrl = TextEditingController(text: c.shippingAddressPhone ?? '');
    }
    _faxCtrl = TextEditingController();
    _country = 'India';
  }

  @override
  void dispose() {
    for (final c in [
      _attentionCtrl,
      _street1,
      _street2,
      _city,
      _zip,
      _phoneCtrl,
      _faxCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final apiService = ref.read(salesOrderApiServiceProvider);
      final addressKey = widget.isBilling
          ? 'billingAddress'
          : 'shippingAddress';
      final updated = await apiService.updateCustomer(widget.customer.id, {
        addressKey: {
          if (_attentionCtrl.text.trim().isNotEmpty)
            'attention': _attentionCtrl.text.trim(),
          'street1': _street1.text.trim(),
          if (_street2.text.trim().isNotEmpty) 'street2': _street2.text.trim(),
          if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
          if (_zip.text.trim().isNotEmpty) 'zip': _zip.text.trim(),
          if (_phoneCtrl.text.trim().isNotEmpty)
            'phone': _phoneCtrl.text.trim(),
        },
      });
      widget.onSaved?.call(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save address');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppTheme.textPrimary,
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        CustomTextField(
          controller: ctrl,
          hintText: label,
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isBilling ? 'Billing Address' : 'Shipping Address';
    final noteText = 'Changes made here will be updated for this customer.';

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        left: 280,
        right: 280,
        top: 0,
        bottom: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Attention', _attentionCtrl),
                    const SizedBox(height: 16),
                    _label('Country/Region'),
                    const SizedBox(height: 6),
                    FormDropdown<String>(
                      value: _country,
                      items: _countries,
                      hint: 'Select',
                      onChanged: (v) => setState(() => _country = v),
                    ),
                    const SizedBox(height: 16),
                    _label('Address'),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _street1,
                      hintText: 'Street 1',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _street2,
                      hintText: 'Street 2',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _field('City', _city),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('State'),
                              const SizedBox(height: 6),
                              FormDropdown<String>(
                                value: _state,
                                items: _states,
                                hint: 'Select or type to add',
                                onChanged: (v) => setState(() => _state = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field(
                            'Pin Code',
                            _zip,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Phone'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.borderLight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          '+91',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _phoneCtrl,
                                      hintText: 'Phone number',
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field(
                            'Fax Number',
                            _faxCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Note: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: noteText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            // Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  ZButton.primary(
                    label: _saving ? 'Saving...' : 'Save',
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(width: 12),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
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

// Unused legacy classes removed â€” replaced by _SrAddressFormDialog
class _SrAddressPickerRow extends StatefulWidget {
  final Map<String, dynamic> address;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback? onEdit;

  const _SrAddressPickerRow({
    required this.address,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
  });

  @override
  State<_SrAddressPickerRow> createState() => _SrAddressPickerRowState();
}

class _SrAddressPickerRowState extends State<_SrAddressPickerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lines = widget.address['lines'] as List<String>? ?? const <String>[];
    final bgColor = _hovered
        ? AppTheme.primaryBlue
        : widget.isSelected
        ? AppTheme.bgDisabled
        : AppTheme.backgroundColor;
    final titleColor = _hovered
        ? AppTheme.backgroundColor
        : AppTheme.textPrimary;
    final detailColor = _hovered
        ? AppTheme.backgroundColor.withValues(alpha: 0.82)
        : AppTheme.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onSelected,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.address['name'] as String? ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...lines.map(
                      (line) => Text(
                        line,
                        style: TextStyle(fontSize: 12, color: detailColor),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onEdit != null)
                GestureDetector(
                  onTap: widget.onEdit,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 14,
                      color: _hovered
                          ? AppTheme.backgroundColor
                          : AppTheme.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ New Address Action â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SrNewAddressAction extends StatefulWidget {
  final VoidCallback onTap;

  const _SrNewAddressAction({required this.onTap});

  @override
  State<_SrNewAddressAction> createState() => _SrNewAddressActionState();
}

class _SrNewAddressActionState extends State<_SrNewAddressAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = _hovered ? AppTheme.backgroundColor : AppTheme.primaryBlue;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.plusCircle, size: 16, color: fgColor),
              const SizedBox(width: 8),
              Text(
                'New address',
                style: TextStyle(
                  fontSize: 13,
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Address Edit Dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SrAddressEditDialog extends StatefulWidget {
  final Map<String, dynamic> address;
  final String title;
  final bool isNewAddress;

  const _SrAddressEditDialog({
    required this.address,
    required this.title,
    // ignore: unused_element_parameter
    this.isNewAddress = false,
  });

  @override
  State<_SrAddressEditDialog> createState() => _SrAddressEditDialogState();
}

class _SrAddressEditDialogState extends State<_SrAddressEditDialog> {
  late final TextEditingController _attentionCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _street2Ctrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _faxCtrl;
  String? _country;
  String? _state;

  static const List<String> _countries = [
    'India',
    'United States',
    'United Kingdom',
    'UAE',
  ];
  static const List<String> _states = [
    'Kerala',
    'Karnataka',
    'Tamil Nadu',
    'Maharashtra',
    'Delhi',
    'Goa',
  ];

  @override
  void initState() {
    super.initState();
    final lines = widget.address['lines'] as List<String>? ?? [];
    _attentionCtrl = TextEditingController(
      text: widget.address['name'] as String? ?? '',
    );
    _addressCtrl = TextEditingController(
      text: lines.isNotEmpty ? lines[0] : '',
    );
    _street2Ctrl = TextEditingController(
      text: lines.length > 1 ? lines[1] : '',
    );
    _cityCtrl = TextEditingController(text: lines.length > 2 ? lines[2] : '');
    _pinCtrl = TextEditingController(
      text: lines.length > 3 ? lines[3].replaceAll(RegExp(r'[^0-9]'), '') : '',
    );
    _phoneCtrl = TextEditingController(
      text: lines.length > 4 ? lines[4].replaceAll(RegExp(r'[^0-9]'), '') : '',
    );
    _faxCtrl = TextEditingController();
    _country = widget.isNewAddress ? null : 'India';
    _state = widget.isNewAddress ? null : 'Kerala';
  }

  @override
  void dispose() {
    for (final c in [
      _attentionCtrl,
      _addressCtrl,
      _street2Ctrl,
      _cityCtrl,
      _pinCtrl,
      _phoneCtrl,
      _faxCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppTheme.textPrimary,
    ),
  );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 6),
        CustomTextField(
          controller: ctrl,
          keyboardType: keyboardType,
          hintText: label,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final noteText = widget.isNewAddress
        ? 'This address will be added for this customer.'
        : 'Changes made here will be updated for this customer.';

    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        left: 80,
        right: 80,
        top: 0,
        bottom: 40,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.primaryBlue,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Attention', _attentionCtrl),
                    const SizedBox(height: 16),
                    _label('Country/Region'),
                    const SizedBox(height: 6),
                    FormDropdown<String>(
                      value: _country,
                      items: _countries,
                      hint: 'Select country',
                      onChanged: (v) => setState(() => _country = v),
                    ),
                    const SizedBox(height: 16),
                    _label('Address'),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _addressCtrl,
                      maxLines: 3,
                      hintText: 'Street / Area',
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _street2Ctrl,
                      maxLines: 3,
                      hintText: 'Street 2',
                    ),
                    const SizedBox(height: 16),
                    _field('City', _cityCtrl),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('State'),
                              const SizedBox(height: 6),
                              FormDropdown<String>(
                                value: _state,
                                items: _states,
                                hint: 'Select state',
                                onChanged: (v) => setState(() => _state = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field(
                            'Pin Code',
                            _pinCtrl,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Phone'),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppTheme.borderLight,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          '+91',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: _phoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      hintText: 'Phone number',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _field(
                            'Fax Number',
                            _faxCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Note: ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: noteText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  ZButton.primary(
                    label: 'Save',
                    onPressed: () => Navigator.pop(context),
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



