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

enum PurchaseReceivesSettingsTab {
  preferences,
  approvals,
  fields,
  validationRules,
  buttons,
  relatedLists,
}

class PurchaseReceivesSettingsPage extends ConsumerStatefulWidget {
  const PurchaseReceivesSettingsPage({
    super.key,
    this.initialTab = PurchaseReceivesSettingsTab.preferences,
  });

  final PurchaseReceivesSettingsTab initialTab;

  @override
  ConsumerState<PurchaseReceivesSettingsPage> createState() =>
      _PurchaseReceivesSettingsPageState();
}

class _PurchaseReceivesSettingsPageState
    extends ConsumerState<PurchaseReceivesSettingsPage> {
  final SettingsPreferencesRepository _preferencesRepository =
      SettingsPreferencesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _contentScrollController = ScrollController();

  bool _receiveQtyMoreThanOrdered = true;
  late PurchaseReceivesSettingsTab _activeTab;

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
        const ['purchase', 'purchase_receives'],
      );
      if (!mounted || data.isEmpty) return;
      setState(
        () => _receiveQtyMoreThanOrdered =
            data['receive_qty_more_than_ordered'] as bool? ??
            _receiveQtyMoreThanOrdered,
      );
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(
          context,
          'Failed to load purchase receive preferences',
        );
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _preferencesRepository.saveSection(
        'stock_preferences',
        {'receive_qty_more_than_ordered': _receiveQtyMoreThanOrdered},
        const ['purchase', 'purchase_receives'],
      );
      if (mounted)
        ZerpaiToast.success(context, 'Purchase Receives preferences saved');
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(
          context,
          'Failed to save purchase receive preferences',
        );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _contentScrollController.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _openTab(PurchaseReceivesSettingsTab tab) {
    setState(() => _activeTab = tab);
    final route = switch (tab) {
      _ => AppRoutes.settingsPurchaseReceives,
    };
    context.go(_withOrgPrefix(route));
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return [
      SettingsSearchItem(
        group: 'Preferences',
        label: 'Receive quantity more than specified in purchase orders',
        onSelected: () {
          _openTab(PurchaseReceivesSettingsTab.preferences);
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
            _PurchaseReceivesSettingsHeader(
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
                          const _PurchaseReceivesPageTitle(),
                          _PurchaseReceivesTabsRow(
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
                                            PurchaseReceivesSettingsTab
                                                .preferences
                                        ? _PurchaseReceivesPreferencesContent(
                                            receiveQtyMoreThanOrdered:
                                                _receiveQtyMoreThanOrdered,
                                            onReceiveQtyMoreThanOrderedChanged:
                                                (value) {
                                                  setState(
                                                    () =>
                                                        _receiveQtyMoreThanOrdered =
                                                            value,
                                                  );
                                                },
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

class _PurchaseReceivesPreferencesContent extends StatelessWidget {
  const _PurchaseReceivesPreferencesContent({
    required this.receiveQtyMoreThanOrdered,
    required this.onReceiveQtyMoreThanOrderedChanged,
    required this.onSave,
  });

  final bool receiveQtyMoreThanOrdered;
  final ValueChanged<bool> onReceiveQtyMoreThanOrderedChanged;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsCheckboxRow(
          value: receiveQtyMoreThanOrdered,
          label: 'Receive quantity more than specified in purchase orders',
          onChanged: onReceiveQtyMoreThanOrderedChanged,
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

class _SettingsCheckboxRow extends StatelessWidget {
  const _SettingsCheckboxRow({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Checkbox(
                value: value,
                activeColor: AppTheme.primaryBlue,
                side: const BorderSide(color: Color(0xFFC3C9DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (checked) => onChanged(checked ?? false),
              ),
            ),
            const SizedBox(width: 4),
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

class _PurchaseReceivesSettingsHeader extends StatelessWidget {
  const _PurchaseReceivesSettingsHeader({
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

class _PurchaseReceivesPageTitle extends StatelessWidget {
  const _PurchaseReceivesPageTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 6),
      child: Text(
        'Purchase Receives',
        style: TextStyle(
          color: Color(0xFF20263A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PurchaseReceivesTabsRow extends StatelessWidget {
  const _PurchaseReceivesTabsRow({
    required this.activeTab,
    required this.onTabSelected,
  });

  final PurchaseReceivesSettingsTab activeTab;
  final ValueChanged<PurchaseReceivesSettingsTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: PurchaseReceivesSettingsTab.values.map((tab) {
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

  String _getTabLabel(PurchaseReceivesSettingsTab tab) {
    return switch (tab) {
      PurchaseReceivesSettingsTab.preferences => 'Preferences',
      PurchaseReceivesSettingsTab.approvals => 'Approvals',
      PurchaseReceivesSettingsTab.fields => 'Fields',
      PurchaseReceivesSettingsTab.validationRules => 'Validation Rules',
      PurchaseReceivesSettingsTab.buttons => 'Buttons',
      PurchaseReceivesSettingsTab.relatedLists => 'Related Lists',
    };
  }
}
