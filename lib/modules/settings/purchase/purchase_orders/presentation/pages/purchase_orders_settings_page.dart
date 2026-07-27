import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';

enum PurchaseOrdersSettingsTab {
  preferences,
  approvals,
  fields,
  validationRules,
  buttons,
  relatedLists,
}

class PurchaseOrdersSettingsPage extends ConsumerStatefulWidget {
  const PurchaseOrdersSettingsPage({
    super.key,
    this.initialTab = PurchaseOrdersSettingsTab.preferences,
  });

  final PurchaseOrdersSettingsTab initialTab;

  @override
  ConsumerState<PurchaseOrdersSettingsPage> createState() =>
      _PurchaseOrdersSettingsPageState();
}

class _PurchaseOrdersSettingsPageState
    extends ConsumerState<PurchaseOrdersSettingsPage> {
  final SettingsPreferencesRepository _preferencesRepository =
      SettingsPreferencesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _termsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();

  int _closePreference =
      0; // 0: When a Purchase Receive is recorded, 1: When a Bill is created, 2: When Receives and Bills are recorded
  late PurchaseOrdersSettingsTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _preferencesRepository.loadSection(
        'stock_preferences',
        const ['purchase', 'purchase_orders'],
      );
      if (!mounted || data.isEmpty) return;
      setState(() {
        _closePreference =
            int.tryParse(data['close_preference']?.toString() ?? '') ??
            _closePreference;
        _termsController.text = data['terms']?.toString() ?? '';
        _notesController.text = data['notes']?.toString() ?? '';
      });
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to load purchase order preferences');
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _preferencesRepository.saveSection(
        'stock_preferences',
        {
          'close_preference': _closePreference,
          'terms': _termsController.text,
          'notes': _notesController.text,
        },
        const ['purchase', 'purchase_orders'],
      );
      if (mounted)
        ZerpaiToast.success(context, 'Purchase Orders preferences saved');
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to save purchase order preferences');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _termsController.dispose();
    _notesController.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _openTab(PurchaseOrdersSettingsTab tab) {
    setState(() => _activeTab = tab);
    final route = switch (tab) {
      _ => AppRoutes.settingsPurchaseOrders,
    };
    context.go(_withOrgPrefix(route));
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return [
      SettingsSearchItem(
        group: 'Preferences',
        label: 'When do you want your Purchase Orders to be closed?',
        onSelected: () {
          _openTab(PurchaseOrdersSettingsTab.preferences);
          _searchFocusNode.unfocus();
        },
      ),
      SettingsSearchItem(
        group: 'Preferences',
        label: 'Terms & Conditions',
        onSelected: () {
          _openTab(PurchaseOrdersSettingsTab.preferences);
          _searchFocusNode.unfocus();
        },
      ),
      SettingsSearchItem(
        group: 'Preferences',
        label: 'Notes',
        onSelected: () {
          _openTab(PurchaseOrdersSettingsTab.preferences);
          _searchFocusNode.unfocus();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true
        ? orgSettings!.name.trim()
        : 'ZERPAI ERP';
    final searchItems = _buildSearchItems();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): () =>
            _searchFocusNode.requestFocus(),
      },
      child: ColoredBox(
        color: const Color(0xFFF7F8FC),
        child: Column(
          children: [
            _PurchaseOrdersSettingsHeader(
              orgName: orgName,
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              searchItems: searchItems,
              onBack: () => context.go(_withOrgPrefix(AppRoutes.settings)),
              onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsNavigationSidebar(
                    currentPath: GoRouterState.of(context).uri.path,
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _PurchaseOrdersPageTitle(),
                          _PurchaseOrdersTabsRow(
                            activeTab: _activeTab,
                            onTabSelected: _openTab,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.borderLight,
                          ),
                          Expanded(
                            child: Scrollbar(
                              controller: _contentScrollController,
                              thumbVisibility: true,
                              child: SingleChildScrollView(
                                controller: _contentScrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  18,
                                  22,
                                  34,
                                ),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 820,
                                    ),
                                    child:
                                        _activeTab ==
                                            PurchaseOrdersSettingsTab
                                                .preferences
                                        ? _PurchaseOrdersPreferencesContent(
                                            closePreference: _closePreference,
                                            onClosePreferenceChanged: (value) {
                                              setState(
                                                () => _closePreference = value,
                                              );
                                            },
                                            termsController: _termsController,
                                            notesController: _notesController,
                                            onSave: _savePreferences,
                                          )
                                        : Center(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 40,
                                                  ),
                                              child: Text(
                                                '${_activeTab.name.toUpperCase()} content placeholder',
                                                style: AppTheme.bodyText
                                                    .copyWith(
                                                      color: AppTheme
                                                          .textSecondary,
                                                    ),
                                              ),
                                            ),
                                          ),
                                  ),
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
          ],
        ),
      ),
    );
  }
}

class _PurchaseOrdersPreferencesContent extends StatelessWidget {
  const _PurchaseOrdersPreferencesContent({
    required this.closePreference,
    required this.onClosePreferenceChanged,
    required this.termsController,
    required this.notesController,
    required this.onSave,
  });

  final int closePreference;
  final ValueChanged<int> onClosePreferenceChanged;
  final TextEditingController termsController;
  final TextEditingController notesController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When do you want your Purchase Orders to be closed?',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF20263A),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsRadioRow(
          value: 0,
          groupValue: closePreference,
          label: 'When a Purchase Receive is recorded',
          onChanged: (val) => onClosePreferenceChanged(val ?? 0),
        ),
        _SettingsRadioRow(
          value: 1,
          groupValue: closePreference,
          label: 'When a Bill is created',
          onChanged: (val) => onClosePreferenceChanged(val ?? 0),
        ),
        _SettingsRadioRow(
          value: 2,
          groupValue: closePreference,
          label: 'When Receives and Bills are recorded',
          onChanged: (val) => onClosePreferenceChanged(val ?? 0),
        ),
        const SizedBox(height: 24),
        Text(
          'Terms & Conditions',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF20263A),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 820,
          child: TextField(
            controller: termsController,
            maxLines: 4,
            style: AppTheme.bodyText.copyWith(fontSize: 13),
            decoration: _textAreaDecoration(
              'Enter terms and conditions to be displayed on purchase orders',
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Notes',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF20263A),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 820,
          child: TextField(
            controller: notesController,
            maxLines: 4,
            style: AppTheme.bodyText.copyWith(fontSize: 13),
            decoration: _textAreaDecoration(
              'Enter notes to be displayed on purchase orders',
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        const SizedBox(height: 28),
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: AppTheme.bodyText.copyWith(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

InputDecoration _textAreaDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTheme.bodyText.copyWith(
      color: const Color(0xFF8E95B2),
      fontSize: 13,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFD8DDF0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.primaryBlue),
    ),
  );
}

class _SettingsRadioRow extends StatelessWidget {
  const _SettingsRadioRow({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  });

  final int value;
  final int groupValue;
  final String label;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Radio<int>(
                value: value,
                groupValue: groupValue,
                activeColor: AppTheme.primaryBlue,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseOrdersSettingsHeader extends StatelessWidget {
  const _PurchaseOrdersSettingsHeader({
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
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Settings',
                style: AppTheme.pageTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                orgName,
                style: AppTheme.captionText.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 320,
            height: 36,
            child: SettingsSearchField(
              controller: searchController,
              focusNode: searchFocusNode,
              items: searchItems,
              onNoMatch: (query) {
                ZerpaiToast.info(
                  context,
                  'No preferences found matching "$query"',
                );
              },
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onClose,
            child: Row(
              children: [
                Text(
                  'Close Settings',
                  style: AppTheme.bodyText.copyWith(
                    color: const Color(0xFFFF596A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.close, size: 14, color: Color(0xFFFF596A)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseOrdersPageTitle extends StatelessWidget {
  const _PurchaseOrdersPageTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 6),
      child: Text(
        'Purchase Orders',
        style: TextStyle(
          color: Color(0xFF20263A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PurchaseOrdersTabsRow extends StatelessWidget {
  const _PurchaseOrdersTabsRow({
    required this.activeTab,
    required this.onTabSelected,
  });

  final PurchaseOrdersSettingsTab activeTab;
  final ValueChanged<PurchaseOrdersSettingsTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: PurchaseOrdersSettingsTab.values.map((tab) {
          final isSelected = tab == activeTab;
          return InkWell(
            onTap: () => onTabSelected(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.only(right: 28),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryBlue
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                _getTabLabel(tab),
                style: AppTheme.bodyText.copyWith(
                  color: isSelected
                      ? const Color(0xFF20263A)
                      : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTabLabel(PurchaseOrdersSettingsTab tab) {
    return switch (tab) {
      PurchaseOrdersSettingsTab.preferences => 'Preferences',
      PurchaseOrdersSettingsTab.approvals => 'Approvals',
      PurchaseOrdersSettingsTab.fields => 'Fields',
      PurchaseOrdersSettingsTab.validationRules => 'Validation Rules',
      PurchaseOrdersSettingsTab.buttons => 'Buttons',
      PurchaseOrdersSettingsTab.relatedLists => 'Related Lists',
    };
  }
}
