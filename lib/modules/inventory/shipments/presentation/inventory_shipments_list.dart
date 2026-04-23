import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class InventoryShipmentsListScreen extends StatelessWidget {
  const InventoryShipmentsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color _textPrimary = Color(0xFF16191E);
    const Color _textSecondary = Color(0xFF6B7280);
    const Color _greenBtn = Color(0xFF28A745);
    const Color _borderCol = Color(0xFFE5E7EB);

    return ZerpaiLayout(
      pageTitle: '', // Custom title below
      enableBodyScroll: true,
      useHorizontalPadding: false,
      useTopPadding: false,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'View EasyPost Usage',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter',
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
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/inventory/shipments/create');
              },
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text(
                'New',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _greenBtn,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: _borderCol),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                LucideIcons.moreHorizontal,
                size: 16,
                color: _textSecondary,
              ),
            ),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // custom header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                const Text(
                  'All Shipments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: Color(0xFF0088FF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _borderCol)),
            ),
            child: Row(
              children: [
                const Text(
                  'Filter By :',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _borderCol),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Type: All',
                        style: TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(LucideIcons.chevronDown, size: 14, color: _textSecondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  // Top Title & Subtitle
                  const Text(
                    'Ship with Confidence and Accuracy',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create shipment records and track delivery status for your orders.',
                    style: TextStyle(
                      fontSize: 15,
                      color: _textSecondary,
                      fontFamily: 'Inter',
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
                        backgroundColor: const Color(0xFF28A745),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'CREATE SHIPMENT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // Flowchart Section
                  const Text(
                    'Life cycle of Shipments',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // The Diagram
                  _buildFlowchart(),
                  
                  const SizedBox(height: 64),
                  
                  // Bottom Features
                  const Text(
                    'In the Shipments module, you can:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0088FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.check, size: 10, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Generate and manage outbound shipments.',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                fontFamily: 'Inter',
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
}
