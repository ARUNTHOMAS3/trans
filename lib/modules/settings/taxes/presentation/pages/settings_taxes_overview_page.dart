import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/settings/taxes/models/settings_tax_rate_model.dart';
import 'package:zerpai_erp/modules/settings/taxes/presentation/dialogs/settings_tax_export_dialog.dart';
import 'package:zerpai_erp/modules/settings/taxes/providers/settings_tax_rates_provider.dart';
import 'package:zerpai_erp/modules/settings/taxes/presentation/widgets/settings_taxes_section_rail.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/models/account_node.dart';
import 'package:zerpai_erp/shared/widgets/inputs/account_tree_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';

class SettingsTaxesOverviewPage extends ConsumerStatefulWidget {
  const SettingsTaxesOverviewPage({super.key});

  static const double _toolbarHeight = 72;
  static const double _headerHeight = 39.4;
  static const double _rowHeight = 39.4;

  @override
  ConsumerState<SettingsTaxesOverviewPage> createState() =>
      _SettingsTaxesOverviewPageState();
}

Future<bool> _showTaxesDeleteConfirm(
  BuildContext context, {
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      return SafeArea(
        child: Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 625),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 76,
                  child: Row(
                    children: [
                      const SizedBox(width: 28),
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 34,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Container(
                  height: 64,
                  padding: const EdgeInsets.only(left: 24),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(49, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text('OK'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          minimumSize: const Size(79, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text('Cancel'),
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
  return result ?? false;
}

class _SettingsTaxesOverviewPageState
    extends ConsumerState<SettingsTaxesOverviewPage> {
  String _selectedSection = 'taxRates';
  final List<Map<String, dynamic>> _gstins = [
    {
      'gstin': '32AACCZ4912F1ZL',
      'state': 'Kerala',
      'legalName': 'ZABNIX PRIVATE LIMITED',
      'isActive': true,
    },
  ];
  int _selectedGstinIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final requestedSection = GoRouterState.of(
      context,
    ).uri.queryParameters['section'];
    if (_isValidTaxesSection(requestedSection) &&
        requestedSection != _selectedSection) {
      _selectedSection = requestedSection!;
    }
  }

  bool _isValidTaxesSection(String? section) {
    return section == 'taxRates' ||
        section == 'taxExemptions' ||
        section == 'gstTds' ||
        section == 'gstSettings';
  }

  void _handleTaxesSectionSelected(String section) {
    if (!_isValidTaxesSection(section)) return;
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    context.go('/$orgSystemId${AppRoutes.settingsTaxes}?section=$section');
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final orgName =
        ref.watch(authUserProvider)?.orgName.trim() ?? 'ORGANIZATION';

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSettingsSidebar = constraints.maxWidth >= 980;
        return Column(
          children: [
            _SettingsPageHeader(orgName: orgName),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSettingsSidebar)
                    SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: ColoredBox(
                      color: const Color(0xFFF5F6F7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SettingsTaxesSectionRail(
                            width: 240,
                            selected: _selectedSection,
                            onSelected: _handleTaxesSectionSelected,
                            gstins: _gstins,
                            selectedGstinIndex: _selectedGstinIndex,
                            onGstinSelected: (index) {
                              setState(() {
                                _selectedGstinIndex = index;
                              });
                            },
                            onGstinCreated: (data) {
                              setState(() {
                                String stateName = 'Kerala';
                                final gstin = data['gstin'] as String;
                                if (gstin.startsWith('33')) {
                                  stateName = 'Tamil Nadu';
                                } else if (gstin.startsWith('29')) {
                                  stateName = 'Karnataka';
                                }
                                final newItem = {...data, 'state': stateName};
                                _gstins.add(newItem);
                                _selectedGstinIndex = _gstins.length - 1;
                                _selectedSection = 'gstSettings';
                              });
                            },
                          ),
                          Expanded(
                            child: switch (_selectedSection) {
                              'taxExemptions' => const _TaxExemptionsReport(),
                              'gstTds' => const _GstTdsSettingsReport(),
                              'gstSettings' => _GstSettingsPage(
                                key: ValueKey(
                                  'gst_${_selectedGstinIndex}_${_gstins[_selectedGstinIndex]['isActive']}',
                                ),
                                newGstinData: _gstins[_selectedGstinIndex],
                                isActive:
                                    _gstins[_selectedGstinIndex]['isActive'] ??
                                    true,
                                onStatusChanged: (isActive) {
                                  setState(() {
                                    _gstins[_selectedGstinIndex]['isActive'] =
                                        isActive;
                                  });
                                },
                              ),
                              _ => const _TaxesReport(),
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsPageHeader extends StatefulWidget {
  const _SettingsPageHeader({required this.orgName});

  final String orgName;

  @override
  State<_SettingsPageHeader> createState() => _SettingsPageHeaderState();
}

class _SettingsPageHeaderState extends State<_SettingsPageHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final searchItems = [
      SettingsSearchItem(
        group: 'Taxes & Compliance',
        label: 'Taxes',
        keywords: const ['tax rates', 'gst', 'igst'],
        onSelected: () => context.go('/$orgSystemId${AppRoutes.settingsTaxes}'),
      ),
    ];

    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.receipt, size: 24, color: AppTheme.errorRed),
          const SizedBox(width: 14),
          Container(width: 1, height: 40, color: AppTheme.borderLight),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/$orgSystemId${AppRoutes.settings}');
                }
              },
              padding: EdgeInsets.zero,
              icon: const Icon(LucideIcons.chevronLeft, size: 17),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Settings',
                style: AppTheme.pageTitle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                widget.orgName,
                style: AppTheme.metaHelper.copyWith(
                  fontSize: 11,
                  color: AppTheme.textBody,
                ),
              ),
            ],
          ),
          const Spacer(),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: SettingsSearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                items: searchItems,
              ),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => context.go('/$orgSystemId/home'),
            iconAlignment: IconAlignment.end,
            icon: const Icon(LucideIcons.x, size: 15, color: AppTheme.errorRed),
            label: const Text('Close Settings'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              backgroundColor: AppTheme.bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxesReport extends ConsumerWidget {
  const _TaxesReport();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsTaxRatesProvider);
    final notifier = ref.read(settingsTaxRatesProvider.notifier);
    final rows = state.visibleRates;
    final selectableRows = rows.where((tax) => tax.isTaxGroup).toList();
    final allSelected =
        selectableRows.isNotEmpty &&
        selectableRows.every((tax) => state.selectedIds.contains(tax.id));
    Future<void> deleteSelectedTaxes() async {
      final selectedIds = state.selectedIds.toList();
      if (selectedIds.isEmpty) return;
      final confirmed = await _showTaxesDeleteConfirm(
        context,
        message: 'Are you sure about deleting these taxes?',
      );
      if (confirmed != true) return;
      for (final id in selectedIds) {
        SettingsTaxRate? selectedTax;
        for (final tax in state.rates) {
          if (tax.id == id) {
            selectedTax = tax;
            break;
          }
        }
        await notifier.deleteTax(
          id,
          isTaxGroup: selectedTax?.isTaxGroup ?? false,
        );
      }
    }

    final Widget body;
    if (state.isLoading && state.rates.isEmpty) {
      body = const SizedBox.shrink();
    } else if (state.errorMessage != null && state.rates.isEmpty) {
      body = _ErrorState(
        message: state.errorMessage!,
        onRetry: () => notifier.load(forceRefresh: true),
      );
    } else if (rows.isEmpty) {
      body = const _EmptyState();
    } else {
      body = _TaxesTable(
        rows: rows,
        allSelected: allSelected,
        selectedIds: state.selectedIds,
        onSelectAll: notifier.toggleSelectAll,
        onSelectRow: notifier.toggleSelection,
      );
    }

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.selectedIds.isNotEmpty)
            _TaxesSelectionBar(
              count: state.selectedIds.length,
              onDelete: deleteSelectedTaxes,
              onClose: () => notifier.toggleSelectAll(false),
            )
          else
            _TaxesToolbar(
              filter: state.filter,
              onFilterChanged: notifier.setFilter,
              onRefresh: () => notifier.load(forceRefresh: true),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _TaxesToolbar extends StatefulWidget {
  const _TaxesToolbar({
    required this.filter,
    required this.onFilterChanged,
    required this.onRefresh,
  });

  final SettingsTaxFilter filter;
  final ValueChanged<SettingsTaxFilter> onFilterChanged;
  final VoidCallback onRefresh;

  @override
  State<_TaxesToolbar> createState() => _TaxesToolbarState();
}

class _GstSettingsPage extends StatefulWidget {
  final Map<String, dynamic>? newGstinData;
  final bool isActive;
  final ValueChanged<bool>? onStatusChanged;

  const _GstSettingsPage({
    super.key,
    this.newGstinData,
    required this.isActive,
    this.onStatusChanged,
  });

  @override
  State<_GstSettingsPage> createState() => _GstSettingsPageState();
}

class _GstSettingsPageState extends State<_GstSettingsPage> {
  static const double _gstFieldWidth = 235;
  static const double _gstFieldHeight = 38;
  static const List<_DefaultTaxPreferenceOption> _intraStateTaxOptions = [
    _DefaultTaxPreferenceOption(label: 'Tax Group', isHeader: true),
    _DefaultTaxPreferenceOption(label: 'GST0 [0%]'),
    _DefaultTaxPreferenceOption(label: 'GST12 [12%]'),
    _DefaultTaxPreferenceOption(label: 'GST18 [18%]'),
    _DefaultTaxPreferenceOption(label: 'GST5 [5%]'),
  ];
  static const List<_DefaultTaxPreferenceOption> _interStateTaxOptions = [
    _DefaultTaxPreferenceOption(label: 'Tax', isHeader: true),
    _DefaultTaxPreferenceOption(label: 'IGST0 [0%]'),
    _DefaultTaxPreferenceOption(label: 'IGST12 [12%]'),
    _DefaultTaxPreferenceOption(label: 'IGST18 [18%]'),
    _DefaultTaxPreferenceOption(label: 'IGST28 [28%]'),
    _DefaultTaxPreferenceOption(label: 'IGST5 [5%]'),
  ];

  static const List<_RegistrationTypeOption> _registrationTypes = [
    _RegistrationTypeOption(
      label: 'Registered Business - Regular',
      description: 'Business that is registered under GST.',
    ),
    _RegistrationTypeOption(
      label: 'Input Service Distributor (ISD)',
      description:
          'My business distributes input tax credit (ITC) on services to its Locations.',
    ),
  ];

  final _gstinController = TextEditingController(text: '32AACCZ4912F1ZL');
  final _legalNameController = TextEditingController(
    text: 'ZABNIX PRIVATE LIMITED',
  );
  final _tradeNameController = TextEditingController();
  final _registeredOnController = TextEditingController();
  final _registeredOnKey = GlobalKey();
  String _tab = 'general';
  _RegistrationTypeOption _registrationType = _registrationTypes[0];
  String _intraStateTaxRate = 'GST12 [12%]';
  String _interStateTaxRate = 'IGST12 [12%]';
  bool _reverseCharge = false;
  bool _importExport = false;
  bool _digitalServices = false;
  String? _selectedBranch = 'Sahakar Tirur';

  final List<AccountDropdownItem> _accountsList = [
    const AccountDropdownItem(name: 'Expense', isHeader: true),
    const AccountDropdownItem(name: 'Advertising And Marketing'),
    const AccountDropdownItem(name: 'Automobile Expense'),
    const AccountDropdownItem(name: 'Bad Debt'),
    const AccountDropdownItem(name: 'Bank Chargers'),
    const AccountDropdownItem(
      name: 'Bank Charges Bandhan Bank',
      isSubItem: true,
    ),
    const AccountDropdownItem(name: 'Bank Charges GST', isSubItem: true),
    const AccountDropdownItem(name: 'MAB-C', isSubItem: true),
    const AccountDropdownItem(name: 'Bank Fees and Charges'),
    const AccountDropdownItem(name: 'Consultant Expense'),
    const AccountDropdownItem(name: 'Contract Assets'),
    const AccountDropdownItem(name: 'Credit Card Charges'),
    const AccountDropdownItem(name: 'Depreciation And Amortisation'),
    const AccountDropdownItem(name: 'Depreciation Expense'),
    const AccountDropdownItem(
      name: 'Employees Welfare Activities',
      isSubItem: true,
    ),
    const AccountDropdownItem(name: 'Exchange Gain or Loss'),
    const AccountDropdownItem(name: 'Food Allowance'),
    const AccountDropdownItem(
      name: 'Directors Food Allowance',
      isSubItem: true,
    ),
    const AccountDropdownItem(name: 'Meeting Food Allowance', isSubItem: true),
    const AccountDropdownItem(name: 'Freelancers-Wages'),
    const AccountDropdownItem(name: 'Fuel/Mileage Expenses'),
    const AccountDropdownItem(name: 'Interest and Late Fee'),
    const AccountDropdownItem(name: 'IT and Internet Expenses'),
    const AccountDropdownItem(name: 'Zoho Book', isSubItem: true),
    const AccountDropdownItem(name: 'Janitorial Expense'),
    const AccountDropdownItem(name: 'Lodging'),
    const AccountDropdownItem(name: 'Meals and Entertainment'),
    const AccountDropdownItem(name: 'Merchandise'),
    const AccountDropdownItem(name: 'Office Supplies'),
    const AccountDropdownItem(name: 'Other Expenses'),
    const AccountDropdownItem(name: 'Parking'),
    const AccountDropdownItem(name: 'Postage'),
    const AccountDropdownItem(name: 'Printing and Stationery'),
    const AccountDropdownItem(name: 'Purchase Discounts'),
    const AccountDropdownItem(name: 'Raw Materials And Consumables'),
    const AccountDropdownItem(name: 'Repairs and Maintenance'),
    const AccountDropdownItem(name: 'Room Rent Expense'),
    const AccountDropdownItem(name: 'SALARY PAID'),
    const AccountDropdownItem(name: 'Stay Allowance'),
    const AccountDropdownItem(
      name: 'Directors Stay Allowance',
      isSubItem: true,
    ),
    const AccountDropdownItem(name: 'Employee Stay Allowance', isSubItem: true),
    const AccountDropdownItem(name: 'Telephone Expense'),
    const AccountDropdownItem(name: 'Transportation Expense'),
    const AccountDropdownItem(name: 'Travel Allowance'),
    const AccountDropdownItem(
      name: 'Directors Travel Allowance',
      isSubItem: true,
    ),
    const AccountDropdownItem(
      name: 'Employee Travel Allowance',
      isSubItem: true,
    ),
    const AccountDropdownItem(name: 'Travel Expense'),
    const AccountDropdownItem(name: 'Uncategorized'),
    const AccountDropdownItem(name: 'Cost Of Goods Sold', isHeader: true),
    const AccountDropdownItem(name: 'C'),
    const AccountDropdownItem(name: 'cost'),
    const AccountDropdownItem(name: 'Cost of Goods Sold'),
    const AccountDropdownItem(name: 'Job Costing'),
    const AccountDropdownItem(name: 'Labor'),
    const AccountDropdownItem(name: 'Materials'),
    const AccountDropdownItem(name: 'shabi'),
    const AccountDropdownItem(name: 'Subcontractor'),
    const AccountDropdownItem(name: 'Other Expense', isHeader: true),
    const AccountDropdownItem(name: 'Administration'),
    const AccountDropdownItem(name: 'CA & Legal', isSubItem: true),
    const AccountDropdownItem(
      name: 'Municipality License Charges',
      isSubItem: true,
    ),
    const AccountDropdownItem(name: 'RCM (Rent 18% Tax)', isSubItem: true),
    const AccountDropdownItem(name: 'Utilities', isSubItem: true),
    const AccountDropdownItem(name: 'Domain Charges'),
  ];
  AccountDropdownItem? _selectedAccount;

  List<AccountNode> get _accountTreeNodes {
    final groups = <_SettingsAccountTreeDraftGroup>[];
    _SettingsAccountTreeDraftGroup? currentGroup;
    _SettingsAccountTreeDraftNode? currentParent;

    for (final item in _accountsList) {
      if (item.isHeader) {
        currentGroup = _SettingsAccountTreeDraftGroup(name: item.name);
        groups.add(currentGroup);
        currentParent = null;
        continue;
      }

      currentGroup ??= _SettingsAccountTreeDraftGroup(name: 'Accounts');
      if (groups.isEmpty) {
        groups.add(currentGroup);
      }

      final draftNode = _SettingsAccountTreeDraftNode(name: item.name);
      if (item.isSubItem && currentParent != null) {
        currentParent.children.add(draftNode);
      } else {
        currentGroup.children.add(draftNode);
        if (!item.isSubItem) {
          currentParent = draftNode;
        }
      }
    }

    return groups
        .map(
          (group) => AccountNode(
            id: '__account_group__${group.name}',
            name: group.name,
            selectable: false,
            children: group.children
                .map((node) => node.toAccountNode())
                .toList(),
          ),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _applyNewGstinData();
  }

  @override
  void didUpdateWidget(_GstSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.newGstinData != oldWidget.newGstinData) {
      _applyNewGstinData();
    }
  }

  void _applyNewGstinData() {
    final data = widget.newGstinData;
    if (data != null) {
      setState(() {
        _gstinController.text = data['gstin'] ?? '';
        _legalNameController.text = data['legalName'] ?? '';
        _tradeNameController.text = data['tradeName'] ?? '';
        _registeredOnController.text = data['registeredOn'] ?? '';
        if (data['registrationType'] != null) {
          final regOption = data['registrationType'] as _RegistrationTypeOption;
          final match = _registrationTypes.firstWhere(
            (element) => element.label == regOption.label,
            orElse: () => _registrationTypes[0],
          );
          _registrationType = match;
        }
        _reverseCharge = data['reverseCharge'] ?? false;
        _importExport = data['importExport'] ?? false;
        if (data['selectedAccount'] != null) {
          final accountItem = data['selectedAccount'] as AccountDropdownItem;
          final match = _accountsList.firstWhere(
            (element) => element.name == accountItem.name,
            orElse: () {
              _accountsList.add(accountItem);
              return accountItem;
            },
          );
          _selectedAccount = match;
        }
      });
    }
  }

  @override
  void dispose() {
    _gstinController.dispose();
    _legalNameController.dispose();
    _tradeNameController.dispose();
    _registeredOnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleBar(),
          _buildTabs(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 44, 34),
              child: _tab == 'general'
                  ? _buildGeneralTab()
                  : _buildDefaultPreferenceTab(),
            ),
          ),
          if (_tab == 'general') _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.fromLTRB(24, 0, 30, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final title = const Text(
            'GST Settings',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w400,
              color: Color(0xFF111111),
            ),
          );
          final action = OutlinedButton(
            onPressed: () {
              widget.onStatusChanged?.call(!widget.isActive);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111111),
              side: const BorderSide(color: Color(0xFFDADDE3)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(128, 40),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Text(
              widget.isActive ? 'Mark as Inactive' : 'Mark as Active',
            ),
          );
          if (constraints.maxWidth < 430) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 10), action],
              ),
            );
          }
          return Row(
            children: [
              Expanded(child: title),
              action,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 54,
      padding: const EdgeInsets.only(left: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          _tabButton('general', 'General'),
          const SizedBox(width: 28),
          _tabButton('default', 'Default Tax Preference'),
        ],
      ),
    );
  }

  Widget _tabButton(String value, String label) {
    final selected = _tab == value;
    return InkWell(
      onTap: () => setState(() => _tab = value),
      child: SizedBox(
        height: 54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? const Color(0xFF333333)
                    : const Color(0xFF56617A),
              ),
            ),
            const SizedBox(height: 9),
            Container(
              width: selected ? 60 : 0,
              height: 3,
              color: selected ? const Color(0xFF4285F4) : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formRow(
          labelText: 'Associated Locations',
          field: const Text(
            'ZABNIX PRIVATE LIMITED,SAHAKAR TIRUR',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF1F6FEB),
            ),
          ),
        ),
        _formRow(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Branch for GST Transactions', style: AppTextStyles.label),
              const SizedBox(width: 6),
              const ZTooltip(
                message:
                    'This branch is used to track the GST payments, the ITC reversal, and the GSTR-3B journals.',
                maxWidth: 320,
              ),
            ],
          ),
          field: _dropdownField<String>(
            value: _selectedBranch,
            items: const ['Sahakar Tirur', 'Sahakar Pvt Limited'],
            hint: 'Select a branch',
            onChanged: (value) => setState(() => _selectedBranch = value),
          ),
        ),
        _formRow(
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZTooltip(
                message:
                    '15 digit number that you receive upon registering for GST',
                maxWidth: 320,
                child: Text(
                  'GSTIN *',
                  style: AppTextStyles.labelRequired.copyWith(
                    fontWeight: FontWeight.normal,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ),
              Text(
                'Maximum 15 digits',
                style: AppTextStyles.helper.copyWith(fontSize: 12),
              ),
            ],
          ),
          field: _gstinField(),
        ),
        _formRow(
          labelText: 'Registration Type',
          field: SizedBox(
            width: _fieldWidth(context),
            height: _gstFieldHeight,
            child: FormDropdown<_RegistrationTypeOption>(
              value: _registrationType,
              hint: 'Select a Registration Type',
              items: _registrationTypes,
              displayStringForValue: (value) => value.label,
              searchStringForValue: (value) =>
                  '${value.label} ${value.description}',
              menuMaxHeight: 240,
              itemEstimatedHeight: 74,
              showSearch: true,
              boldSelected: false,
              itemBuilderWithMenuHover:
                  (item, isSelected, isHovered, isMenuHovered) {
                    final isActive =
                        isHovered || (isSelected && !isMenuHovered);
                    final backgroundColor = isActive
                        ? const Color(0xFF4285F4)
                        : isSelected
                        ? const Color(0xFFE9EEF8)
                        : Colors.white;
                    final titleColor = isActive
                        ? Colors.white
                        : const Color(0xFF2D3748);
                    final descriptionColor = isActive
                        ? Colors.white
                        : const Color(0xFF66708C);
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: titleColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFF4285F4),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              height: 1.25,
                              color: descriptionColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
              onChanged: (value) {
                if (value != null) {
                  setState(() => _registrationType = value);
                }
              },
            ),
          ),
        ),
        _formRow(
          label: _requiredLabel('Business Legal Name*'),
          field: _textField(_legalNameController),
        ),
        _formRow(
          labelText: 'Business Trade Name',
          field: _textField(_tradeNameController),
        ),
        _formRow(
          labelText: 'GST Registered On',
          field: _datePickerField(
            controller: _registeredOnController,
            targetKey: _registeredOnKey,
          ),
        ),
        if (_registrationType.label != 'Input Service Distributor (ISD)') ...[
          _formRow(
            labelText: 'Reverse Charge',
            field: _checkboxLine(
              value: _reverseCharge,
              onChanged: (value) => setState(() => _reverseCharge = value),
              text: 'Enable Reverse Charge in Sales transactions',
            ),
          ),
          _formRow(
            label: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: ZTooltip(
                message:
                    'Enabling this option would allow you to create Bill of entry for import and shipping bill for export.',
                maxWidth: 320,
                child: const Text(
                  'Import / Export',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF2D3748),
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                  ),
                ),
              ),
            ),
            field: _checkboxLine(
              value: _importExport,
              onChanged: (value) => setState(() => _importExport = value),
              text: 'My business is involved in SEZ / Overseas Trading',
            ),
          ),
          if (_importExport) ...[
            _formRow(
              label: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Custom Duty Tracking Account*',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFFFF1F1F),
                  ),
                ),
              ),
              field: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: _fieldWidth(context),
                    height: 38,
                    child: AccountTreeDropdown(
                      value: _selectedAccount?.name,
                      nodes: _accountTreeNodes,
                      hint: 'Select an account',
                      height: 38,
                      hierarchyBulletMinDepth: 2,
                      showSettings: true,
                      settingsLabel: 'New Account',
                      settingsIcon: LucideIcons.plusCircle,
                      onSettingsTap: () async {
                        final newAccountName = await showDialog<String>(
                          context: context,
                          barrierColor: Colors.black54,
                          builder: (context) => const CreateAccountDialog(),
                        );
                        if (newAccountName != null &&
                            newAccountName.isNotEmpty) {
                          final newItem = AccountDropdownItem(
                            name: newAccountName,
                          );
                          setState(() {
                            _accountsList.add(newItem);
                            _selectedAccount = newItem;
                          });
                        }
                      },
                      onChanged: (value) {
                        setState(() {
                          _selectedAccount = value == null
                              ? null
                              : _accountsList.firstWhere(
                                  (item) =>
                                      !item.isHeader && item.name == value,
                                  orElse: () =>
                                      AccountDropdownItem(name: value),
                                );
                        });
                      },
                      /*
                      itemBuilder: (item, isSelected, isHovered) {
                        if (item.isHeader) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                          );
                        }
                        final double paddingLeft = item.isSubItem ? 24.0 : 12.0;
                        final isActive = isHovered;
                        return Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(paddingLeft, 8, 12, 8),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              if (item.isSubItem) ...[
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFF66708C),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFF2D3748),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onSettingsTap: () async {
                        final newAccountName = await showDialog<String>(
                          context: context,
                          barrierColor: Colors.black54,
                          builder: (context) => const CreateAccountDialog(),
                        );
                        if (newAccountName != null && newAccountName.isNotEmpty) {
                          final newItem =
                              AccountDropdownItem(name: newAccountName);
                          setState(() {
                            _accountsList.add(newItem);
                            _selectedAccount = newItem;
                          });
                        }
                      },
                      */
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
          _formRow(
            labelText: 'Digital Services',
            field: _checkboxLine(
              value: _digitalServices,
              onChanged: (value) => setState(() => _digitalServices = value),
              text: 'Track sale of digital services to overseas\ncustomers',
              helper: _digitalServices
                  ? 'If you disable this option, any digital service created by\nyou will be considered as a service.'
                  : 'Enabling this option will let you record and track export\nof digital services to individuals.',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultPreferenceTab() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _defaultPreferenceRow(
              label: 'Intra State Tax Rate*',
              helper: '(Within your State)',
              value: _intraStateTaxRate,
              items: _intraStateTaxOptions,
              onChanged: (value) =>
                  setState(() => _intraStateTaxRate = value ?? 'GST12 [12%]'),
            ),
            const SizedBox(height: 20),
            _defaultPreferenceRow(
              label: 'Inter State Tax Rate*',
              helper: '(Outside your State)',
              value: _interStateTaxRate,
              items: _interStateTaxOptions,
              onChanged: (value) =>
                  setState(() => _interStateTaxRate = value ?? 'IGST12 [12%]'),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 400,
              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
            const SizedBox(height: 24),
            const Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Note : ',
                    style: TextStyle(color: Color(0xFF111111)),
                  ),
                  TextSpan(
                    text:
                        "Clicking Save will update the tax rates for all items except for the ones that you've manually changed under the Items\nmodule.",
                  ),
                ],
              ),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF66708C),
              ),
            ),
            const SizedBox(height: 20),
            ZButton.primary(onPressed: () {}, label: 'Save', height: 32),
          ],
        ),
      ),
    );
  }

  Widget _defaultPreferenceRow({
    required String label,
    required String helper,
    required String value,
    required List<_DefaultTaxPreferenceOption> items,
    required ValueChanged<String?> onChanged,
  }) {
    final selectedItem = items.firstWhere(
      (item) => item.label == value,
      orElse: () => items.firstWhere((item) => !item.isHeader),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final labelWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFFFF1F1F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              helper,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF66708C),
              ),
            ),
          ],
        );
        final dropdownWidget = SizedBox(
          width: constraints.maxWidth < 400 ? double.infinity : 220.0,
          height: 36,
          child: FormDropdown<_DefaultTaxPreferenceOption>(
            value: selectedItem,
            items: items,
            onChanged: (item) => onChanged(item?.label),
            height: 36,
            menuWidth: 300,
            showSearch: true,
            boldSelected: false,
            placeholder: 'Search',
            isItemEnabled: (item) => !item.isHeader,
            displayStringForValue: (item) => item.label,
            searchStringForValue: (item) => item.isHeader ? '' : item.label,
            itemBuilderWithMenuHover:
                (item, isSelected, isHovered, isMenuHovered) {
                  if (item.isHeader) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    );
                  }

                  final isActive = isHovered || (isSelected && !isMenuHovered);
                  final backgroundColor = isActive
                      ? const Color(0xFF4285F4)
                      : isSelected
                      ? const Color(0xFFE9EEF8)
                      : Colors.white;
                  final textColor = isActive
                      ? Colors.white
                      : const Color(0xFF2D3748);
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 16,
                            color: isActive
                                ? Colors.white
                                : const Color(0xFF4285F4),
                          ),
                      ],
                    ),
                  );
                },
            textStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF2D3748),
            ),
          ),
        );

        if (constraints.maxWidth < 400) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelWidget,
                const SizedBox(height: 8),
                dropdownWidget,
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 180, child: labelWidget),
            dropdownWidget,
          ],
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ZButton.primary(onPressed: () {}, label: 'Save', height: 32),
    );
  }

  Widget _formRow({Widget? label, String? labelText, required Widget field}) {
    final labelWidget =
        label ??
        Text(
          labelText ?? '',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF111111),
          ),
        );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 5), field],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 280, child: labelWidget),
              Flexible(child: field),
            ],
          ),
        );
      },
    );
  }

  double _fieldWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 760) return width.clamp(165, _gstFieldWidth).toDouble();
    return _gstFieldWidth;
  }

  Widget _gstinField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final getDetailsButton = InkWell(
          onTap: () {
            showDialog<void>(
              context: context,
              barrierColor: Colors.black54,
              builder: (context) => TaxpayerDetailsDialog(
                gstin: _gstinController.text.trim().isEmpty
                    ? '32AACCZ4912F1ZL'
                    : _gstinController.text.trim(),
              ),
            );
          },
          child: const Text(
            'Get Taxpayer details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF1F6FEB),
            ),
          ),
        );

        if (constraints.maxWidth < 430) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _textField(_gstinController),
              const SizedBox(height: 6),
              getDetailsButton,
            ],
          );
        }
        return Row(
          children: [
            _textField(_gstinController),
            const SizedBox(width: 8),
            Flexible(child: getDetailsButton),
          ],
        );
      },
    );
  }

  Widget _textField(TextEditingController controller) {
    return SizedBox(
      width: _fieldWidth(context),
      height: _gstFieldHeight,
      child: CustomTextField(controller: controller, hintText: ''),
    );
  }

  Widget _datePickerField({
    required TextEditingController controller,
    required GlobalKey targetKey,
  }) {
    return GestureDetector(
      key: targetKey,
      onTap: () async {
        DateTime initial = DateTime.now();
        try {
          final parts = controller.text.split('-');
          if (parts.length == 3) {
            initial = DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        } catch (_) {}

        final picked = await ZerpaiDatePicker.show(
          context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          targetKey: targetKey,
        );
        if (picked != null) {
          final formatted =
              "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
          setState(() {
            controller.text = formatted;
          });
        }
      },
      child: Container(
        width: _fieldWidth(context),
        height: _gstFieldHeight,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF3B82F6), width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final text = value.text.isEmpty ? 'dd-MM-yyyy' : value.text;
                  final color = value.text.isEmpty
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF111827);
                  return Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: color,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required T? value,
    required List<T> items,
    String? hint,
    ValueChanged<T?>? onChanged,
  }) {
    return SizedBox(
      width: _fieldWidth(context),
      height: _gstFieldHeight,
      child: FormDropdown<T>(
        value: value,
        hint: hint,
        items: items,
        onChanged: onChanged ?? (_) {},
        displayStringForValue: (value) => value.toString(),
        height: _gstFieldHeight,
        menuWidth: _fieldWidth(context),
        showSearch: true,
        boldSelected: false,
      ),
    );
  }

  Widget _requiredLabel(
    String text, {
    String? helper,
    bool hasUnderline = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: AppTextStyles.labelRequired.copyWith(
            fontWeight: FontWeight.normal,
            decoration: hasUnderline
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationStyle: hasUnderline ? TextDecorationStyle.dotted : null,
          ),
        ),
        if (helper != null)
          Text(helper, style: AppTextStyles.helper.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _checkboxLine({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
    String? helper,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: Transform.scale(
              scale: 0.78,
              child: Checkbox(
                value: value,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: const Color(0xFF1F6FEB),
                side: const BorderSide(color: Color(0xFFC9CDD3)),
                onChanged: (next) => onChanged(next ?? false),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF111111),
                  ),
                ),
                if (helper != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      helper,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.45,
                        color: Color(0xFF66708C),
                      ),
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

class _GstTdsSettingsReport extends StatefulWidget {
  const _GstTdsSettingsReport();

  @override
  State<_GstTdsSettingsReport> createState() => _GstTdsSettingsReportState();
}

class _GstTdsSettingsReportState extends State<_GstTdsSettingsReport> {
  bool _enabled = false;
  String? _enabledFor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: SettingsTaxesOverviewPage._toolbarHeight,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE6E6E6))),
                ),
                child: const Text(
                  'GST TDS Settings',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 360,
                              child: Text(
                                'GST TDS',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFF111111),
                                ),
                              ),
                            ),
                            Text(
                              _enabled ? 'Enabled' : 'Disabled',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF111111),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.scale(
                              scale: 0.68,
                              child: Switch(
                                value: _enabled,
                                activeThumbColor: Colors.white,
                                activeTrackColor: const Color(0xFF4285F4),
                                inactiveThumbColor: Colors.white,
                                inactiveTrackColor: const Color(0xFFD1D5DB),
                                onChanged: (value) {
                                  setState(() => _enabled = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const SizedBox(
                          width: 850,
                          child: Text(
                            'GST TDS requires certain taxpayers to deduct a percentage of the total invoice value and pay it to the government on behalf of\n'
                            'the vendor. Once enabled here, you can enable it for customers and vendors when creating or editing them, and for customers\n'
                            'with GST Treatment as Tax Deductor, it is enabled by default.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              height: 1.25,
                              color: Color(0xFF66708C),
                            ),
                          ),
                        ),
                        if (_enabled) ...[
                          const SizedBox(height: 32),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 635) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Enable GST TDS Settings For*',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: FormDropdown<String>(
                                        value: _enabledFor,
                                        items: const [
                                          'Customers',
                                          'Vendors',
                                          'Customers and Vendors',
                                        ],
                                        hint: '',
                                        showSearch: true,
                                        boldSelected: false,
                                        onChanged: (value) {
                                          setState(() => _enabledFor = value);
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  const SizedBox(
                                    width: 360,
                                    child: Text(
                                      'Enable GST TDS Settings For*',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 275,
                                    height: 38,
                                    child: FormDropdown<String>(
                                      value: _enabledFor,
                                      items: const [
                                        'Customers',
                                        'Vendors',
                                        'Customers and Vendors',
                                      ],
                                      hint: '',
                                      showSearch: true,
                                      boldSelected: false,
                                      onChanged: (value) {
                                        setState(() => _enabledFor = value);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_enabled)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 66,
                padding: const EdgeInsets.only(left: 18),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    ZerpaiToast.success(context, 'GST TDS settings saved.');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaxExemptionsReport extends StatefulWidget {
  const _TaxExemptionsReport();

  @override
  State<_TaxExemptionsReport> createState() => _TaxExemptionsReportState();
}

class _TaxExemptionsReportState extends State<_TaxExemptionsReport> {
  final List<_TaxExemptionRowData> _rows = [
    _TaxExemptionRowData(
      reason: 'GSTMARGINSCHEME',
      associatedWith: 'Item',
      description: 'GST Margin Scheme',
    ),
    _TaxExemptionRowData(
      reason: 'LACK OF STOCK',
      associatedWith: 'Item',
      description: '',
    ),
  ];
  final Set<int> _selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TaxExemptionsToolbar(
            onNew: _showNewDialog,
            onBulkCreate: _showBulkCreateDialog,
          ),
          Expanded(
            child: _TaxExemptionsTable(
              rows: _rows,
              selectedIndexes: _selectedIndexes,
              onToggle: (index, selected) {
                setState(() {
                  if (selected) {
                    _selectedIndexes.add(index);
                  } else {
                    _selectedIndexes.remove(index);
                  }
                });
              },
              onSelectAll: (selected) {
                setState(() {
                  _selectedIndexes
                    ..clear()
                    ..addAll(
                      selected
                          ? List<int>.generate(_rows.length, (index) => index)
                          : const <int>[],
                    );
                });
              },
              onRowTap: _showEditDialog,
              onDeleteSelected: _deleteSelected,
              onClearSelection: () => setState(_selectedIndexes.clear),
              onDeleteRow: _deleteRow,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showNewDialog() async {
    final result = await showDialog<_TaxExemptionRowData>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => const _TaxExemptionDialog(),
    );
    if (result == null) return;
    setState(() => _rows.add(result));
  }

  Future<void> _showEditDialog(int index) async {
    final result = await showDialog<_TaxExemptionRowData>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _TaxExemptionDialog(initial: _rows[index]),
    );
    if (result == null) return;
    setState(() => _rows[index] = result);
  }

  Future<void> _showBulkCreateDialog() async {
    final result = await showDialog<List<_TaxExemptionRowData>>(
      context: context,
      barrierColor: Colors.black54,
      barrierDismissible: false,
      builder: (_) => const _BulkCreateTaxExemptionsDialog(),
    );
    if (result == null || result.isEmpty) return;
    setState(() => _rows.addAll(result));
  }

  Future<void> _deleteSelected() async {
    final confirmed = await _showTaxesDeleteConfirm(
      context,
      message: 'Are you sure about deleting these tax exemptions?',
    );
    if (confirmed != true) return;
    setState(() {
      final sorted = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sorted) {
        if (index >= 0 && index < _rows.length) {
          _rows.removeAt(index);
        }
      }
      _selectedIndexes.clear();
    });
  }

  Future<void> _deleteRow(int index) async {
    final confirmed = await _showTaxesDeleteConfirm(
      context,
      message: 'Are you sure about deleting this tax exemption?',
    );
    if (confirmed != true) return;
    setState(() {
      if (index >= 0 && index < _rows.length) {
        _rows.removeAt(index);
      }
      _selectedIndexes
        ..remove(index)
        ..removeWhere((selected) => selected >= _rows.length);
    });
  }
}

class _TaxExemptionsToolbar extends StatelessWidget {
  const _TaxExemptionsToolbar({
    required this.onNew,
    required this.onBulkCreate,
  });

  final VoidCallback onNew;
  final VoidCallback onBulkCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SettingsTaxesOverviewPage._toolbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE6E6E6))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Tax Exemptions',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 26,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(
            width: 158.7,
            height: 32.15,
            child: ElevatedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Tax Exemption'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 28,
            height: 32.15,
            decoration: const BoxDecoration(
              color: Color(0xFF22B378),
              border: Border(left: BorderSide(color: Colors.white24)),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: PopupMenuButton<String>(
              tooltip: '',
              color: Colors.white,
              surfaceTintColor: Colors.white,
              padding: EdgeInsets.zero,
              position: PopupMenuPosition.under,
              offset: Offset.zero,
              constraints: const BoxConstraints(minWidth: 210, maxWidth: 210),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              icon: const Icon(
                LucideIcons.chevronDown,
                size: 13,
                color: Colors.white,
              ),
              onSelected: (value) {
                if (value == 'bulk_create') {
                  onBulkCreate();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'bulk_create',
                  padding: EdgeInsets.zero,
                  height: 34,
                  child: _PopupRow(label: 'Bulk Create Tax Exemptions'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaxExemptionsTable extends StatelessWidget {
  const _TaxExemptionsTable({
    required this.rows,
    required this.selectedIndexes,
    required this.onToggle,
    required this.onSelectAll,
    required this.onRowTap,
    required this.onDeleteSelected,
    required this.onClearSelection,
    required this.onDeleteRow,
  });

  final List<_TaxExemptionRowData> rows;
  final Set<int> selectedIndexes;
  final void Function(int index, bool selected) onToggle;
  final ValueChanged<bool> onSelectAll;
  final ValueChanged<int> onRowTap;
  final VoidCallback onDeleteSelected;
  final VoidCallback onClearSelection;
  final ValueChanged<int> onDeleteRow;

  @override
  Widget build(BuildContext context) {
    final allSelected =
        rows.isNotEmpty && selectedIndexes.length == rows.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (selectedIndexes.isNotEmpty)
          _TaxExemptionSelectionBar(
            count: selectedIndexes.length,
            onDelete: onDeleteSelected,
            onClose: onClearSelection,
          ),
        Container(
          height: SettingsTaxesOverviewPage._headerHeight,
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: _TaxesTable._tableCheckbox(
                  height: SettingsTaxesOverviewPage._headerHeight,
                  value: allSelected,
                  onChanged: onSelectAll,
                ),
              ),
              const Expanded(flex: 3, child: _HeaderCell('EXEMPTION REASON')),
              const Expanded(flex: 2, child: _HeaderCell('ASSOCIATED WITH')),
              const Expanded(flex: 3, child: _HeaderCell('DESCRIPTION')),
              const SizedBox(width: 60),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rows.length; i++)
                  _TaxExemptionTableRow(
                    index: i,
                    row: rows[i],
                    selected: selectedIndexes.contains(i),
                    onToggle: (selected) => onToggle(i, selected),
                    onTap: () => onRowTap(i),
                    onDelete: () => onDeleteRow(i),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TaxExemptionSelectionBar extends StatelessWidget {
  const _TaxExemptionSelectionBar({
    required this.count,
    required this.onDelete,
    required this.onClose,
  });

  final int count;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 15),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 18),
          const Text(
            '•',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count Tax Exemptions Selected',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 22),
            color: const Color(0xFF6B7280),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

class _TaxExemptionTableRow extends StatefulWidget {
  const _TaxExemptionTableRow({
    required this.index,
    required this.row,
    required this.selected,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final _TaxExemptionRowData row;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_TaxExemptionTableRow> createState() => _TaxExemptionTableRowState();
}

class _TaxExemptionTableRowState extends State<_TaxExemptionTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          height: SettingsTaxesOverviewPage._rowHeight,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF4F6F8) : Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: _TaxesTable._tableCheckbox(
                  height: SettingsTaxesOverviewPage._rowHeight,
                  value: widget.selected,
                  onChanged: widget.onToggle,
                ),
              ),
              Expanded(flex: 3, child: _BodyCell(widget.row.reason)),
              Expanded(flex: 2, child: _BodyCell(widget.row.associatedWith)),
              Expanded(flex: 3, child: _BodyCell(widget.row.description)),
              SizedBox(
                width: 60,
                child: _hovered
                    ? IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        color: Colors.black,
                        splashRadius: 16,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaxesToolbarState extends State<_TaxesToolbar> {
  final MenuController _filterMenuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SettingsTaxesOverviewPage._toolbarHeight,
      padding: const EdgeInsets.only(left: 28, right: 35),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E6E6))),
      ),
      child: Row(
        children: [
          MenuAnchor(
            controller: _filterMenuController,
            alignmentOffset: const Offset(0, 6),
            style: const MenuStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.white),
              surfaceTintColor: WidgetStatePropertyAll(Colors.white),
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              elevation: WidgetStatePropertyAll(8),
              minimumSize: WidgetStatePropertyAll(Size(240, 0)),
              maximumSize: WidgetStatePropertyAll(Size(240, 320)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ),
            builder: (context, controller, child) {
              return InkWell(
                onTap: controller.isOpen ? controller.close : controller.open,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filterTitle(widget.filter),
                      style: AppTheme.pageTitle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: Color(0xFF1F6FEB),
                    ),
                  ],
                ),
              );
            },
            menuChildren: [
              Container(
                width: 240,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final value in SettingsTaxFilter.values)
                      _FilterMenuRow(
                        label: _filterLabel(value),
                        onTap: () {
                          widget.onFilterChanged(value);
                          _filterMenuController.close();
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 108,
            height: 30,
            child: ElevatedButton.icon(
              onPressed: () {
                final orgSystemId =
                    GoRouterState.of(context).pathParameters['orgSystemId'] ??
                    '6000000000';
                context.go('/$orgSystemId${AppRoutes.settingsTaxCreate}');
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Tax'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 28,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFF22B378),
              border: Border(left: BorderSide(color: Colors.white24)),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
            ),
            child: PopupMenuButton<String>(
              tooltip: '',
              color: Colors.white,
              surfaceTintColor: Colors.white,
              padding: EdgeInsets.zero,
              position: PopupMenuPosition.under,
              offset: Offset.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              constraints: const BoxConstraints(
                minWidth: 114.48,
                maxWidth: 114.48,
              ),
              icon: const Icon(
                LucideIcons.chevronDown,
                size: 13,
                color: Colors.white,
              ),
              onSelected: (value) {
                if (value == 'new_group') {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (context) => const _EditTaxDialog(
                      tax: SettingsTaxRate(
                        id: '',
                        name: '',
                        type: 'Group',
                        rate: 0,
                        isActive: true,
                      ),
                      isNewGroup: true,
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'new_group',
                  padding: EdgeInsets.zero,
                  height: 34.8,
                  mouseCursor: SystemMouseCursors.click,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    child: const _NewTaxGroupPopupRow(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: '',
            color: Colors.white,
            surfaceTintColor: Colors.white,
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            offset: Offset.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            constraints: const BoxConstraints(minWidth: 188, maxWidth: 188),
            onSelected: (value) async {
              final orgSystemId =
                  GoRouterState.of(context).pathParameters['orgSystemId'] ??
                  '6000000000';
              if (value == 'import_taxes') {
                context.go('/$orgSystemId${AppRoutes.settingsTaxImport}');
              } else if (value == 'export_taxes') {
                await showTaxExportDialog(context);
              } else if (value == 'import_tax_group') {
                context.go('/$orgSystemId${AppRoutes.settingsTaxGroupImport}');
              } else if (value == 'export_tax_group') {
                await showTaxExportDialog(context, taxGroup: true);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'import_taxes',
                padding: EdgeInsets.zero,
                height: 36,
                child: _PopupRowWithIcon(
                  icon: LucideIcons.download,
                  label: 'Import Taxes',
                ),
              ),
              PopupMenuItem(
                value: 'export_taxes',
                padding: EdgeInsets.zero,
                height: 36,
                child: _PopupRowWithIcon(
                  icon: LucideIcons.upload,
                  label: 'Export Taxes',
                ),
              ),
              PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: 'import_tax_group',
                padding: EdgeInsets.zero,
                height: 36,
                child: _PopupRowWithIcon(
                  icon: LucideIcons.download,
                  label: 'Import Tax Group',
                ),
              ),
              PopupMenuItem(
                value: 'export_tax_group',
                padding: EdgeInsets.zero,
                height: 36,
                child: _PopupRowWithIcon(
                  icon: LucideIcons.upload,
                  label: 'Export Tax Group',
                ),
              ),
            ],
            child: Container(
              width: 34,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                LucideIcons.moreVertical,
                size: 19,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _filterLabel(SettingsTaxFilter filter) {
    switch (filter) {
      case SettingsTaxFilter.all:
        return 'All';
      case SettingsTaxFilter.active:
        return 'Active';
      case SettingsTaxFilter.inactive:
        return 'Inactive';
      case SettingsTaxFilter.expired:
        return 'Expired';
      case SettingsTaxFilter.tax:
        return 'Tax';
      case SettingsTaxFilter.taxGroup:
        return 'Tax Group';
    }
  }

  static String _filterTitle(SettingsTaxFilter filter) {
    switch (filter) {
      case SettingsTaxFilter.all:
        return 'All taxes';
      case SettingsTaxFilter.active:
        return 'Active taxes';
      case SettingsTaxFilter.inactive:
        return 'Inactive taxes';
      case SettingsTaxFilter.expired:
        return 'Expired taxes';
      case SettingsTaxFilter.tax:
        return 'Taxes';
      case SettingsTaxFilter.taxGroup:
        return 'Tax groups';
    }
  }
}

class _TaxesTable extends StatelessWidget {
  const _TaxesTable({
    required this.rows,
    required this.allSelected,
    required this.selectedIds,
    required this.onSelectAll,
    required this.onSelectRow,
  });

  final List<SettingsTaxRate> rows;
  final bool allSelected;
  final Set<String> selectedIds;
  final ValueChanged<bool> onSelectAll;
  final void Function(String id, bool selected) onSelectRow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double minWidth = 870;
        final double tableWidth = constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: SettingsTaxesOverviewPage._headerHeight,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE6E6E6)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: _tableCheckbox(
                            height: SettingsTaxesOverviewPage._headerHeight,
                            value: allSelected,
                            onChanged: onSelectAll,
                          ),
                        ),
                        const SizedBox(
                          width: 360,
                          child: _HeaderCell('TAX NAME'),
                        ),
                        const SizedBox(
                          width: 260,
                          child: _HeaderCell('TAX TYPE'),
                        ),
                        const SizedBox(
                          width: 120,
                          child: _HeaderCell('RATE (%)'),
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        const SizedBox(width: 80, child: SizedBox()),
                      ],
                    ),
                  ),
                  ...rows.map(
                    (tax) => _TaxesTableRow(
                      tax: tax,
                      isSelected: selectedIds.contains(tax.id),
                      onSelectRow: (selected) {
                        if (!tax.isTaxGroup) return;
                        onSelectRow(tax.id, selected);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _tableCheckbox({
    required double height,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: Transform.scale(
            scale: 0.78,
            child: Checkbox(
              value: value,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: const Color(0xFF1F6FEB),
              side: const BorderSide(color: Color(0xFFBDBDBD)),
              onChanged: (next) => onChanged(next ?? false),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatRate(double rate) {
    return rate == rate.roundToDouble()
        ? rate.toInt().toString()
        : rate.toStringAsFixed(2);
  }
}

class _TaxesSelectionBar extends StatelessWidget {
  const _TaxesSelectionBar({
    required this.count,
    required this.onDelete,
    required this.onClose,
  });

  final int count;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(LucideIcons.trash2, size: 15),
            label: const Text('Delete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const SizedBox(width: 18),
          const Text(
            '\u2022',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count Taxes Selected',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(LucideIcons.x, size: 22),
            color: const Color(0xFF777777),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _TaxesTableRow extends StatefulWidget {
  const _TaxesTableRow({
    required this.tax,
    required this.isSelected,
    required this.onSelectRow,
  });

  final SettingsTaxRate tax;
  final bool isSelected;
  final ValueChanged<bool> onSelectRow;

  @override
  State<_TaxesTableRow> createState() => _TaxesTableRowState();
}

class _TaxesTableRowState extends State<_TaxesTableRow> {
  bool _isHovered = false;
  bool _isActionsMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: SettingsTaxesOverviewPage._rowHeight,
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFFF4F6F8) : Colors.white,
          border: const Border(bottom: BorderSide(color: Color(0xFFE6E6E6))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              child: widget.tax.isTaxGroup
                  ? _TaxesTable._tableCheckbox(
                      height: SettingsTaxesOverviewPage._rowHeight,
                      value: widget.isSelected,
                      onChanged: widget.onSelectRow,
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(width: 360, child: _TaxNameCell(tax: widget.tax)),
            SizedBox(
              width: 260,
              child: _BodyCell(
                widget.tax.isTaxGroup ? '' : widget.tax.type.toUpperCase(),
              ),
            ),
            SizedBox(
              width: 120,
              child: _BodyCell(_TaxesTable._formatRate(widget.tax.rate)),
            ),
            const Expanded(child: SizedBox.shrink()),
            SizedBox(
              width: 80,
              child: Container(
                height: SettingsTaxesOverviewPage._rowHeight,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 12),
                child: _isHovered || _isActionsMenuOpen
                    ? _TaxesRowActionsButton(
                        tax: widget.tax,
                        onMenuOpenChanged: (isOpen) {
                          if (mounted) {
                            setState(() => _isActionsMenuOpen = isOpen);
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxesRowActionsButton extends ConsumerWidget {
  const _TaxesRowActionsButton({
    required this.tax,
    required this.onMenuOpenChanged,
  });

  final SettingsTaxRate tax;
  final ValueChanged<bool> onMenuOpenChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: '',
      color: Colors.white,
      surfaceTintColor: Colors.white,
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      offset: Offset.zero,
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 220),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      onOpened: () => onMenuOpenChanged(true),
      onCanceled: () => onMenuOpenChanged(false),
      onSelected: (value) async {
        if (value == 'view_associated') {
          onMenuOpenChanged(false);
          _showAssociatedRecordsPanel(context, tax);
        } else if (value == 'view') {
          onMenuOpenChanged(false);
          ZerpaiToast.info(context, 'Tax details are not available yet');
        } else if (value == 'edit') {
          onMenuOpenChanged(false);
          showDialog(
            context: context,
            barrierColor: Colors.black26,
            builder: (context) => _EditTaxDialog(tax: tax),
          );
        } else if (value == 'delete') {
          final confirmed = await _showTaxesDeleteConfirm(
            context,
            message: tax.isTaxGroup
                ? 'Are you sure about deleting this tax group?'
                : 'Are you sure about deleting this tax rate?',
          );
          onMenuOpenChanged(false);
          if (!context.mounted) return;
          if (confirmed == true) {
            final ok = await ref
                .read(settingsTaxRatesProvider.notifier)
                .deleteTax(tax.id, isTaxGroup: tax.isTaxGroup);
            if (context.mounted) {
              if (ok) {
                ZerpaiToast.success(
                  context,
                  tax.isTaxGroup
                      ? 'Tax group deleted successfully.'
                      : 'Tax rate deleted successfully.',
                );
              } else {
                ZerpaiToast.error(
                  context,
                  tax.isTaxGroup
                      ? 'Unable to delete tax group.'
                      : 'Unable to delete tax rate.',
                );
              }
            }
          }
        } else if (value == 'toggle_active') {
          onMenuOpenChanged(false);
          final nextActive = !tax.isActive;
          ref
              .read(settingsTaxRatesProvider.notifier)
              .toggleTaxStatus(
                id: tax.id,
                isActive: nextActive,
                isTaxGroup: tax.isTaxGroup,
              )
              .then((ok) {
                if (context.mounted) {
                  if (ok) {
                    ZerpaiToast.success(
                      context,
                      'Tax marked as ${nextActive ? 'Active' : 'Inactive'} successfully.',
                    );
                  } else {
                    ZerpaiToast.error(context, 'Unable to update status.');
                  }
                }
              });
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'view_associated',
          padding: EdgeInsets.zero,
          height: 36,
          child: _PopupRowWithIcon(
            icon: LucideIcons.history,
            label: 'View Associated Records',
          ),
        ),
        if (!tax.isTaxGroup)
          const PopupMenuItem<String>(
            value: 'view',
            padding: EdgeInsets.zero,
            height: 36,
            child: _PopupRowWithIcon(icon: LucideIcons.eye, label: 'View'),
          ),
        if (tax.isTaxGroup) ...[
          const PopupMenuItem<String>(
            value: 'edit',
            padding: EdgeInsets.zero,
            height: 36,
            child: _PopupRowWithIcon(icon: LucideIcons.pencil, label: 'Edit'),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            padding: EdgeInsets.zero,
            height: 36,
            child: _PopupRowWithIcon(
              icon: LucideIcons.trash2,
              label: 'Delete',
              isDestructive: true,
            ),
          ),
        ],
        PopupMenuItem<String>(
          value: 'toggle_active',
          padding: EdgeInsets.zero,
          height: 36,
          child: _PopupRowWithIcon(
            icon: tax.isActive ? LucideIcons.xCircle : LucideIcons.checkSquare,
            label: tax.isActive ? 'Mark as Inactive' : 'Mark as Active',
          ),
        ),
      ],
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF2BB673),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          LucideIcons.chevronDown,
          size: 13,
          color: Colors.white,
        ),
      ),
    );
  }
}

void _showAssociatedRecordsPanel(BuildContext context, SettingsTaxRate tax) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Associated Records',
    barrierColor: Colors.black.withValues(alpha: 0.58),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: _AssociatedRecordsPanel(tax: tax),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

class _AssociatedRecordsPanel extends StatelessWidget {
  const _AssociatedRecordsPanel({required this.tax});

  final SettingsTaxRate tax;

  @override
  Widget build(BuildContext context) {
    final displayRate = _TaxesTable._formatRate(tax.rate);

    return Material(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: SizedBox(
        width: 420,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Associated Records',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () {},
                    icon: const Icon(
                      LucideIcons.refreshCw,
                      size: 18,
                      color: Color(0xFF22B378),
                    ),
                    splashRadius: 18,
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 20,
                      color: Color(0xFFFF4D4F),
                    ),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.receipt,
                      size: 28,
                      color: Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tax Name',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${tax.name} : $displayRate%',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Divider(height: 1, color: Color(0xFFE5E7EB)),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'No results found',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupRowWithIcon extends StatefulWidget {
  const _PopupRowWithIcon({
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  State<_PopupRowWithIcon> createState() => _PopupRowWithIconState();
}

class _PopupRowWithIconState extends State<_PopupRowWithIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        color: _hovered ? const Color(0xFF1F6FEB) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 16,
              color: _hovered ? Colors.white : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: _hovered ? Colors.white : const Color(0xFF333333),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditTaxDialog extends ConsumerStatefulWidget {
  const _EditTaxDialog({required this.tax, this.isNewGroup = false});

  final SettingsTaxRate tax;
  final bool isNewGroup;

  @override
  ConsumerState<_EditTaxDialog> createState() => _EditTaxDialogState();
}

class _EditTaxDialogState extends ConsumerState<_EditTaxDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _rateController;
  String? _taxType;
  String? _nameError;
  String? _rateError;
  String? _typeError;
  late List<SettingsTaxRate> _groupTaxRows;
  late Set<String> _associatedTaxIds;
  bool _draftInvoices = false;
  bool _draftSalesOrders = false;
  bool _recurringTransactions = true;
  bool _acceptGroupUpdate = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.tax.name);
    _rateController = TextEditingController(
      text: widget.tax.rate == widget.tax.rate.roundToDouble()
          ? widget.tax.rate.toInt().toString()
          : widget.tax.rate.toString(),
    );
    _taxType = widget.tax.type.toUpperCase().isEmpty
        ? null
        : widget.tax.type.toUpperCase();
    _groupTaxRows = _buildInitialGroupTaxRows();
    _associatedTaxIds = widget.isNewGroup
        ? <String>{}
        : _groupTaxRows.take(2).map((tax) => tax.id).toSet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final name = _nameController.text.trim();
    if (widget.isNewGroup || widget.tax.isTaxGroup) {
      setState(() {
        _nameError = name.isEmpty ? 'Tax group name is required' : null;
      });
      if (_nameError != null) return;

      final notifier = ref.read(settingsTaxRatesProvider.notifier);
      final taxIds = _associatedTaxIds.toList();
      final groupRate = _groupTaxRows
          .where((tax) => _associatedTaxIds.contains(tax.id))
          .fold<double>(0, (total, tax) => total + tax.rate);
      final updated = widget.isNewGroup
          ? await notifier.createTax(
              name: name,
              type: 'Group',
              rate: groupRate,
              taxIds: taxIds,
            )
          : await notifier.updateTax(
              id: widget.tax.id,
              name: name,
              type: 'Group',
              rate: groupRate,
              taxIds: taxIds,
            );
      if (!mounted) return;
      if (updated) {
        ZerpaiToast.success(
          context,
          widget.isNewGroup
              ? 'Tax group created successfully'
              : 'Tax group updated successfully',
        );
        Navigator.of(context).pop(true);
      } else {
        ZerpaiToast.error(
          context,
          widget.isNewGroup
              ? 'Unable to create tax group'
              : 'Unable to update tax group',
        );
      }
      return;
    }

    final rate = double.tryParse(_rateController.text.trim());
    setState(() {
      _nameError = name.isEmpty ? 'Tax name is required' : null;
      _rateError = rate == null || rate < 0 || rate > 100
          ? 'Enter a rate from 0 to 100'
          : null;
      _typeError = _taxType == null ? 'Tax type is required' : null;
    });
    if (_nameError != null || _rateError != null || _typeError != null) return;

    final updated = await ref
        .read(settingsTaxRatesProvider.notifier)
        .updateTax(id: widget.tax.id, name: name, type: _taxType!, rate: rate!);
    if (!mounted) return;
    if (updated) {
      ZerpaiToast.success(context, 'Tax updated successfully');
      Navigator.of(context).pop(true);
    } else {
      ZerpaiToast.error(context, 'Unable to update tax');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_usesTaxGroupEditLayout) {
      return _buildTaxGroupDialog(context);
    }

    final isSaving = ref.watch(settingsTaxRatesProvider).isSaving;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Tax',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    hoverColor: AppTheme.bgHover,
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tax Name*',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Enter tax name (e.g. GST18)',
                    errorText: _nameError,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tax Type*',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 38,
                    child: FormDropdown<String>(
                      value: _taxType,
                      hint: 'Select Tax Type',
                      items: const ['SGST', 'CGST', 'IGST', 'UTGST', 'CESS'],
                      boldSelected: false,
                      onChanged: (val) {
                        setState(() {
                          _taxType = val;
                          _typeError = null;
                        });
                      },
                    ),
                  ),
                  if (_typeError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _typeError!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Rate (%)*',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  CustomTextField(
                    controller: _rateController,
                    hintText: 'Enter rate percentage',
                    errorText: _rateError,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Row(
                children: [
                  ZButton.primary(
                    onPressed: isSaving ? null : _update,
                    label: 'Save',
                    loading: isSaving,
                  ),
                  const SizedBox(width: 12),
                  ZButton.secondary(
                    onPressed: () => Navigator.of(context).pop(),
                    label: 'Cancel',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _usesTaxGroupEditLayout => true;

  List<SettingsTaxRate> _buildInitialGroupTaxRows() {
    final realRows = ref
        .read(settingsTaxRatesProvider)
        .rates
        .where((tax) => !tax.isTaxGroup)
        .toList();

    const defaults = [
      ('CGST0', 'CGST', 0.0),
      ('SGST0', 'SGST', 0.0),
      ('IGST0', 'IGST', 0.0),
      ('IGST5', 'IGST', 5.0),
      ('IGST12', 'IGST', 12.0),
      ('IGST18', 'IGST', 18.0),
      ('IGST28', 'IGST', 28.0),
      ('CGST2.5', 'CGST', 2.5),
      ('SGST2.5', 'SGST', 2.5),
      ('CGST6', 'CGST', 6.0),
      ('SGST6', 'SGST', 6.0),
      ('CGST9', 'CGST', 9.0),
      ('SGST9', 'SGST', 9.0),
      ('CGST14', 'CGST', 14.0),
      ('SGST14', 'SGST', 14.0),
    ];

    final defaultRows = defaults
        .map(
          (row) => SettingsTaxRate(
            id: row.$1,
            name: row.$1,
            type: row.$2,
            rate: row.$3,
            isActive: true,
          ),
        )
        .toList();
    if (realRows.isEmpty) return defaultRows;

    final rowsByName = {
      for (final row in defaultRows) row.name.toUpperCase(): row,
      for (final row in realRows) row.name.toUpperCase(): row,
    };

    return [
      for (final row in defaultRows) rowsByName.remove(row.name.toUpperCase())!,
      ...rowsByName.values,
    ];
  }

  Widget _buildTaxGroupDialog(BuildContext context) {
    final isSaving = ref.watch(settingsTaxRatesProvider).isSaving;

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, bottom: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 870),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.isNewGroup ? 'New Tax Group' : 'Edit Tax Group',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      color: Color(0xFFFF3333),
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 560,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _taxGroupLabel('Tax Group Name*'),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 352,
                                child: CustomTextField(
                                  controller: _nameController,
                                  hintText: 'Enter tax group name',
                                  errorText: _nameError,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _taxGroupLabel('Associate Taxes*'),
                                  const Spacer(),
                                  const Icon(
                                    Icons.drag_indicator,
                                    size: 18,
                                    color: Color(0xFFD9DDE6),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Drag taxes to reorder',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF7C859B),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    LucideIcons.info,
                                    size: 14,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                              ),
                              _buildAssociatedTaxesTable(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!widget.isNewGroup) _buildTaxGroupWarningArea(),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
                      decoration: const BoxDecoration(color: Colors.white),
                      child: Row(
                        children: [
                          ZButton.primary(
                            onPressed: isSaving ? null : _update,
                            label: 'Save',
                            loading: isSaving,
                          ),
                          const SizedBox(width: 14),
                          ZButton.secondary(
                            onPressed: () => Navigator.of(context).pop(),
                            label: 'Cancel',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _taxGroupLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: Color(0xFFFF1F1F),
      ),
    );
  }

  Widget _buildAssociatedTaxesTable() {
    return SizedBox(
      width: 560,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          padding: EdgeInsets.zero,
          itemCount: _groupTaxRows.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final row = _groupTaxRows.removeAt(oldIndex);
              _groupTaxRows.insert(newIndex, row);
            });
          },
          itemBuilder: (context, index) {
            final tax = _groupTaxRows[index];
            final selected = _associatedTaxIds.contains(tax.id);
            return _TaxGroupTaxRow(
              key: ValueKey(tax.id),
              tax: tax,
              selected: selected,
              onSelectedChanged: (next) {
                setState(() {
                  next
                      ? _associatedTaxIds.add(tax.id)
                      : _associatedTaxIds.remove(tax.id);
                });
              },
              dragHandle: ReorderableDragStartListener(
                index: index,
                child: const Icon(
                  Icons.drag_indicator,
                  size: 18,
                  color: Color(0xFFD0D4DC),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaxGroupWarningArea() {
    return Container(
      color: const Color(0xFFFFF7F2),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select the existing transactions you want to update tax group details for:',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          _taxGroupOption(
            value: _draftInvoices,
            label: 'Draft Invoices',
            onChanged: (v) => setState(() => _draftInvoices = v),
          ),
          _taxGroupOption(
            value: _draftSalesOrders,
            label: 'Draft Sales Orders',
            onChanged: (v) => setState(() => _draftSalesOrders = v),
          ),
          _taxGroupOption(
            value: _recurringTransactions,
            label: 'Recurring Transactions',
            onChanged: (v) => setState(() => _recurringTransactions = v),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE6D8CC)),
          const SizedBox(height: 14),
          const _TaxGroupBullet(
            text:
                'Taxes that are applicable only during a specified period will not be listed above.',
          ),
          const _TaxGroupBullet(
            text:
                'The tax group details you edited will be updated in the selected draft transactions and will automatically apply to your future transactions.',
          ),
          const _TaxGroupBullet(
            text:
                'It may take some time for the edited tax group details to be updated in all your existing transactions.',
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE6D8CC)),
          const SizedBox(height: 10),
          _taxGroupOption(
            value: _acceptGroupUpdate,
            label:
                'I accept that updating the tax group will mark the existing tax group inactive, create a new one, and update it in chosen transactions.',
            onChanged: (v) => setState(() => _acceptGroupUpdate = v),
            normalWeight: true,
          ),
        ],
      ),
    );
  }

  Widget _taxGroupOption({
    required bool value,
    required String label,
    required ValueChanged<bool> onChanged,
    bool normalWeight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: Transform.scale(
                scale: 0.78,
                child: Checkbox(
                  value: value,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: const Color(0xFF1F6FEB),
                  side: const BorderSide(color: Color(0xFFBFC6D1)),
                  onChanged: (next) => onChanged(next ?? false),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: normalWeight ? FontWeight.w400 : FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxGroupTaxRow extends StatelessWidget {
  const _TaxGroupTaxRow({
    super.key,
    required this.tax,
    required this.selected,
    required this.onSelectedChanged,
    required this.dragHandle,
  });

  final SettingsTaxRate tax;
  final bool selected;
  final ValueChanged<bool> onSelectedChanged;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: Transform.scale(
                    scale: 0.78,
                    child: Checkbox(
                      value: selected,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: const Color(0xFF1F6FEB),
                      side: const BorderSide(color: Color(0xFFC9CDD3)),
                      onChanged: (next) => onSelectedChanged(next ?? false),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 34,
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Color(0xFFE5E7EB)),
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  tax.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ),
            Container(
              width: 110,
              height: 34,
              alignment: Alignment.centerRight,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                '${_TaxesTable._formatRate(tax.rate)} %',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: dragHandle,
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxGroupBullet extends StatelessWidget {
  const _TaxGroupBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              '\u2022',
              style: TextStyle(fontSize: 14, color: Color(0xFF9A6B31)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.35,
                color: Color(0xFF9A6B31),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SettingsTaxesOverviewPage._headerHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF888888),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SettingsTaxesOverviewPage._rowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF111827),
          ),
        ),
      ),
    );
  }
}

class _TaxNameCell extends StatelessWidget {
  const _TaxNameCell({required this.tax});

  final SettingsTaxRate tax;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: SettingsTaxesOverviewPage._rowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () {
              if (tax.isTaxGroup) {
                showDialog(
                  context: context,
                  barrierColor: Colors.black26,
                  builder: (context) => _EditTaxDialog(tax: tax),
                );
                return;
              }

              final orgSystemId =
                  GoRouterState.of(context).pathParameters['orgSystemId'] ??
                  '6000000000';
              context.go('/$orgSystemId/settings/taxes/${tax.id}/view');
            },
            borderRadius: BorderRadius.circular(4),
            hoverColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tax.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1F6FEB),
                      ),
                    ),
                    if (tax.isTaxGroup)
                      const TextSpan(
                        text: ' (Tax Group)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF2BB673),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkCreateTaxExemptionsDialog extends StatefulWidget {
  const _BulkCreateTaxExemptionsDialog();

  @override
  State<_BulkCreateTaxExemptionsDialog> createState() =>
      _BulkCreateTaxExemptionsDialogState();
}

class _BulkCreateTaxExemptionsDialogState
    extends State<_BulkCreateTaxExemptionsDialog> {
  final List<_BulkTaxExemptionDraft> _rows = List.generate(
    3,
    (_) => _BulkTaxExemptionDraft(),
  );

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          borderRadius: BorderRadius.circular(7),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 820,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 36, 0),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Column(
                            children: [
                              _buildTableHeader(),
                              for (var i = 0; i < _rows.length; i++)
                                _BulkTaxExemptionRow(
                                  draft: _rows[i],
                                  showRemove: _rows.length > 1,
                                  onRemove: () => _removeRow(i),
                                ),
                            ],
                          ),
                          const Positioned(
                            left: 300,
                            top: 0,
                            bottom: 0,
                            child: _BulkVerticalRule(),
                          ),
                          const Positioned(
                            left: 440,
                            top: 0,
                            bottom: 0,
                            child: _BulkVerticalRule(),
                          ),
                        ],
                      ),
                      _buildAddRow(),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 66,
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Bulk Create Tax Exemptions',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 22,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111111),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 300,
            child: _BulkHeaderLabel(requiredText: 'EXEMPTION REASON'),
          ),
          SizedBox(
            width: 140,
            child: _BulkColumnCell(child: _BulkHeaderLabel(text: 'TYPE')),
          ),
          Expanded(
            child: _BulkColumnCell(
              child: _BulkHeaderLabel(text: 'DESCRIPTION'),
            ),
          ),
          // action-column spacer aligned with the row remove button
          SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildAddRow() {
    return SizedBox(
      height: 46,
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: _addRow,
          borderRadius: BorderRadius.circular(4),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.plusCircle,
                  size: 16,
                  color: Color(0xFF1F2937),
                ),
                SizedBox(width: 6),
                Text(
                  'New Exemption Reason',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 100,
      padding: const EdgeInsets.only(left: 24),
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111111),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _addRow() {
    setState(() => _rows.add(_BulkTaxExemptionDraft()));
  }

  void _removeRow(int index) {
    setState(() {
      final row = _rows.removeAt(index);
      row.dispose();
    });
  }

  void _save() {
    final result = _rows
        .where((row) => row.reason.text.trim().isNotEmpty)
        .map(
          (row) => _TaxExemptionRowData(
            reason: row.reason.text.trim(),
            associatedWith: row.type,
            description: row.description.text.trim(),
          ),
        )
        .toList();
    Navigator.of(context).pop(result);
  }
}

class _BulkHeaderLabel extends StatelessWidget {
  const _BulkHeaderLabel({this.text, this.requiredText});

  final String? text;
  final String? requiredText;

  @override
  Widget build(BuildContext context) {
    final value = requiredText ?? text ?? '';
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: RichText(
        text: TextSpan(
          text: value,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF66708C),
          ),
          children: requiredText == null
              ? const []
              : const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: Color(0xFFDC2626)),
                  ),
                ],
        ),
      ),
    );
  }
}

class _BulkColumnCell extends StatelessWidget {
  const _BulkColumnCell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _BulkVerticalRule extends StatelessWidget {
  const _BulkVerticalRule();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 1,
      child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFFE5E7EB))),
    );
  }
}

class _BulkTaxExemptionRow extends StatefulWidget {
  const _BulkTaxExemptionRow({
    required this.draft,
    required this.showRemove,
    required this.onRemove,
  });

  final _BulkTaxExemptionDraft draft;
  final bool showRemove;
  final VoidCallback onRemove;

  @override
  State<_BulkTaxExemptionRow> createState() => _BulkTaxExemptionRowState();
}

class _BulkTaxExemptionRowState extends State<_BulkTaxExemptionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: 54,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 300,
              child: _bulkTextField(
                widget.draft.reason,
                hint: 'Exemption Reason Name',
                height: 54,
              ),
            ),
            SizedBox(width: 140, child: _typeCell()),
            Expanded(child: _descriptionCell()),
            // action column – fixed 36px, aligns with header spacer
            SizedBox(
              width: 36,
              child: widget.showRemove
                  ? AnimatedOpacity(
                      opacity: _isHovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Center(
                        child: IconButton(
                          onPressed: _isHovered ? widget.onRemove : null,
                          icon: const Icon(
                            LucideIcons.x,
                            size: 15,
                            color: Color(0xFFDC2626),
                          ),
                          splashRadius: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeCell() {
    bool cellHovered = false;
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return MouseRegion(
          onEnter: (_) => setStateLocal(() => cellHovered = true),
          onExit: (_) => setStateLocal(() => cellHovered = false),
          child: _BulkColumnCell(
            child: Container(
              height: 54,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 36,
                child: FormDropdown<String>(
                  value: widget.draft.type,
                  items: const ['Item', 'Customer'],
                  showSearch: true,
                  boldSelected: false,
                  forceDownward: true,
                  menuWidth: 140,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cellHovered
                        ? const Color(0xFF4285F4)
                        : Colors.transparent,
                    width: 1.4,
                  ),
                  fillColor: Colors.white,
                  disableBorder: false,
                  hideBorderDefault: false,
                  textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF374151),
                  ),
                  itemBuilder: (item, isSelected, isHovered) {
                    return Container(
                      height: 32,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isHovered
                              ? Colors.white
                              : const Color(0xFF374151),
                        ),
                      ),
                    );
                  },
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        widget.draft.type = value;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _descriptionCell() {
    return _BulkColumnCell(
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _bulkTextField(
          widget.draft.description,
          minLines: 2,
          maxLines: 2,
          height: 54,
        ),
      ),
    );
  }

  Widget _bulkTextField(
    TextEditingController controller, {
    String? hint,
    int minLines = 1,
    int maxLines = 1,
    required double height,
  }) {
    bool isHovered = false;
    final double inputHeight = minLines > 1 ? 38.0 : 36.0;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: inputHeight,
              child: TextField(
                controller: controller,
                minLines: minLines,
                maxLines: maxLines,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF374151),
                ),
                decoration: InputDecoration(
                  hoverColor: Colors.transparent,
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: minLines > 1 ? 6.0 : 8.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isHovered
                          ? const Color(0xFF4285F4)
                          : Colors.transparent,
                      width: 1.4,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isHovered
                          ? const Color(0xFF4285F4)
                          : Colors.transparent,
                      width: 1.4,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF4285F4),
                      width: 1.4,
                    ),
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

class _BulkTaxExemptionDraft {
  final TextEditingController reason = TextEditingController();
  final TextEditingController description = TextEditingController();
  String type = 'Customer';

  void dispose() {
    reason.dispose();
    description.dispose();
  }
}

class _TaxExemptionDialog extends StatefulWidget {
  const _TaxExemptionDialog({this.initial});

  final _TaxExemptionRowData? initial;

  @override
  State<_TaxExemptionDialog> createState() => _TaxExemptionDialogState();
}

class _TaxExemptionDialogState extends State<_TaxExemptionDialog> {
  late final TextEditingController _reasonController;
  late final TextEditingController _descriptionController;
  late String _type;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(
      text: widget.initial?.reason ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initial?.description ?? '',
    );
    _type = widget.initial?.associatedWith ?? 'Customer';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Material(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, minWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _requiredLabel('Exemption Reason'),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 340,
                        child: _dialogTextField(_reasonController),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'E.g. Non-Profit Organization',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 340,
                        child: _dialogTextField(
                          _descriptionController,
                          minLines: 4,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _requiredLabel('Type'),
                      const SizedBox(height: 8),
                      RadioGroup<String>(
                        groupValue: _type,
                        onChanged: (next) =>
                            setState(() => _type = next ?? _type),
                        child: Row(
                          children: [
                            _typeRadio('Customer'),
                            const SizedBox(width: 18),
                            _typeRadio('Item'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 54,
      padding: const EdgeInsets.fromLTRB(24, 0, 16, 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEdit ? 'Edit Exemption' : 'New Tax Exemption',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Color(0xFF111111),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text('Save'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111111),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _dialogTextField(
    TextEditingController controller, {
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: Color(0xFF374151),
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFF4285F4), width: 1.5),
        ),
      ),
    );
  }

  Widget _typeRadio(String value) {
    return InkWell(
      onTap: () => setState(() => _type = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Radio<String>(
              value: value,
              activeColor: const Color(0xFF4285F4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: text,
        style: AppTextStyles.labelRequired.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        children: const [TextSpan(text: '*')],
      ),
    );
  }

  void _save() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;
    Navigator.of(context).pop(
      _TaxExemptionRowData(
        reason: reason,
        associatedWith: _type,
        description: _descriptionController.text.trim(),
      ),
    );
  }
}

class _TaxExemptionRowData {
  const _TaxExemptionRowData({
    required this.reason,
    required this.associatedWith,
    required this.description,
  });

  final String reason;
  final String associatedWith;
  final String description;
}

class _FilterMenuRow extends StatefulWidget {
  const _FilterMenuRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_FilterMenuRow> createState() => _FilterMenuRowState();
}

class _FilterMenuRowState extends State<_FilterMenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 40,
          color: _hovered ? const Color(0xFF1F6FEB) : Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.label,
            style: AppTheme.bodyText.copyWith(
              color: _hovered ? Colors.white : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupRow extends StatefulWidget {
  const _PopupRow({required this.label});

  final String label;

  @override
  State<_PopupRow> createState() => _PopupRowState();
}

class _PopupRowState extends State<_PopupRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: double.infinity,
        color: _hovered ? const Color(0xFF1F6FEB) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          widget.label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            color: _hovered ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

class _NewTaxGroupPopupRow extends StatefulWidget {
  const _NewTaxGroupPopupRow();

  @override
  State<_NewTaxGroupPopupRow> createState() => _NewTaxGroupPopupRowState();
}

class _NewTaxGroupPopupRowState extends State<_NewTaxGroupPopupRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: 114.48,
        height: 34.8,
        alignment: Alignment.centerLeft,
        color: _hovered ? const Color(0xFF1F6FEB) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          'New Tax Group',
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            color: _hovered ? Colors.white : const Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No taxes found.',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: AppTheme.bodyText.copyWith(color: AppTheme.errorRed),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class AccountDropdownItem {
  final String name;
  final bool isHeader;
  final bool isSubItem;

  const AccountDropdownItem({
    required this.name,
    this.isHeader = false,
    this.isSubItem = false,
  });

  @override
  String toString() => name;
}

class _SettingsAccountTreeDraftGroup {
  _SettingsAccountTreeDraftGroup({required this.name});

  final String name;
  final List<_SettingsAccountTreeDraftNode> children = [];
}

class _SettingsAccountTreeDraftNode {
  _SettingsAccountTreeDraftNode({required this.name});

  final String name;
  final List<_SettingsAccountTreeDraftNode> children = [];

  AccountNode toAccountNode() {
    return AccountNode(
      id: name,
      name: name,
      children: children.map((child) => child.toAccountNode()).toList(),
    );
  }
}

class CreateAccountDialog extends StatefulWidget {
  const CreateAccountDialog();

  @override
  State<CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<CreateAccountDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, bottom: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 220),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Create Account', style: AppTextStyles.title),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFFFF3333),
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Text(
                        'Account Name*',
                        style: AppTextStyles.labelRequired,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: CustomTextField(
                          controller: _nameController,
                          hintText: '',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isNotEmpty) {
                        Navigator.of(context).pop(name);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Save and Select',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF1F2937),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
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
    );
  }
}

class TaxpayerDetailsDialog extends StatefulWidget {
  final String gstin;
  const TaxpayerDetailsDialog({required this.gstin});

  @override
  State<TaxpayerDetailsDialog> createState() => _TaxpayerDetailsDialogState();
}

class _TaxpayerDetailsDialogState extends State<TaxpayerDetailsDialog> {
  bool _expanded = false;

  final List<Map<String, String>> _returnHistory = [
    {
      'period': 'May-2026',
      'type': 'GSTR-3B',
      'status': 'Filed',
      'ack': 'AA320526304572J',
      'date': '16-06-2026',
    },
    {
      'period': 'May-2026',
      'type': 'GSTR-1',
      'status': 'Filed',
      'ack': 'AA3205261719615',
      'date': '10-06-2026',
    },
    {
      'period': 'April-2026',
      'type': 'GSTR-3B',
      'status': 'Filed',
      'ack': 'AA320426555118A',
      'date': '20-05-2026',
    },
    {
      'period': 'April-2026',
      'type': 'GSTR-1',
      'status': 'Filed',
      'ack': 'AA320426103533Q',
      'date': '08-05-2026',
    },
    {
      'period': 'March-2026',
      'type': 'GSTR-3B',
      'status': 'Filed',
      'ack': 'AA320326433257F',
      'date': '18-04-2026',
    },
    {
      'period': 'March-2026',
      'type': 'GSTR-1',
      'status': 'Filed',
      'ack': 'AA320326176718Z',
      'date': '10-04-2026',
    },
    {
      'period': 'February-2026',
      'type': 'GSTR-3B',
      'status': 'Filed',
      'ack': 'AA320226502985A',
      'date': '19-03-2026',
    },
    {
      'period': 'February-2026',
      'type': 'GSTR-1',
      'status': 'Filed',
      'ack': 'AA320226042151Y',
      'date': '03-03-2026',
    },
    {
      'period': 'January-2026',
      'type': 'GSTR-3B',
      'status': 'Filed',
      'ack': 'AA320126461899V',
      'date': '19-02-2026',
    },
    {
      'period': 'January-2026',
      'type': 'GSTR-1',
      'status': 'Filed',
      'ack': 'AA320126049101Y',
      'date': '04-02-2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, bottom: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Taxpayer details',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFFFF3333),
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Entered GSTIN/UIN: ',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                          TextSpan(
                            text: widget.gstin,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            title: 'Company Name',
                            value: 'ZABNIX PRIVATE LIMITED',
                            gradientColors: [
                              const Color(0xFFFF9A9E),
                              const Color(0xFFFECFEF),
                            ],
                            icon: Icons.business,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            title: 'Date of Registration',
                            value: '17/01/2025',
                            gradientColors: [
                              const Color(0xFFF1A7F1),
                              const Color(0xFFFAD0C4),
                            ],
                            icon: Icons.calendar_month,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _statCard(
                            title: 'GSTIN/UIN status',
                            value: 'Active',
                            gradientColors: [
                              const Color(0xFFA1C4FD),
                              const Color(0xFFC2E9FB),
                            ],
                            icon: Icons.show_chart,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 20),
                    _detailRow('Taxpayer Type', 'Regular'),
                    _detailRow('Centre Jurisdiction', 'PERINTHALMANNA RANGE'),
                    _detailRow(
                      'State Jurisdiction',
                      'Taxpayer Services Circle, Perinthalmanna',
                    ),
                    _detailRow(
                      'Constitution of Business',
                      'Private Limited Company',
                    ),
                    _detailRow('Business Trade Name', ''),
                    _detailRow('e-Invoicing Applicability', 'Not Applicable'),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expanded = !_expanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Return Details',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _expanded
                                  ? Icons.arrow_drop_down
                                  : Icons.arrow_right,
                              size: 20,
                              color: Colors.grey[800],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 16),
                      _buildReturnTable(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: const [
              Expanded(
                flex: 2,
                child: Text(
                  'TAX PERIOD',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'RETURN TYPE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'STATUS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'ACKNOWLEDGEMENT NUMBER',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'DATE OF FILING',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._returnHistory.map((row) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    row['period']!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    row['type']!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    row['status']!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    row['ack']!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    row['date']!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _RegistrationTypeOption {
  final String label;
  final String description;

  const _RegistrationTypeOption({
    required this.label,
    required this.description,
  });
}

class _DefaultTaxPreferenceOption {
  final String label;
  final bool isHeader;

  const _DefaultTaxPreferenceOption({
    required this.label,
    this.isHeader = false,
  });
}
