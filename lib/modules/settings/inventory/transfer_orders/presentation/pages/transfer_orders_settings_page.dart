import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';

enum TransferOrdersSettingsTab {
  preferences,
  approvals,
  fields,
  buttons,
  relatedLists,
}

enum CostPricePreferenceType { costPrice, averagePrice }

class TransferOrdersSettingsPage extends ConsumerStatefulWidget {
  const TransferOrdersSettingsPage({
    super.key,
    this.initialTab = TransferOrdersSettingsTab.preferences,
  });

  final TransferOrdersSettingsTab initialTab;

  @override
  ConsumerState<TransferOrdersSettingsPage> createState() =>
      _TransferOrdersSettingsPageState();
}

class _TransferOrdersSettingsPageState
    extends ConsumerState<TransferOrdersSettingsPage> {
  final SettingsPreferencesRepository _preferencesRepository = SettingsPreferencesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _contentScrollController = ScrollController();

  CostPricePreferenceType _costPricePreference =
      CostPricePreferenceType.costPrice;
  bool _showCostPriceInTransferOrders = true;
  String _selectedLocationPreference = 'Only Accessible Locations';
  late TransferOrdersSettingsTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final data = await _preferencesRepository.loadSection('stock_preferences', const ['inventory', 'transfer_orders']);
      if (!mounted || data.isEmpty) return;
      setState(() {
        _costPricePreference = CostPricePreferenceType.values.where((v) => v.name == data['cost_price_preference']).firstOrNull ?? _costPricePreference;
        _showCostPriceInTransferOrders = data['show_cost_price'] as bool? ?? _showCostPriceInTransferOrders;
        _selectedLocationPreference = data['location_preference']?.toString() ?? _selectedLocationPreference;
      });
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to load transfer order preferences');
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _preferencesRepository.saveSection('stock_preferences', {
        'cost_price_preference': _costPricePreference.name,
        'show_cost_price': _showCostPriceInTransferOrders,
        'location_preference': _selectedLocationPreference,
      }, const ['inventory', 'transfer_orders']);
      if (mounted) ZerpaiToast.success(context, 'Transfer Orders preferences saved');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save transfer order preferences');
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

  void _openTab(TransferOrdersSettingsTab tab) {
    setState(() => _activeTab = tab);
    final route = switch (tab) {
      _ => AppRoutes.settingsTransferOrders,
    };
    context.go(_withOrgPrefix(route));
  }

  List<SettingsSearchItem> _buildSearchItems() {
    return [
      SettingsSearchItem(
        group: 'Preferences',
        label: 'Cost Price Preference',
        onSelected: () {
          _openTab(TransferOrdersSettingsTab.preferences);
          _searchFocusNode.unfocus();
        },
      ),
      SettingsSearchItem(
        group: 'Preferences',
        label: 'Show cost price in transfer orders',
        onSelected: () {
          _openTab(TransferOrdersSettingsTab.preferences);
          _searchFocusNode.unfocus();
        },
      ),
      SettingsSearchItem(
        group: 'Preferences',
        label: 'Location Preference',
        onSelected: () {
          _openTab(TransferOrdersSettingsTab.preferences);
          _searchFocusNode.unfocus();
        },
      ),
    ];
  }

  Widget _dropdownItemBuilder(String label, bool isSelected, bool isHovered) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHovered
            ? const Color(0xFF3B82F6)
            : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          color: isHovered ? Colors.white : const Color(0xFF1F2937),
        ),
      ),
    );
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
            _TransferOrdersSettingsHeader(
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
                          const _TransferOrdersPageTitle(),
                          _TransferOrdersTabsRow(
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
                                            TransferOrdersSettingsTab
                                                .preferences
                                        ? _TransferOrdersPreferencesContent(
                                            costPricePreference:
                                                _costPricePreference,
                                            onCostPricePreferenceChanged:
                                                (value) {
                                                  setState(
                                                    () => _costPricePreference =
                                                        value!,
                                                  );
                                                },
                                            showCostPriceInTransferOrders:
                                                _showCostPriceInTransferOrders,
                                            onShowCostPriceInTransferOrdersChanged:
                                                (value) {
                                                  setState(
                                                    () =>
                                                        _showCostPriceInTransferOrders =
                                                            value,
                                                  );
                                                },
                                            selectedLocationPreference:
                                                _selectedLocationPreference,
                                            onLocationPreferenceChanged: (value) {
                                              setState(
                                                () => _selectedLocationPreference =
                                                    value ??
                                                    'Only Accessible Locations',
                                              );
                                            },
                                            dropdownItemBuilder:
                                                _dropdownItemBuilder,
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

class _TransferOrdersPreferencesContent extends StatelessWidget {
  const _TransferOrdersPreferencesContent({
    required this.costPricePreference,
    required this.onCostPricePreferenceChanged,
    required this.showCostPriceInTransferOrders,
    required this.onShowCostPriceInTransferOrdersChanged,
    required this.selectedLocationPreference,
    required this.onLocationPreferenceChanged,
    required this.dropdownItemBuilder,
    required this.onSave,
  });

  final CostPricePreferenceType costPricePreference;
  final ValueChanged<CostPricePreferenceType?> onCostPricePreferenceChanged;
  final bool showCostPriceInTransferOrders;
  final ValueChanged<bool> onShowCostPriceInTransferOrdersChanged;
  final String selectedLocationPreference;
  final ValueChanged<String?> onLocationPreferenceChanged;
  final Widget Function(String, bool, bool) dropdownItemBuilder;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cost Price Preference',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF20263A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Choose how you want Zoho Inventory to calculate an item's cost price in transfer orders.",
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _CostPricePreferenceRadioOption(
          value: CostPricePreferenceType.costPrice,
          groupValue: costPricePreference,
          onChanged: onCostPricePreferenceChanged,
          label: 'Cost Price',
          description:
              "If the selected locations have same GSTIN, then the cost price of the item will be taken from the most recent transaction associated with the destination location. If the selected locations have different GSTIN then the cost price of the item will be item's default cost price.",
          child: Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, bottom: 8),
            child: _SettingsCheckboxRow(
              value: showCostPriceInTransferOrders,
              label: 'Show cost price in transfer orders',
              onChanged: onShowCostPriceInTransferOrdersChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _CostPricePreferenceRadioOption(
          value: CostPricePreferenceType.averagePrice,
          groupValue: costPricePreference,
          onChanged: onCostPricePreferenceChanged,
          label: 'Average Price',
          description:
              'The average cost price of an item will be calculated based on the source location and will be used in transfer orders.',
          child: Padding(
            padding: const EdgeInsets.only(left: 32, top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFEA580C),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "If you choose this option, Zoho Inventory won't show the cost price in transfer orders.",
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 11.5,
                        color: const Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        const SizedBox(height: 24),
        Text(
          'Location Preference',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF20263A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Users can create transfer orders for:',
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 320,
          child: FormDropdown<String>(
            height: 32,
            value: selectedLocationPreference,
            hint: 'Select Location Preference',
            items: const ['Only Accessible Locations', 'All Locations'],
            displayStringForValue: (v) => v,
            itemBuilder: (v, isSelected, isHovered) =>
                dropdownItemBuilder(v, isSelected, isHovered),
            onChanged: onLocationPreferenceChanged,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFEDD5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFEA580C),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Note:',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC2410C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NoteBulletItem(
                      text:
                          'To assign users to the location, go to the location and select the users from Associate Users section.',
                    ),
                    const SizedBox(height: 6),
                    _NoteBulletItem(
                      text:
                          'To assign locations to users, go to Settings > Users & Roles. Under the More tab in the users section, click the Configure button near the location you want to give access.',
                    ),
                  ],
                ),
              ),
            ],
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

class _NoteBulletItem extends StatelessWidget {
  const _NoteBulletItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFC2410C),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyText.copyWith(
              fontSize: 12,
              height: 1.4,
              color: const Color(0xFF9A3412),
            ),
          ),
        ),
      ],
    );
  }
}

class _CostPricePreferenceRadioOption extends StatelessWidget {
  const _CostPricePreferenceRadioOption({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    required this.description,
    this.child,
  });

  final CostPricePreferenceType value;
  final CostPricePreferenceType groupValue;
  final ValueChanged<CostPricePreferenceType?> onChanged;
  final String label;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => onChanged(value),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Radio<CostPricePreferenceType>(
                    value: value,
                    groupValue: groupValue,
                    activeColor: AppTheme.primaryBlue,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12,
                        height: 1.4,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isSelected && child != null) child!,
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
        padding: const EdgeInsets.only(bottom: 4),
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

class _TransferOrdersSettingsHeader extends StatelessWidget {
  const _TransferOrdersSettingsHeader({
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

class _TransferOrdersPageTitle extends StatelessWidget {
  const _TransferOrdersPageTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 6),
      child: Text(
        'Transfer Orders',
        style: TextStyle(
          color: Color(0xFF20263A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TransferOrdersTabsRow extends StatelessWidget {
  const _TransferOrdersTabsRow({
    required this.activeTab,
    required this.onTabSelected,
  });

  final TransferOrdersSettingsTab activeTab;
  final ValueChanged<TransferOrdersSettingsTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: TransferOrdersSettingsTab.values.map((tab) {
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

  String _getTabLabel(TransferOrdersSettingsTab tab) {
    return switch (tab) {
      TransferOrdersSettingsTab.preferences => 'Preferences',
      TransferOrdersSettingsTab.approvals => 'Approvals',
      TransferOrdersSettingsTab.fields => 'Fields',
      TransferOrdersSettingsTab.buttons => 'Buttons',
      TransferOrdersSettingsTab.relatedLists => 'Related Lists',
    };
  }
}
