import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class InventoryShipmentsListScreen extends StatelessWidget {
  const InventoryShipmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(context),
          
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  'Filter By :',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Type: All',
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Column(
              children: [
                // Top Title & Subtitle
                Text(
                  'Ship with Confidence and Accuracy',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Create shipment records and track delivery status for your orders.',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/inventory/shipments/create');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'CREATE SHIPMENT',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 64),
                // Flowchart Section
                Text(
                  'Life cycle of Shipments',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 48),
                // The Diagram
                _buildFlowchart(),
                const SizedBox(height: 64),
                // Bottom Features
                Text(
                  'In the Shipments module, you can:',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Generate and manage outbound shipments.',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowchart() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNode('Sales Order Confirmed', LucideIcons.fileText, iconColor: const Color(0xFF0088FF), bgColor: const Color(0xFFEFF6FF)),
            _buildArrow(),
            _buildNode('Packages Created', LucideIcons.package, iconColor: const Color(0xFF0088FF), bgColor: const Color(0xFFEFF6FF)),
            _buildArrow(),
            _buildNode('Create Shipment', LucideIcons.filePlus, iconColor: const Color(0xFF7C3AED), bgColor: const Color(0xFFFAF5FF)),
            _buildArrow(),
            
            // Fork
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildNode('Via Carrier', LucideIcons.truck, iconColor: const Color(0xFF0088FF), bgColor: const Color(0xFFEFF6FF)),
                const SizedBox(height: 24),
                _buildNode('Manually', LucideIcons.clipboardList, iconColor: const Color(0xFF0088FF), bgColor: const Color(0xFFEFF6FF)),
              ],
            ),
            
            _buildArrow(),
            _buildNode('Shipped', LucideIcons.truck, iconColor: const Color(0xFF28A745), bgColor: const Color(0xFFECFDF5)),
            _buildArrow(),
            _buildNode('Delivered', LucideIcons.packageCheck, iconColor: const Color(0xFF28A745), bgColor: const Color(0xFFECFDF5)),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(String text, IconData icon, {required Color iconColor, required Color bgColor}) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, width: 24, color: const Color(0xFFE5E7EB)),
          const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }
  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'All Shipments',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'View EasyPost Usage',
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'easypost.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 24),
          const Icon(LucideIcons.search, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 20),
          const Icon(LucideIcons.filter, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 20),
          ZButton.primary(
            onPressed: () {
              context.go('/inventory/shipments/create');
            },
            icon: LucideIcons.plus,
            label: 'New',
          ),
          const SizedBox(width: 8),
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
