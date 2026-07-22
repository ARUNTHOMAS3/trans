import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/shared/widgets/settings_page_header.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/modules/settings/taxes/models/settings_tax_rate_model.dart';
import 'package:zerpai_erp/modules/settings/taxes/providers/settings_tax_rates_provider.dart';
import 'package:zerpai_erp/modules/settings/taxes/presentation/widgets/settings_taxes_section_rail.dart';

class SettingsTaxCreatePage extends ConsumerStatefulWidget {
  const SettingsTaxCreatePage({super.key});

  @override
  ConsumerState<SettingsTaxCreatePage> createState() =>
      _SettingsTaxCreatePageState();
}

class _SettingsTaxCreatePageState extends ConsumerState<SettingsTaxCreatePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  String? _taxType;
  String? _nameError;
  String? _rateError;
  String? _typeError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String get _orgSystemId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  void _cancel() {
    context.go('/$_orgSystemId${AppRoutes.settingsTaxes}');
  }

  void _openTaxesSection(String section) {
    context.go('/$_orgSystemId${AppRoutes.settingsTaxes}?section=$section');
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final rate = double.tryParse(_rateController.text.trim());
    setState(() {
      _nameError = name.isEmpty ? 'Tax name is required' : null;
      _rateError = rate == null || rate < 0 || rate > 100
          ? 'Enter a rate from 0 to 100'
          : null;
      _typeError = null;
    });
    if (_nameError != null || _rateError != null || _typeError != null) return;

    final saved = await ref
        .read(settingsTaxRatesProvider.notifier)
        .createTax(name: name, type: _taxType ?? 'IGST', rate: rate!);
    if (!mounted) return;
    if (saved) {
      ZerpaiToast.success(context, 'Tax created successfully');
      _cancel();
    } else {
      ZerpaiToast.error(context, 'Unable to create tax');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(settingsTaxRatesProvider).isSaving;
    final currentPath = GoRouterState.of(context).uri.path;
    final orgName =
        ref.watch(authUserProvider)?.orgName.trim() ??
        'ORGANIZATION';
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSettingsSidebar = constraints.maxWidth >= 980;
        return Column(
          children: [
            SettingsPageHeader(
              orgName: orgName,
              searchItems: [
                SettingsSearchItem(
                  group: 'Taxes & Compliance',
                  label: 'Taxes',
                  onSelected: _cancel,
                ),
              ],
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSettingsSidebar)
                    SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (constraints.maxWidth >= 700)
                            SettingsTaxesSectionRail(
                              width: 240,
                              selected: 'taxRates',
                              onSelected: _openTaxesSection,
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                _buildHeader(),
                                Expanded(child: _buildForm()),
                                _buildFooter(isSaving),
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
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: InkWell(
        onTap: _cancel,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.chevronLeft,
              size: 18,
              color: AppTheme.primaryBlueDark,
            ),
            const SizedBox(width: 4),
            Text(
              'New Tax',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            _formRow(
              label: 'Tax Name*',
              required: true,
              child: CustomTextField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                errorText: _nameError,
                height: 34,
              ),
            ),
            const SizedBox(height: 20),
            _formRow(
              label: 'Rate (%)*',
              required: true,
              child: CustomTextField(
                controller: _rateController,
                errorText: _rateError,
                height: 34,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,3}(\.\d{0,2})?'),
                  ),
                ],
                suffixSeparator: true,
                suffixWidget: Container(
                  width: 38,
                  alignment: Alignment.center,
                  child: Text('%', style: AppTheme.bodyText),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _formRow(
              label: 'Tax Type',
              child: FormDropdown<String>(
                value: _taxType,
                items: const ['CGST', 'SGST', 'IGST', 'UTGST', 'Cess'],
                hint: 'Select a Tax Type.',
                placeholder: 'Search',
                showSearch: true,
                allowClear: true,
                showArrowOnSelection: true,
                height: 34,
                errorText: _typeError,
                onChanged: (value) => setState(() {
                  _taxType = value;
                  _typeError = null;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formRow({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 450.5) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    color: required ? AppTheme.errorRed : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                child,
              ],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              height: 34,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 14,
                    color: required ? AppTheme.errorRed : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            SizedBox(width: 300.5, child: child),
          ],
        );
      },
    );
  }

  Widget _buildFooter(bool isSaving) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          ZButton.primary(label: 'Save', loading: isSaving, onPressed: _save),
          const SizedBox(width: 10),
          ZButton.secondary(
            label: 'Cancel',
            onPressed: isSaving ? null : _cancel,
          ),
        ],
      ),
    );
  }
}

class SettingsTaxViewPage extends ConsumerWidget {
  const SettingsTaxViewPage({super.key, required this.taxId});

  final String taxId;

  String _orgSystemId(BuildContext context) =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  void _back(BuildContext context) {
    context.go('/${_orgSystemId(context)}${AppRoutes.settingsTaxes}');
  }

  void _openTaxesSection(BuildContext context, String section) {
    context.go(
      '/${_orgSystemId(context)}${AppRoutes.settingsTaxes}?section=$section',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsTaxRatesProvider);
    SettingsTaxRate? tax;
    for (final row in state.rates) {
      if (row.id == taxId) {
        tax = row;
        break;
      }
    }
    final currentPath = GoRouterState.of(context).uri.path;
    final orgName =
        ref.watch(authUserProvider)?.orgName.trim() ??
        'ORGANIZATION';

    return LayoutBuilder(
      builder: (context, constraints) {
        final showSettingsSidebar = constraints.maxWidth >= 980;
        return Column(
          children: [
            SettingsPageHeader(
              orgName: orgName,
              searchItems: [
                SettingsSearchItem(
                  group: 'Taxes & Compliance',
                  label: 'Taxes',
                  onSelected: () => _back(context),
                ),
              ],
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showSettingsSidebar)
                    SettingsNavigationSidebar(currentPath: currentPath),
                  Expanded(
                    child: ColoredBox(
                      color: Colors.white,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (constraints.maxWidth >= 700)
                            SettingsTaxesSectionRail(
                              width: 240,
                              selected: 'taxRates',
                              onSelected: (section) =>
                                  _openTaxesSection(context, section),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                _buildViewHeader(context),
                                Expanded(
                                  child: tax == null
                                      ? const Center(
                                          child:
                                              CircularProgressIndicator(),
                                        )
                                      : _buildViewForm(tax),
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
          ],
        );
      },
    );
  }

  Widget _buildViewHeader(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: InkWell(
        onTap: () => _back(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.chevronLeft,
              size: 18,
              color: AppTheme.primaryBlueDark,
            ),
            const SizedBox(width: 4),
            Text(
              'View Tax',
              style: AppTheme.pageTitle.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewForm(SettingsTaxRate tax) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 26, 22, 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          children: [
            _viewRow(
              label: 'Tax Name*',
              required: true,
              child: CustomTextField(
                controller: TextEditingController(text: tax.name),
                enabled: false,
                height: 34,
              ),
            ),
            const SizedBox(height: 20),
            _viewRow(
              label: 'Rate (%)*',
              required: true,
              child: CustomTextField(
                controller: TextEditingController(
                  text: tax.rate == tax.rate.roundToDouble()
                      ? tax.rate.toInt().toString()
                      : tax.rate.toString(),
                ),
                enabled: false,
                height: 34,
                suffixSeparator: true,
                suffixWidget: Container(
                  width: 38,
                  alignment: Alignment.center,
                  child: Text('%', style: AppTheme.bodyText),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _viewRow(
              label: 'Tax Type',
              child: FormDropdown<String>(
                value: tax.type.isEmpty ? null : tax.type.toUpperCase(),
                items: const ['IGST', 'CGST', 'SGST'],
                onChanged: (_) {},
                enabled: false,
                showSearch: false,
                allowClear: true,
                height: 34,
                fillColor: const Color(0xFFF3F4F6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewRow({
    required String label,
    required Widget child,
    bool required = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          height: 34,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                color: required ? AppTheme.errorRed : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
        SizedBox(width: 300.5, child: child),
      ],
    );
  }
}
