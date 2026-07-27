import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/shared_field_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:intl/intl.dart';
import '../../../../shared/utils/zerpai_toast.dart';
import '../../../auth/controller/auth_controller.dart';
import '../../../../core/services/api_client.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/modules/accountant/repositories/accountant_repository.dart';
import 'package:zerpai_erp/modules/settings/shared/data/repositories/settings_preferences_repository.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

class AccountantSettingsScreen extends ConsumerStatefulWidget {
  const AccountantSettingsScreen({super.key});

  @override
  ConsumerState<AccountantSettingsScreen> createState() =>
      _AccountantSettingsScreenState();
}

class _AccountantSettingsScreenState
    extends ConsumerState<AccountantSettingsScreen> {
  final _fiscalYearStartKey = GlobalKey();
  DateTime _fiscalYearStart = DateTime(DateTime.now().year, 4, 1);
  String? _baseCurrency;
  String _roundingType = 'Normal Rounding';
  bool _enableTax = true;
  bool _isSaving = false;
  bool _isLoading = true;
  bool _isDirty = false;
  Object? _loadError;
  String? _fiscalYearId;
  List<String> _currencyCodes = const [];
  late final TextEditingController _fiscalYearController;
  late final SettingsPreferencesRepository _preferencesRepository;

  @override
  void initState() {
    super.initState();
    _fiscalYearController = TextEditingController();
    _preferencesRepository = SettingsPreferencesRepository(
      apiClient: ref.read(apiClientProvider),
    );
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _fiscalYearController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait<dynamic>([
        api.get('accountant/fiscal-years', useCache: false),
        ref.read(accountantRepositoryProvider).getCurrencies(),
        ref.read(orgSettingsProvider.future),
        _preferencesRepository.loadSection('charges_preferences', const [
          'accounting',
        ]),
      ]);
      final fiscalRows = (results[0].data as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      final fiscalYear = fiscalRows.isEmpty ? null : fiscalRows.first;
      final currencies = results[1] as List;
      final orgSettings = results[2];
      final preferences = results[3] as Map<String, dynamic>;
      if (currencies.isEmpty) {
        throw StateError('No active currencies are configured');
      }
      if (!mounted) return;
      final startDate = fiscalYear == null
          ? DateTime(DateTime.now().year, 4, 1)
          : DateTime.parse(fiscalYear['start_date'].toString());
      setState(() {
        _fiscalYearId = fiscalYear?['id']?.toString();
        _fiscalYearStart = startDate;
        _fiscalYearController.text = DateFormat(
          'dd MMM yyyy',
        ).format(startDate);
        _currencyCodes = currencies
            .map((currency) => currency.code.toString())
            .where((code) => code.trim().isNotEmpty)
            .toSet()
            .toList();
        final configuredCurrency = orgSettings?.baseCurrency?.toString().trim();
        _baseCurrency =
            configuredCurrency != null &&
                _currencyCodes.contains(configuredCurrency)
            ? configuredCurrency
            : null;
        _roundingType =
            preferences['rounding_type']?.toString() ?? 'Normal Rounding';
        _enableTax =
            preferences['enable_tax_digital_compliance'] as bool? ?? true;
        _isLoading = false;
        _isDirty = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error;
      });
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _save() async {
    final baseCurrency = _baseCurrency;
    if (baseCurrency == null || baseCurrency.isEmpty) {
      ZerpaiToast.error(context, 'Select a configured base currency.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);
      final authUser = ref.read(authUserProvider);
      final orgId = authUser?.orgId;
      if (orgId == null || orgId.trim().isEmpty) {
        throw StateError('No active organization is selected');
      }

      final fiscalYearEnd = DateTime(
        _fiscalYearStart.year + 1,
        _fiscalYearStart.month,
        _fiscalYearStart.day,
      ).subtract(const Duration(days: 1));
      final fiscalResponse = await api.post(
        'accountant/fiscal-years',
        data: {
          if (_fiscalYearId != null) 'id': _fiscalYearId,
          'name': 'FY ${_fiscalYearStart.year}-${fiscalYearEnd.year}',
          'start_date': _dateOnly(_fiscalYearStart),
          'end_date': _dateOnly(fiscalYearEnd),
          'is_active': true,
        },
      );
      _fiscalYearId =
          (fiscalResponse.data as Map?)?['id']?.toString() ?? _fiscalYearId;
      await api.post(
        '/lookups/org/$orgId/save',
        data: {'base_currency': baseCurrency},
      );
      await _preferencesRepository.saveSection(
        'charges_preferences',
        {
          'rounding_type': _roundingType,
          'enable_tax_digital_compliance': _enableTax,
        },
        const ['accounting'],
      );
      ref.invalidate(orgSettingsProvider);

      if (mounted) {
        setState(() => _isDirty = false);
        ZerpaiToast.success(context, 'Accounting settings saved');
      }
    } catch (error) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to save settings: $error');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Accounting Settings',
      isDirty: _isDirty,
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(AppTheme.space32),
              child: ZFormSkeleton(rows: 4),
            )
          : _loadError != null
          ? ZErrorPlaceholder(
              error: _loadError!,
              message: 'Unable to load accounting settings',
              onRetry: _load,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.space32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'General Settings',
                    icon: LucideIcons.settings,
                    children: [
                      SharedFieldLayout(
                        label: 'Fiscal Year Start',
                        required: true,
                        tooltip:
                            'The starting date of your business financial/reporting year.',
                        child: InkWell(
                          key: _fiscalYearStartKey,
                          onTap: () async {
                            final picked = await ZerpaiDatePicker.show(
                              context,
                              initialDate: _fiscalYearStart,
                              targetKey: _fiscalYearStartKey,
                            );
                            if (picked != null) {
                              setState(() {
                                _fiscalYearStart = picked;
                                _fiscalYearController.text = DateFormat(
                                  'dd MMM yyyy',
                                ).format(picked);
                              });
                              _markDirty();
                            }
                          },
                          child: CustomTextField(
                            controller: _fiscalYearController,
                            enabled: false,
                            suffixWidget: const Icon(
                              LucideIcons.calendar,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      SharedFieldLayout(
                        label: 'Base Currency',
                        required: true,
                        tooltip:
                            'The primary currency used for all business operations and final accounting reports.',
                        child: FormDropdown<String>(
                          value: _baseCurrency,
                          items: _currencyCodes,
                          hint: 'Select base currency',
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _baseCurrency = v);
                            _markDirty();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space32),
                  _buildSection(
                    title: 'Rounding & Tax',
                    icon: LucideIcons.percent,
                    children: [
                      SharedFieldLayout(
                        label: 'Rounding Type',
                        tooltip:
                            'How fraction amounts are treated across system-wide invoice/bill totals.',
                        child: FormDropdown<String>(
                          value: _roundingType,
                          items: const [
                            'Normal Rounding',
                            'Round Up',
                            'Round Down',
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() => _roundingType = v);
                            _markDirty();
                          },
                        ),
                      ),
                      SwitchListTile(
                        title: const Text(
                          'Enable Tax Digital Compliance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: const Text(
                          'Automatically validate GSTIN and calculate tax components.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        value: _enableTax,
                        onChanged: (v) {
                          setState(() => _enableTax = v);
                          _markDirty();
                        },
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space40),
                  Row(
                    children: [
                      ZButton.primary(
                        label: _isSaving ? 'Saving...' : 'Save Settings',
                        onPressed: _isSaving ? null : _save,
                      ),
                      const SizedBox(width: 12),
                      ZButton.secondary(
                        label: 'Reset Changes',
                        onPressed: _isSaving ? null : _load,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primaryBlue),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppTheme.borderColor),
          ...children,
        ],
      ),
    );
  }
}
