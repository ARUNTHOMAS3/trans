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
import '../../../shared/utils/zerpai_toast.dart';
import '../../auth/controller/auth_controller.dart';
import '../../../core/api/dio_client.dart';

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
  String _baseCurrency = 'INR';
  String _roundingType = 'Normal Rounding';
  bool _enableTax = true;
  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      final authUser = ref.read(authUserProvider);
      final orgId = authUser?.orgId;

      await dio.post(
        'accountant/fiscal-years',
        data: {'startDate': _fiscalYearStart.toIso8601String()},
        queryParameters: orgId != null ? {'orgId': orgId} : null,
      );

      if (mounted) ZerpaiToast.success(context, 'Settings saved');
    } catch (e) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save settings');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetToDefault() {
    setState(() {
      _fiscalYearStart = DateTime(DateTime.now().year, 4, 1);
      _baseCurrency = 'INR';
      _roundingType = 'Normal Rounding';
      _enableTax = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Accounting Settings',
      child: SingleChildScrollView(
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
                        setState(() => _fiscalYearStart = picked);
                      }
                    },
                    child: CustomTextField(
                      controller: TextEditingController(
                        text: DateFormat('dd MMM').format(_fiscalYearStart),
                      ),
                      enabled: false,
                      suffixWidget: const Icon(LucideIcons.calendar, size: 16),
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
                    items: const ['INR', 'USD', 'EUR', 'GBP'],
                    onChanged: (v) => setState(() => _baseCurrency = v!),
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
                    items: const ['Normal Rounding', 'Round Up', 'Round Down'],
                    onChanged: (v) => setState(() => _roundingType = v!),
                  ),
                ),
                SwitchListTile(
                  title: const Text(
                    'Enable Tax Digital Compliance',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text(
                    'Automatically validate GSTIN and calculate tax components.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  value: _enableTax,
                  onChanged: (v) => setState(() => _enableTax = v),
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
                  label: 'Reset to Default',
                  onPressed: _isSaving ? null : _resetToDefault,
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
