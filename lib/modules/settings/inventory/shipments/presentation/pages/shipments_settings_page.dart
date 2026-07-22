import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/address_dialog.dart';

enum ShipmentsSettingsTab { preferences, fields, buttons, relatedLists }

class ShipmentsSettingsPage extends ConsumerStatefulWidget {
  const ShipmentsSettingsPage({
    super.key,
    this.initialTab = ShipmentsSettingsTab.preferences,
  });

  final ShipmentsSettingsTab initialTab;

  @override
  ConsumerState<ShipmentsSettingsPage> createState() =>
      _ShipmentsSettingsPageState();
}

class _ShipmentsSettingsPageState extends ConsumerState<ShipmentsSettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _contentScrollController = ScrollController();
  final LayerLink _addressLayerLink = LayerLink();
  OverlayEntry? _addressOverlayEntry;

  bool _notifyCarrierShipments = true;
  bool _notifyManualShipments = true;
  late ShipmentsSettingsTab _activeTab;

  List<Map<String, dynamic>> _dispatchAddresses = [
    {
      'companyName': 'zabnixprivatelimited',
      'attention': '',
      'street1': 'PERINTHALMANNA',
      'street2': 'MALAPPURAM, Kerala',
      'city': 'MALAPPURAM',
      'state': 'KL',
      'stateName': 'Kerala',
      'country': 'IN',
      'countryName': 'India',
      'zip': '679322',
      'phone': '8086355500',
    },
  ];
  int _selectedAddressIndex = 0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _hideAddressSelectionOverlay();
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

  void _openTab(ShipmentsSettingsTab tab) {
    setState(() => _activeTab = tab);
    final route = switch (tab) {
      _ => AppRoutes.settingsShipments,
    };
    context.go(_withOrgPrefix(route));
  }

  void _showAddressSelectionOverlay() {
    if (_addressOverlayEntry != null) {
      _hideAddressSelectionOverlay();
      return;
    }
    final overlay = Overlay.of(context);
    _addressOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _addressLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 36),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(4),
            child: _buildAddressSelectionCard(),
          ),
        ),
      ),
    );
    overlay.insert(_addressOverlayEntry!);
  }

  void _hideAddressSelectionOverlay() {
    _addressOverlayEntry?.remove();
    _addressOverlayEntry = null;
  }

  Widget _buildAddressSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: List.generate(_dispatchAddresses.length, (i) {
                  final addr = _dispatchAddresses[i];
                  final isActive = i == _selectedAddressIndex;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedAddressIndex = i;
                      });
                      _hideAddressSelectionOverlay();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF3B82F6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isActive
                              ? Colors.transparent
                              : AppTheme.borderLight,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  addr['companyName'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isActive
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ...[
                                      if (addr['street1']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['street1'].toString(),
                                      if (addr['street2']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['street2'].toString(),
                                      '${addr['city'] ?? ''}${addr['city'] != null && addr['stateName'] != null ? ', ' : ''}${addr['stateName'] ?? addr['state'] ?? ''}'
                                          .trim(),
                                      '${addr['countryName'] ?? addr['country'] ?? ''}${addr['countryName'] != null && addr['zip'] != null ? ' , ' : ''}${addr['zip'] ?? ''}'
                                          .trim(),
                                      if (addr['phone']
                                              ?.toString()
                                              .isNotEmpty ==
                                          true)
                                        addr['phone'].toString(),
                                    ]
                                    .where((line) => line.isNotEmpty)
                                    .map(
                                      (line) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 2,
                                        ),
                                        child: Text(
                                          line,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isActive
                                                ? Colors.white.withValues(
                                                    alpha: 0.9,
                                                  )
                                                : AppTheme.textSecondary,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () async {
                                _hideAddressSelectionOverlay();
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AddressDialog(
                                    title: 'DISPATCH ADDRESS',
                                    initialAddress: addr,
                                    onSave: (updated) {
                                      setState(() {
                                        _dispatchAddresses[i] = updated;
                                      });
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  LucideIcons.pencil,
                                  size: 12,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          InkWell(
            onTap: () async {
              _hideAddressSelectionOverlay();
              await showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AddressDialog(
                  title: 'DISPATCH ADDRESS',
                  initialAddress: {
                    'companyName': '',
                    'attention': '',
                    'street1': '',
                    'street2': '',
                    'city': '',
                    'zip': '',
                    'state': '',
                    'stateName': '',
                    'country': 'IN',
                    'countryName': 'India',
                    'phone': '',
                  },
                  onSave: (newAddress) {
                    setState(() {
                      _dispatchAddresses.add(newAddress);
                      _selectedAddressIndex = _dispatchAddresses.length - 1;
                    });
                  },
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: Color(0xFF3B82F6),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'New address',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
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

  List<SettingsSearchItem> _buildSearchItems() {
    return [
      SettingsSearchItem(
        group: 'Preferences',
        label:
            'Do you want to send notifications to customers for carrier shipments?',
        onSelected: () {
          _openTab(ShipmentsSettingsTab.preferences);
          _searchFocusNode.unfocus();
        },
      ),
      SettingsSearchItem(
        group: 'Preferences',
        label:
            'Do you want to send notifications to customers for manual shipments?',
        onSelected: () {
          _openTab(ShipmentsSettingsTab.preferences);
          _searchFocusNode.unfocus();
        },
      ),
      SettingsSearchItem(
        group: 'Preferences',
        label: 'Choose default Dispatch address',
        onSelected: () {
          _openTab(ShipmentsSettingsTab.preferences);
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

    final activeAddress = _dispatchAddresses.isNotEmpty
        ? _dispatchAddresses[_selectedAddressIndex]
        : null;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): () =>
            _searchFocusNode.requestFocus(),
      },
      child: GestureDetector(
        onTap: _hideAddressSelectionOverlay,
        child: ColoredBox(
          color: const Color(0xFFF7F8FC),
          child: Column(
            children: [
              _ShipmentsSettingsHeader(
                orgName: orgName,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                searchItems: searchItems,
                onBack: () => context.go(_withOrgPrefix(AppRoutes.settings)),
                onClose: () => context.go(_withOrgPrefix(AppRoutes.home)),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderLight,
              ),
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
                            const _ShipmentsPageTitle(),
                            _ShipmentsTabsRow(
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
                                              ShipmentsSettingsTab.preferences
                                          ? Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _ShipmentsPreferencesContent(
                                                  notifyCarrierShipments:
                                                      _notifyCarrierShipments,
                                                  onNotifyCarrierShipmentsChanged:
                                                      (value) {
                                                        setState(
                                                          () =>
                                                              _notifyCarrierShipments =
                                                                  value,
                                                        );
                                                      },
                                                  notifyManualShipments:
                                                      _notifyManualShipments,
                                                  onNotifyManualShipmentsChanged:
                                                      (value) {
                                                        setState(
                                                          () =>
                                                              _notifyManualShipments =
                                                                  value,
                                                        );
                                                      },
                                                ),
                                                const SizedBox(height: 24),
                                                Text(
                                                  'Choose default Dispatch address',
                                                  style: AppTheme.bodyText
                                                      .copyWith(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: const Color(
                                                          0xFF20263A,
                                                        ),
                                                      ),
                                                ),
                                                const SizedBox(height: 12),
                                                CompositedTransformTarget(
                                                  link: _addressLayerLink,
                                                  child: Container(
                                                    width: 440,
                                                    padding:
                                                        const EdgeInsets.all(
                                                          16,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF8FAFC,
                                                      ),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFE2E8F0,
                                                        ),
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        if (activeAddress !=
                                                            null) ...[
                                                          if (activeAddress['companyName']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                            Text(
                                                              activeAddress['companyName']
                                                                  .toString(),
                                                              style: AppTheme
                                                                  .bodyText
                                                                  .copyWith(
                                                                    fontSize:
                                                                        12.5,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    color: const Color(
                                                                      0xFF1E293B,
                                                                    ),
                                                                  ),
                                                            ),
                                                          if (activeAddress['street1']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                            Text(
                                                              activeAddress['street1']
                                                                  .toString(),
                                                              style: AppTheme
                                                                  .bodyText
                                                                  .copyWith(
                                                                    fontSize:
                                                                        12.5,
                                                                    color: const Color(
                                                                      0xFF475569,
                                                                    ),
                                                                  ),
                                                            ),
                                                          if (activeAddress['street2']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                            Text(
                                                              activeAddress['street2']
                                                                  .toString(),
                                                              style: AppTheme
                                                                  .bodyText
                                                                  .copyWith(
                                                                    fontSize:
                                                                        12.5,
                                                                    color: const Color(
                                                                      0xFF475569,
                                                                    ),
                                                                  ),
                                                            ),
                                                          Text(
                                                            '${activeAddress['city'] ?? ''}${activeAddress['city'] != null && activeAddress['stateName'] != null ? ', ' : ''}${activeAddress['stateName'] ?? activeAddress['state'] ?? ''}'
                                                                .trim(),
                                                            style: AppTheme
                                                                .bodyText
                                                                .copyWith(
                                                                  fontSize:
                                                                      12.5,
                                                                  color: const Color(
                                                                    0xFF475569,
                                                                  ),
                                                                ),
                                                          ),
                                                          Text(
                                                            '${activeAddress['countryName'] ?? activeAddress['country'] ?? ''}${activeAddress['countryName'] != null && activeAddress['zip'] != null ? ', ' : ''}${activeAddress['zip'] ?? ''}'
                                                                .trim(),
                                                            style: AppTheme
                                                                .bodyText
                                                                .copyWith(
                                                                  fontSize:
                                                                      12.5,
                                                                  color: const Color(
                                                                    0xFF475569,
                                                                  ),
                                                                ),
                                                          ),
                                                          if (activeAddress['phone']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                            Text(
                                                              activeAddress['phone']
                                                                  .toString(),
                                                              style: AppTheme
                                                                  .bodyText
                                                                  .copyWith(
                                                                    fontSize:
                                                                        12.5,
                                                                    color: const Color(
                                                                      0xFF475569,
                                                                    ),
                                                                  ),
                                                            ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                        ],
                                                        InkWell(
                                                          onTap:
                                                              _showAddressSelectionOverlay,
                                                          child: Text(
                                                            'Change Address',
                                                            style: AppTheme
                                                                .bodyText
                                                                .copyWith(
                                                                  color: const Color(
                                                                    0xFF2563EB,
                                                                  ),
                                                                  fontSize:
                                                                      12.5,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  decoration:
                                                                      TextDecoration
                                                                          .none,
                                                                ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 28),
                                                const Divider(
                                                  height: 1,
                                                  thickness: 1,
                                                  color: AppTheme.borderLight,
                                                ),
                                                const SizedBox(height: 28),
                                                SizedBox(
                                                  height: 34,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      ZerpaiToast.success(
                                                        context,
                                                        'Shipments preferences saved',
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF28B36B,
                                                          ),
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 0,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Save',
                                                      style: AppTheme.bodyText
                                                          .copyWith(
                                                            color: Colors.white,
                                                            fontSize: 12.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
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
      ),
    );
  }
}

class _ShipmentsPreferencesContent extends StatelessWidget {
  const _ShipmentsPreferencesContent({
    required this.notifyCarrierShipments,
    required this.onNotifyCarrierShipmentsChanged,
    required this.notifyManualShipments,
    required this.onNotifyManualShipmentsChanged,
  });

  final bool notifyCarrierShipments;
  final ValueChanged<bool> onNotifyCarrierShipmentsChanged;
  final bool notifyManualShipments;
  final ValueChanged<bool> onNotifyManualShipmentsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipment Notification',
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF20263A),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCheckboxRow(
          value: notifyCarrierShipments,
          label:
              'Do you want to send notifications to customers for carrier shipments?',
          onChanged: onNotifyCarrierShipmentsChanged,
        ),
        _SettingsCheckboxRow(
          value: notifyManualShipments,
          label:
              'Do you want to send notifications to customers for manual shipments?',
          onChanged: onNotifyManualShipmentsChanged,
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

class _ShipmentsSettingsHeader extends StatelessWidget {
  const _ShipmentsSettingsHeader({
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

class _ShipmentsPageTitle extends StatelessWidget {
  const _ShipmentsPageTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, 6),
      child: Text(
        'Shipments',
        style: TextStyle(
          color: Color(0xFF20263A),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ShipmentsTabsRow extends StatelessWidget {
  const _ShipmentsTabsRow({
    required this.activeTab,
    required this.onTabSelected,
  });

  final ShipmentsSettingsTab activeTab;
  final ValueChanged<ShipmentsSettingsTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: ShipmentsSettingsTab.values.map((tab) {
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

  String _getTabLabel(ShipmentsSettingsTab tab) {
    return switch (tab) {
      ShipmentsSettingsTab.preferences => 'Preferences',
      ShipmentsSettingsTab.fields => 'Fields',
      ShipmentsSettingsTab.buttons => 'Buttons',
      ShipmentsSettingsTab.relatedLists => 'Related Lists',
    };
  }
}
