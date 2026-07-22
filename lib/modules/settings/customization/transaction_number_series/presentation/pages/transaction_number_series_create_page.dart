import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/settings/customization/transaction_number_series/presentation/providers/transaction_number_series_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class TransactionNumberSeriesCreatePage extends ConsumerStatefulWidget {
  const TransactionNumberSeriesCreatePage({super.key});

  @override
  ConsumerState<TransactionNumberSeriesCreatePage> createState() =>
      _TransactionNumberSeriesCreatePageState();
}

class _TransactionNumberSeriesCreatePageState
    extends ConsumerState<TransactionNumberSeriesCreatePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _seriesNameController = TextEditingController();

  final List<_SeriesCreateRow> _rows = _seedRows
      .map((row) => row.copy())
      .toList(growable: false);
  bool _didLoadInitialRecord = false;
  int? _editingIndex;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _seriesNameController.dispose();
    for (final row in _rows) {
      row.prefixController.dispose();
      row.startingController.dispose();
    }
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadInitialRecord) return;
    _didLoadInitialRecord = true;

    final editIndexParam = GoRouterState.of(
      context,
    ).uri.queryParameters['editIndex'];
    final editIndex = int.tryParse(editIndexParam ?? '');
    if (editIndex == null) return;

    final records = ref.read(transactionNumberSeriesProvider);
    if (editIndex < 0 || editIndex >= records.length) return;

    _editingIndex = editIndex;
    _loadRecordForEdit(records[editIndex]);
  }

  void _loadRecordForEdit(TransactionNumberSeriesRecord record) {
    _seriesNameController.text = record.seriesName;

    final moduleValues = <String, String>{
      'Vendor Payment': record.vendorPayment,
      'Retainer Invoice': record.retainerInvoice,
      'Purchase Order': record.purchaseOrder,
      'Credit Note': record.creditNote,
      'Customer Payment': record.customerPayment,
      'Delivery Challan': record.deliveryChallan,
      'Bill Of Supply': record.billOfSupply,
      'Invoice': record.invoice,
      'Sales Order': record.salesOrder,
      'Self-Invoice': record.selfInvoice,
    };

    for (final row in _rows) {
      final rawValue = moduleValues[row.module];
      if (rawValue == null) continue;
      final split = _splitSeriesValue(
        rawValue,
        expectedStartingLength: row.startingNumber.length,
      );
      row.prefixController.text = split.$1;
      row.startingController.text = split.$2;
    }
  }

  (String, String) _splitSeriesValue(
    String value, {
    required int expectedStartingLength,
  }) {
    if (value.isEmpty) return ('', '');
    if (value.length <= expectedStartingLength) return ('', value);
    return (
      value.substring(0, value.length - expectedStartingLength),
      value.substring(value.length - expectedStartingLength),
    );
  }

  String _seriesValueForModule(String moduleName) {
    for (final row in _rows) {
      if (row.module == moduleName) {
        return '${row.prefixController.text}${row.startingController.text}';
      }
    }
    return '';
  }

  void _saveSeries() {
    final seriesName = _seriesNameController.text.trim();
    if (seriesName.isEmpty) {
      ZerpaiToast.error(context, 'Series Name is required');
      return;
    }

    final record = TransactionNumberSeriesRecord(
      seriesName: seriesName,
      vendorPayment: _seriesValueForModule('Vendor Payment'),
      retainerInvoice: _seriesValueForModule('Retainer Invoice'),
      purchaseOrder: _seriesValueForModule('Purchase Order'),
      creditNote: _seriesValueForModule('Credit Note'),
      customerPayment: _seriesValueForModule('Customer Payment'),
      deliveryChallan: _seriesValueForModule('Delivery Challan'),
      billOfSupply: _seriesValueForModule('Bill Of Supply'),
      invoice: _seriesValueForModule('Invoice'),
      salesOrder: _seriesValueForModule('Sales Order'),
      selfInvoice: _seriesValueForModule('Self-Invoice'),
      associatedLocations: '--',
    );

    final notifier = ref.read(transactionNumberSeriesProvider.notifier);
    final request = _editingIndex != null
        ? notifier.updateSeries(_editingIndex!, record)
        : notifier.addSeries(record);

    request
        .then((_) {
          if (!mounted) return;
          context.go(_withOrgPrefix(AppRoutes.settingsTransactionNumberSeries));
        })
        .catchError((error) {
          if (!mounted) return;
          ZerpaiToast.error(context, error.toString());
        });
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return kSettingsNavigationSections
        .expand(
          (section) => section.blocks.expand(
            (block) => block.items.map(
              (entry) => SettingsSearchItem(
                group: block.title,
                label: entry.label,
                subtitle: section.title,
                keywords: <String>[section.title, block.title],
                onSelected: () {
                  if (entry.route == null) return;
                  context.go(_withOrgPrefix(entry.route!));
                },
              ),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';
    final currentPath = GoRouterState.of(context).uri.path;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: ColoredBox(
        color: const Color(0xFFF7F8FC),
        child: Column(
          children: [
            _CreateHeader(
              orgName: orgName,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchItems: _buildSearchItems(),
              onBack: () => context.go(_withOrgPrefix(AppRoutes.settings)),
              onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CreatePaneHeader(
                            title: _editingIndex != null
                                ? 'Edit Series'
                                : 'New Series',
                            onClose: () => context.go(
                              _withOrgPrefix(
                                AppRoutes.settingsTransactionNumberSeries,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FormRow(
                                    label: 'Series Name*',
                                    labelColor: const Color(0xFFFF2E2E),
                                    child: SizedBox(
                                      width: 490,
                                      child: CustomTextField(
                                        controller: _seriesNameController,
                                        height: 38,
                                        forceUppercase: false,
                                        contentCase: ContentCase.none,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  _CreateSeriesTable(rows: _rows),
                                ],
                              ),
                            ),
                          ),
                          _CreateFooter(
                            onSave: _saveSeries,
                            onCancel: () => context.go(
                              _withOrgPrefix(
                                AppRoutes.settingsTransactionNumberSeries,
                              ),
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
      ),
    );
  }
}

class _CreateHeader extends StatelessWidget {
  const _CreateHeader({
    required this.orgName,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchItems,
    required this.onBack,
    required this.onClose,
  });

  final String orgName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_outlined,
              color: Color(0xFFFF5D5D),
              size: 28,
            ),
          ),
          Container(
            width: 1,
            height: 46,
            margin: const EdgeInsets.only(right: 14),
            color: AppTheme.borderLight,
          ),
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD8DDF0)),
              ),
              child: const Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Settings',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                orgName,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 340,
            child: SettingsSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              items: searchItems,
            ),
          ),
          const SizedBox(width: 18),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Text(
                    'Close Settings',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.close, size: 15, color: Color(0xFFFF5C73)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatePaneHeader extends StatelessWidget {
  const _CreatePaneHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppTheme.pageTitle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 20, color: Color(0xFFFF4A4A)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.label, required this.child, this.labelColor});

  final String label;
  final Widget child;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 262,
          child: Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 15,
              color: labelColor ?? Colors.black,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _CreateSeriesTable extends StatelessWidget {
  const _CreateSeriesTable({required this.rows});

  final List<_SeriesCreateRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: FixedColumnWidth(250),
          1: FixedColumnWidth(315),
          2: FixedColumnWidth(190),
          3: FixedColumnWidth(250),
          4: FixedColumnWidth(250),
        },
        children: [
          const TableRow(
            children: [
              _CreateHeaderCell(label: 'MODULE'),
              _CreateHeaderCell(label: 'PREFIX'),
              _CreateHeaderCell(
                label: 'STARTING NUMBER',
                tooltipMessage:
                    'This will be the number assigned to the next transaction you create.',
              ),
              _CreateHeaderCell(
                label: 'RESTART NUMBERING',
                tooltipMessage:
                    'Choose when to restart numbering the transactions with the starting number.',
              ),
              _CreateHeaderCell(
                label: 'PREVIEW',
                tooltipMessage:
                    'You can preview your transaction numbers here once you save the series.',
              ),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                _CreateBodyLabelCell(label: row.module),
                _PrefixCell(
                  controller: row.prefixController,
                  initialSelectedPlaceholder: row.selectedPlaceholder,
                  initialSelectedPlaceholderValue: row.selectedPlaceholderValue,
                  onSelectedPlaceholderChanged: (value) {
                    row.selectedPlaceholder = value;
                  },
                  onSelectedPlaceholderValueChanged: (value) {
                    row.selectedPlaceholderValue = value;
                  },
                ),
                _StartingNumberCell(controller: row.startingController),
                _RestartNumberingCell(row: row),
                _PreviewCell(row: row),
              ],
            ),
        ],
      ),
    );
  }
}

class _CreateHeaderCell extends StatelessWidget {
  const _CreateHeaderCell({required this.label, this.tooltipMessage})
    : showInfo = false;

  final String label;
  final bool showInfo;
  final String? tooltipMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFCFE),
        border: Border(
          right: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.captionText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6C718A),
                letterSpacing: 0.1,
              ),
            ),
            if (tooltipMessage != null || showInfo) ...[
              const SizedBox(width: 4),
              if (tooltipMessage != null)
                ZTooltip(message: tooltipMessage!)
              else
                const Icon(Icons.info, size: 14, color: Color(0xFFA8ADC1)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CreateBodyLabelCell extends StatelessWidget {
  const _CreateBodyLabelCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Text(label, style: AppTheme.bodyText.copyWith(fontSize: 15)),
    );
  }
}

class _PrefixCell extends StatelessWidget {
  const _PrefixCell({
    this.controller,
    this.initialSelectedPlaceholder,
    this.initialSelectedPlaceholderValue,
    this.onSelectedPlaceholderChanged,
    this.onSelectedPlaceholderValueChanged,
  }) : prefix = null;

  final String? prefix;
  final TextEditingController? controller;
  final String? initialSelectedPlaceholder;
  final String? initialSelectedPlaceholderValue;
  final ValueChanged<String>? onSelectedPlaceholderChanged;
  final ValueChanged<String>? onSelectedPlaceholderValueChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveController =
        controller ?? TextEditingController(text: prefix ?? '');
    var isFocused = false;
    var isHovered = false;
    var suppressHoverBorder = false;
    String? selectedPlaceholder = initialSelectedPlaceholder;
    String? selectedPlaceholderValue = initialSelectedPlaceholderValue;
    return StatefulBuilder(
      builder: (context, setState) {
        final showActiveBorder =
            isFocused || (isHovered && !suppressHoverBorder);

        void appendToken(String? token) {
          if (token == null) return;
          FocusScope.of(context).unfocus();
          setState(() {
            isFocused = false;
            isHovered = false;
            suppressHoverBorder = true;
            effectiveController.text = '${effectiveController.text}$token';
            effectiveController.selection = TextSelection.collapsed(
              offset: effectiveController.text.length,
            );
          });
        }

        return MouseRegion(
          onEnter: (_) {
            setState(() {
              if (!suppressHoverBorder) {
                isHovered = true;
              }
            });
          },
          onExit: (_) {
            setState(() {
              isHovered = false;
              suppressHoverBorder = false;
            });
          },
          child: Container(
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: AppTheme.borderLight),
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Focus(
                        onFocusChange: (focused) {
                          setState(() {
                            isFocused = focused;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 6),
                          child: CustomTextField(
                            controller: effectiveController,
                            height: 34,
                            hideBorderDefault: true,
                            border: Border.all(color: Colors.transparent),
                            forceUppercase: false,
                            contentCase: ContentCase.none,
                            keyboardType: TextInputType.text,
                            textStyle: AppTheme.bodyText.copyWith(fontSize: 15),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: double.infinity,
                      color: const Color(0xFFFBFCFF),
                      child: Center(
                        child: MenuAnchor(
                          alignmentOffset: const Offset(-158, 10),
                          style: const MenuStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Colors.white,
                            ),
                            surfaceTintColor: WidgetStatePropertyAll(
                              Colors.white,
                            ),
                            padding: WidgetStatePropertyAll(
                              EdgeInsets.fromLTRB(10, 10, 10, 8),
                            ),
                            elevation: WidgetStatePropertyAll(10),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          menuChildren: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(2, 4, 2, 10),
                              child: Text(
                                'PLACEHOLDER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF8D94AA),
                                  letterSpacing: 0.18,
                                ),
                              ),
                            ),
                            ..._prefixPlaceholderItems.map((item) {
                              final submenuItems =
                                  _prefixPlaceholderChildItems[item] ??
                                  const [];
                              if (submenuItems.isEmpty) {
                                return _PrefixPlaceholderPlainMenuItem(
                                  label: item,
                                  onTap: () {
                                    selectedPlaceholder = item;
                                    selectedPlaceholderValue = null;
                                    onSelectedPlaceholderChanged?.call(item);
                                    appendToken(
                                      _prefixPlaceholderTokenValues[item],
                                    );
                                  },
                                );
                              }
                              return _PrefixPlaceholderSubmenuItem(
                                label: item,
                                selected: selectedPlaceholder == item,
                                selectedChildValue: selectedPlaceholder == item
                                    ? selectedPlaceholderValue
                                    : null,
                                submenuItems: submenuItems,
                                onSelected: (childValue) {
                                  selectedPlaceholder = item;
                                  selectedPlaceholderValue = childValue;
                                  onSelectedPlaceholderChanged?.call(item);
                                  onSelectedPlaceholderValueChanged?.call(
                                    childValue,
                                  );
                                  appendToken(
                                    _prefixPlaceholderTokenValuesByChild[item]?[childValue],
                                  );
                                },
                              );
                            }),
                          ],
                          builder: (context, menuController, child) {
                            return InkWell(
                              onTap: () => menuController.isOpen
                                  ? menuController.close()
                                  : menuController.open(),
                              borderRadius: BorderRadius.circular(999),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF2F6BFF),
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: Center(
                                    child: Icon(
                                      Icons.add,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                if (showActiveBorder)
                  Positioned.fill(
                    left: 2,
                    top: 2,
                    right: 2,
                    bottom: 2,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryBlue,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StartingNumberCell extends StatelessWidget {
  const _StartingNumberCell({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    var isFocused = false;
    var isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Focus(
            onFocusChange: (focused) => setState(() => isFocused = focused),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isFocused || isHovered ? 8 : 0,
                ),
                border: Border(
                  top: BorderSide(
                    color: isFocused || isHovered
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    width: isFocused || isHovered ? 1.2 : 1,
                  ),
                  left: BorderSide(
                    color: isFocused || isHovered
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    width: isFocused || isHovered ? 1.2 : 1,
                  ),
                  right: BorderSide(
                    color: isFocused || isHovered
                        ? AppTheme.primaryBlue
                        : AppTheme.borderLight,
                    width: isFocused || isHovered ? 1.2 : 1,
                  ),
                  bottom: BorderSide(
                    color: isFocused || isHovered
                        ? AppTheme.primaryBlue
                        : AppTheme.borderLight,
                    width: isFocused || isHovered ? 1.2 : 1,
                  ),
                ),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 120,
                  child: CustomTextField(
                    controller: controller,
                    height: 34,
                    hideBorderDefault: true,
                    border: Border.all(color: Colors.transparent),
                    forceUppercase: false,
                    contentCase: ContentCase.none,
                    keyboardType: TextInputType.text,
                    textStyle: AppTheme.bodyText.copyWith(fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RestartNumberingCell extends StatefulWidget {
  const _RestartNumberingCell({required this.row});

  final _SeriesCreateRow row;

  @override
  State<_RestartNumberingCell> createState() => _RestartNumberingCellState();
}

class _RestartNumberingCellState extends State<_RestartNumberingCell> {
  static const List<String> _items = ['None', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    var isFocused = false;
    var isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Focus(
            onFocusChange: (focused) => setState(() => isFocused = focused),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isFocused || isHovered ? 8 : 0,
                ),
                border: Border(
                  top: BorderSide(
                    color: isFocused || isHovered
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    width: isFocused || isHovered ? 1.2 : 1,
                  ),
                  left: BorderSide(
                    color: isFocused || isHovered
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    width: isFocused || isHovered ? 1.2 : 1,
                  ),
                  right: BorderSide(
                    color: isFocused || isHovered
                        ? AppTheme.primaryBlue
                        : AppTheme.borderLight,
                    width: isFocused || isHovered ? 1.2 : 1,
                  ),
                  bottom: BorderSide(
                    color: isFocused || isHovered
                        ? AppTheme.primaryBlue
                        : AppTheme.borderLight,
                    width: isFocused || isHovered ? 1.2 : 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: FormDropdown<String>(
                  value: widget.row.restartNumbering,
                  items: _items,
                  onChanged: (value) {
                    setState(() {
                      widget.row.restartNumbering = value ?? 'None';
                      isFocused = false;
                    });
                  },
                  height: 40,
                  menuWidth: 240,
                  menuMaxHeight: 148,
                  maxVisibleItems: 2,
                  itemHeight: 36,
                  placeholder: 'Search',
                  showSearch: true,
                  showSearchIcon: true,
                  hideBorderDefault: true,
                  border: Border.all(color: Colors.transparent),
                  activeBorderColor: Colors.transparent,
                  fillColor: Colors.white,
                  textStyle: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                  iconSize: 18,
                  itemBuilder: (item, selected, hovered) {
                    final bool showBlue = hovered;
                    final Color background = showBlue
                        ? const Color(0xFF3B82F6)
                        : (selected ? const Color(0xFFF3F4F6) : Colors.white);
                    final Color textColor = showBlue
                        ? Colors.white
                        : const Color(0xFF3D4663);
                    final Color iconColor = showBlue
                        ? Colors.white
                        : const Color(0xFF2F6BFF);

                    return Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 14,
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(Icons.check, size: 16, color: iconColor),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PreviewCell extends StatelessWidget {
  const _PreviewCell({required this.row});

  final _SeriesCreateRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: row.prefixController,
        builder: (context, _, __) {
          return ValueListenableBuilder<TextEditingValue>(
            valueListenable: row.startingController,
            builder: (context, _, __) {
              return Text(
                row.previewText,
                style: AppTheme.bodyText.copyWith(fontSize: 15),
              );
            },
          );
        },
      ),
    );
  }
}

class _CreateFooter extends StatelessWidget {
  const _CreateFooter({required this.onSave, required this.onCancel});

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 36,
            child: ZButton.primary(
              label: 'Save',
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onSave,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ZButton.secondary(
              label: 'Cancel',
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: onCancel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesCreateRow {
  final String module;
  final String prefix;
  final String startingNumber;
  final String preview;
  final TextEditingController prefixController;
  final TextEditingController startingController;
  String restartNumbering;
  String? selectedPlaceholder;
  String? selectedPlaceholderValue;

  _SeriesCreateRow({
    required this.module,
    required this.prefix,
    required this.startingNumber,
    required this.preview,
    this.restartNumbering = 'None',
    this.selectedPlaceholder,
    this.selectedPlaceholderValue,
  }) : prefixController = TextEditingController(text: prefix),
       startingController = TextEditingController(text: startingNumber);

  _SeriesCreateRow copy() => _SeriesCreateRow(
    module: module,
    prefix: prefix,
    startingNumber: startingNumber,
    preview: preview,
    restartNumbering: restartNumbering,
    selectedPlaceholder: selectedPlaceholder,
    selectedPlaceholderValue: selectedPlaceholderValue,
  );

  String get previewText =>
      '${prefixController.text}${startingController.text}';
}

class _SeriesCreateSeed {
  const _SeriesCreateSeed({
    required this.module,
    required this.prefix,
    required this.startingNumber,
    required this.preview,
    this.restartNumbering = 'None',
  });

  final String module;
  final String prefix;
  final String startingNumber;
  final String preview;
  final String restartNumbering;

  _SeriesCreateRow copy() => _SeriesCreateRow(
    module: module,
    prefix: prefix,
    startingNumber: startingNumber,
    preview: preview,
    restartNumbering: restartNumbering,
  );
}

final List<_SeriesCreateSeed> _seedRows = [
  _SeriesCreateSeed(
    module: 'Credit Note',
    prefix: 'CN-',
    startingNumber: '00001',
    preview: 'CN-00001',
  ),
  _SeriesCreateSeed(
    module: 'Customer Payment',
    prefix: '',
    startingNumber: '1',
    preview: '1',
  ),
  _SeriesCreateSeed(
    module: 'Purchase Order',
    prefix: 'PO-',
    startingNumber: '00001',
    preview: 'PO-00001',
  ),
  _SeriesCreateSeed(
    module: 'Sales Order',
    prefix: 'SO-',
    startingNumber: '00001',
    preview: 'SO-00001',
  ),
  _SeriesCreateSeed(
    module: 'Vendor Payment',
    prefix: '',
    startingNumber: '1',
    preview: '1',
  ),
  _SeriesCreateSeed(
    module: 'Retainer Invoice',
    prefix: 'RET-',
    startingNumber: '00001',
    preview: 'RET-00001',
  ),
  _SeriesCreateSeed(
    module: 'Bill Of Supply',
    prefix: 'BOS-',
    startingNumber: '000001',
    preview: 'BOS-000001',
  ),
  _SeriesCreateSeed(
    module: 'Invoice',
    prefix: 'INV-',
    startingNumber: '000001',
    preview: 'INV-000001',
  ),
  _SeriesCreateSeed(
    module: 'Delivery Challan',
    prefix: 'DC-',
    startingNumber: '00001',
    preview: 'DC-00001',
    restartNumbering: 'Yearly',
  ),
  _SeriesCreateSeed(
    module: 'Self-Invoice',
    prefix: '',
    startingNumber: '1',
    preview: '1',
  ),
];

const List<String> _prefixPlaceholderItems = [
  'Fiscal Year Start',
  'Fiscal Year End',
  'Transaction Year',
  'Transaction Date',
  'Transaction Month',
];

const Map<String, List<String>> _prefixPlaceholderChildItems = {
  'Fiscal Year Start': ['YY', 'YYYY'],
  'Fiscal Year End': ['YY', 'YYYY'],
  'Transaction Year': ['YY', 'YYYY'],
  'Transaction Month': ['MM', 'MMM'],
};

const Map<String, String> _prefixPlaceholderTokenValues = {
  'Transaction Date': '%DD%',
};

const Map<String, Map<String, String>> _prefixPlaceholderTokenValuesByChild = {
  'Fiscal Year Start': {'YY': '%FYS_YY%', 'YYYY': '%FYS_YYYY%'},
  'Fiscal Year End': {'YY': '%FYE_YY%', 'YYYY': '%FYE_YYYY%'},
  'Transaction Year': {'YY': '%YY%', 'YYYY': '%YYYY%'},
  'Transaction Month': {'MM': '%MM%', 'MMM': '%MMM%'},
};

class _PrefixPlaceholderPlainMenuItem extends StatelessWidget {
  const _PrefixPlaceholderPlainMenuItem({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onTap,
      style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return Colors.white;
          return const Color(0xFF515A70);
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(156, 34)),
        fixedSize: const WidgetStatePropertyAll(Size(156, 34)),
        alignment: Alignment.centerLeft,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _PrefixPlaceholderSubmenuItem extends StatefulWidget {
  const _PrefixPlaceholderSubmenuItem({
    required this.label,
    required this.selected,
    required this.submenuItems,
    required this.onSelected,
    this.selectedChildValue,
  });

  final String label;
  final bool selected;
  final List<String> submenuItems;
  final ValueChanged<String> onSelected;
  final String? selectedChildValue;

  @override
  State<_PrefixPlaceholderSubmenuItem> createState() =>
      _PrefixPlaceholderSubmenuItemState();
}

class _PrefixPlaceholderSubmenuItemState
    extends State<_PrefixPlaceholderSubmenuItem> {
  @override
  Widget build(BuildContext context) {
    return SubmenuButton(
      menuStyle: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.all(6)),
        elevation: WidgetStatePropertyAll(10),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return Colors.white;
          return const Color(0xFF515A70);
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(156, 34)),
        fixedSize: const WidgetStatePropertyAll(Size(156, 34)),
        alignment: Alignment.centerLeft,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      submenuIcon: const WidgetStatePropertyAll(SizedBox.shrink()),
      menuChildren: widget.submenuItems
          .map(
            (item) => _PrefixPlaceholderChildMenuItem(
              label: item,
              selected: widget.selectedChildValue == item,
              onTap: () => widget.onSelected(item),
            ),
          )
          .toList(),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrefixPlaceholderChildMenuItem extends StatelessWidget {
  const _PrefixPlaceholderChildMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onTap,
      style: ButtonStyle(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return AppTheme.primaryBlue;
          return Colors.white;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return Colors.white;
          return const Color(0xFF515A70);
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(72, 34)),
        fixedSize: const WidgetStatePropertyAll(Size(72, 34)),
        alignment: Alignment.centerLeft,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
