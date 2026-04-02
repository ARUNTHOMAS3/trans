import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../../shared/widgets/zerpai_layout.dart';

class InventoryPackagesCreateScreen extends StatefulWidget {
  const InventoryPackagesCreateScreen({super.key});

  @override
  State<InventoryPackagesCreateScreen> createState() => _InventoryPackagesCreateScreenState();
}

class _InventoryPackagesCreateScreenState extends State<InventoryPackagesCreateScreen> {
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderCol = Color(0xFFE5E7EB);
  static const Color _focusBorder = Color(0xFF3B82F6);
  static const Color _greenBtn = Color(0xFF10B981);
  static const Color _bgLight = Color(0xFFF9FAFB);

  String? _selectedCustomer;
  String? _selectedSalesOrder;
  final TextEditingController _packageSlipCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final GlobalKey _dateFieldKey = GlobalKey();
  DateTime? _selectedDate;

  bool get _isSalesOrderSelected => _selectedSalesOrder != null;

  bool get _isFormValid => _isSalesOrderSelected; // Add further mandatory validations as needed later

  @override
  void dispose() {
    _packageSlipCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(LucideIcons.box, size: 24, color: _textPrimary),
                const SizedBox(width: 12),
                const Text(
                  'New Package',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.x, size: 20, color: _textSecondary),
                  splashRadius: 20,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderCol),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1
                  _buildFormRow(
                    label: 'Customer Name',
                    child: SizedBox(
                      width: 350,
                      child: FormDropdown<String>(
                        value: _selectedCustomer,
                        hint: 'Select Customer',
                        items: const ['Customer A', 'Customer B'], // Placeholder UI only
                        displayStringForValue: (s) => s,
                        searchStringForValue: (s) => s,
                        itemBuilder: (item, isSelected, isHovered) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: isHovered ? const Color(0xFFEAF3FF) : Colors.transparent,
                          child: Text(item, style: const TextStyle(fontSize: 13, fontFamily: 'Inter')),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedCustomer = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFormRow(
                    label: 'Sales Order#',
                    isRequired: true,
                    child: SizedBox(
                      width: 350,
                      child: FormDropdown<String>(
                        value: _selectedSalesOrder,
                        hint: 'Select Sales Order',
                        items: const ['SO-001', 'SO-002'], // Placeholder UI only
                        displayStringForValue: (s) => s,
                        searchStringForValue: (s) => s,
                        itemBuilder: (item, isSelected, isHovered) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          color: isHovered ? const Color(0xFFEAF3FF) : Colors.transparent,
                          child: Text(item, style: const TextStyle(fontSize: 13, fontFamily: 'Inter')),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _selectedSalesOrder = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Conditional Dependent UI
                  Opacity(
                    opacity: _isSalesOrderSelected ? 1.0 : 0.3,
                    child: IgnorePointer(
                      ignoring: !_isSalesOrderSelected,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormRow(
                            label: 'Package Slip#',
                            isRequired: true,
                            child: SizedBox(
                              width: 350,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _packageSlipCtrl,
                                      style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                                      onChanged: (_) => setState(() {}),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _borderCol)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _borderCol)),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _focusBorder)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.settings, size: 16, color: _focusBorder),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFormRow(
                            label: 'Date',
                            isRequired: true,
                            child: SizedBox(
                              width: 350,
                              child: TextField(
                                controller: _dateCtrl,
                                readOnly: true,
                                key: _dateFieldKey,
                                onTap: () async {
                                  final picked = await ZerpaiDatePicker.show(
                                    context,
                                    initialDate: _selectedDate ?? DateTime.now(),
                                    targetKey: _dateFieldKey,
                                  );
                                  if (picked != null && mounted) {
                                    setState(() {
                                      _selectedDate = picked;
                                      _dateCtrl.text = "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
                                    });
                                  }
                                },
                                style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                                decoration: InputDecoration(
                                  hintText: 'dd-MM-yyyy',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _borderCol)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _borderCol)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _focusBorder)),
                                  suffixIcon: const Icon(LucideIcons.calendar, size: 16, color: _textSecondary),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB), // Light yellow warning banner
                              border: Border.all(color: const Color(0xFFFDE68A)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.info, size: 16, color: Color(0xFFD97706)),
                                const SizedBox(width: 8),
                                Text(
                                  'You can also select or scan the items to be included from the sales order.',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), fontFamily: 'Inter'),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () {},
                                  child: const Text('Select or Scan items', style: TextStyle(fontSize: 13, color: _focusBorder, fontFamily: 'Inter')),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Items Table
                          Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: _buildItemsTable(),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Internal Notes
                          const Text(
                            'INTERNAL NOTES',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary, fontFamily: 'Inter'),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 500,
                            child: TextField(
                              controller: _notesCtrl,
                              maxLines: 4,
                              style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                              decoration: InputDecoration(
                                hintText: '',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _borderCol)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _borderCol)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _focusBorder)),
                                fillColor: Colors.white,
                                filled: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Sticky Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: _borderCol)),
            ),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isFormValid ? () {} : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFormValid ? _greenBtn : const Color(0xFFE5E7EB),
                    foregroundColor: _isFormValid ? Colors.white : const Color(0xFF9CA3AF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    elevation: 0,
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: _borderCol),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    bool isRequired = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 180,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              if (isRequired)
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                    fontFamily: 'Inter',
                  ),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: _bgLight,
            border: Border(bottom: BorderSide(color: _borderCol)),
          ),
          child: Row(
            children: [
              const Expanded(flex: 3, child: Text('ITEMS & DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary, fontFamily: 'Inter'))),
              const Expanded(flex: 1, child: Text('ORDERED', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary, fontFamily: 'Inter'))),
              const Expanded(flex: 1, child: Text('PACKED', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary, fontFamily: 'Inter'))),
              const Expanded(flex: 1, child: Text('QUANTITY TO PACK', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary, fontFamily: 'Inter'))),
            ],
          ),
        ),
        // Empty State Body
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _borderCol)),
          ),
          child: const Center(
            child: Text(
              'No items found.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
