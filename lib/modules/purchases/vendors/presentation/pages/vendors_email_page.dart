import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository_impl.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

/// Full-page "Email To <vendor>" composer reached from the vendor overview's
/// More → Email Vendor action. Top section = recipients + subject + editor;
/// bottom section = attachment filter (location + vendor statement + uploads).
class VendorsEmailPage extends ConsumerStatefulWidget {
  final String vendorId;

  const VendorsEmailPage({super.key, required this.vendorId});

  @override
  ConsumerState<VendorsEmailPage> createState() => _VendorsEmailPageState();
}

class _VendorsEmailPageState extends ConsumerState<VendorsEmailPage> {
  bool _loading = true;
  Vendor? _vendor;

  final _toCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _bccCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  bool _showCc = false;
  bool _showBcc = false;
  bool _attachStatement = false;
  String _location = 'All Locations';

  static const List<String> _locationOptions = [
    'All Locations',
    'Head Office',
    'Branch',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _bccCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Vendor? vendor;
    try {
      vendor = await ref
          .read(vendorRepositoryProvider)
          .getVendorById(widget.vendorId);
    } catch (_) {
      // Leave fields blank if the vendor can't be loaded.
    }
    if (!mounted) return;
    setState(() {
      _vendor = vendor;
      _toCtrl.text = vendor?.email ?? '';
      _loading = false;
    });
  }

  String get _orgId =>
      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  void _backToOverview() {
    context.go('/$_orgId/purchases/vendors/${widget.vendorId}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final vendorName = _vendor?.displayName ?? 'Vendor';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email To $vendorName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildComposeCard(),
                  const SizedBox(height: 28),
                  _buildAttachmentsSection(),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildActions(),
          ),
        ],
      ),
    );
  }

  // ── Top: recipients + subject + editor ─────────────────────────────────────
  Widget _buildComposeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _emailRow(
            'Send To',
            _toCtrl,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ccBccLink('Cc', () => setState(() => _showCc = !_showCc)),
                const SizedBox(width: 12),
                _ccBccLink('Bcc', () => setState(() => _showBcc = !_showBcc)),
              ],
            ),
          ),
          if (_showCc) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _emailRow('Cc', _ccCtrl),
          ],
          if (_showBcc) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _emailRow('Bcc', _bccCtrl),
          ],
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _emailRow('Subject', _subjectCtrl),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildToolbar(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _bodyCtrl,
              maxLines: 12,
              minLines: 12,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: '',
              ),
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailRow(
    String label,
    TextEditingController ctrl, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: '',
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _ccBccLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    const iconColor = Color(0xFF4B5563);
    Widget icon(IconData i) => Icon(i, size: 18, color: iconColor);
    return Container(
      color: const Color(0xFFF1F5F0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          icon(LucideIcons.bold),
          icon(LucideIcons.italic),
          icon(LucideIcons.underline),
          icon(LucideIcons.strikethrough),
          const _ToolbarChip(label: '16px'),
          const _ToolbarChip(label: 'Arial', width: 90),
          icon(LucideIcons.indent),
          icon(LucideIcons.alignLeft),
          icon(LucideIcons.list),
          icon(LucideIcons.image),
          icon(LucideIcons.link),
        ],
      ),
    );
  }

  // ── Bottom: attachment filter ──────────────────────────────────────────────
  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filter and choose what to include in the email attachments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose whether to include transactions from all locations or a specific location. '
          'You can attach their unpaid invoices, vendor statement, or both.',
          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.45),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const SizedBox(
              width: 90,
              child: Text(
                'Location',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ),
            SizedBox(
              width: 300,
              child: FormDropdown<String>(
                value: _location,
                items: _locationOptions,
                onChanged: (value) {
                  if (value != null) setState(() => _location = value);
                },
                displayStringForValue: (value) => value,
                showSearch: false,
                height: 38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _checkbox(_attachStatement, (value) {
                setState(() => _attachStatement = value ?? false);
              }),
              const SizedBox(width: 12),
              const Text(
                'Attach Vendor Statement',
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DottedBorder(
          color: const Color(0xFFD1D5DB),
          strokeWidth: 1,
          dashPattern: const [5, 4],
          radius: const Radius.circular(6),
          borderType: BorderType.RRect,
          child: InkWell(
            onTap: () {},
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(LucideIcons.paperclip, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2563EB),
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

  Widget _buildActions() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            ZerpaiToast.success(context, 'Email sent successfully');
            _backToOverview();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text(
            'Send',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _backToOverview,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textPrimary,
            side: const BorderSide(color: AppTheme.borderColor),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('Cancel', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _checkbox(bool value, ValueChanged<bool?> onChanged) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Theme(
        data: Theme.of(context).copyWith(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          checkboxTheme: CheckboxThemeData(
            side: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ),
            fillColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? const Color(0xFF2563EB)
                  : Colors.white,
            ),
            checkColor: const WidgetStatePropertyAll(Colors.white),
          ),
        ),
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF2563EB),
        ),
      ),
    );
  }
}

class _ToolbarChip extends StatelessWidget {
  final String label;
  final double width;

  const _ToolbarChip({required this.label, this.width = 70});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
          ),
          const Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: Color(0xFF6B7280),
          ),
        ],
      ),
    );
  }
}
