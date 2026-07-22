import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';

enum CustomersAndVendorsTab { preferences, fields, buttons, relatedLists }

class CustomersAndVendorsSettingsPage extends ConsumerStatefulWidget {
  const CustomersAndVendorsSettingsPage({
    super.key,
    this.initialTab = CustomersAndVendorsTab.preferences,
  });

  final CustomersAndVendorsTab initialTab;

  @override
  ConsumerState<CustomersAndVendorsSettingsPage> createState() =>
      _CustomersAndVendorsSettingsPageState();
}

class _CustomersAndVendorsSettingsPageState
    extends ConsumerState<CustomersAndVendorsSettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late CustomersAndVendorsTab _activeTab;
  final ScrollController _contentScrollController = ScrollController();

  // State fields matching the form in the screenshot
  bool _allowDuplicates = true;
  String _defaultCustomerType = 'Individual'; // 'Business' or 'Individual'
  bool _creditLimitEnabled = true;
  String _creditLimitExceededAction =
      'Show warning'; // 'Restrict' or 'Show warning'
  bool _includeSalesOrdersInLimit = true;
  bool _multiCurrencyEnabled = false;

  late final TextEditingController _billingAddressController;
  late final TextEditingController _shippingAddressController;

  // LayerLinks for anchor dropdown positioning
  final _billingLayerLink = LayerLink();
  final _shippingLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;

    _billingAddressController = TextEditingController(
      text:
          '\${CONTACT.CONTACT_DISPLAYNAME}\n'
          '\${CONTACT.CONTACT_ADDRESS}\n'
          '\${CONTACT.CONTACT_CITY}\n'
          '\${CONTACT.CONTACT_CODE} \${CONTACT.CONTACT_STATE}\n'
          '\${CONTACT.CONTACT_COUNTRY}\n'
          '\${CONTACT.CONTACT_GSTIN_LABEL} \${CONTACT.CONTACT_GSTIN}',
    );

    _shippingAddressController = TextEditingController(
      text:
          '\${CONTACT.CONTACT_ADDRESS}\n'
          '\${CONTACT.CONTACT_CITY}\n'
          '\${CONTACT.CONTACT_CODE} \${CONTACT.CONTACT_STATE}\n'
          '\${CONTACT.CONTACT_COUNTRY}',
    );
  }

  @override
  void dispose() {
    _hidePlaceholderDropdown();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _contentScrollController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  void _focusSearch() {
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
  }

  void _saveSettings() {
    ZerpaiToast.success(
      context,
      'Customers and Vendors settings saved successfully.',
    );
  }

  void _showPlaceholderDropdown(
    BuildContext context,
    LayerLink link,
    TextEditingController targetController,
  ) {
    _hidePlaceholderDropdown();

    _overlayEntry = OverlayEntry(
      builder: (context) => _PlaceholderDropdownOverlay(
        link: link,
        onClose: _hidePlaceholderDropdown,
        onSelect: (placeholder) {
          final text = targetController.text;
          final selection = targetController.selection;
          final insertText = '\${$placeholder}';

          if (selection.isValid) {
            final start = selection.start;
            final end = selection.end;
            final newText = text.replaceRange(start, end, insertText);
            targetController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                offset: start + insertText.length,
              ),
            );
          } else {
            targetController.text = text + insertText;
          }
          _hidePlaceholderDropdown();
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePlaceholderDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final orgName =
        ref.watch(orgSettingsProvider).valueOrNull?.name ??
        'ZABNIX PRIVATE LIMITED';
    final currentPath = GoRouterState.of(context).uri.toString();

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.slash): _focusSearch,
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // ── Top header ──────────────────────────────────────────────────
            _buildTopBar(orgName),
            // ── Main layout ─────────────────────────────────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPageTitle(),
                          _buildTabsRow(),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppTheme.borderLight,
                          ),
                          Expanded(
                            child:
                                _activeTab == CustomersAndVendorsTab.preferences
                                ? Scrollbar(
                                    controller: _contentScrollController,
                                    thumbVisibility: true,
                                    child: SingleChildScrollView(
                                      controller: _contentScrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        20,
                                        24,
                                        40,
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 600,
                                          ),
                                          child: _buildPreferencesContent(),
                                        ),
                                      ),
                                    ),
                                  )
                                : _buildPlaceholderContent(),
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

  Widget _buildTopBar(String orgName) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              LucideIcons.chevronLeft,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => context.go(_withOrgPrefix(AppRoutes.settings)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Settings',
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                orgName,
                style: AppTheme.captionText.copyWith(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SettingsSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              items: const [],
            ),
          ),
          const SizedBox(width: 24),
          TextButton.icon(
            onPressed: () => context.go(_withOrgPrefix(AppRoutes.home)),
            icon: const Icon(LucideIcons.x, size: 14),
            label: const Text('Close Settings'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              textStyle: AppTheme.bodyText.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Text(
        'Customers and Vendors',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTabsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildTabItem(CustomersAndVendorsTab.preferences, 'Preferences'),
          _buildTabItem(CustomersAndVendorsTab.fields, 'Fields'),
          _buildTabItem(CustomersAndVendorsTab.buttons, 'Buttons'),
          _buildTabItem(CustomersAndVendorsTab.relatedLists, 'Related Lists'),
        ],
      ),
    );
  }

  Widget _buildTabItem(CustomersAndVendorsTab tab, String label) {
    final bool isActive = _activeTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderContent() {
    return Center(
      child: Text(
        'This section is not configurable yet.',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildPreferencesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Allow duplicates checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: _allowDuplicates,
                activeColor: AppTheme.primaryBlue,
                onChanged: (val) {
                  setState(() {
                    _allowDuplicates = val ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Allow duplicates for customer and vendor display name.',
                style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: AppTheme.borderLight, height: 1),
        const SizedBox(height: 20),

        // 2. Customer & Vendor Numbers
        const Text(
          'Customer & Vendor Numbers',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Generate customer and vendor numbers automatically. You can configure the series in which numbers are generated while creating new records.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Opacity(
              opacity: 0.5,
              child: SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: true,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Enable Customer Numbers',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Opacity(
              opacity: 0.5,
              child: SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: true,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (_) {},
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Enable Vendor Numbers',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: AppTheme.borderLight, height: 1),
        const SizedBox(height: 20),

        // 3. Default Customer Type
        const Text(
          'Default Customer Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select the default customer type based on the kind of customers you usually sell your products or services to. The default customer type will be pre-selected in the customer creation form.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Radio<String>(
                  value: 'Business',
                  groupValue: _defaultCustomerType,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      if (val != null) _defaultCustomerType = val;
                    });
                  },
                ),
                const Text(
                  'Business',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
              ],
            ),
            Row(
              children: [
                Radio<String>(
                  value: 'Individual',
                  groupValue: _defaultCustomerType,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (val) {
                    setState(() {
                      if (val != null) _defaultCustomerType = val;
                    });
                  },
                ),
                const Text(
                  'Individual',
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: AppTheme.borderLight, height: 1),
        const SizedBox(height: 20),

        // 4. Customer Credit Limit
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Customer Credit Limit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  _creditLimitEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontSize: 13,
                    color: _creditLimitEnabled
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _CustomMiniSwitch(
                  value: _creditLimitEnabled,
                  onChanged: (val) {
                    setState(() {
                      _creditLimitEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Credit Limit enables you to set limit on the outstanding receivable amount of the customers.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        if (_creditLimitEnabled) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What do you want to do when credit limit is exceeded?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Restrict',
                      groupValue: _creditLimitExceededAction,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          if (val != null) _creditLimitExceededAction = val;
                        });
                      },
                    ),
                    const Text(
                      'Restrict creating or updating invoices',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: 'Show warning',
                      groupValue: _creditLimitExceededAction,
                      activeColor: AppTheme.primaryBlue,
                      onChanged: (val) {
                        setState(() {
                          if (val != null) _creditLimitExceededAction = val;
                        });
                      },
                    ),
                    const Text(
                      'Show a warning and allow users to proceed',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: Checkbox(
                          value: _includeSalesOrdersInLimit,
                          activeColor: AppTheme.primaryBlue,
                          onChanged: (val) {
                            setState(() {
                              _includeSalesOrdersInLimit = val ?? false;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Include sales orders' amount in limiting the credit given to customers",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Credit Limit will not affect the creation of sales orders from marketplace, Zoho POS Registers and Zoho Commerce.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Note:\n• Go to the respective customer\'s contact details to set the credit limit.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Divider(color: AppTheme.borderLight, height: 1),
        const SizedBox(height: 20),

        // 5. Multi-currency Transactions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Multi-currency Transactions for Each Contact',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  _multiCurrencyEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontSize: 13,
                    color: _multiCurrencyEnabled
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _CustomMiniSwitch(
                  value: _multiCurrencyEnabled,
                  onChanged: (val) {
                    setState(() {
                      _multiCurrencyEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Create sales and purchase transactions in multiple currencies for each of your customers and vendors. You can then run reports in the base and associated foreign currencies.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        const Divider(color: AppTheme.borderLight, height: 1),
        const SizedBox(height: 20),

        // 6. Billing Address Format
        Row(
          children: [
            const Text(
              'Customer and Vendor Billing Address Format ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Text(
              '(Displayed in PDF only)',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 4),
            const ZTooltip(
              message:
                  'Placeholders and characters like comma, space, -, , : are allowed.',
              child: Icon(
                LucideIcons.helpCircle,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAddressFormatContainer(
          _billingAddressController,
          7,
          _billingLayerLink,
        ),
        const SizedBox(height: 24),
        const Divider(color: AppTheme.borderLight, height: 1),
        const SizedBox(height: 20),

        // 7. Shipping Address Format
        Row(
          children: [
            const Text(
              'Customer and Vendor Shipping Address Format ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Text(
              '(Displayed in PDF only)',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(width: 4),
            const ZTooltip(
              message:
                  'Placeholders and characters like comma, space, -, , : are allowed.',
              child: Icon(
                LucideIcons.helpCircle,
                size: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAddressFormatContainer(
          _shippingAddressController,
          6,
          _shippingLayerLink,
        ),
        const SizedBox(height: 32),

        // 8. Save Button
        ElevatedButton(
          onPressed: _saveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Save',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressFormatContainer(
    TextEditingController controller,
    int maxLines,
    LayerLink link,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
            ),
            child: Row(
              children: [
                CompositedTransformTarget(
                  link: link,
                  child: _buildInsertPlaceholdersDropdown(link, controller),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
          Stack(
            children: [
              TextField(
                controller: controller,
                maxLines: maxLines,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.fromLTRB(12, 12, 24, 16),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: CustomPaint(
                  size: const Size(8, 8),
                  painter: _ResizeHandlePainter(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsertPlaceholdersDropdown(
    LayerLink link,
    TextEditingController targetController,
  ) {
    return InkWell(
      onTap: () => _showPlaceholderDropdown(context, link, targetController),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Insert Placeholders',
              style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
            SizedBox(width: 8),
            Icon(
              LucideIcons.chevronDown,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResizeHandlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(size.width - 2, size.height),
      Offset(size.width, size.height - 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - 5, size.height),
      Offset(size.width, size.height - 5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CustomMiniSwitch extends StatelessWidget {
  const _CustomMiniSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 20,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: value ? AppTheme.primaryBlue : const Color(0xFFCBD5E1),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x2B000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderDropdownOverlay extends StatefulWidget {
  const _PlaceholderDropdownOverlay({
    required this.link,
    required this.onClose,
    required this.onSelect,
  });

  final LayerLink link;
  final VoidCallback onClose;
  final ValueChanged<String> onSelect;

  @override
  State<_PlaceholderDropdownOverlay> createState() =>
      _PlaceholderDropdownOverlayState();
}

class _PlaceholderDropdownOverlayState
    extends State<_PlaceholderDropdownOverlay> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _contactItems = [
    {'label': 'Display Name', 'value': 'CONTACT.CONTACT_DISPLAYNAME'},
    {'label': 'Company Name', 'value': 'CONTACT.CONTACT_COMPANYNAME'},
    {'label': 'Website', 'value': 'CONTACT.CONTACT_WEBSITE'},
    {'label': 'Salutation', 'value': 'CONTACT.CONTACT_SALUTATION'},
    {'label': 'First Name', 'value': 'CONTACT.CONTACT_FIRSTNAME'},
    {'label': 'Last Name', 'value': 'CONTACT.CONTACT_LASTNAME'},
    {'label': 'Contact Email', 'value': 'CONTACT.CONTACT_EMAIL'},
    {'label': 'Mobile Phone', 'value': 'CONTACT.CONTACT_MOBILE'},
    {'label': 'Phone Label', 'value': 'CONTACT.CONTACT_PHONE_LABEL'},
    {'label': 'Phone', 'value': 'CONTACT.CONTACT_PHONE'},
    {'label': 'Department', 'value': 'CONTACT.CONTACT_DEPARTMENT'},
    {'label': 'Designation', 'value': 'CONTACT.CONTACT_DESIGNATION'},
    {'label': 'PAN Label', 'value': 'CONTACT.CONTACT_PAN_LABEL'},
    {'label': 'PAN', 'value': 'CONTACT.CONTACT_PAN'},
    {'label': 'GSTIN Label', 'value': 'CONTACT.CONTACT_GSTIN_LABEL'},
    {'label': 'GSTIN', 'value': 'CONTACT.CONTACT_GSTIN'},
    {'label': 'Contact Number', 'value': 'CONTACT.CONTACT_NUMBER'},
  ];

  final List<Map<String, String>> _addressItems = [
    {'label': 'Attention', 'value': 'CONTACT.CONTACT_ATTENTION'},
    {'label': 'Street Address', 'value': 'CONTACT.CONTACT_ADDRESS'},
    {'label': 'Street Address1', 'value': 'CONTACT.CONTACT_STREET1'},
    {'label': 'Street Address2', 'value': 'CONTACT.CONTACT_STREET2'},
    {'label': 'City', 'value': 'CONTACT.CONTACT_CITY'},
    {'label': 'State/Province', 'value': 'CONTACT.CONTACT_STATE'},
    {'label': 'Country', 'value': 'CONTACT.CONTACT_COUNTRY'},
    {'label': 'ZIP/Postal Code', 'value': 'CONTACT.CONTACT_CODE'},
    {'label': 'Fax Label', 'value': 'CONTACT.CONTACT_FAX_LABEL'},
    {'label': 'Phone', 'value': 'CONTACT.CONTACT_PHONE'},
    {'label': 'Fax', 'value': 'CONTACT.CONTACT_FAX'},
  ];

  String? _hoveredValue;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _contactItems
        .where(
          (item) => item['label']!.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final filteredAddresses = _addressItems
        .where(
          (item) => item['label']!.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onClose,
          behavior: HitTestBehavior.translucent,
          child: Container(),
        ),
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          offset: const Offset(0, 32),
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 440,
              height: 380,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          const Icon(
                            LucideIcons.search,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _queryController,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _query = val;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildColumnGroup(
                                title: 'CONTACT',
                                items: filteredContacts,
                              ),
                            ),
                            Expanded(
                              child: _buildColumnGroup(
                                title: 'ADDRESS',
                                items: filteredAddresses,
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
      ],
    );
  }

  Widget _buildColumnGroup({
    required String title,
    required List<Map<String, String>> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items.map((item) {
          final label = item['label']!;
          final val = item['value']!;
          final isHovered = _hoveredValue == val;

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredValue = val),
            onExit: (_) => setState(() => _hoveredValue = null),
            child: GestureDetector(
              onTap: () => widget.onSelect(val),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: isHovered ? AppTheme.primaryBlue : Colors.transparent,
                width: double.infinity,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHovered ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isHovered ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
