import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';

class StockCountsSettingsPage extends ConsumerStatefulWidget {
  const StockCountsSettingsPage({super.key});

  @override
  ConsumerState<StockCountsSettingsPage> createState() =>
      _StockCountsSettingsPageState();
}

class _StockCountsSettingsPageState
    extends ConsumerState<StockCountsSettingsPage> {
  final ApiClient _apiClient = ApiClient();
  final SettingsPreferencesRepository _preferencesRepository = SettingsPreferencesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _adjustmentAccounts = [];
  String _selectedAdjustmentAccount = '';
  String _selectedAdjustmentReason = '';
  List<Map<String, dynamic>> _reasons = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final results = await Future.wait([
        _apiClient.get('accountant', useCache: false),
        _apiClient.get('inventory-adjustments/reasons', useCache: false),
        _preferencesRepository.loadSection('stock_preferences', const ['inventory', 'stock_counts']),
      ]);
      final accounts = <String>[];
      void collect(dynamic rows) {
        if (rows is! List) return;
        for (final raw in rows.whereType<Map>()) {
          final row = Map<String, dynamic>.from(raw);
          final name = row['user_account_name'] ?? row['system_account_name'] ?? row['name'];
          if (name != null && name.toString().trim().isNotEmpty) accounts.add(name.toString().trim());
          collect(row['children']);
        }
      }
      final accountResponse = results[0] as dynamic;
      final reasonResponse = results[1] as dynamic;
      collect(accountResponse.data);
      final reasons = (reasonResponse.data as List? ?? const []).whereType<Map>().map((row) {
        final value = Map<String, dynamic>.from(row);
        return <String, dynamic>{
          'id': value['id'],
          'name': value['name']?.toString() ?? '',
          'isActive': value['is_active'] != false,
        };
      }).toList();
      final preferences = Map<String, dynamic>.from(results[2] as Map);
      if (!mounted) return;
      setState(() {
        _adjustmentAccounts = accounts.toSet().toList()..sort();
        _reasons = reasons;
        _selectedAdjustmentAccount = preferences['adjustment_account']?.toString() ?? (_adjustmentAccounts.firstOrNull ?? '');
        _selectedAdjustmentReason = preferences['adjustment_reason']?.toString() ?? reasons.where((r) => r['isActive'] == true).map((r) => r['name'].toString()).firstOrNull ?? '';
      });
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to load stock count settings');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  List<SettingsSearchItem> _buildSearchItems() {
    return <SettingsSearchItem>[
      SettingsSearchItem(
        group: 'Inventory',
        label: 'Adjustment Account',
        subtitle: 'Stock Counts',
        keywords: const <String>['stock count', 'account', 'adjustment'],
        onSelected: _focusSearch,
      ),
      SettingsSearchItem(
        group: 'Inventory',
        label: 'Adjustment Reason',
        subtitle: 'Stock Counts',
        keywords: const <String>['stocktaking', 'reason', 'inventory counts'],
        onSelected: _focusSearch,
      ),
    ];
  }

  Future<void> _saveSettings() async {
    try {
      await _preferencesRepository.saveSection('stock_preferences', {
        'adjustment_account': _selectedAdjustmentAccount,
        'adjustment_reason': _selectedAdjustmentReason,
      }, const ['inventory', 'stock_counts']);
      if (mounted) ZerpaiToast.success(context, 'Stock counts preferences saved');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save stock count settings');
    }
  }

  Future<void> _syncReasons(List<Map<String, dynamic>> rows) async {
    try {
      for (final row in rows) {
        final id = row['id']?.toString();
        final data = {
          'name': row['name']?.toString() ?? '',
          'is_active': row['isActive'] != false,
        };
        if (id == null || id.isEmpty) {
          await _apiClient.post('inventory-adjustments/reasons', data: data);
        } else {
          await _apiClient.patch('inventory-adjustments/reasons/$id', data: data);
        }
      }
      await _loadSettings();
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to update adjustment reasons');
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final String orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';
    final String currentPath = GoRouterState.of(context).uri.path;

    final reasonsList = _reasons
        .where((r) => r['isActive'] == true)
        .map((r) => r['name'].toString())
        .toList();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
              child: _StockCountsSettingsHeader(
                orgName: orgName,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                searchItems: _buildSearchItems(),
                onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: AppTheme.borderLight),
                          top: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                              child: Text(
                                'Stock Counts',
                                style: AppTheme.pageTitle.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Divider(
                              height: 28,
                              thickness: 1,
                              color: AppTheme.borderLight,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 980,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _StockCountsSection(
                                      title: 'Adjustment Account',
                                      description:
                                          'Select an account to record and '
                                          'track the adjustments posted when '
                                          'there is a difference in stock '
                                          'counting.',
                                      child: SizedBox(
                                        width: 296,
                                        child: FormDropdown<String>(
                                          value: _adjustmentAccounts.contains(_selectedAdjustmentAccount) ? _selectedAdjustmentAccount : null,
                                          items: _adjustmentAccounts,
                                          onChanged: (String? value) {
                                            if (value == null) return;
                                            setState(() {
                                              _selectedAdjustmentAccount =
                                                  value;
                                            });
                                          },
                                          displayStringForValue:
                                              (String value) => value,
                                          showSearch: true,
                                          menuWidth: 296,
                                          menuMaxHeight: 308,
                                          itemBuilder:
                                              (
                                                String item,
                                                bool isSelected,
                                                bool isHovered,
                                              ) => _StockCountsDropdownRow(
                                                label: item,
                                                isSelected: isSelected,
                                                isHovered: isHovered,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Divider(
                                      height: 1,
                                      color: AppTheme.borderLight,
                                    ),
                                    const SizedBox(height: 24),
                                    _StockCountsSection(
                                      title: 'Adjustment Reason',
                                      description:
                                          'Select a reason to be used as the '
                                          'default reason when there is a '
                                          'difference in stock counting.',
                                      child: SizedBox(
                                        width: 296,
                                        child: FormDropdown<String>(
                                          value: reasonsList.contains(_selectedAdjustmentReason) ? _selectedAdjustmentReason : null,
                                          items: reasonsList,
                                          onChanged: (String? value) {
                                            if (value == null) return;
                                            setState(() {
                                              _selectedAdjustmentReason = value;
                                            });
                                          },
                                          displayStringForValue:
                                              (String value) => value,
                                          showSearch: true,
                                          showSettings: true,
                                          settingsLabel: 'Manage Reasons',
                                          settingsLeading: const Icon(
                                            Icons.settings,
                                            size: 16,
                                            color: AppTheme.primaryBlueDark,
                                          ),
                                          onSettingsTap: () async {
                                            await showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) =>
                                                  _ManageReasonsDialog(
                                                    initialReasons: _reasons,
                                                    onSave: (updatedReasons) {
                                                      setState(() {
                                                        _reasons =
                                                            updatedReasons;
                                                        // Auto-select latest active if not set or just updated
                                                        if (updatedReasons
                                                            .isNotEmpty) {
                                                          _selectedAdjustmentReason =
                                                              updatedReasons
                                                                  .last['name'];
                                                        }
                                                      });
                                                      _syncReasons(updatedReasons);
                                                    },
                                                  ),
                                            );
                                          },
                                          menuWidth: 296,
                                          menuMaxHeight: 354,
                                          itemBuilder:
                                              (
                                                String item,
                                                bool isSelected,
                                                bool isHovered,
                                              ) => _StockCountsDropdownRow(
                                                label: item,
                                                isSelected: isSelected,
                                                isHovered: isHovered,
                                                showCheckIcon: true,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    const Divider(
                                      height: 1,
                                      color: AppTheme.borderLight,
                                    ),
                                    const SizedBox(height: 36),
                                    SizedBox(
                                      height: 34,
                                      child: ZButton.primary(
                                        label: 'Save',
                                        onPressed: _saveSettings,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
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

class _StockCountsSettingsHeader extends StatelessWidget {
  const _StockCountsSettingsHeader({
    required this.orgName,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchItems,
    required this.onClose,
  });

  final String orgName;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<SettingsSearchItem> searchItems;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SettingsHeaderIdentity(orgName: orgName),
        const Spacer(),
        SizedBox(
          width: 340,
          child: SettingsSearchField(
            controller: searchController,
            focusNode: searchFocusNode,
            items: searchItems,
            onNoMatch: (String query) {
              ZerpaiToast.info(context, 'No settings matched "$query"');
            },
          ),
        ),
        const SizedBox(width: 14),
        _CloseSettingsButton(onTap: onClose),
      ],
    );
  }
}

class _SettingsHeaderIdentity extends StatelessWidget {
  const _SettingsHeaderIdentity({required this.orgName});

  final String orgName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.menu_book_outlined,
            size: 20,
            color: Color(0xFFFF5C5C),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Settings',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              orgName,
              style: AppTheme.bodyText.copyWith(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CloseSettingsButton extends StatelessWidget {
  const _CloseSettingsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Close Settings',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.close, size: 15, color: Color(0xFFFF5C73)),
          ],
        ),
      ),
    );
  }
}

class _StockCountsSection extends StatelessWidget {
  const _StockCountsSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyText.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 680,
          child: Text(
            description,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              height: 1.55,
              color: const Color(0xFF707A94),
            ),
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _StockCountsDropdownRow extends StatelessWidget {
  const _StockCountsDropdownRow({
    required this.label,
    required this.isSelected,
    required this.isHovered,
    this.showCheckIcon = false,
  });

  final String label;
  final bool isSelected;
  final bool isHovered;
  final bool showCheckIcon;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isHovered
        ? const Color(0xFF3B82F6)
        : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent);
    final Color textColor = isHovered ? Colors.white : AppTheme.textPrimary;
    final Color iconColor = isHovered ? Colors.white : AppTheme.primaryBlueDark;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: backgroundColor,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: textColor,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (showCheckIcon && isSelected)
            Icon(Icons.check, size: 16, color: iconColor),
        ],
      ),
    );
  }
}

class _ManageReasonsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> initialReasons;
  final ValueChanged<List<Map<String, dynamic>>> onSave;

  const _ManageReasonsDialog({
    required this.initialReasons,
    required this.onSave,
  });

  @override
  State<_ManageReasonsDialog> createState() => _ManageReasonsDialogState();
}

class _ManageReasonsDialogState extends State<_ManageReasonsDialog> {
  late List<Map<String, dynamic>> _reasons;
  bool _isAdding = false;
  final _newReasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reasons = List<Map<String, dynamic>>.from(
      widget.initialReasons.map((r) => Map<String, dynamic>.from(r)),
    );
  }

  @override
  void dispose() {
    _newReasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 600,
          height: 500.86,
          margin: const EdgeInsets.only(top: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Stock Counts',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isAdding)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isAdding = true;
                              _newReasonCtrl.clear();
                            });
                          },
                          icon: const Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Add new reason',
                            style: AppTheme.bodyText.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: 'Reason',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF4444),
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: '*',
                                      style: TextStyle(
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 32,
                                child: TextField(
                                  controller: _newReasonCtrl,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF1E293B),
                                  ),
                                  decoration: InputDecoration(
                                    fillColor: Colors.white,
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      final val = _newReasonCtrl.text.trim();
                                      if (val.isNotEmpty) {
                                        setState(() {
                                          _reasons.add({
                                            'name': val,
                                            'isActive': true,
                                          });
                                          _isAdding = false;
                                        });
                                        widget.onSave(_reasons);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'Save and Select',
                                      style: AppTheme.bodyText.copyWith(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isAdding = false;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFFCBD5E1),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: AppTheme.bodyText.copyWith(
                                        color: const Color(0xFF475569),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: const Color(0xFFF8FAFC),
                        child: Text(
                          'REASON',
                          style: AppTheme.captionText.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      ..._reasons.asMap().entries.map((entry) {
                        final int idx = entry.key;
                        final Map<String, dynamic> r = entry.value;
                        final bool active = r['isActive'] ?? true;
                        return _ReasonRow(
                          name: r['name'] ?? '',
                          isActive: active,
                          onMarkInactive: () {
                            setState(() {
                              _reasons[idx] = Map<String, dynamic>.from(r)
                                ..['isActive'] = false;
                            });
                            widget.onSave(_reasons);
                          },
                          onMarkActive: () {
                            setState(() {
                              _reasons[idx] = Map<String, dynamic>.from(r)
                                ..['isActive'] = true;
                            });
                            widget.onSave(_reasons);
                          },
                        );
                      }),
                    ],
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

class _ReasonRow extends StatefulWidget {
  const _ReasonRow({
    required this.name,
    required this.isActive,
    this.onMarkInactive,
    this.onMarkActive,
  });

  final String name;
  final bool isActive;
  final VoidCallback? onMarkInactive;
  final VoidCallback? onMarkActive;

  @override
  State<_ReasonRow> createState() => _ReasonRowState();
}

class _ReasonRowState extends State<_ReasonRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        color: _hovered ? const Color(0xFFEFF6FF) : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Text(
                    widget.name,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: widget.isActive
                          ? (_hovered
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF1E293B))
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  if (!widget.isActive) ...[
                    const SizedBox(width: 8),
                    Text(
                      '[INACTIVE]',
                      style: AppTheme.captionText.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_hovered && !widget.isActive)
                    _HoverAction(
                      label: 'Mark as Active',
                      icon: Icons.check_circle_outline,
                      activeColor: const Color(0xFF16A34A),
                      hoverBgColor: const Color(0xFFDCFCE7),
                      hoverColor: const Color(0xFF15803D),
                      onTap: widget.onMarkActive,
                    ),
                  if (_hovered && widget.isActive)
                    _HoverAction(
                      label: 'Mark as Inactive',
                      icon: Icons.delete_outline,
                      activeColor: const Color(0xFFEF4444),
                      hoverBgColor: const Color(0xFFFEE2E2),
                      hoverColor: const Color(0xFFDC2626),
                      onTap: widget.onMarkInactive,
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
          ],
        ),
      ),
    );
  }
}

class _HoverAction extends StatefulWidget {
  const _HoverAction({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.hoverBgColor,
    required this.hoverColor,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final Color hoverBgColor;
  final Color hoverColor;
  final VoidCallback? onTap;

  @override
  State<_HoverAction> createState() => _HoverActionState();
}

class _HoverActionState extends State<_HoverAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _hovered ? widget.hoverColor : widget.activeColor,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? widget.hoverColor : widget.activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
