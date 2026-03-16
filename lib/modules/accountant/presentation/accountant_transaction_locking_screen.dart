import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import '../models/transaction_lock_model.dart';
import '../providers/transaction_lock_provider.dart';

class AccountantTransactionLockingScreen extends ConsumerStatefulWidget {
  const AccountantTransactionLockingScreen({super.key});

  @override
  ConsumerState<AccountantTransactionLockingScreen> createState() =>
      _AccountantTransactionLockingScreenState();
}

class _AccountantTransactionLockingScreenState
    extends ConsumerState<AccountantTransactionLockingScreen> {
  bool _showConfig = false;
  String _negativeStockMode = 'restrict'; // 'allow' or 'restrict'

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Transaction Locking',
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Transaction locking prevents you and your users from making any changes to transactions that might affect your accounts. Once transactions are locked, users cannot edit, modify, or delete any transactions that were recorded before the specified date in this module.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space40),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Restrict transaction locking with negative stock ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9A3412),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _showConfig = true),
                            child: const Text(
                              'Configure',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space40),
                _buildLockItem(
                  icon: LucideIcons.lock,
                  title: 'Sales',
                  onInfoTap: () {},
                  lock: ref.watch(transactionLockProvider)['Sales'],
                  onLockTap: () => _showLockDialog('Sales'),
                ),
                const SizedBox(height: AppTheme.space24),
                _buildLockItem(
                  icon: LucideIcons.lock,
                  title: 'Purchases',
                  onInfoTap: () {},
                  lock: ref.watch(transactionLockProvider)['Purchases'],
                  onLockTap: () => _showLockDialog('Purchases'),
                ),
                const SizedBox(height: AppTheme.space24),
                _buildLockItem(
                  icon: LucideIcons.lock,
                  title: 'Banking',
                  onInfoTap: () {},
                  lock: ref.watch(transactionLockProvider)['Banking'],
                  onLockTap: () => _showLockDialog('Banking'),
                ),
                const SizedBox(height: AppTheme.space24),
                _buildLockItem(
                  icon: LucideIcons.lock,
                  title: 'Accountant',
                  onInfoTap: () {},
                  lock: ref.watch(transactionLockProvider)['Accountant'],
                  onLockTap: () => _showLockDialog('Accountant'),
                ),
                const SizedBox(height: AppTheme.space64),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: AppTheme.space24),
                _buildLockAllSection(),
              ],
            ),
          ),
          if (_showConfig) _buildConfigPopup(),
        ],
      ),
    );
  }

  void _showLockDialog(String moduleName) {
    final lock = ref.read(transactionLockProvider)[moduleName];
    if (lock != null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Unlock Module'),
              content: Text('Are you sure you want to unlock $moduleName transactions?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref
                        .read(transactionLockProvider.notifier)
                        .unlockModule(moduleName);
                  },
                  child: const Text('Unlock'),
                ),
              ],
            ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _LockModuleDialog(moduleName: moduleName),
    );
  }

  Widget _buildConfigPopup() {
    return Positioned(
      top: 80,
      right: 32,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.space24),
              child: Column(
                children: [
                  _buildConfigOption(
                    id: 'allow',
                    title: 'Allow transaction locking with negative stock',
                    description:
                        'You can lock transactions even with negative stock. The system uses the Purchase Rate from recent transactions as a temporary COGS. This COGS is automatically updated once the related purchase is recorded, which may change the locked period\'s financial data.',
                  ),
                  const SizedBox(height: AppTheme.space24),
                  _buildConfigOption(
                    id: 'restrict',
                    title: 'Restrict transaction locking with negative stock',
                    description:
                        'Transaction locking will not be allowed if any item has negative stock. You can lock transactions only after stock becomes zero or positive, ensuring that all sales use the correct Cost of Goods Sold (COGS).',
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.bgLight,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  ZButton.primary(
                    onPressed: () => setState(() => _showConfig = false),
                    label: 'Apply',
                  ),
                  const SizedBox(width: 8),
                  ZButton.secondary(
                    onPressed: () => setState(() => _showConfig = false),
                    label: 'Cancel',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigOption({
    required String id,
    required String title,
    required String description,
  }) {
    final isSelected = _negativeStockMode == id;
    return InkWell(
      onTap: () => setState(() => _negativeStockMode = id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 20,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
          ),
          const SizedBox(width: AppTheme.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockItem({
    required IconData icon,
    required String title,
    required VoidCallback onInfoTap,
    TransactionLock? lock,
    required VoidCallback onLockTap,
  }) {
    final isLocked = lock != null;
    final statusText = isLocked
        ? 'Transactions are locked until ${DateFormat('dd MMM yyyy').format(lock.lockDate)}'
        : 'You have not locked the transactions in this module.';

    return Container(
      padding: const EdgeInsets.all(AppTheme.space24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 20, color: AppTheme.textMuted),
          ),
          const SizedBox(width: AppTheme.space24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: onInfoTap,
                      child: const Icon(
                        LucideIcons.helpCircle,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isLocked ? AppTheme.primaryBlue : AppTheme.textMuted,
                    fontWeight: isLocked ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onLockTap,
            icon: Icon(
              isLocked ? LucideIcons.unlock : LucideIcons.lock,
              size: 14,
            ),
            label: Text(isLocked ? 'Unlock' : 'Lock'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockAllSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lock All Transactions At Once',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'You can freeze all transactions at once instead of locking the Sales, Purchases, Banking and Account transactions individually.',
                style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTheme.space24),
        TextButton(
          onPressed: () => _showLockAllDialog(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Switch to Lock All Transactions'),
              const SizedBox(width: 4),
              const Icon(LucideIcons.arrowRight, size: 14),
            ],
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showLockAllDialog() {
    showDialog(
      context: context,
      builder: (context) => _LockAllDialog(
        onConfirm: (date, reason) async {
          final notifier = ref.read(transactionLockProvider.notifier);
          for (final module in ['Sales', 'Purchases', 'Banking', 'Accountant']) {
            await notifier.lockModule(
              moduleName: module,
              lockDate: date,
              reason: reason,
            );
          }
        },
      ),
    );
  }
}

class _LockAllDialog extends ConsumerStatefulWidget {
  final Future<void> Function(DateTime date, String reason) onConfirm;

  const _LockAllDialog({required this.onConfirm});

  @override
  ConsumerState<_LockAllDialog> createState() => _LockAllDialogState();
}

class _LockAllDialogState extends ConsumerState<_LockAllDialog> {
  final _dateKey = GlobalKey();
  final _dateController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  DateTime _selectedDate = DateTime.now();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lock All Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                    color: AppTheme.textMuted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 32, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will lock Sales, Purchases, Banking, and Accountant transactions up to the selected date.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  const Text(
                    'Lock Date *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 350,
                    child: TextField(
                      key: _dateKey,
                      controller: _dateController,
                      readOnly: true,
                      onTap: () async {
                        final date = await ZerpaiDatePicker.show(
                          context,
                          initialDate: _selectedDate,
                          targetKey: _dateKey,
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                            _dateController.text =
                                DateFormat('dd/MM/yyyy').format(date);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppTheme.borderColor),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  const Text(
                    'Reason *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 0, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  ZButton.primary(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            if (_reasonController.text.trim().isEmpty) return;
                            setState(() => _isLoading = true);
                            await widget.onConfirm(
                                _selectedDate, _reasonController.text.trim());
                            if (mounted) Navigator.pop(context);
                          },
                    label: _isLoading ? 'Locking...' : 'Lock All',
                  ),
                  const SizedBox(width: 8),
                  ZButton.secondary(
                    onPressed: () => Navigator.pop(context),
                    label: 'Cancel',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}

class _LockModuleDialog extends ConsumerStatefulWidget {
  final String moduleName;

  const _LockModuleDialog({required this.moduleName});

  @override
  ConsumerState<_LockModuleDialog> createState() => _LockModuleDialogState();
}

class _LockModuleDialogState extends ConsumerState<_LockModuleDialog> {
  final _dateKey = GlobalKey();
  final _dateController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  DateTime _selectedDate = DateTime.now();
  final _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lock - ${widget.moduleName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, size: 20),
                    color: AppTheme.textMuted,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 32, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Lock Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(
                            0xFFEF4444,
                          ), // Red color as per screenshot
                        ),
                      ),
                      const Text(
                        '*',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.helpCircle,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 350,
                    child: TextField(
                      key: _dateKey,
                      controller: _dateController,
                      readOnly: true,
                      onTap: () async {
                        final date = await ZerpaiDatePicker.show(
                          context,
                          initialDate: _selectedDate,
                          targetKey: _dateKey,
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                            _dateController.text = DateFormat(
                              'dd/MM/yyyy',
                            ).format(date);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppTheme.borderColor,
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                  Row(
                    children: [
                      const Text(
                        'Reason',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const Text(
                        '*',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderColor,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Divider(height: 0, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  ZButton.primary(
                    onPressed: () async {
                      await ref
                          .read(transactionLockProvider.notifier)
                          .lockModule(
                            moduleName: widget.moduleName,
                            lockDate: _selectedDate,
                            reason: _reasonController.text,
                          );
                      if (mounted) Navigator.pop(context);
                    },
                    label: 'Lock',
                  ),
                  const SizedBox(width: 8),
                  ZButton.secondary(
                    onPressed: () => Navigator.pop(context),
                    label: 'Cancel',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
}
