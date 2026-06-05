import 'dart:async';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/repositories/adjustments_repository.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/presentation/widgets/item_details_sidebar.dart';
import 'package:zerpai_erp/modules/items/items/services/products_api_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/radio_group.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/inventory_batch_bin_selection_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/inventory_order_date_dialog.dart';
import 'package:zerpai_erp/shared/widgets/buttons/z_split_action_menu_button.dart';
import 'package:zerpai_erp/shared/widgets/sections/attachment_section.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:web/web.dart' as web;

class InventoryMoveOrdersCreateScreen extends ConsumerStatefulWidget {
  const InventoryMoveOrdersCreateScreen({super.key});

  @override
  ConsumerState<InventoryMoveOrdersCreateScreen> createState() =>
      _InventoryMoveOrdersCreateScreenState();
}

class _InventoryMoveOrdersCreateScreenState
    extends ConsumerState<InventoryMoveOrdersCreateScreen> {
  static const double _scanPanelWidth = 560;
  static const double _scanBatchFieldWidth = 140;
  static const double _scanBinFieldWidth = 140;
  static const double _scanQtyFieldWidth = 110;

  final ProductsApiService _productsApi = ProductsApiService();
  final AdjustmentsRepository _adjustmentsRepository = AdjustmentsRepository();
  final ApiClient _apiClient = ApiClient();

  final GlobalKey _dateFieldKey = GlobalKey();
  final TextEditingController _moveOrderController = TextEditingController(
    text: 'MO-00003',
  );
  final TextEditingController _dateController = TextEditingController(
    text: DateFormat('dd-MM-yyyy').format(DateTime.now()),
  );
  final TextEditingController _notesController = TextEditingController();
  final List<PlatformFile> _attachments = <PlatformFile>[];
  final List<_MoveItemRowDraft> _rows = <_MoveItemRowDraft>[];

  DateTime _moveDate = DateTime.now();
  Warehouse? _selectedWarehouse;
  _AssigneeOption? _selectedAssignee;
  late Future<List<_AssigneeOption>> _assigneesFuture;
  bool _saving = false;

  bool _autoGenerate = true;
  final TextEditingController _prefixController = TextEditingController(
    text: 'MO-',
  );
  final TextEditingController _nextNumberController = TextEditingController(
    text: '00003',
  );

  bool _showScanPanel = false;
  _MoveProductOption? _scanSelectedItem;

  List<_BinOption> _scanSourceBins = const <_BinOption>[];
  List<_BatchOption> _scanBatchOptions = const <_BatchOption>[];
  _BatchOption? _scanSelectedSourceBatch;
  _BinOption? _scanSelectedSourceBin;
  final TextEditingController _scanSourceQtyController =
      TextEditingController();
  List<_BinLine> _scanSourceLines = <_BinLine>[];

  List<_BinOption> _scanDestinationBins = const <_BinOption>[];
  _BatchOption? _scanSelectedDestinationBatch;
  _BinOption? _scanSelectedDestinationBin;
  final TextEditingController _scanDestinationQtyController =
      TextEditingController();
  List<_BinLine> _scanDestinationLines = <_BinLine>[];

  List<_MoveProductOption> _products = const <_MoveProductOption>[];
  Timer? _scanDebounce;
  _ScanStage _scanStage = _ScanStage.source;
  BuildContext? _drawerHostContext;

  String get _orgId {
    final path = GoRouterState.of(context).uri.path;
    final segments = path.split('/').where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? '' : segments.first;
  }

  @override
  void initState() {
    super.initState();
    _rows.add(_newRow());
    _assigneesFuture = _loadAssigneesFromPublicUsers();
    _loadProducts();
    _seedMoveOrderNumberFromDb();
  }

  @override
  void dispose() {
    _moveOrderController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _prefixController.dispose();
    _nextNumberController.dispose();
    _scanSourceQtyController.dispose();
    _scanDestinationQtyController.dispose();
    _scanDebounce?.cancel();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  _MoveItemRowDraft _newRow() => _MoveItemRowDraft(
    itemController: TextEditingController(),
    descriptionController: TextEditingController(),
    quantityController: TextEditingController(),
  );

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final accent = Theme.of(context).colorScheme.primary;

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      endDrawer: const ItemDetailsSidebar(),
      footer: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: IgnorePointer(
            ignoring: _selectedWarehouse == null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _selectedWarehouse == null ? 0.32 : 1,
              child: _buildFooter(),
            ),
          ),
        ),
      ),
      child: Builder(
        builder: (drawerHostContext) {
          _drawerHostContext = drawerHostContext;
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Move Order',
                              style: AppTheme.pageTitle.copyWith(fontSize: 22),
                            ),
                            const SizedBox(height: 12),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderColor,
                            ),
                            const SizedBox(height: 16),
                            _labeledField(
                              label: 'Move Order#*',
                              child: SizedBox(
                                width: 330,
                                child: CustomTextField(
                                  controller: _moveOrderController,
                                  suffixWidget: InkWell(
                                    onTap: _openNumberPreferences,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(
                                        LucideIcons.settings,
                                        size: 14,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _labeledField(
                              label: 'Date',
                              child: SizedBox(
                                width: 330,
                                child: InkWell(
                                  key: _dateFieldKey,
                                  onTap: () async {
                                    final picked = await ZerpaiDatePicker.show(
                                      context,
                                      initialDate: _moveDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      targetKey: _dateFieldKey,
                                    );
                                    if (picked == null || !mounted) return;
                                    setState(() {
                                      _moveDate = picked;
                                      _dateController.text = DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(_moveDate);
                                    });
                                  },
                                  child: IgnorePointer(
                                    child: CustomTextField(
                                      controller: _dateController,
                                      readOnly: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _labeledField(
                              label: 'Location Name*',
                              child: SizedBox(
                                width: 330,
                                child: warehousesAsync.when(
                                  data: (warehouses) => FormDropdown<Warehouse>(
                                    value: _selectedWarehouse,
                                    items: warehouses,
                                    hint: 'Select a location',
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedWarehouse = value;
                                        for (final row in _rows) {
                                          row.sourceBins = const <_BinLine>[];
                                          row.destinationBins =
                                              const <_BinLine>[];
                                        }
                                      });
                                    },
                                    displayStringForValue: (w) => w.name,
                                    searchStringForValue: (w) =>
                                        '${w.name} ${w.code ?? ''} ${w.id}',
                                  ),
                                  loading: () => const CustomTextField(
                                    enabled: false,
                                    hintText: '',
                                    suffixWidget: _MoveFieldSkeleton(),
                                  ),
                                  error: (_, __) => const CustomTextField(
                                    enabled: false,
                                    hintText: 'Unable to load locations',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            IgnorePointer(
                              ignoring: _selectedWarehouse == null,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 160),
                                opacity: _selectedWarehouse == null ? 0.32 : 1,
                                child: _labeledField(
                                  label: 'Assignee',
                                  child: SizedBox(
                                    width: 330,
                                    child: FutureBuilder<List<_AssigneeOption>>(
                                      future: _assigneesFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CustomTextField(
                                            enabled: false,
                                            hintText: '',
                                            suffixWidget: _MoveFieldSkeleton(),
                                          );
                                        }
                                        if (snapshot.hasError) {
                                          return const CustomTextField(
                                            enabled: false,
                                            hintText: 'Unable to load users',
                                          );
                                        }
                                        final users =
                                            snapshot.data ??
                                            const <_AssigneeOption>[];
                                        return FormDropdown<_AssigneeOption>(
                                          value: _selectedAssignee,
                                          items: users,
                                          hint: 'Select User',
                                          onChanged: (value) {
                                            setState(
                                              () => _selectedAssignee = value,
                                            );
                                          },
                                          displayStringForValue: (u) =>
                                              u.fullName,
                                          searchStringForValue: (u) =>
                                              '${u.fullName} ${u.email}',
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            IgnorePointer(
                              ignoring: _selectedWarehouse == null,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 160),
                                opacity: _selectedWarehouse == null ? 0.32 : 1,
                                child: _labeledField(
                                  label: 'Internal Notes',
                                  child: SizedBox(
                                    width: 330,
                                    child: CustomTextField(
                                      controller: _notesController,
                                      maxLines: 3,
                                      height: 84,
                                      contentCase: ContentCase.sentence,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            IgnorePointer(
                              ignoring: _selectedWarehouse == null,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 160),
                                opacity: _selectedWarehouse == null ? 0.32 : 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildItemTable(accent),
                                    const SizedBox(height: 20),
                                    const Divider(
                                      height: 1,
                                      color: AppTheme.borderColor,
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: 390,
                                      child: AttachmentSection(
                                        title: 'Attach File(s) to move order',
                                        files: _attachments,
                                        onFilesChanged: (files) => setState(() {
                                          _attachments
                                            ..clear()
                                            ..addAll(files);
                                        }),
                                        helperText:
                                            'You can upload a maximum of 10 files, 10MB each',
                                        maxFiles: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_showScanPanel) _buildScanPanel(context, accent),
            ],
          );
        },
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.only(top: 9),
            child: RichText(
              text: TextSpan(
                text: label.replaceAll('*', ''),
                style: AppTheme.bodyText.copyWith(fontSize: 14),
                children: label.contains('*')
                    ? const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppTheme.errorRed),
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildItemTable(Color accent) {
    return Container(
      width: 800,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppTheme.tableHeaderBg,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Item Details',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                  ),
                ),
                InkWell(
                  onTap: _openScanPanelForNewItem,
                  child: Row(
                    children: [
                      Icon(LucideIcons.scanLine, size: 15, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        'Scan Item',
                        style: AppTheme.metaHelper.copyWith(
                          fontSize: 14,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Item Details', style: AppTheme.tableHeader),
                ),
                SizedBox(
                  width: 200,
                  child: Text(
                    'Quantity transferred',
                    textAlign: TextAlign.right,
                    style: AppTheme.tableHeader,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < _rows.length; i++) _buildRow(i),
          Container(
            height: 46,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              onPressed: () {
                setState(() => _rows.add(_newRow()));
              },
              icon: Icon(LucideIcons.plusCircle, size: 14, color: AppTheme.primaryBlue),
              label: Text(
                'Add New Row',
                style: AppTheme.metaHelper.copyWith(
                  color: AppTheme.primaryBlue,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int index) {
    final row = _rows[index];
    final product = row.selectedProduct;
    final isBinTracked = product?.trackBinLocation == true;
    final qty = double.tryParse(row.quantityController.text.trim()) ?? 0;
    final showSelectedRowActions = product != null;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                if (product == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: FormDropdown<_MoveProductOption>(
                      value: row.selectedProduct,
                      items: _products,
                      hint: 'Type or click to select an item.',
                      onSearch: _searchProductOptions,
                      onChanged: (value) async {
                        if (value == null) return;
                        final duplicate = _rows.any(
                          (r) => r != row && r.selectedProduct?.id == value.id,
                        );
                        if (duplicate) {
                          ZerpaiToast.error(
                            context,
                            '${value.name} is already included in this move order',
                          );
                          return;
                        }
                        setState(() {
                          row.selectedProduct = value;
                          row.itemController.text = value.name;
                          row.descriptionController.text = value.description
                              .trim();
                          row.quantityController.clear();
                          row.sourceBins = <_BinLine>[];
                          row.destinationBins = <_BinLine>[];
                        });
                        if (row.descriptionController.text.trim().isEmpty) {
                          final salesDesc = await _loadSalesDescription(
                            value.id,
                          );
                          if (!mounted) return;
                          if (row.selectedProduct?.id == value.id &&
                              salesDesc.isNotEmpty) {
                            setState(() {
                              row.descriptionController.text = salesDesc;
                            });
                          }
                        }
                      },
                      displayStringForValue: (v) => v.name,
                      searchStringForValue: (v) =>
                          '${v.name} ${v.code} ${v.sku} ${v.upc} ${v.ean}',
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w400,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          tooltip: '',
                          color: Colors.white,
                          elevation: 6,
                          offset: const Offset(0, 18),
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          constraints: const BoxConstraints(
                            minWidth: 168,
                            maxWidth: 168,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditItemForRow(index);
                            } else if (value == 'details') {
                              _openItemDetailsDrawerForRow(context, index);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem<String>(
                              value: 'edit',
                              height: 34,
                              child: Text('Edit Item'),
                            ),
                            PopupMenuItem<String>(
                              value: 'details',
                              height: 34,
                              child: Text('View Item Details'),
                            ),
                          ],
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.moreHorizontal,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => setState(() => _rows[index].clear()),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (product != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                    child: CustomTextField(
                      controller: row.descriptionController,
                      hintText: 'Add a description to your item',
                      maxLines: 2,
                      contentCase: ContentCase.sentence,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 236,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 90,
                  child: CustomTextField(
                    controller: row.quantityController,
                    hintText: '0',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (value) {
                      final normalized = _normalizeQtyInput(value);
                      if (row.quantityController.text != normalized) {
                        row.quantityController.text = normalized;
                      }
                      setState(() {});
                    },
                  ),
                ),
                if (product != null && isBinTracked && qty > 0) ...[
                  const SizedBox(height: 8),
                  if (row.sourceBins.isEmpty)
                    _actionLink(
                      'Select source bins',
                      onTap: () => _openBinDialog(index, isSource: true),
                    )
                  else
                    _actionLink(
                      '${_formatQty(_totalBinQty(row.sourceBins))} pcs taken from ${row.sourceBins.length} bins.',
                      onTap: () => _openBinDialog(index, isSource: true),
                    ),
                  const SizedBox(height: 4),
                  if (row.destinationBins.isEmpty)
                    _actionLink(
                      'Select destination bins',
                      onTap: row.sourceBins.isEmpty
                          ? null
                          : () => _openBinDialog(index, isSource: false),
                    )
                  else
                    _actionLink(
                      '${_formatQty(_totalBinQty(row.destinationBins))} pcs added to ${row.destinationBins.length} bins.',
                      onTap: () => _openBinDialog(index, isSource: false),
                    ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: Column(
              children: [
                const SizedBox(height: 12),
                if (!showSelectedRowActions)
                  InkWell(
                    onTap: _rows.length == 1
                        ? null
                        : () {
                            final removed = _rows.removeAt(index);
                            removed.dispose();
                            setState(() {});
                          },
                    child: Icon(
                      LucideIcons.xCircle,
                      size: 14,
                      color: _rows.length == 1
                          ? AppTheme.textDisabled
                          : AppTheme.errorRed,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionLink(String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: AppTheme.metaHelper.copyWith(
          color: onTap == null
              ? AppTheme.textDisabled
              : AppTheme.primaryBlue,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        SizedBox(
          height: 38,
          child: OutlinedButton(
            onPressed: _saving ? null : _saveDraft,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save as Draft'),
          ),
        ),
        const SizedBox(width: 8),
        ZSplitActionMenuButton(
          height: 38,
          triggerLabel: 'Save as Completed',
          isDisabled: _saving,
          menuItems: [
            ZSplitActionMenuItem(
              label: 'Save as Confirmed',
              onPressed: () => _saveCompleted('Confirmed'),
            ),
            ZSplitActionMenuItem(
              label: 'Save as In Progress',
              onPressed: () => _saveCompleted('In Progress'),
            ),
          ],
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 38,
          child: OutlinedButton(
            onPressed: _saving ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildScanPanel(BuildContext context, Color accent) {
    final hasScanItem = _scanSelectedItem != null;
    final showSourceStage = hasScanItem && _scanStage == _ScanStage.source;
    final showDestinationStage =
        hasScanItem && _scanStage == _ScanStage.destination;
    final sourceRequiresBatch = _scanSelectedItem?.trackBatches == true;
    final canGoDestination = _scanLinesAreValid(
      _scanSourceLines,
      requireBatch: sourceRequiresBatch,
    );
    final canApplyScan = hasScanItem;

    return Positioned.fill(
      child: Container(
        color: AppTheme.textPrimary.withValues(alpha: 0.08),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showScanPanel = false),
              ),
            ),
            Container(
              width: _scanPanelWidth,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 62,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Scan Item',
                          style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _showScanPanel = false),
                          child: const Icon(
                            LucideIcons.x,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          color: AppTheme.bgLight,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Select the item you want to move',
                                style: AppTheme.sectionHeader.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FormDropdown<_MoveProductOption>(
                                value: _scanSelectedItem,
                                items: _products,
                                hint: 'Select the item you want to move',
                                onSearch: _searchProductOptions,
                                onChanged: (value) async {
                                  setState(() {
                                    _scanSelectedItem = value;
                                    _scanStage = _ScanStage.source;
                                    _scanSourceLines = <_BinLine>[];
                                    _scanDestinationLines = <_BinLine>[];
                                  });
                                  if (value != null) {
                                    await _loadScanBins();
                                  }
                                },
                                displayStringForValue: (v) => v.name,
                                searchStringForValue: (v) =>
                                    '${v.name} ${v.code} ${v.sku} ${v.upc} ${v.ean}',
                              ),
                              if (_scanSelectedItem != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppTheme.borderLight,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    color: AppTheme.backgroundColor,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Unit',
                                        style: AppTheme.metaHelper.copyWith(
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'pcs',
                                        style: AppTheme.bodyText.copyWith(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (showSourceStage) ...[
                          const SizedBox(height: 16),
                          _scanBinSection(
                            title: 'Source Bins',
                            isSource: true,
                            requireBatch:
                                _scanSelectedItem?.trackBatches == true,
                            batchOptions: _scanBatchOptions,
                            selectedBatch: _scanSelectedSourceBatch,
                            onBatchChanged: (batch) => setState(
                              () => _scanSelectedSourceBatch = batch,
                            ),
                            bins: _scanSourceBins,
                            selectedBin: _scanSelectedSourceBin,
                            quantityController: _scanSourceQtyController,
                            lines: _scanSourceLines,
                            onBinChanged: (bin) =>
                                setState(() => _scanSelectedSourceBin = bin),
                            onAdd: _addSourceBinLine,
                          ),
                        ],
                        if (showDestinationStage) ...[
                          const SizedBox(height: 16),
                          _scanBinSection(
                            title: 'Destination Bins',
                            isSource: false,
                            requireBatch:
                                _scanSelectedItem?.trackBatches == true,
                            batchOptions: _destinationBatchOptionsFromSource(),
                            selectedBatch: _scanSelectedDestinationBatch,
                            onBatchChanged: (batch) => setState(() {
                              _scanSelectedDestinationBatch = batch;
                              if (batch != null &&
                                  _scanDestinationLines.isNotEmpty) {
                                _scanDestinationLines = _scanDestinationLines
                                    .map(
                                      (line) => _BinLine(
                                        binId: line.binId,
                                        binCode: line.binCode,
                                        qty: line.qty,
                                        batchId: batch.id,
                                        batchRef: batch.reference,
                                        manufacturerBatchNo:
                                            batch.manufacturerBatchNo,
                                        mfgDate: batch.mfgDate,
                                        expiryDate: batch.expiryDate,
                                        availableQty: batch.availableQty,
                                      ),
                                    )
                                    .toList(growable: true);
                              }
                            }),
                            bins: _scanDestinationBins,
                            selectedBin: _scanSelectedDestinationBin,
                            quantityController: _scanDestinationQtyController,
                            lines: _scanDestinationLines,
                            onBinChanged: (bin) => setState(
                              () => _scanSelectedDestinationBin = bin,
                            ),
                            onAdd: _addDestinationBinLine,
                            extraHeader:
                                'Selected source quantity: ${_formatQty(_totalBinQty(_scanSourceLines))} pcs',
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (showDestinationStage) ...[
                          SizedBox(
                            width: 38,
                            height: 38,
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() => _scanStage = _ScanStage.source);
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.chevronLeft,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        SizedBox(
                          height: 38,
                          child: ElevatedButton(
                            onPressed: canApplyScan
                                ? _applyScanSelection
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (!showDestinationStage) ...[
                          SizedBox(
                            height: 38,
                            child: OutlinedButton(
                              onPressed: canGoDestination
                                  ? () {
                                      setState(() {
                                        _scanStage = _ScanStage.destination;
                                        final options =
                                            _destinationBatchOptionsFromSource();
                                        if (_scanSelectedDestinationBatch ==
                                                null &&
                                            options.isNotEmpty) {
                                          _scanSelectedDestinationBatch =
                                              options.first;
                                        }
                                      });
                                    }
                                  : null,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFFF3F4F6,
                                ),
                                foregroundColor: AppTheme.textPrimary,
                                disabledForegroundColor: AppTheme.textDisabled,
                                side: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text('Select destination bins'),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        SizedBox(
                          height: 38,
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _showScanPanel = false),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: const Text('Cancel'),
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
    );
  }

  Widget _scanBinSection({
    required String title,
    required bool isSource,
    required bool requireBatch,
    required List<_BatchOption> batchOptions,
    required _BatchOption? selectedBatch,
    required ValueChanged<_BatchOption?>? onBatchChanged,
    String? extraHeader,
    required List<_BinOption> bins,
    required _BinOption? selectedBin,
    required TextEditingController quantityController,
    required List<_BinLine> lines,
    required ValueChanged<_BinOption?> onBinChanged,
    required VoidCallback onAdd,
  }) {
    final safeBatchOptions = List<_BatchOption>.from(batchOptions);
    final safeBins = List<_BinOption>.from(bins);
    final safeLines = lines;
    return Container(
      color: AppTheme.bgLight,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AppTheme.sectionHeader.copyWith(fontSize: 14)),
              const Spacer(),
              if (extraHeader != null)
                Text(
                  extraHeader,
                  style: AppTheme.bodyText.copyWith(fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: _scanBatchFieldWidth,
                child: FormDropdown<_BatchOption>(
                  value: selectedBatch,
                  items: safeBatchOptions,
                  hint: 'Select Batch',
                  onChanged: onBatchChanged ?? (_) {},
                  displayStringForValue: (b) => b.reference,
                  searchStringForValue: (b) =>
                      '${b.reference} ${b.manufacturerBatchNo} ${b.expiryDate}',
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _scanBinFieldWidth,
                child: FormDropdown<_BinOption>(
                  value: selectedBin,
                  items: safeBins,
                  hint: 'Select bin',
                  enabled: !requireBatch || selectedBatch != null,
                  onChanged: onBinChanged,
                  displayStringForValue: (b) => b.code,
                  searchStringForValue: (b) =>
                      '${b.code} ${_formatQty(b.stock)}',
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: _scanQtyFieldWidth,
                child: CustomTextField(
                  controller: quantityController,
                  hintText: '0',
                  enabled: !requireBatch || selectedBatch != null,
                  keyboardType: TextInputType.number,
                  onSubmitted: (value) {
                    final normalized = _normalizeQtyInput(value);
                    if (quantityController.text != normalized) {
                      quantityController.text = normalized;
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onAdd,
                child: Icon(
                  LucideIcons.plusCircle,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
              color: AppTheme.backgroundColor,
            ),
            child: Column(
              children: [
                Container(
                  height: 30,
                  color: AppTheme.tableHeaderBg,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'BATCHES',
                          style: AppTheme.tableHeader.copyWith(fontSize: 12),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isSource ? 'SOURCE BINS' : 'DESTINATION BINS',
                          style: AppTheme.tableHeader.copyWith(fontSize: 12),
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: Text(
                          'QUANTITY',
                          textAlign: TextAlign.right,
                          style: AppTheme.tableHeader.copyWith(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                if (safeLines.isEmpty)
                  const SizedBox(height: 1)
                else
                  for (int i = 0; i < safeLines.length; i++)
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  safeLines[i].batchRef.isEmpty
                                      ? '-'
                                      : safeLines[i].batchRef,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                                if (!isSource &&
                                    safeLines[i].batchRef.trim().isNotEmpty)
                                  Text(
                                    'Selected source quantity: ${_formatQty(_sourceQtyForBatchRef(safeLines[i].batchRef))} pcs',
                                    style: AppTheme.metaHelper.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              safeLines[i].binCode,
                              style: AppTheme.bodyText.copyWith(fontSize: 13),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: CustomTextField(
                              controller: TextEditingController(
                                text: _formatQty(safeLines[i].qty),
                              ),
                              hintText: '0',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              onChanged: (value) {
                                final nextQty =
                                    double.tryParse(value.trim()) ?? 0;
                                setState(() {
                                  lines[i] = _BinLine(
                                    binId: lines[i].binId,
                                    binCode: lines[i].binCode,
                                    qty: nextQty,
                                    batchId: lines[i].batchId,
                                    batchRef: lines[i].batchRef,
                                    manufacturerBatchNo:
                                        lines[i].manufacturerBatchNo,
                                    mfgDate: lines[i].mfgDate,
                                    expiryDate: lines[i].expiryDate,
                                    availableQty: lines[i].availableQty,
                                  );
                                });
                              },
                              onSubmitted: (value) {
                                final normalized = _normalizeQtyInput(value);
                                final nextQty =
                                    double.tryParse(normalized.trim()) ?? 0;
                                setState(() {
                                  lines[i] = _BinLine(
                                    binId: lines[i].binId,
                                    binCode: lines[i].binCode,
                                    qty: nextQty,
                                    batchId: lines[i].batchId,
                                    batchRef: lines[i].batchRef,
                                    manufacturerBatchNo:
                                        lines[i].manufacturerBatchNo,
                                    mfgDate: lines[i].mfgDate,
                                    expiryDate: lines[i].expiryDate,
                                    availableQty: lines[i].availableQty,
                                  );
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => setState(() => lines.removeAt(i)),
                            child: const Icon(
                              LucideIcons.xCircle,
                              size: 14,
                              color: AppTheme.errorRed,
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
    );
  }

  Future<void> _openNumberPreferences() async {
    final autoBefore = _autoGenerate;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        bool localAuto = _autoGenerate;
        final localPrefix = TextEditingController(text: _prefixController.text);
        final localNext = TextEditingController(
          text: _nextNumberController.text,
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              alignment: Alignment.topCenter,
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: 760,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Configure Move Order# Preferences',
                              style: AppTheme.sectionHeader.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(false),
                              child: const Icon(
                                LucideIcons.x,
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        child: Text(
                          localAuto
                              ? 'Your move order numbers are set on auto-generate mode to save your time. Are you sure about changing this setting?'
                              : 'You have selected manual move order numbering. Do you want us to auto-generate it for you?',
                          style: AppTheme.bodyText.copyWith(fontSize: 14),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: RadioScope<bool>(
                          value: localAuto,
                          onChanged: (value) =>
                              setDialogState(() => localAuto = value),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const RadioGroupItem<bool>(value: true),
                                  Expanded(
                                    child: Text(
                                      'Continue auto-generating move order numbers',
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (localAuto)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 26,
                                    top: 2,
                                    bottom: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 110,
                                        child: CustomTextField(
                                          controller: localPrefix,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 240,
                                        child: CustomTextField(
                                          controller: localNext,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  const RadioGroupItem<bool>(value: false),
                                  Expanded(
                                    child: Text(
                                      'Enter move order numbers manually',
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () {
                                  _autoGenerate = localAuto;
                                  _prefixController.text = localPrefix.text;
                                  _nextNumberController.text = localNext.text;
                                  if (_autoGenerate) {
                                    _moveOrderController.text =
                                        '${_prefixController.text}${_nextNumberController.text}';
                                  }
                                  Navigator.of(ctx).pop(true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text('Save'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 38,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text('Cancel'),
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
          },
        );
      },
    );

    if (result == true && !autoBefore && _autoGenerate && mounted) {
      ZerpaiToast.success(context, 'Move order numbering set to auto-generate');
    }
  }

  Future<void> _openBinDialog(int rowIndex, {required bool isSource}) async {
    final row = _rows[rowIndex];
    final qty = double.tryParse(row.quantityController.text.trim()) ?? 0;
    if (_selectedWarehouse == null || qty <= 0) {
      ZerpaiToast.error(context, 'Please select location and valid quantity.');
      return;
    }

    final options = await _loadBinOptions(_selectedWarehouse!.id);
    final batchOptions = row.selectedProduct?.trackBatches == true
        ? await _loadBatchOptions(
            row.selectedProduct!.id,
            warehouseId: _selectedWarehouse!.id,
          )
        : const <_BatchOption>[];
    if (!mounted) return;
    final sourceBinIds = row.sourceBins
        .map((line) => line.binId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final dialogOptions = isSource
        ? options
        : options
              .where((option) => !sourceBinIds.contains(option.id.trim()))
              .toList(growable: false);
    if (!isSource && dialogOptions.isEmpty) {
      ZerpaiToast.error(
        context,
        'No destination bins are available because source and destination cannot be the same bin.',
      );
      return;
    }

    final existing = isSource ? row.sourceBins : row.destinationBins;
    final initialLines = !isSource && existing.isEmpty
        ? row.sourceBins
              .where((line) => line.qty > 0)
              .map(
                (line) => _BinLine(
                  binId: '',
                  binCode: '',
                  qty: line.qty,
                  batchId: line.batchId,
                  batchRef: line.batchRef,
                  manufacturerBatchNo: line.manufacturerBatchNo,
                  mfgDate: line.mfgDate,
                  expiryDate: line.expiryDate,
                  availableQty: line.qty,
                ),
              )
              .toList(growable: false)
        : existing;
    final result = await showDialog<List<InventoryBatchBinDialogLine>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InventoryBatchBinSelectionDialog(
        title: 'Select Batches and Bin Locations',
        locationName: _selectedWarehouse!.name,
        itemName: row.selectedProduct?.name ?? 'Item',
        totalQuantity: qty,
        options: dialogOptions
            .map(
              (option) => InventoryBatchBinDialogBinOption(
                id: option.id,
                code: option.code,
                stock: option.stock,
              ),
            )
            .toList(growable: false),
        batchOptions: batchOptions
            .map(
              (option) => InventoryBatchBinDialogBatchOption(
                id: option.id,
                reference: option.reference,
                manufacturerBatchNo: option.manufacturerBatchNo,
                mfgDate: option.mfgDate,
                expiryDate: option.expiryDate,
                availableQty: option.availableQty,
                connectedBinIds: option.connectedBinIds,
              ),
            )
            .toList(growable: false),
        initialLines: initialLines
            .map(
              (line) => InventoryBatchBinDialogLine(
                binId: line.binId,
                binCode: line.binCode,
                qty: line.qty,
                batchId: line.batchId,
                batchRef: line.batchRef,
                manufacturerBatchNo: line.manufacturerBatchNo,
                mfgDate: line.mfgDate,
                expiryDate: line.expiryDate,
                availableQty: line.availableQty,
              ),
            )
            .toList(growable: false),
        isSource: isSource,
        requiresBatch: row.selectedProduct?.trackBatches == true,
        locationContextLabel: 'Location',
        quantityUnitLabel: 'pcs',
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      final mappedResult = result
          .map(
            (line) => _BinLine(
              binId: line.binId,
              binCode: line.binCode,
              qty: line.qty,
              batchId: line.batchId,
              batchRef: line.batchRef,
              manufacturerBatchNo: line.manufacturerBatchNo,
              mfgDate: line.mfgDate,
              expiryDate: line.expiryDate,
              availableQty: line.availableQty,
            ),
          )
          .toList(growable: false);
      if (isSource) {
        row.sourceBins = mappedResult;
        if (row.destinationBins.isNotEmpty &&
            (_totalBinQty(row.destinationBins) != _totalBinQty(mappedResult) ||
                _hasSameSourceAndDestinationBin(
                  sourceBins: mappedResult,
                  destinationBins: row.destinationBins,
                ))) {
          row.destinationBins = <_BinLine>[];
        }
      } else {
        row.destinationBins = mappedResult;
      }
    });
  }

  Future<List<_BinOption>> _loadBinOptions(String warehouseId) async {
    final rows = await _adjustmentsRepository.getBinOptions(warehouseId);
    return rows
        .map(
          (e) => _BinOption(
            id: (e['id'] ?? '').toString(),
            code: (e['bin_code'] ?? '').toString(),
            stock: 0,
          ),
        )
        .where((e) => e.id.isNotEmpty && e.code.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<_BatchOption>> _loadBatchOptions(
    String productId, {
    String? warehouseId,
  }) async {
    try {
      final rows = await _productsApi.getProductBatches(
        productId,
        warehouseId: warehouseId,
      );
      String str(dynamic value) => (value ?? '').toString().trim();
      double numVal(dynamic value) {
        if (value is num) return value.toDouble();
        return double.tryParse((value ?? '').toString()) ?? 0;
      }

      final seen = <String>{};
      final out = <_BatchOption>[];
      for (final row in rows) {
        final ref = str(
          row['batch_no'] ??
              row['batchNo'] ??
              row['batch_number'] ??
              row['batchNumber'] ??
              row['batch_reference'] ??
              row['batchReference'] ??
              row['name'] ??
              row['code'],
        );
        if (ref.isEmpty || seen.contains(ref)) continue;
        seen.add(ref);
        out.add(
          _BatchOption(
            id: str(row['id']).isEmpty ? ref : str(row['id']),
            reference: ref,
            manufacturerBatchNo: str(
              row['manufacturer_batch_no'] ?? row['manufacturerBatchNo'],
            ),
            mfgDate: str(row['mfg_date'] ?? row['mfgDate']),
            expiryDate: str(row['expiry_date'] ?? row['expiryDate']),
            availableQty: numVal(
              row['quantity_available'] ??
                  row['qty_available'] ??
                  row['available_qty'] ??
                  row['available_quantity'] ??
                  row['balance'] ??
                  row['quantity'] ??
                  row['qty'],
            ),
            connectedBinIds: (() {
              final raw = row['connected_bin_ids'];
              final source = raw is List ? raw : const <dynamic>[];
              return source
                  .map((e) => (e ?? '').toString())
                  .where((e) => e.trim().isNotEmpty)
                  .toSet();
            })(),
          ),
        );
      }
      return out;
    } catch (_) {
      return const <_BatchOption>[];
    }
  }

  Future<void> _loadProducts() async {
    final rows = await _productsApi.fetchProducts(limit: 300, offset: 0);
    if (!mounted) return;
    setState(() {
      _products = rows
          .map(_MoveProductOption.fromMap)
          .where((p) => p.id.isNotEmpty && p.name.trim().isNotEmpty)
          .toList(growable: false);
    });
  }

  Future<List<_MoveProductOption>> _searchProductOptions(String query) async {
    final q = query.trim();
    if (q.isEmpty) return _products;

    try {
      final response = await _apiClient.get(
        '/products/search',
        queryParameters: {'q': q, 'limit': 50},
      );
      final payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic> && payload['data'] is List
                ? payload['data'] as List<dynamic>
                : const <dynamic>[]);

      final out = <_MoveProductOption>[];
      final seen = <String>{};
      for (final raw in rows.whereType<Map>()) {
        final mapped = _MoveProductOption.fromMap(
          Map<String, dynamic>.from(raw),
        );
        if (mapped.id.isEmpty || !seen.add(mapped.id)) continue;
        out.add(mapped);
      }
      return out;
    } catch (_) {
      return _products;
    }
  }

  Future<String> _loadSalesDescription(String productId) async {
    try {
      final payload = await _productsApi.fetchProductById(productId);
      if (payload == null) return '';
      return (payload['sales_description'] ??
              payload['salesDescription'] ??
              payload['description'] ??
              '')
          .toString()
          .trim();
    } catch (_) {
      return '';
    }
  }

  Future<List<_AssigneeOption>> _loadAssigneesFromPublicUsers() async {
    try {
      final response = await _apiClient.get('/users');
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);
      return rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .map(_AssigneeOption.fromJson)
          .where((user) => user.id.isNotEmpty && user.fullName.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const <_AssigneeOption>[];
    }
  }

  Future<void> _loadScanBins() async {
    if (_selectedWarehouse == null) return;
    final bins = await _loadBinOptions(_selectedWarehouse!.id);
    final batches =
        (_scanSelectedItem?.trackBatches == true && _scanSelectedItem != null)
        ? await _loadBatchOptions(
            _scanSelectedItem!.id,
            warehouseId: _selectedWarehouse!.id,
          )
        : const <_BatchOption>[];
    if (!mounted) return;
    setState(() {
      _scanSourceBins = bins;
      _scanDestinationBins = bins;
      _scanBatchOptions = batches;
      _scanSelectedSourceBatch = null;
      _scanSelectedDestinationBatch = null;
      _scanSelectedSourceBin = null;
      _scanSelectedDestinationBin = null;
      _scanSourceQtyController.clear();
      _scanDestinationQtyController.clear();
      _scanSourceLines = <_BinLine>[];
      _scanDestinationLines = <_BinLine>[];
    });
  }

  void _addSourceBinLine() {
    final selected = _scanSelectedSourceBin;
    final requireBatch = _scanSelectedItem?.trackBatches == true;
    final selectedBatch = _scanSelectedSourceBatch;
    final qty = double.tryParse(_scanSourceQtyController.text.trim()) ?? 0;
    if (selected == null || qty <= 0) return;
    if (requireBatch && selectedBatch == null) return;
    if (_scanSourceLines.any((line) => line.binId == selected.id)) {
      ZerpaiToast.error(context, 'This source bin is already added.');
      return;
    }
    setState(() {
      _scanSourceLines.add(
        _BinLine(
          binId: selected.id,
          binCode: selected.code,
          qty: qty,
          batchId: selectedBatch?.id ?? '',
          batchRef: selectedBatch?.reference ?? '',
          manufacturerBatchNo: selectedBatch?.manufacturerBatchNo ?? '',
          mfgDate: selectedBatch?.mfgDate ?? '',
          expiryDate: selectedBatch?.expiryDate ?? '',
          availableQty: selectedBatch?.availableQty ?? 0,
        ),
      );
      _scanSourceQtyController.clear();
    });
  }

  void _openScanPanelForNewItem() {
    setState(() {
      _showScanPanel = true;
      _scanStage = _ScanStage.source;
      _scanSelectedItem = null;
      _scanBatchOptions = const <_BatchOption>[];
      _scanSelectedSourceBatch = null;
      _scanSelectedDestinationBatch = null;
      _scanSourceBins = const <_BinOption>[];
      _scanDestinationBins = const <_BinOption>[];
      _scanSelectedSourceBin = null;
      _scanSelectedDestinationBin = null;
      _scanSourceQtyController.clear();
      _scanDestinationQtyController.clear();
      _scanSourceLines = <_BinLine>[];
      _scanDestinationLines = <_BinLine>[];
    });
  }

  void _addDestinationBinLine() {
    final sourceRequiresBatch = _scanSelectedItem?.trackBatches == true;
    if (!_scanLinesAreValid(
      _scanSourceLines,
      requireBatch: sourceRequiresBatch,
    )) {
      ZerpaiToast.error(
        context,
        sourceRequiresBatch
            ? 'Please complete valid source rows (batch, bin, quantity) first.'
            : 'Please complete valid source rows (bin, quantity) first.',
      );
      return;
    }
    final selected = _scanSelectedDestinationBin;
    final requireBatch = _scanSelectedItem?.trackBatches == true;
    final selectedBatch = _scanSelectedDestinationBatch;
    final qty = double.tryParse(_scanDestinationQtyController.text.trim()) ?? 0;
    if (selected == null || qty <= 0) return;
    if (requireBatch && selectedBatch == null) return;
    if (_scanDestinationLines.any((line) => line.binId == selected.id)) {
      ZerpaiToast.error(context, 'This destination bin is already added.');
      return;
    }
    setState(() {
      _scanDestinationLines.add(
        _BinLine(
          binId: selected.id,
          binCode: selected.code,
          qty: qty,
          batchId: selectedBatch?.id ?? '',
          batchRef: selectedBatch?.reference ?? '',
          manufacturerBatchNo: selectedBatch?.manufacturerBatchNo ?? '',
          mfgDate: selectedBatch?.mfgDate ?? '',
          expiryDate: selectedBatch?.expiryDate ?? '',
          availableQty: selectedBatch?.availableQty ?? 0,
        ),
      );
      _scanDestinationQtyController.clear();
    });
  }

  Future<void> _applyScanSelection() async {
    final sourceRequiresBatch = _scanSelectedItem?.trackBatches == true;
    final normalizedSourceQty = _normalizeQtyInput(_scanSourceQtyController.text);
    final normalizedDestinationQty = _normalizeQtyInput(
      _scanDestinationQtyController.text,
    );
    final pendingSourceLine = _buildPendingBinLine(
      isSource: true,
      requireBatch: sourceRequiresBatch,
      normalizedQty: normalizedSourceQty,
    );
    final pendingDestinationLine = _buildPendingBinLine(
      isSource: false,
      requireBatch: sourceRequiresBatch,
      normalizedQty: normalizedDestinationQty,
    );
    final effectiveSourceLines = <_BinLine>[
      ..._scanSourceLines,
      if (pendingSourceLine != null &&
          !_scanSourceLines.any((line) => line.binId == pendingSourceLine.binId))
        pendingSourceLine,
    ];
    final effectiveDestinationLines = <_BinLine>[
      ..._scanDestinationLines,
      if (pendingDestinationLine != null &&
          !_scanDestinationLines.any(
            (line) => line.binId == pendingDestinationLine.binId,
          ))
        pendingDestinationLine,
    ];
    final hasDestinationRows = effectiveDestinationLines.isNotEmpty;
    final requireDestination = _scanStage == _ScanStage.destination;
    if (_scanSelectedItem == null) {
      ZerpaiToast.error(context, 'Please select an item to move.');
      return;
    }
    if (!_scanLinesAreValid(
      effectiveSourceLines,
      requireBatch: sourceRequiresBatch,
    )) {
      ZerpaiToast.error(
        context,
        sourceRequiresBatch
            ? 'Please add valid source rows with batch, bin, and quantity.'
            : 'Please add valid source rows with bin and quantity.',
      );
      return;
    }
    if (hasDestinationRows &&
        !_scanLinesAreValid(
          effectiveDestinationLines,
          requireBatch: sourceRequiresBatch,
        )) {
      ZerpaiToast.error(
        context,
        'Please add valid destination rows with bin and quantity.',
      );
      return;
    }
    if (effectiveSourceLines.isEmpty) {
      ZerpaiToast.error(context, 'Please select source bins.');
      return;
    }
    if (requireDestination && effectiveDestinationLines.isEmpty) {
      ZerpaiToast.error(context, 'Please select source and destination bins.');
      return;
    }
    if (hasDestinationRows &&
        (_totalBinQty(effectiveSourceLines) -
                _totalBinQty(effectiveDestinationLines))
                .abs() >
            0.0001) {
      ZerpaiToast.error(
        context,
        'Source and destination quantities must match.',
      );
      return;
    }

    int targetIndex = _rows.indexWhere(
      (r) => r.selectedProduct?.id == _scanSelectedItem!.id,
    );
    if (targetIndex < 0) {
      targetIndex = _rows.indexWhere((r) => r.selectedProduct == null);
    }
    if (targetIndex < 0) {
      setState(() {
        _rows.add(_newRow());
        targetIndex = _rows.length - 1;
      });
    }

    final targetRow = _rows[targetIndex];
    setState(() {
      targetRow.selectedProduct = _scanSelectedItem;
      targetRow.itemController.text = _scanSelectedItem!.name;
      targetRow.descriptionController.text = _scanSelectedItem!.description
          .trim();
      targetRow.quantityController.text = _formatQty(
        _totalBinQty(effectiveSourceLines),
      );
      targetRow.sourceBins = List<_BinLine>.from(effectiveSourceLines);
      targetRow.destinationBins = hasDestinationRows
          ? List<_BinLine>.from(effectiveDestinationLines)
          : <_BinLine>[];
      _showScanPanel = false;
    });
    if (targetRow.descriptionController.text.trim().isEmpty) {
      final salesDesc = await _loadSalesDescription(_scanSelectedItem!.id);
      if (!mounted) return;
      if (targetRow.selectedProduct?.id == _scanSelectedItem!.id &&
          salesDesc.isNotEmpty) {
        setState(() {
          targetRow.descriptionController.text = salesDesc;
        });
      }
    }
  }

  double _totalBinQty(List<_BinLine> lines) =>
      lines.fold<double>(0, (sum, line) => sum + line.qty);

  bool _hasSameSourceAndDestinationBin({
    required List<_BinLine> sourceBins,
    required List<_BinLine> destinationBins,
  }) {
    final sourceIds = sourceBins
        .map((line) => line.binId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (sourceIds.isEmpty) return false;
    return destinationBins.any(
      (line) => sourceIds.contains(line.binId.trim()),
    );
  }

  String _formatQty(num value) {
    final fixed = value.toStringAsFixed(2);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  bool _scanLineIsValid(_BinLine line, {required bool requireBatch}) {
    final hasBin = line.binId.trim().isNotEmpty;
    final hasQty = line.qty > 0;
    final hasBatch = !requireBatch || line.batchRef.trim().isNotEmpty;
    return hasBin && hasQty && hasBatch;
  }

  bool _scanLinesAreValid(List<_BinLine> lines, {required bool requireBatch}) {
    if (lines.isEmpty) return false;
    final seen = <String>{};
    for (final line in lines) {
      if (!_scanLineIsValid(line, requireBatch: requireBatch)) return false;
      if (!seen.add(line.binId.trim())) return false;
    }
    return true;
  }

  List<_BatchOption> _destinationBatchOptionsFromSource() {
    final byRef = <String, _BatchOption>{};
    for (final line in _scanSourceLines) {
      final ref = line.batchRef.trim();
      if (ref.isEmpty) continue;
      byRef.putIfAbsent(
        ref,
        () => _BatchOption(
          id: line.batchId.isEmpty ? ref : line.batchId,
          reference: ref,
          manufacturerBatchNo: line.manufacturerBatchNo,
          mfgDate: line.mfgDate,
          expiryDate: line.expiryDate,
          availableQty: line.qty,
          connectedBinIds: const <String>{},
        ),
      );
    }
    return byRef.values.toList(growable: false);
  }

  double _sourceQtyForBatchRef(String batchRef) {
    final target = batchRef.trim().toLowerCase();
    return _scanSourceLines
        .where((line) => line.batchRef.trim().toLowerCase() == target)
        .fold<double>(0, (sum, line) => sum + line.qty);
  }

  String _normalizeQtyInput(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) return '';
    return _formatQty(parsed);
  }

  _BinLine? _buildPendingBinLine({
    required bool isSource,
    required bool requireBatch,
    required String normalizedQty,
  }) {
    final selectedBin = isSource ? _scanSelectedSourceBin : _scanSelectedDestinationBin;
    final selectedBatch = isSource
        ? _scanSelectedSourceBatch
        : _scanSelectedDestinationBatch;
    if (selectedBin == null || normalizedQty.isEmpty) return null;
    if (requireBatch && selectedBatch == null) return null;
    final qty = double.tryParse(normalizedQty) ?? 0;
    if (qty <= 0) return null;
    return _BinLine(
      binId: selectedBin.id,
      binCode: selectedBin.code,
      qty: qty,
      batchId: selectedBatch?.id ?? '',
      batchRef: selectedBatch?.reference ?? '',
      manufacturerBatchNo: selectedBatch?.manufacturerBatchNo ?? '',
      mfgDate: selectedBatch?.mfgDate ?? '',
      expiryDate: selectedBatch?.expiryDate ?? '',
      availableQty: selectedBatch?.availableQty ?? 0,
    );
  }

  Future<void> _saveDraft() async {
    if (!_validate()) return;
    if (_autoGenerate) {
      await _seedMoveOrderNumberFromDb();
    }
    setState(() => _saving = true);
    try {
      await _createMoveOrderWithDuplicateRetry();
      if (!mounted) return;
      ZerpaiToast.saved(context, 'Move order draft');
      context.go('/$_orgId/inventory/move-orders');
    } catch (error) {
      if (!mounted) return;
      ZerpaiToast.error(
        context,
        _extractApiErrorMessage(error, 'Failed to save move order draft'),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveCompleted(String status) async {
    if (!_validate()) return;
    if (_autoGenerate) {
      await _seedMoveOrderNumberFromDb();
    }
    final confirmedDate = await InventoryOrderDateDialog.show(
      context,
      title: 'Choose the move order date',
      label: 'Moved date*',
      initialDate: _moveDate,
    );
    if (confirmedDate == null || !mounted) return;
    setState(() {
      _moveDate = confirmedDate;
      _dateController.text = DateFormat('dd-MM-yyyy').format(_moveDate);
    });
    setState(() => _saving = true);
    try {
      final createRes = await _createMoveOrderWithDuplicateRetry();
      final created = createRes.data is Map<String, dynamic>
          ? createRes.data as Map<String, dynamic>
          : <String, dynamic>{};
      final moveOrderId = (created['id'] ?? '').toString().trim();
      if (moveOrderId.isEmpty) {
        throw Exception('Invalid move-order create response');
      }
      await _apiClient.post(
        '/move-orders/$moveOrderId/complete',
        data: {'completed_at': _moveDate.toIso8601String()},
      );
      if (!mounted) return;
      ZerpaiToast.success(context, 'Move order saved as $status.');
      context.go('/$_orgId/inventory/move-orders');
    } catch (error) {
      if (!mounted) return;
      ZerpaiToast.error(
        context,
        _extractApiErrorMessage(
          error,
          'Failed to save move order as completed',
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _extractApiErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final responseData = error.response?.data;
      if (responseData is Map) {
        final message = responseData['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
        final meta = responseData['meta'];
        if (meta is Map) {
          final metaError = meta['error'];
          if (metaError is Map) {
            final metaMessage = metaError['message'];
            if (metaMessage is String && metaMessage.trim().isNotEmpty) {
              return metaMessage.trim();
            }
          }
        }
      }
      final payload = error.error;
      if (payload is Map) {
        final msg = payload['message'];
        if (msg is String && msg.trim().isNotEmpty) return msg.trim();
      }
      final direct = error.message?.trim();
      if (direct != null && direct.isNotEmpty) return direct;
    }
    final raw = error.toString().trim();
    if (raw.isNotEmpty && raw.toLowerCase() != 'exception') return raw;
    return fallback;
  }

  Future<dynamic> _createMoveOrderWithDuplicateRetry({int maxAttempts = 3}) async {
    Object? lastError;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await _apiClient.post('/move-orders', data: _buildMoveOrderPayload());
      } catch (error) {
        lastError = error;
        final lower = error.toString().toLowerCase();
        final isDuplicateNumber =
            lower.contains('inventory_move_orders_move_order_number_key') ||
            lower.contains('duplicate key value violates unique constraint');
        if (!_autoGenerate || !isDuplicateNumber || attempt == maxAttempts - 1) {
          rethrow;
        }
        await _seedMoveOrderNumberFromDb();
      }
    }
    throw lastError ?? Exception('Failed to create move order');
  }

  Map<String, dynamic> _buildMoveOrderPayload() {
    final items = _rows
        .where((row) => row.selectedProduct != null)
        .map((row) {
          final qty = double.tryParse(row.quantityController.text.trim()) ?? 0;
          final sourceRows = row.sourceBins
              .where((line) => line.binId.trim().isNotEmpty && line.qty > 0)
              .map(
                (line) => {
                  'source_layer_id': '',
                  'batch_id': line.batchId.trim(),
                  'source_bin_id': line.binId.trim(),
                  'qty_out': line.qty,
                },
              )
              .toList(growable: false);
          final destinationRows = row.destinationBins
              .where((line) => line.binId.trim().isNotEmpty && line.qty > 0)
              .map(
                (line) => {
                  'source_layer_id': '',
                  'source_bin_id': '',
                  'batch_id': line.batchId.trim(),
                  'destination_bin_id': line.binId.trim(),
                  'qty_in': line.qty,
                },
              )
              .toList(growable: false);
          return {
            'product_id': row.selectedProduct!.id,
            'qty': qty,
            'remarks': row.descriptionController.text.trim(),
            'source_batches': sourceRows,
            'destination_bins': destinationRows,
          };
        })
        .where((item) => ((item['qty'] as num?) ?? 0) > 0)
        .toList(growable: false);
    return {
      'move_order_number': _moveOrderController.text.trim(),
      'move_date': _moveDate.toIso8601String(),
      'warehouse_id': _selectedWarehouse?.id.trim(),
      'assignee_id': _selectedAssignee?.id,
      'notes': _notesController.text.trim(),
      'status': 'draft',
      'items': items,
    };
  }

  Future<void> _seedMoveOrderNumberFromDb() async {
    try {
      final prefix = _prefixController.text.trim().isEmpty
          ? 'MO-'
          : _prefixController.text.trim();
      final padding = _nextNumberController.text.trim().isEmpty
          ? 5
          : _nextNumberController.text.trim().length;
      final pattern = RegExp('^${RegExp.escape(prefix)}(\\d+)\$');

      int page = 1;
      int maxValue = 0;
      bool hasMore = true;
      while (hasMore && page <= 10) {
        final response = await _apiClient.get(
          '/move-orders',
          useCache: false,
          queryParameters: <String, dynamic>{'page': page, 'limit': 200},
        );
        final payload = response.data;
        List<dynamic> rows = const <dynamic>[];
        if (payload is Map<String, dynamic>) {
          final node = payload['data'];
          if (node is List) rows = node;
        } else if (payload is List) {
          rows = payload;
        }
        if (rows.isEmpty) {
          hasMore = false;
          break;
        }

        for (final raw in rows.whereType<Map>()) {
          final map = Map<String, dynamic>.from(raw);
          final number = (map['move_order_number'] ?? '').toString().trim();
          final match = pattern.firstMatch(number);
          if (match == null) continue;
          final value = int.tryParse(match.group(1) ?? '') ?? 0;
          if (value > maxValue) maxValue = value;
        }

        hasMore = rows.length >= 200;
        page += 1;
      }

      final next = (maxValue + 1).toString().padLeft(padding, '0');
      if (!mounted) return;
      setState(() {
        _nextNumberController.text = next;
        if (_autoGenerate) {
          _moveOrderController.text = '$prefix$next';
        }
      });
    } catch (_) {
      // Keep existing number if lookup fails; save path still validates server-side.
    }
  }

  bool _validate() {
    if (_selectedWarehouse == null) {
      ZerpaiToast.error(context, 'Please select location.');
      return false;
    }
    final activeRows = _rows.where((r) => r.selectedProduct != null).toList();
    if (activeRows.isEmpty) {
      ZerpaiToast.error(context, 'Please add at least one item.');
      return false;
    }
    for (final row in activeRows) {
      final qty = double.tryParse(row.quantityController.text.trim()) ?? 0;
      if (qty <= 0) {
        ZerpaiToast.error(context, 'Quantity must be greater than zero.');
        return false;
      }
      if (row.selectedProduct?.trackBinLocation == true) {
        if (row.sourceBins.isEmpty) {
          ZerpaiToast.error(
            context,
            'Please select source bins for ${row.selectedProduct!.name}.',
          );
          return false;
        }
        if (row.destinationBins.isEmpty) {
          ZerpaiToast.error(
            context,
            'Please select destination bins for ${row.selectedProduct!.name}.',
          );
          return false;
        }
        final source = _totalBinQty(row.sourceBins);
        final destination = _totalBinQty(row.destinationBins);
        if (_hasSameSourceAndDestinationBin(
          sourceBins: row.sourceBins,
          destinationBins: row.destinationBins,
        )) {
          ZerpaiToast.error(
            context,
            'Source and destination bins cannot be the same for ${row.selectedProduct!.name}.',
          );
          return false;
        }
        if ((source - qty).abs() > 0.0001 ||
            (destination - qty).abs() > 0.0001) {
          ZerpaiToast.error(
            context,
            'Bin quantities must match row quantity for ${row.selectedProduct!.name}.',
          );
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _openItemDetailsDrawerForRow(
    BuildContext rowContext,
    int rowIndex,
  ) async {
    if (rowIndex < 0 || rowIndex >= _rows.length) return;
    final itemId = _rows[rowIndex].selectedProduct?.id.trim() ?? '';
    if (itemId.isEmpty) {
      ZerpaiToast.error(context, 'Select an item first');
      return;
    }
    try {
      final item = await ref
          .read(itemsControllerProvider.notifier)
          .ensureItemLoaded(itemId, forceRefresh: true);
      if (!mounted) return;
      if (item == null) {
        ZerpaiToast.error(context, 'Failed to load item details.');
        return;
      }
      ref.read(itemDetailsSidebarProvider.notifier).state = item;
      final drawerContext = _drawerHostContext ?? rowContext;
      final scaffoldState = Scaffold.maybeOf(drawerContext);
      scaffoldState?.openEndDrawer();
    } catch (_) {
      if (!mounted) return;
      ZerpaiToast.error(context, 'Failed to load item details.');
    }
  }

  void _openEditItemForRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= _rows.length) return;
    final itemId = _rows[rowIndex].selectedProduct?.id.trim() ?? '';
    if (itemId.isEmpty) {
      ZerpaiToast.error(context, 'Select an item first');
      return;
    }
    final targetPath = '/$_orgId/items/edit/$itemId';
    if (kIsWeb) {
      web.window.open(targetPath, '_blank');
      return;
    }
    context.push(targetPath);
  }
}

class _MoveItemRowDraft {
  _MoveItemRowDraft({
    required this.itemController,
    required this.descriptionController,
    required this.quantityController,
  });

  final TextEditingController itemController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  _MoveProductOption? selectedProduct;
  List<_BinLine> sourceBins = <_BinLine>[];
  List<_BinLine> destinationBins = <_BinLine>[];

  void clear() {
    itemController.clear();
    descriptionController.clear();
    quantityController.clear();
    selectedProduct = null;
    sourceBins = <_BinLine>[];
    destinationBins = <_BinLine>[];
  }

  void dispose() {
    itemController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
  }
}

class _MoveProductOption {
  const _MoveProductOption({
    required this.id,
    required this.name,
    required this.code,
    required this.sku,
    required this.upc,
    required this.ean,
    required this.description,
    required this.trackBinLocation,
    required this.trackBatches,
  });

  final String id;
  final String name;
  final String code;
  final String sku;
  final String upc;
  final String ean;
  final String description;
  final bool trackBinLocation;
  final bool trackBatches;

  factory _MoveProductOption.fromMap(Map<String, dynamic> json) {
    return _MoveProductOption(
      id: (json['id'] ?? '').toString(),
      name: (json['product_name'] ?? json['name'] ?? '').toString(),
      code: (json['item_code'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      upc: (json['upc'] ?? '').toString(),
      ean: (json['ean'] ?? '').toString(),
      description:
          (json['sales_description'] ??
                  json['salesDescription'] ??
                  json['description'] ??
                  '')
              .toString(),
      trackBinLocation: json['track_bin_location'] == true,
      trackBatches: json['track_batches'] == true,
    );
  }
}

class _AssigneeOption {
  const _AssigneeOption({
    required this.id,
    required this.fullName,
    required this.email,
  });

  final String id;
  final String fullName;
  final String email;

  factory _AssigneeOption.fromJson(Map<String, dynamic> json) {
    return _AssigneeOption(
      id: (json['id'] ?? '').toString().trim(),
      fullName: (json['full_name'] ?? json['name'] ?? '').toString().trim(),
      email: (json['email'] ?? '').toString().trim(),
    );
  }
}

class _BinOption {
  const _BinOption({required this.id, required this.code, required this.stock});
  final String id;
  final String code;
  final double stock;
}

class _BatchOption {
  const _BatchOption({
    required this.id,
    required this.reference,
    required this.manufacturerBatchNo,
    required this.mfgDate,
    required this.expiryDate,
    required this.availableQty,
    required this.connectedBinIds,
  });

  final String id;
  final String reference;
  final String manufacturerBatchNo;
  final String mfgDate;
  final String expiryDate;
  final double availableQty;
  final Set<String> connectedBinIds;
}

class _BinLine {
  const _BinLine({
    required this.binId,
    required this.binCode,
    required this.qty,
    this.batchId = '',
    this.batchRef = '',
    this.manufacturerBatchNo = '',
    this.mfgDate = '',
    this.expiryDate = '',
    this.availableQty = 0,
  });
  final String binId;
  final String binCode;
  final double qty;
  final String batchId;
  final String batchRef;
  final String manufacturerBatchNo;
  final String mfgDate;
  final String expiryDate;
  final double availableQty;
}

class _MoveFieldSkeleton extends StatelessWidget {
  const _MoveFieldSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: ZBone(height: 14, width: 140),
    );
  }
}

enum _ScanStage { source, destination }
