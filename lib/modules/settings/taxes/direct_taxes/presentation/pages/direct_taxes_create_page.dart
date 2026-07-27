import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';

class DirectTaxesCreatePage extends StatefulWidget {
  const DirectTaxesCreatePage({super.key});

  @override
  State<DirectTaxesCreatePage> createState() => _DirectTaxesCreatePageState();
}

enum _DirectTaxMenuItem { tdsIncomeSettings, tdsIncomeRates, tcsIncomeRates }

enum _TdsApplyMode { transaction, lineItem }

class _TdsRateRow {
  const _TdsRateRow({
    this.id,
    required this.taxName,
    required this.rate,
    required this.taxType,
    required this.status,
    this.isGroup = false,
    this.source = const <String, dynamic>{},
  });

  final String? id;
  final String taxName;
  final String rate;
  final String taxType;
  final String status;
  final bool isGroup;
  final Map<String, dynamic> source;
}

class _SectionOption {
  const _SectionOption({
    this.id,
    required this.title,
    required this.description,
    required this.earlier,
  });

  final String? id;
  final String title;
  final String description;
  final String earlier;
}

class _HigherTdsReasonOption {
  const _HigherTdsReasonOption({
    this.id,
    required this.title,
    required this.description,
  });

  final String? id;
  final String title;
  final String description;
}

class _GroupTaxSelectableRate {
  const _GroupTaxSelectableRate({
    required this.id,
    required this.name,
    required this.rate,
    this.sectionLabel,
  });

  final String id;
  final String name;
  final String rate;
  final String? sectionLabel;
}

class _DirectTaxesCreatePageState extends State<DirectTaxesCreatePage> {
  final ApiClient _apiClient = ApiClient();
  final SettingsPreferencesRepository _preferencesRepository =
      SettingsPreferencesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  _DirectTaxMenuItem _selectedMenuItem = _DirectTaxMenuItem.tdsIncomeSettings;
  _TdsApplyMode _selectedApplyMode = _TdsApplyMode.transaction;
  bool _enableTdsLiabilitiesReport = false;
  String? _selectedStartPeriod;
  String? _selectedPenaltyAccount;
  String? _selectedInterestAccount;
  String _selectedTdsRatesFilter = 'All';
  final List<_TdsRateRow> _dbTdsRateRows = <_TdsRateRow>[];
  final List<_TdsRateRow> _dbTcsRateRows = <_TdsRateRow>[];
  final List<_SectionOption> _dbTdsSections = <_SectionOption>[];
  final List<_SectionOption> _dbTcsNatures = <_SectionOption>[];
  final List<_HigherTdsReasonOption> _dbTcsHigherReasons =
      <_HigherTdsReasonOption>[];
  final Map<String, String> _accountIdByName = <String, String>{};
  bool _isLoadingRates = true;

  static const List<String> _tdsRatesFilters = <String>[
    'All',
    'Active',
    'Inactive',
    'Expired',
    'TDS',
    'TDS Group',
  ];
  static const List<String> _newTdsTaxActions = <String>[
    'New TDS Surcharge',
    'New TDS Cess',
  ];

  List<_TdsRateRow> get _filteredTdsRows => _dbTdsRateRows.where((row) {
    switch (_selectedTdsRatesFilter) {
      case 'Active':
      case 'Inactive':
      case 'Expired':
        return row.status == _selectedTdsRatesFilter;
      case 'TDS':
        return !row.isGroup;
      case 'TDS Group':
        return row.isGroup;
      default:
        return true;
    }
  }).toList();
  @override
  void initState() {
    super.initState();
    _loadDirectTaxRates();
  }

  Future<void> _loadDirectTaxRates() async {
    try {
      final responses = await Future.wait<dynamic>([
        _apiClient.get('settings-taxes/tds/sections', useCache: false),
        _apiClient.get('settings-taxes/tds/rates', useCache: false),
        _apiClient.get('settings-taxes/tds/groups', useCache: false),
        _apiClient.get('settings-taxes/tcs/natures', useCache: false),
        _apiClient.get('settings-taxes/tcs/rates', useCache: false),
        _apiClient.get(
          'settings-taxes/tcs/higher-rate-reasons',
          useCache: false,
        ),
        _apiClient.get('accountant', useCache: false),
        _preferencesRepository.loadSection('charges_preferences', const [
          'direct_taxes',
        ]),
      ]);
      final sectionNames = <String, String>{
        for (final row
            in (responses[0].data as List? ?? const []).whereType<Map>())
          if (row['id'] != null)
            row['id'].toString(): row['section_name']?.toString() ?? '',
      };
      final natureNames = <String, String>{
        for (final row
            in (responses[3].data as List? ?? const []).whereType<Map>())
          if (row['id'] != null)
            row['id'].toString(): row['nature_name']?.toString() ?? '',
      };
      final tdsRows = <_TdsRateRow>[
        for (final raw
            in (responses[1].data as List? ?? const []).whereType<Map>())
          _TdsRateRow(
            id: raw['id']?.toString(),
            taxName: raw['tax_name']?.toString() ?? '',
            rate: raw['base_rate']?.toString() ?? '0',
            taxType: sectionNames[raw['section_id']?.toString()] ?? '',
            status: _directTaxStatus(raw),
            source: Map<String, dynamic>.from(raw),
          ),
        for (final raw
            in (responses[2].data as List? ?? const []).whereType<Map>())
          _TdsRateRow(
            id: raw['id']?.toString(),
            taxName: raw['group_name']?.toString() ?? '',
            rate: (raw['rates'] as List? ?? const [])
                .whereType<Map>()
                .fold<double>(
                  0,
                  (sum, rate) =>
                      sum +
                      (double.tryParse(rate['base_rate']?.toString() ?? '') ??
                          0),
                )
                .toString(),
            taxType: 'TDS Group',
            status: _directTaxStatus(raw),
            isGroup: true,
            source: Map<String, dynamic>.from(raw),
          ),
      ];
      final tcsRows = <_TdsRateRow>[
        for (final raw
            in (responses[4].data as List? ?? const []).whereType<Map>())
          _TdsRateRow(
            id: raw['id']?.toString(),
            taxName: raw['tax_name']?.toString() ?? '',
            rate: raw['rate']?.toString() ?? '0',
            taxType: natureNames[raw['nature_id']?.toString()] ?? '',
            status: _directTaxStatus(raw),
            source: Map<String, dynamic>.from(raw),
          ),
      ];
      final accounts = <String, String>{};
      void collectAccounts(dynamic rows) {
        if (rows is! List) return;
        for (final raw in rows.whereType<Map>()) {
          final id = raw['id']?.toString();
          final name =
              (raw['user_account_name'] ??
                      raw['system_account_name'] ??
                      raw['name'])
                  ?.toString()
                  .trim();
          if (id != null && name != null && name.isNotEmpty) {
            accounts[name] = id;
          }
          collectAccounts(raw['children']);
        }
      }

      collectAccounts(responses[6].data);
      final preferences = Map<String, dynamic>.from(
        responses[7] as Map? ?? const <String, dynamic>{},
      );
      if (!mounted) return;
      setState(() {
        _dbTdsRateRows
          ..clear()
          ..addAll(tdsRows);
        _dbTcsRateRows
          ..clear()
          ..addAll(tcsRows);
        _dbTdsSections
          ..clear()
          ..addAll(
            (responses[0].data as List? ?? const []).whereType<Map>().map(
              (row) => _SectionOption(
                id: row['id']?.toString(),
                title: row['section_name']?.toString() ?? '',
                description: row['description']?.toString() ?? '',
                earlier: '',
              ),
            ),
          );
        _dbTcsNatures
          ..clear()
          ..addAll(
            (responses[3].data as List? ?? const []).whereType<Map>().map(
              (row) => _SectionOption(
                id: row['id']?.toString(),
                title: row['nature_name']?.toString() ?? '',
                description: row['description']?.toString() ?? '',
                earlier: '',
              ),
            ),
          );
        _dbTcsHigherReasons
          ..clear()
          ..addAll(
            (responses[5].data as List? ?? const []).whereType<Map>().map(
              (row) => _HigherTdsReasonOption(
                id: row['id']?.toString(),
                title: row['reason_name']?.toString() ?? '',
                description: row['description']?.toString() ?? '',
              ),
            ),
          );
        _accountIdByName
          ..clear()
          ..addAll(accounts);
        _selectedApplyMode = preferences['apply_mode'] == 'lineItem'
            ? _TdsApplyMode.lineItem
            : _TdsApplyMode.transaction;
        _enableTdsLiabilitiesReport =
            preferences['enable_liabilities_report'] == true;
        _selectedStartPeriod = preferences['start_period']?.toString();
        final penaltyAccount = preferences['penalty_account_name']?.toString();
        final interestAccount = preferences['interest_account_name']
            ?.toString();
        _selectedPenaltyAccount = accounts.containsKey(penaltyAccount)
            ? penaltyAccount
            : null;
        _selectedInterestAccount = accounts.containsKey(interestAccount)
            ? interestAccount
            : null;
        _isLoadingRates = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingRates = false);
      ZerpaiToast.error(context, 'Failed to load direct tax rates');
    }
  }

  String _directTaxStatus(Map<dynamic, dynamic> row) {
    if (row['is_active'] == false) return 'Inactive';
    final end = DateTime.tryParse(row['applicable_to']?.toString() ?? '');
    return end != null && end.isBefore(DateTime.now()) ? 'Expired' : 'Active';
  }

  Future<void> _deleteDirectTax(_TdsRateRow row, {required bool isTcs}) async {
    if (row.id == null) return;
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Direct Tax',
      message: 'This tax master will be removed.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed || !mounted) return;
    try {
      final path = isTcs
          ? 'settings-taxes/tcs/rates/${row.id}'
          : 'settings-taxes/tds/${row.isGroup ? 'groups' : 'rates'}/${row.id}';
      await _apiClient.delete(path);
      await _loadDirectTaxRates();
      if (mounted) ZerpaiToast.success(context, 'Direct tax deleted');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to delete direct tax');
    }
  }

  Future<void> _toggleDirectTax(_TdsRateRow row, {required bool isTcs}) async {
    if (row.id == null) return;
    try {
      final path = isTcs
          ? 'settings-taxes/tcs/rates/${row.id}'
          : 'settings-taxes/tds/${row.isGroup ? 'groups' : 'rates'}/${row.id}';
      await _apiClient.patch(path, data: {'is_active': row.status != 'Active'});
      await _loadDirectTaxRates();
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to update direct tax');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _showNewTdsDialog({
    String title = 'New TDS',
    _TdsRateRow? existing,
  }) {
    if (title == 'New TDS Surcharge' || title == 'New TDS Cess') {
      ZerpaiToast.info(
        context,
        'Surcharge and cess are configured on a TDS rate.',
      );
      return Future<void>.value();
    }
    final isTcs = title == 'New TCS';
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useSafeArea: false,
      builder: (BuildContext context) => _NewTdsDialog(
        title: existing == null ? title : (isTcs ? 'Edit TCS' : 'Edit TDS'),
        options: isTcs ? _dbTcsNatures : _dbTdsSections,
        higherRateReasons: isTcs
            ? _dbTcsHigherReasons
            : const <_HigherTdsReasonOption>[],
        accountIdByName: _accountIdByName,
        initial: existing?.source,
        isTcs: isTcs,
        onSave: (payload) async {
          try {
            final path = isTcs
                ? 'settings-taxes/tcs/rates'
                : 'settings-taxes/tds/rates';
            if (existing?.id == null) {
              await _apiClient.post(path, data: payload);
            } else {
              await _apiClient.patch('$path/${existing!.id}', data: payload);
            }
            await _loadDirectTaxRates();
            return true;
          } catch (_) {
            return false;
          }
        },
      ),
    );
  }

  Future<void> _showNewTdsGroupTaxDialog([_TdsRateRow? existing]) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      useSafeArea: false,
      builder: (BuildContext context) => _NewTdsGroupTaxDialog(
        initial: existing?.source,
        rates: _dbTdsRateRows
            .where((row) => !row.isGroup && row.id != null)
            .map(
              (row) => _GroupTaxSelectableRate(
                id: row.id!,
                name: row.taxName,
                sectionLabel: row.taxType,
                rate: '${row.rate} %',
              ),
            )
            .toList(),
        onSave: (name, rateIds, from, to) async {
          try {
            final payload = {
              'group_name': name,
              'tds_rate_ids': rateIds,
              'applicable_from': from,
              'applicable_to': to,
              'is_active': existing?.source['is_active'] ?? true,
            };
            if (existing?.id == null) {
              await _apiClient.post('settings-taxes/tds/groups', data: payload);
            } else {
              await _apiClient.patch(
                'settings-taxes/tds/groups/${existing!.id}',
                data: payload,
              );
            }
            await _loadDirectTaxRates();
            return true;
          } catch (_) {
            return false;
          }
        },
      ),
    );
  }

  Future<void> _editDirectTax(_TdsRateRow row, {required bool isTcs}) {
    if (row.isGroup) return _showNewTdsGroupTaxDialog(row);
    return _showNewTdsDialog(
      title: isTcs ? 'New TCS' : 'New TDS',
      existing: row,
    );
  }

  Future<void> _saveDirectTaxPreferences() async {
    if (_enableTdsLiabilitiesReport && _selectedStartPeriod == null) {
      ZerpaiToast.info(context, 'Select the TDS liabilities start period');
      return;
    }
    try {
      await _preferencesRepository.saveSection(
        'charges_preferences',
        {
          'apply_mode': _selectedApplyMode.name,
          'enable_liabilities_report': _enableTdsLiabilitiesReport,
          'start_period': _selectedStartPeriod,
          'penalty_account_id': _accountIdByName[_selectedPenaltyAccount],
          'penalty_account_name': _selectedPenaltyAccount,
          'interest_account_id': _accountIdByName[_selectedInterestAccount],
          'interest_account_name': _selectedInterestAccount,
        },
        const ['direct_taxes'],
      );
      if (mounted) ZerpaiToast.success(context, 'Direct tax settings saved');
    } catch (_) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to save direct tax settings');
      }
    }
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Taxes & Compliance',
        label: 'Direct Taxes',
        subtitle: 'Income TDS Settings',
        keywords: const <String>[
          'direct taxes',
          'tds',
          'tcs',
          'income tds settings',
        ],
        onSelected: () => setState(
          () => _selectedMenuItem = _DirectTaxMenuItem.tdsIncomeSettings,
        ),
      ),
      SettingsSearchItem(
        group: 'Taxes & Compliance',
        label: 'Income TDS Rates',
        subtitle: 'Direct Taxes',
        keywords: const <String>['tds', 'rates'],
        onSelected: () => setState(
          () => _selectedMenuItem = _DirectTaxMenuItem.tdsIncomeRates,
        ),
      ),
      SettingsSearchItem(
        group: 'Taxes & Compliance',
        label: 'Income TCS Rates',
        subtitle: 'Direct Taxes',
        keywords: const <String>['tcs', 'rates'],
        onSelected: () => setState(
          () => _selectedMenuItem = _DirectTaxMenuItem.tcsIncomeRates,
        ),
      ),
    ];
  }

  String _orgScopedRoute(BuildContext context, String route) {
    final path = GoRouterState.of(context).uri.path;
    final match = RegExp(r'^/(\d{10,20})(?:/|$)').firstMatch(path);
    final orgSystemId = match?.group(1);
    if (orgSystemId == null || orgSystemId.isEmpty) {
      return route;
    }
    return '/$orgSystemId$route';
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(
      context,
    ).uri.path.replaceFirst(RegExp(r'^/\d{10,20}'), '');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SettingsPageHeader(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            searchItems: _buildSearchItems(),
            showBackButton: true,
            onBack: () =>
                context.go(_orgScopedRoute(context, AppRoutes.settings)),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsNavigationSidebar(currentPath: currentPath),
                  _buildSectionRail(),
                  Expanded(child: _buildContentPane()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionRail() {
    return Container(
      width: 228,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 50,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Text(
              'Direct Taxes',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          _buildSectionLabel('TDS'),
          _buildRailItem(
            label: 'Income TDS Settings',
            item: _DirectTaxMenuItem.tdsIncomeSettings,
            showBottomBorder: false,
          ),
          _buildRailItem(
            label: 'Income TDS Rates',
            item: _DirectTaxMenuItem.tdsIncomeRates,
            showBottomBorder: false,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          _buildSectionLabel('TCS'),
          _buildRailItem(
            label: 'Income TCS Rates',
            item: _DirectTaxMenuItem.tcsIncomeRates,
            showBottomBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Text(
        label,
        style: AppTheme.bodyText.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w400,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildRailItem({
    required String label,
    required _DirectTaxMenuItem item,
    bool showBottomBorder = true,
  }) {
    final bool isActive = _selectedMenuItem == item;
    return InkWell(
      onTap: () => setState(() => _selectedMenuItem = item),
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF7F8FB) : Colors.white,
          border: Border(
            bottom: showBottomBorder
                ? const BorderSide(color: AppTheme.borderLight)
                : BorderSide.none,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildContentPane() {
    switch (_selectedMenuItem) {
      case _DirectTaxMenuItem.tdsIncomeSettings:
        return _buildTdsSettingsPane();
      case _DirectTaxMenuItem.tdsIncomeRates:
        return _buildTdsRatesPane();
      case _DirectTaxMenuItem.tcsIncomeRates:
        return _buildTcsRatesPane();
    }
  }

  Widget _buildTdsSettingsPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Text(
            'Income TDS Settings',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TDS',
                              style: AppTheme.pageTitle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'TDS or Tax Deducted at Source, can be associated at either the transaction level or at the line item level.',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF98A2B3),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Apply TDS:',
                              style: AppTheme.bodyText.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildRadioOption(
                              title: 'At Transaction Level',
                              subtitle:
                                  'TDS will be applied to the transaction\'s total.',
                              value: _TdsApplyMode.transaction,
                            ),
                            const SizedBox(height: 12),
                            _buildRadioOption(
                              title: 'At Line Item Level',
                              subtitle:
                                  'TDS will be applied to the line items for which you associate TDS.',
                              value: _TdsApplyMode.lineItem,
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppTheme.borderLight,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 20, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Transform.translate(
                                  offset: const Offset(-2, 0),
                                  child: Checkbox(
                                    value: _enableTdsLiabilitiesReport,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _enableTdsLiabilitiesReport =
                                            value ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.primaryBlue,
                                    checkColor: Colors.white,
                                    side: const BorderSide(
                                      color: AppTheme.borderColorDark,
                                    ),
                                    visualDensity: const VisualDensity(
                                      horizontal: -4,
                                      vertical: -4,
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Enable TDS Liabilities Report',
                                  style: AppTheme.bodyText.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: const Color(0xFF1F2937),
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                            if (_enableTdsLiabilitiesReport) ...[
                              const SizedBox(height: 10),
                              _buildLiabilitiesFields(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: _saveDirectTaxPreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: AppTheme.buttonText.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String subtitle,
    required _TdsApplyMode value,
  }) {
    return RadioListTile<_TdsApplyMode>(
      value: value,
      groupValue: _selectedApplyMode,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _selectedApplyMode = value);
      },
      activeColor: AppTheme.primaryBlue,
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -3),
      title: Text(
        title,
        style: AppTheme.bodyText.copyWith(
          fontSize: 12.9,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF374151),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          subtitle,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.4,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF98A2B3),
          ),
        ),
      ),
    );
  }

  Widget _buildLiabilitiesFields() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 2),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 646),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: 'Start Period',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12.6,
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w400,
                ),
                children: <InlineSpan>[
                  TextSpan(
                    text: '*',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12.6,
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            SizedBox(width: 191, child: _buildMonthYearField()),
            const SizedBox(height: 10),
            SizedBox(
              width: 448,
              child: Text(
                'Note: The TDS liability details will be generated starting from the selected month, and you can record challans accordingly.',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12.4,
                  color: const Color(0xFF8A94B2),
                  fontWeight: FontWeight.w400,
                  height: 1.38,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Select Account To Track Penalties and Interest',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12.95,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildAccountField(
                    label: 'Penalty Account',
                    value: _selectedPenaltyAccount,
                    onChanged: (String? value) {
                      setState(() => _selectedPenaltyAccount = value);
                    },
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildAccountField(
                    label: 'Interest Account',
                    value: _selectedInterestAccount,
                    onChanged: (String? value) {
                      setState(() => _selectedInterestAccount = value);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.75,
            color: const Color(0xFF2E3646),
            fontWeight: FontWeight.w400,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        _buildStyledPatternDropdown(
          value: value,
          items: _accountIdByName.keys.toList()..sort(),
          hint: 'Select an account',
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildStyledPatternDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return FormDropdown<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      height: 33,
      showSearch: true,
      hint: hint,
      boldSelected: false,
      itemHeight: 36,
      itemEstimatedHeight: 36,
      menuMaxHeight: 260,
      maxVisibleItems: 7,
      allowClear: false,
      showCustomValueAction: false,
      paintSelectionBackground: false,
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 12.9,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF4B5563),
      ),
      itemBuilder: (String item, bool isSelected, bool isHovered) {
        final Color rowColor = isHovered
            ? const Color(0xFF4A86E8)
            : isSelected
            ? const Color(0xFFF1F4FA)
            : Colors.white;
        final Color textColor = isHovered
            ? Colors.white
            : const Color(0xFF374151);
        final Color tickColor = isHovered ? Colors.white : AppTheme.primaryBlue;

        return Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: rowColor,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check, size: 16, color: tickColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthYearField() {
    return _MonthYearPickerField(
      value: _selectedStartPeriod,
      onChanged: (String? value) {
        setState(() => _selectedStartPeriod = value);
      },
    );
  }

  Widget _buildTdsRatesPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(18, 0, 8, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              _buildTdsRatesFilterDropdown(),
              const Spacer(),
              _buildNewTdsTaxDropdownButton(),
              const SizedBox(width: 8),
              _buildHeaderActionButton(
                label: 'TDS Group Tax',
                showAddIcon: true,
                onPressed: _showNewTdsGroupTaxDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _RateHeaderCell(label: 'TAX NAME', width: 298),
                      _RateHeaderCell(label: 'RATE (%)', width: 82),
                      _RateHeaderCell(label: 'TAX TYPE', width: 154),
                      _RateHeaderCell(label: 'STATUS', width: 96),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                if (_isLoadingRates)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  for (final row in _filteredTdsRows)
                    _buildTdsRateRow(
                      row,
                      isTcs: false,
                      showMarkAsInactive: true,
                    ),
                _buildRatesTableFooter(totalCount: _filteredTdsRows.length),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTcsRatesPane() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 52,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Text(
                'Income TCS Rates',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const Spacer(),
              _buildHeaderActionButton(
                label: 'New TCS Tax',
                showAddIcon: true,
                onPressed: () => _showNewTdsDialog(title: 'New TCS'),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: const Row(
                    children: [
                      _RateHeaderCell(label: 'TAX NAME', width: 298),
                      _RateHeaderCell(label: 'RATE (%)', width: 82),
                      _RateHeaderCell(label: 'TAX TYPE', width: 154),
                      _RateHeaderCell(label: 'STATUS', width: 96),
                      Expanded(child: SizedBox()),
                    ],
                  ),
                ),
                if (_isLoadingRates)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  for (final row in _dbTcsRateRows)
                    _buildTdsRateRow(
                      row,
                      isTcs: true,
                      showMarkAsInactive: true,
                    ),
                _buildRatesTableFooter(totalCount: _dbTcsRateRows.length),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatesTableFooter({required int totalCount}) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            'Total Count: $totalCount',
            style: AppTheme.bodyText.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          const Spacer(),
          Container(
            height: 32,
            width: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9E2F2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.chevronLeft,
                  size: 15,
                  color: Color(0xFFB7C3D7),
                ),
                const SizedBox(width: 8),
                Text(
                  '1 - $totalCount',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 15,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({
    required String label,
    bool showAddIcon = false,
    bool showCaret = false,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed ?? () {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showAddIcon) ...[
              const Icon(Icons.add, size: 14),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: AppTheme.buttonText.copyWith(
                fontSize: 11.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showCaret) ...[
              const SizedBox(width: 3),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewTdsTaxDropdownButton() {
    final MenuController controller = MenuController();

    return MenuAnchor(
      controller: controller,
      crossAxisUnconstrained: false,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      menuChildren: <Widget>[
        Container(
          width: 194,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _newTdsTaxActions.map((String option) {
              return InkWell(
                onTap: () {
                  controller.close();
                  _showNewTdsDialog(title: option);
                },
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: _HeaderActionDropdownItem(label: option),
              );
            }).toList(),
          ),
        ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            final bool isOpen = controller.isOpen;

            return Container(
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF22B378),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showNewTdsDialog(),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 14, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            'New TDS Tax',
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 11.8,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  InkWell(
                    onTap: () {
                      if (isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                    child: SizedBox(
                      width: 26,
                      height: 28,
                      child: Icon(
                        isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildTdsRatesFilterDropdown() {
    final MenuController controller = MenuController();

    return MenuAnchor(
      controller: controller,
      crossAxisUnconstrained: false,
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      menuChildren: <Widget>[
        Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _tdsRatesFilters.map((String option) {
              return InkWell(
                onTap: () {
                  setState(() => _selectedTdsRatesFilter = option);
                  controller.close();
                },
                hoverColor: const Color(0xFF4A86E8),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: _TdsRatesFilterMenuItem(
                  label: option,
                  isSelected: _selectedTdsRatesFilter == option,
                ),
              );
            }).toList(),
          ),
        ),
      ],
      builder:
          (BuildContext context, MenuController controller, Widget? child) {
            final bool isOpen = controller.isOpen;
            return InkWell(
              onTap: () {
                if (isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              borderRadius: BorderRadius.circular(4),
              hoverColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'All TDS Rates',
                    style: AppTheme.pageTitle.copyWith(
                      fontSize: 17.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.expand_more,
                    size: 17,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _buildTdsRateRow(
    _TdsRateRow row, {
    required bool isTcs,
    required bool showMarkAsInactive,
  }) {
    return _HoverableTdsRateTableRow(
      row: row,
      showMarkAsInactive: showMarkAsInactive,
      onDelete: () => _deleteDirectTax(row, isTcs: isTcs),
      onEdit: () => _editDirectTax(row, isTcs: isTcs),
      onToggleStatus: () => _toggleDirectTax(row, isTcs: isTcs),
    );
  }
}

class _HoverableTdsRateTableRow extends StatefulWidget {
  const _HoverableTdsRateTableRow({
    required this.row,
    required this.showMarkAsInactive,
    required this.onDelete,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final _TdsRateRow row;
  final bool showMarkAsInactive;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  State<_HoverableTdsRateTableRow> createState() =>
      _HoverableTdsRateTableRowState();
}

class _HoverableTdsRateTableRowState extends State<_HoverableTdsRateTableRow> {
  bool _hovered = false;
  bool _menuOpen = false;

  void _setRowActionMenuOpen(bool isOpen) {
    if (!mounted || _menuOpen == isOpen) {
      return;
    }

    setState(() => _menuOpen = isOpen);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF22B378);
      case 'inactive':
        return const Color(0xFF98A2B3);
      default:
        return const Color(0xFFFF6B6B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final _TdsRateRow row = widget.row;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF3F4F6) : Colors.white,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 298,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18, right: 14),
                    child: Text(
                      row.taxName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13.4,
                        fontWeight: FontWeight.w600,
                        color: row.isGroup
                            ? AppTheme.accentGreen
                            : AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 82,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Text(
                        row.rate,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13.1,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF344054),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 154,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 14),
                    child: Text(
                      row.taxType,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13.1,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF344054),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Text(
                      row.status,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13.1,
                        fontWeight: FontWeight.w500,
                        color: _statusColor(row.status),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 42),
              ],
            ),
            Positioned(
              right: 62,
              top: 10,
              child: MenuAnchor(
                onOpen: () => _setRowActionMenuOpen(true),
                onClose: () => _setRowActionMenuOpen(false),
                crossAxisUnconstrained: false,
                alignmentOffset: const Offset(-172, 6),
                style: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                  surfaceTintColor: WidgetStateProperty.all(Colors.white),
                  elevation: WidgetStateProperty.all(10),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                menuChildren: [
                  Container(
                    width: 228,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TdsRateRowActionMenuItem(
                          icon: LucideIcons.edit3,
                          label: 'Edit',
                          onPressed: widget.onEdit,
                        ),
                        _TdsRateRowActionMenuItem(
                          icon: LucideIcons.trash2,
                          label: 'Delete',
                          onPressed: widget.onDelete,
                        ),
                        if (widget.showMarkAsInactive)
                          _TdsRateRowActionMenuItem(
                            icon: LucideIcons.ban,
                            label: row.status == 'Active'
                                ? 'Mark as Inactive'
                                : 'Mark as Active',
                            onPressed: widget.onToggleStatus,
                          ),
                      ],
                    ),
                  ),
                ],
                builder:
                    (
                      BuildContext context,
                      MenuController controller,
                      Widget? child,
                    ) {
                      final bool showAction = _hovered || _menuOpen;

                      return IgnorePointer(
                        ignoring: !showAction,
                        child: InkWell(
                          onTap: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: showAction ? 1 : 0,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22B378),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.chevronDown,
                                size: 11,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
}

class _TdsRateRowActionMenuItem extends StatefulWidget {
  const _TdsRateRowActionMenuItem({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  State<_TdsRateRowActionMenuItem> createState() =>
      _TdsRateRowActionMenuItemState();
}

class _TdsRateRowActionMenuItemState extends State<_TdsRateRowActionMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isHighlighted ? const Color(0xFF4A86E8) : Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 17,
                color: isHighlighted ? Colors.white : const Color(0xFF4A86E8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w400,
                    color: isHighlighted
                        ? Colors.white
                        : const Color(0xFF4B5563),
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

class _RateHeaderCell extends StatelessWidget {
  const _RateHeaderCell({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    final TextAlign textAlign = label == 'RATE (%)'
        ? TextAlign.right
        : TextAlign.left;
    final EdgeInsets padding = EdgeInsets.only(
      left: label == 'TAX NAME'
          ? 18
          : label == 'RATE (%)'
          ? 12
          : 8,
      right: 14,
    );

    return SizedBox(
      width: width,
      child: Padding(
        padding: padding,
        child: Text(
          label,
          textAlign: textAlign,
          style: AppTheme.bodyText.copyWith(
            fontSize: 11.4,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF7B869C),
            letterSpacing: 0.18,
          ),
        ),
      ),
    );
  }
}

class _TdsRatesFilterMenuItem extends StatefulWidget {
  const _TdsRatesFilterMenuItem({
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  @override
  State<_TdsRatesFilterMenuItem> createState() =>
      _TdsRatesFilterMenuItemState();
}

class _TdsRatesFilterMenuItemState extends State<_TdsRatesFilterMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isHovered = _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFF4A86E8) : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: isHovered ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionDropdownItem extends StatefulWidget {
  const _HeaderActionDropdownItem({required this.label});

  final String label;

  @override
  State<_HeaderActionDropdownItem> createState() =>
      _HeaderActionDropdownItemState();
}

class _HeaderActionDropdownItemState extends State<_HeaderActionDropdownItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isHovered = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isHovered ? const Color(0xFF4A86E8) : Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add,
              size: 15,
              color: isHovered ? Colors.white : AppTheme.primaryBlue,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w400,
                  color: isHovered ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthYearPickerField extends StatefulWidget {
  const _MonthYearPickerField({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  State<_MonthYearPickerField> createState() => _MonthYearPickerFieldState();
}

class _MonthYearPickerFieldState extends State<_MonthYearPickerField> {
  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const Map<String, String> _monthAliases = <String, String>{
    'January': 'Jan',
    'February': 'Feb',
    'March': 'Mar',
    'April': 'Apr',
    'May': 'May',
    'June': 'Jun',
    'July': 'Jul',
    'August': 'Aug',
    'September': 'Sep',
    'October': 'Oct',
    'November': 'Nov',
    'December': 'Dec',
  };

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  int _displayYear = 2026;

  @override
  void initState() {
    super.initState();
    _displayYear = _parseYear(widget.value) ?? 2026;
  }

  @override
  void didUpdateWidget(covariant _MonthYearPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isOpen) {
      _displayYear = _parseYear(widget.value) ?? _displayYear;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  int? _parseYear(String? value) {
    if (value == null || value == 'Month Year') {
      return null;
    }
    final List<String> parts = value.split(' ');
    if (parts.length < 2) {
      return null;
    }
    return int.tryParse(parts.last);
  }

  String? _selectedMonthAbbrev() {
    final String? value = widget.value;
    if (value == null || value == 'Month Year') {
      return null;
    }
    final List<String> parts = value.split(' ');
    if (parts.isEmpty) {
      return null;
    }
    return _monthAliases[parts.first] ?? parts.first;
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned.fill(
          child: Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: const SizedBox.expand(),
              ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, -238),
                child: _buildOverlayCard(),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted && _isOpen) {
      setState(() => _isOpen = false);
    }
  }

  void _changeYear(int delta) {
    setState(() => _displayYear += delta);
    _overlayEntry?.markNeedsBuild();
  }

  void _selectMonth(String month) {
    widget.onChanged('$month $_displayYear');
    _removeOverlay();
  }

  Widget _buildOverlayCard() {
    final String? selectedMonth = _selectedMonthAbbrev();
    final int? selectedYear = _parseYear(widget.value);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 248,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _changeYear(-1),
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(
                              child: Text(
                                '«',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '$_displayYear',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13.8,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _changeYear(1),
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Center(
                              child: Text(
                                '»',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF667085),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _months.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1.12,
                          ),
                      itemBuilder: (BuildContext context, int index) {
                        final String month = _months[index];
                        final bool isSelected =
                            selectedMonth == month &&
                            selectedYear == _displayYear;

                        return InkWell(
                          onTap: () => _selectMonth(month),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE5E7EB)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              month,
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 14,
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 18,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 158,
                    child: Center(
                      child: Container(
                        width: 7,
                        height: 158,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8B8C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                    child: Center(
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: AppTheme.textMuted,
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
      child: InkWell(
        onTap: _toggleOverlay,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          height: 33,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isOpen ? AppTheme.primaryBlue : AppTheme.borderColor,
              width: _isOpen
                  ? AppTheme.inputActiveBorderWidth
                  : AppTheme.inputBorderWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.value ?? 'Month Year',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12.9,
                    fontWeight: FontWeight.w400,
                    color: widget.value == null
                        ? AppTheme.textMuted
                        : const Color(0xFF4B5563),
                  ),
                ),
              ),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewTdsGroupTaxDialog extends StatefulWidget {
  const _NewTdsGroupTaxDialog({
    required this.rates,
    required this.onSave,
    this.initial,
  });

  final List<_GroupTaxSelectableRate> rates;
  final Map<String, dynamic>? initial;
  final Future<bool> Function(
    String name,
    List<String> rateIds,
    String? applicableFrom,
    String? applicableTo,
  )
  onSave;

  @override
  State<_NewTdsGroupTaxDialog> createState() => _NewTdsGroupTaxDialogState();
}

class _NewTdsGroupTaxDialogState extends State<_NewTdsGroupTaxDialog> {
  final TextEditingController _groupTaxNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final GlobalKey _startDateKey = GlobalKey();
  final GlobalKey _endDateKey = GlobalKey();
  final Set<String> _selectedRateIds = <String>{};

  DateTime? _startDateValue;
  DateTime? _endDateValue;
  late final List<_GroupTaxSelectableRate> _rateItems;

  @override
  void initState() {
    super.initState();
    _rateItems = List<_GroupTaxSelectableRate>.from(widget.rates);
    final initial = widget.initial;
    if (initial != null) {
      _groupTaxNameController.text = initial['group_name']?.toString() ?? '';
      _selectedRateIds.addAll(
        (initial['tds_rate_ids'] as List? ?? const []).map(
          (id) => id.toString(),
        ),
      );
      _startDateValue = DateTime.tryParse(
        initial['applicable_from']?.toString() ?? '',
      );
      _endDateValue = DateTime.tryParse(
        initial['applicable_to']?.toString() ?? '',
      );
      if (_startDateValue != null) {
        _startDateController.text = _formatDate(_startDateValue!);
      }
      if (_endDateValue != null) {
        _endDateController.text = _formatDate(_endDateValue!);
      }
    }
  }

  Future<void> _save() async {
    final name = _groupTaxNameController.text.trim();
    final selected = _rateItems
        .where((rate) => _selectedRateIds.contains(rate.id))
        .map((rate) => rate.id)
        .toList();
    if (name.isEmpty || selected.isEmpty) {
      ZerpaiToast.info(context, 'Enter a group name and select TDS rates');
      return;
    }
    final saved = await widget.onSave(
      name,
      selected,
      _startDateValue?.toIso8601String(),
      _endDateValue?.toIso8601String(),
    );
    if (!mounted) return;
    if (!saved) {
      ZerpaiToast.error(context, 'Failed to create TDS group');
      return;
    }
    Navigator.of(context).pop();
    ZerpaiToast.success(context, 'TDS group created');
  }

  @override
  void dispose() {
    _groupTaxNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day-$month-$year';
  }

  Future<void> _pickStartDate() async {
    final DateTime initialDate =
        _startDateValue ?? DateTime(DateTime.now().year, 4, 1);
    final DateTime? picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      targetKey: _startDateKey,
      openAbove: true,
    );
    if (picked == null) return;

    setState(() {
      _startDateValue = picked;
      _startDateController.text = _formatDate(picked);
      if (_endDateValue != null && _endDateValue!.isBefore(picked)) {
        _endDateValue = null;
        _endDateController.clear();
      }
    });
  }

  Future<void> _pickEndDate() async {
    final DateTime initialDate =
        _endDateValue ?? _startDateValue ?? DateTime.now();
    final DateTime? picked = await ZerpaiDatePicker.show(
      context,
      initialDate: initialDate,
      firstDate: _startDateValue,
      targetKey: _endDateKey,
      openAbove: true,
    );
    if (picked == null) return;

    setState(() {
      _endDateValue = picked;
      _endDateController.text = _formatDate(picked);
    });
  }

  void _reorderRates(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final _GroupTaxSelectableRate item = _rateItems.removeAt(oldIndex);
      _rateItems.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height - 28;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 660, maxHeight: maxHeight),
          child: Material(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 24,
            borderRadius: BorderRadius.circular(8),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildHeader(context),
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabeledField(
                            label: 'TDS Group Tax Name*',
                            child: SizedBox(
                              width: 270,
                              child: CustomTextField(
                                controller: _groupTaxNameController,
                                height: 34,
                                autoFocus: true,
                                forceUppercase: false,
                                contentCase: ContentCase.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Applicable Period',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const ZTooltip(
                                message:
                                    'If this TDS rate is applicable only for a certain period, select the date range during which, users can use this rate in transactions.',
                                direction: ZTooltipDirection.top,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildNeutralLabeledField(
                                  label: 'Start Date',
                                  child: Container(
                                    key: _startDateKey,
                                    child: CustomTextField(
                                      controller: _startDateController,
                                      height: 34,
                                      hintText: 'dd-MM-yyyy',
                                      readOnly: true,
                                      onTap: _pickStartDate,
                                      forceUppercase: false,
                                      contentCase: ContentCase.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 28),
                              Expanded(
                                child: _buildNeutralLabeledField(
                                  label: 'End Date',
                                  child: Container(
                                    key: _endDateKey,
                                    child: CustomTextField(
                                      controller: _endDateController,
                                      height: 34,
                                      hintText: 'dd-MM-yyyy',
                                      readOnly: true,
                                      onTap: _pickEndDate,
                                      forceUppercase: false,
                                      contentCase: ContentCase.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4D8DFF),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'i',
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You can create a TDS group tax only using TDSs that fall under section 195.',
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 12.8,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                'Associate TDS Rates*',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                              const Spacer(),
                              _buildDragGrip(),
                              const SizedBox(width: 5),
                              Text(
                                'Drag TDS rates to reorder',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12.3,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF98A2B3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildRatesTable(),
                          const SizedBox(height: 16),
                          Text(
                            'TDS Surcharge*',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No TDS Surcharge Available.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'TDS Cess*',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.errorRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No TDS Cess Available.',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 36, 18, 18),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                top: BorderSide(color: AppTheme.borderLight),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 31,
                                  child: ElevatedButton(
                                    onPressed: _save,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'Save',
                                      style: AppTheme.buttonText.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 31,
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF4B5563),
                                      side: const BorderSide(
                                        color: AppTheme.borderLight,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: AppTheme.buttonText.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF4B5563),
                                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'New TDS Group Tax',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 18, color: Color(0xFFFF5A5A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        primary: false,
        buildDefaultDragHandles: false,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        onReorder: _reorderRates,
        itemCount: _rateItems.length,
        itemBuilder: (BuildContext context, int index) {
          final _GroupTaxSelectableRate rate = _rateItems[index];
          return _buildRateTableRow(
            rate,
            index,
            index == _rateItems.length - 1,
            key: ValueKey<String>(rate.name),
          );
        },
      ),
    );
  }

  Widget _buildRateTableRow(
    _GroupTaxSelectableRate rate,
    int index,
    bool isLast, {
    required Key key,
  }) {
    return Container(
      key: key,
      height: 34,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Checkbox(
              value: _selectedRateIds.contains(rate.id),
              onChanged: (bool? value) {
                setState(() {
                  if (value ?? false) {
                    _selectedRateIds.add(rate.id);
                  } else {
                    _selectedRateIds.remove(rate.id);
                  }
                });
              },
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              activeColor: AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.borderLight)),
              ),
              child: rate.sectionLabel == null
                  ? Text(
                      rate.name,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12.7,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B5563),
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 12.7,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4B5563),
                        ),
                        children: [
                          TextSpan(text: rate.name),
                          TextSpan(
                            text: '  (${rate.sectionLabel!})',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 12.7,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFFF6A3D),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  rate.rate,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12.7,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: SizedBox(
                width: 24,
                child: Center(child: _buildDragGrip()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.8,
            fontWeight: FontWeight.w400,
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildNeutralLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.8,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildDragGrip() {
    return SizedBox(
      width: 10,
      height: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(4, (_) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(2, (_) {
                return Container(
                  width: 2,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1D5DB),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _NewTdsDialog extends StatefulWidget {
  const _NewTdsDialog({
    required this.title,
    required this.isTcs,
    required this.options,
    required this.higherRateReasons,
    required this.accountIdByName,
    required this.onSave,
    this.initial,
  });

  final String title;
  final bool isTcs;
  final List<_SectionOption> options;
  final List<_HigherTdsReasonOption> higherRateReasons;
  final Map<String, String> accountIdByName;
  final Future<bool> Function(Map<String, dynamic> payload) onSave;
  final Map<String, dynamic>? initial;

  @override
  State<_NewTdsDialog> createState() => _NewTdsDialogState();
}

class _NewTdsDialogState extends State<_NewTdsDialog> {
  final TextEditingController _taxNameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _surchargeRateController =
      TextEditingController();
  final TextEditingController _cessRateController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _higherRateReasonController =
      TextEditingController();
  final GlobalKey _startDateKey = GlobalKey();
  final GlobalKey _endDateKey = GlobalKey();

  String? _selectedIncomeTaxAct = 'New Income Tax Act 2025';
  _SectionOption? _selectedSection;
  _HigherTdsReasonOption? _selectedHigherTdsReason;
  String? _selectedTdsPayableAccount;
  String? _selectedTdsReceivableAccount;
  bool _showAccountDropdowns = false;
  bool _isHigherTdsRate = false;
  DateTime _startDateValue = DateTime.now();
  DateTime? _endDateValue;

  static const List<String> _incomeTaxActOptions = <String>[
    'New Income Tax Act 2025',
    'Income Tax Act 1961',
  ];

  bool get _isChargeDialog =>
      widget.title == 'New TDS Surcharge' || widget.title == 'New TDS Cess';

  String get _chargeLabel =>
      widget.title == 'New TDS Cess' ? 'TDS Cess' : 'TDS Surcharge';

  String get _dialogTitle => _isChargeDialog ? 'New TDS' : widget.title;

  bool get _isTcs => widget.isTcs;

  Future<void> _save() async {
    final name = _taxNameController.text.trim();
    final rate = double.tryParse(_rateController.text.trim());
    final surchargeRate =
        double.tryParse(_surchargeRateController.text.trim()) ?? 0;
    final cessRate = double.tryParse(_cessRateController.text.trim()) ?? 0;
    if (name.isEmpty || rate == null || rate < 0 || rate > 100) {
      ZerpaiToast.info(context, 'Enter a valid tax name and rate');
      return;
    }
    if (surchargeRate < 0 ||
        surchargeRate > 100 ||
        cessRate < 0 ||
        cessRate > 100) {
      ZerpaiToast.info(context, 'Enter valid surcharge and cess rates');
      return;
    }
    if (_selectedSection?.id == null) {
      ZerpaiToast.info(
        context,
        _isTcs ? 'Select a TCS nature' : 'Select a TDS section',
      );
      return;
    }
    if (_isHigherTdsRate && _isTcs && _selectedHigherTdsReason?.id == null) {
      ZerpaiToast.info(context, 'Select a higher-rate reason');
      return;
    }
    if (_isHigherTdsRate &&
        !_isTcs &&
        _higherRateReasonController.text.trim().isEmpty) {
      ZerpaiToast.info(context, 'Enter a higher-rate reason');
      return;
    }
    final payload = <String, dynamic>{
      'tax_name': name,
      if (_isTcs) ...{
        'nature_id': _selectedSection!.id,
        'rate': rate,
        'higher_rate_reason_id': _selectedHigherTdsReason?.id,
        'income_tax_act': _selectedIncomeTaxAct,
      } else ...{
        'section_id': _selectedSection!.id,
        'base_rate': rate,
        'surcharge_rate': surchargeRate,
        'cess_rate': cessRate,
        'reason_higher_rate': _isHigherTdsRate
            ? _higherRateReasonController.text.trim()
            : null,
      },
      'payable_account_id': widget.accountIdByName[_selectedTdsPayableAccount],
      'receivable_account_id':
          widget.accountIdByName[_selectedTdsReceivableAccount],
      'is_higher_rate': _isHigherTdsRate,
      'applicable_from': _startDateController.text.isEmpty
          ? null
          : _startDateValue.toIso8601String(),
      'applicable_to': _endDateController.text.isEmpty
          ? null
          : _endDateValue?.toIso8601String(),
      'is_active': widget.initial?['is_active'] ?? true,
    };
    final saved = await widget.onSave(payload);
    if (!mounted) return;
    if (!saved) {
      ZerpaiToast.error(context, 'Failed to save direct tax');
      return;
    }
    Navigator.of(context).pop();
    ZerpaiToast.success(context, 'Direct tax saved');
  }

  Widget _buildAccountDropdown({
    required String? value,
    required ValueChanged<String?> onChanged,
    required List<String> items,
  }) {
    return FormDropdown<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      hint: 'Select an account',
      height: 34,
      showSearch: true,
      showSearchIcon: true,
      allowClear: true,
      clearTooltipMessage: 'Clear the selected option',
      clearTooltipDirection: ZTooltipDirection.top,
      showClearDivider: true,
      showCustomValueAction: false,
      boldSelected: false,
      paintSelectionBackground: false,
      itemBuilder: (String item, bool isSelected, bool isHovered) {
        final Color backgroundColor = isHovered
            ? const Color(0xFF4A86E8)
            : (isSelected ? const Color(0xFFE9EDF5) : Colors.white);
        final Color textColor = isHovered
            ? Colors.white
            : const Color(0xFF4B5563);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: isHovered ? Colors.white : const Color(0xFF4A86E8),
                  ),
              ],
            ),
          ),
        );
      },
      textStyle: AppTheme.bodyText.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF4B5563),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _taxNameController.text = initial['tax_name']?.toString() ?? '';
      _rateController.text =
          initial[_isTcs ? 'rate' : 'base_rate']?.toString() ?? '';
      _surchargeRateController.text =
          initial['surcharge_rate']?.toString() ?? '';
      _cessRateController.text = initial['cess_rate']?.toString() ?? '';
      final optionId = initial[_isTcs ? 'nature_id' : 'section_id']?.toString();
      _selectedSection = widget.options
          .where((option) => option.id == optionId)
          .firstOrNull;
      _selectedIncomeTaxAct =
          initial['income_tax_act']?.toString() ?? _selectedIncomeTaxAct;
      _isHigherTdsRate = initial['is_higher_rate'] == true;
      _higherRateReasonController.text =
          initial['reason_higher_rate']?.toString() ?? '';
      final reasonId = initial['higher_rate_reason_id']?.toString();
      _selectedHigherTdsReason = widget.higherRateReasons
          .where((reason) => reason.id == reasonId)
          .firstOrNull;
      String? accountName(String? id) {
        if (id == null) return null;
        for (final entry in widget.accountIdByName.entries) {
          if (entry.value == id) return entry.key;
        }
        return null;
      }

      _selectedTdsPayableAccount = accountName(
        initial['payable_account_id']?.toString(),
      );
      _selectedTdsReceivableAccount = accountName(
        initial['receivable_account_id']?.toString(),
      );
      _showAccountDropdowns =
          _selectedTdsPayableAccount != null ||
          _selectedTdsReceivableAccount != null;
      _startDateValue =
          DateTime.tryParse(initial['applicable_from']?.toString() ?? '') ??
          _startDateValue;
      _endDateValue = DateTime.tryParse(
        initial['applicable_to']?.toString() ?? '',
      );
      if (initial['applicable_from'] != null) {
        _startDateController.text = _formatDate(_startDateValue);
      }
      if (_endDateValue != null) {
        _endDateController.text = _formatDate(_endDateValue!);
      }
    }
  }

  @override
  void dispose() {
    _taxNameController.dispose();
    _rateController.dispose();
    _surchargeRateController.dispose();
    _cessRateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _higherRateReasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day-$month-$year';
  }

  Future<void> _pickStartDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _startDateValue,
      targetKey: _startDateKey,
      openAbove: true,
    );
    if (picked == null) return;

    setState(() {
      _startDateValue = picked;
      _startDateController.text = _formatDate(picked);
      if (_endDateValue != null && _endDateValue!.isBefore(picked)) {
        _endDateValue = null;
        _endDateController.clear();
      }
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: _endDateValue ?? _startDateValue,
      firstDate: _startDateValue,
      targetKey: _endDateKey,
      openAbove: true,
    );
    if (picked == null) return;

    setState(() {
      _endDateValue = picked;
      _endDateController.text = _formatDate(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 670),
          child: Material(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 24,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const Divider(height: 1, color: AppTheme.borderLight),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildLabeledField(
                                  label: 'Tax Name*',
                                  child: CustomTextField(
                                    controller: _taxNameController,
                                    height: 34,
                                    autoFocus: true,
                                    forceUppercase: false,
                                    contentCase: ContentCase.none,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 26),
                              Expanded(
                                child: _buildLabeledField(
                                  label: 'Rate (%)*',
                                  child: CustomTextField(
                                    controller: _rateController,
                                    height: 34,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    forceUppercase: false,
                                    contentCase: ContentCase.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!_isTcs) ...[
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildLabeledField(
                                    label: 'Surcharge Rate (%)',
                                    child: CustomTextField(
                                      controller: _surchargeRateController,
                                      height: 34,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      forceUppercase: false,
                                      contentCase: ContentCase.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 26),
                                Expanded(
                                  child: _buildLabeledField(
                                    label: 'Cess Rate (%)',
                                    child: CustomTextField(
                                      controller: _cessRateController,
                                      height: 34,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      forceUppercase: false,
                                      contentCase: ContentCase.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (!_isChargeDialog) ...[
                            const SizedBox(height: 14),
                            _buildLabeledField(
                              label: 'Applicable Income Tax Act',
                              child: SizedBox(
                                width: 302,
                                child: FormDropdown<String>(
                                  value: _selectedIncomeTaxAct,
                                  items: _incomeTaxActOptions,
                                  onChanged: (String? value) {
                                    setState(
                                      () => _selectedIncomeTaxAct = value,
                                    );
                                  },
                                  hint: 'Select Income Tax Act',
                                  height: 34,
                                  showSearch: false,
                                  boldSelected: false,
                                  allowClear: false,
                                  showCustomValueAction: false,
                                  paintSelectionBackground: false,
                                  textStyle: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF4B5563),
                                  ),
                                  itemBuilder:
                                      (
                                        String item,
                                        bool isSelected,
                                        bool isHovered,
                                      ) {
                                        return Container(
                                          height: 36,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isHovered
                                                ? const Color(0xFF4A86E8)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            item,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w400,
                                              color: isHovered
                                                  ? Colors.white
                                                  : const Color(0xFF374151),
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildLabeledField(
                              label: _isTcs ? 'Nature*' : 'Section*',
                              child: SizedBox(
                                width: 302,
                                child: FormDropdown<_SectionOption>(
                                  value: _selectedSection,
                                  items: widget.options,
                                  onChanged: (_SectionOption? value) {
                                    setState(() => _selectedSection = value);
                                  },
                                  hint: 'Select a Tax Type.',
                                  height: 34,
                                  showSearch: true,
                                  showSearchIcon: true,
                                  allowClear: false,
                                  showCustomValueAction: false,
                                  menuWidth: 398,
                                  menuMaxHeight: 260,
                                  itemHeight: 74,
                                  itemEstimatedHeight: 74,
                                  displayStringForValue:
                                      (_SectionOption value) => value.title,
                                  searchStringForValue: (_SectionOption value) =>
                                      '${value.title} ${value.description} ${value.earlier}',
                                  textStyle: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF4B5563),
                                  ),
                                  itemBuilder:
                                      (
                                        _SectionOption item,
                                        bool isSelected,
                                        bool isHovered,
                                      ) {
                                        final Color textColor = isHovered
                                            ? Colors.white
                                            : const Color(0xFF1F2937);
                                        final Color subTextColor = isHovered
                                            ? Colors.white
                                            : const Color(0xFF667085);

                                        return Container(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            10,
                                            12,
                                            10,
                                          ),
                                          color: Colors.transparent,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.bodyText
                                                    .copyWith(
                                                      fontSize: 12.9,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: textColor,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.bodyText
                                                    .copyWith(
                                                      fontSize: 12.1,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: subTextColor,
                                                      height: 1.25,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                item.earlier,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTheme.bodyText
                                                    .copyWith(
                                                      fontSize: 11.8,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: subTextColor,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ] else
                            const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.info,
                                    size: 14,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 12.7,
                                        height: 1.5,
                                        color: const Color(0xFF4B5563),
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              'By default, ${_isChargeDialog ? _chargeLabel : 'TDS'} will be tracked under ',
                                        ),
                                        TextSpan(
                                          text: 'TDS Payable',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 12.7,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF374151),
                                          ),
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'TDS Receivable',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 12.7,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF374151),
                                          ),
                                        ),
                                        const TextSpan(
                                          text:
                                              ' accounts. Click Edit to choose an account of your choice. ',
                                        ),
                                        TextSpan(
                                          text: 'Edit',
                                          style: AppTheme.bodyText.copyWith(
                                            fontSize: 12.7,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryBlue,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              setState(() {
                                                _showAccountDropdowns =
                                                    !_showAccountDropdowns;
                                              });
                                            },
                                        ),
                                        WidgetSpan(
                                          alignment:
                                              PlaceholderAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 3,
                                            ),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _showAccountDropdowns =
                                                      !_showAccountDropdowns;
                                                });
                                              },
                                              child: Icon(
                                                LucideIcons.edit3,
                                                size: 12,
                                                color: AppTheme.primaryBlue,
                                              ),
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
                          if (_showAccountDropdowns) ...[
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildNeutralLabeledField(
                                    label: 'TDS Payable Account',
                                    child: _buildAccountDropdown(
                                      value: _selectedTdsPayableAccount,
                                      items: widget.accountIdByName.keys
                                          .toList(),
                                      onChanged: (String? value) {
                                        setState(
                                          () => _selectedTdsPayableAccount =
                                              value,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 26),
                                Expanded(
                                  child: _buildNeutralLabeledField(
                                    label: 'TDS Receivable Account',
                                    child: _buildAccountDropdown(
                                      value: _selectedTdsReceivableAccount,
                                      items: widget.accountIdByName.keys
                                          .toList(),
                                      onChanged: (String? value) {
                                        setState(
                                          () => _selectedTdsReceivableAccount =
                                              value,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (!_isChargeDialog) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                    value: _isHigherTdsRate,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _isHigherTdsRate = value ?? false;
                                        if (!_isHigherTdsRate) {
                                          _selectedHigherTdsReason = null;
                                        }
                                      });
                                    },
                                    side: const BorderSide(
                                      color: AppTheme.borderColorDark,
                                    ),
                                    activeColor: AppTheme.primaryBlue,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'This is a Higher TDS Rate',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const ZTooltip(
                                  message:
                                      "Mark this option if the TDS you're adding is a Higher TDS Rate as mentioned under section 206AB of the Income Tax Act, 1961 effective from 1 July 2021. You'll have to deduct higher TDS rate if you're creating the transaction for a non-filer of Income Tax returns.",
                                  direction: ZTooltipDirection.top,
                                ),
                              ],
                            ),
                            if (_isHigherTdsRate) ...[
                              const SizedBox(height: 16),
                              _buildLabeledField(
                                label: _isTcs
                                    ? 'Reason for Higher TCS Rate*'
                                    : 'Reason for Higher TDS Rate*',
                                child: SizedBox(
                                  width: 302,
                                  child: _isTcs
                                      ? FormDropdown<_HigherTdsReasonOption>(
                                          value: _selectedHigherTdsReason,
                                          items: widget.higherRateReasons,
                                          onChanged:
                                              (_HigherTdsReasonOption? value) {
                                                setState(
                                                  () =>
                                                      _selectedHigherTdsReason =
                                                          value,
                                                );
                                              },
                                          hint: '',
                                          height: 34,
                                          showSearch: true,
                                          showSearchIcon: true,
                                          allowClear: false,
                                          showCustomValueAction: false,
                                          boldSelected: false,
                                          menuWidth: 430,
                                          menuMaxHeight: 220,
                                          itemHeight: 74,
                                          itemEstimatedHeight: 74,
                                          displayStringForValue:
                                              (_HigherTdsReasonOption value) =>
                                                  value.title,
                                          searchStringForValue:
                                              (_HigherTdsReasonOption value) =>
                                                  '${value.title} ${value.description}',
                                          paintSelectionBackground: false,
                                          textStyle: AppTheme.bodyText.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF4B5563),
                                          ),
                                          itemBuilder:
                                              (
                                                _HigherTdsReasonOption item,
                                                bool isSelected,
                                                bool isHovered,
                                              ) {
                                                final Color bgColor = isHovered
                                                    ? const Color(0xFF4A86E8)
                                                    : Colors.white;
                                                final Color titleColor =
                                                    isHovered
                                                    ? Colors.white
                                                    : const Color(0xFF1F2937);
                                                final Color descColor =
                                                    isHovered
                                                    ? Colors.white
                                                    : const Color(0xFF667085);

                                                return Container(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        12,
                                                        10,
                                                        12,
                                                        10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: bgColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 1,
                                                      ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        item.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: AppTheme.bodyText
                                                            .copyWith(
                                                              fontSize: 12.9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: titleColor,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        item.description,
                                                        maxLines: 3,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: AppTheme.bodyText
                                                            .copyWith(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                              color: descColor,
                                                              height: 1.25,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                        )
                                      : CustomTextField(
                                          controller:
                                              _higherRateReasonController,
                                          height: 34,
                                          forceUppercase: false,
                                          contentCase: ContentCase.none,
                                        ),
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Text(
                                'Applicable Period',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const ZTooltip(
                                message:
                                    'If this TDS rate is applicable only for a certain period, select the date range during which, users can use this rate in transactions.',
                                direction: ZTooltipDirection.top,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child:
                                    (_isChargeDialog
                                    ? _buildNeutralLabeledField
                                    : _buildLabeledField)(
                                      label: 'Start Date',
                                      child: Container(
                                        key: _startDateKey,
                                        child: CustomTextField(
                                          controller: _startDateController,
                                          height: 34,
                                          readOnly: true,
                                          onTap: _pickStartDate,
                                          forceUppercase: false,
                                          contentCase: ContentCase.none,
                                          hintText: 'dd-MM-yyyy',
                                          suffixWidget: _isChargeDialog
                                              ? null
                                              : const Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 16,
                                                  color: AppTheme.textSecondary,
                                                ),
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(width: 26),
                              Expanded(
                                child:
                                    (_isChargeDialog
                                    ? _buildNeutralLabeledField
                                    : _buildLabeledField)(
                                      label: 'End Date',
                                      child: Container(
                                        key: _endDateKey,
                                        child: CustomTextField(
                                          controller: _endDateController,
                                          height: 34,
                                          readOnly: true,
                                          onTap: _pickEndDate,
                                          forceUppercase: false,
                                          contentCase: ContentCase.none,
                                          hintText: 'dd-MM-yyyy',
                                          suffixWidget: _isChargeDialog
                                              ? null
                                              : const Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 16,
                                                  color: AppTheme.textSecondary,
                                                ),
                                        ),
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: AppTheme.borderLight),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'Save',
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4B5563),
                            side: const BorderSide(color: AppTheme.borderLight),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTheme.buttonText.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF4B5563),
                            ),
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
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _dialogTitle,
              style: AppTheme.pageTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 18, color: Color(0xFFFF5A5A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.8,
            fontWeight: FontWeight.w400,
            color: AppTheme.errorRed,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _buildNeutralLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12.8,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}
