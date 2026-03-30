import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../shared/widgets/zerpai_layout.dart';
import '../../../../shared/widgets/inputs/z_tooltip.dart';

class InventoryPackagesListScreen extends StatefulWidget {
  const InventoryPackagesListScreen({super.key});

  @override
  State<InventoryPackagesListScreen> createState() =>
      _InventoryPackagesListScreenState();
}

class _InventoryPackagesListScreenState
    extends State<InventoryPackagesListScreen> {
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderCol = Color(0xFFE5E7EB);
  static const Color _greenBtn = Color(0xFF10B981);

  // Column Colors – exact Zoho match
  static const Color _col1Bg = Color(0xFFD9F3F7); // Packages, Not Shipped
  static const Color _col2Bg = Color(0xFFF6EDB7); // Shipped Packages
  static const Color _col3Bg = Color(0xFFDDEDC8); // Delivered Packages

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: _borderCol),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  ZTooltip(
                    message: 'List View',
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: const Icon(
                          LucideIcons.list,
                          size: 14,
                          color: _textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Container(width: 1, color: _borderCol),
                  ZTooltip(
                    message: 'Kanban View',
                    child: InkWell(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        color: Colors.white,
                        child: const Icon(
                          LucideIcons.layoutGrid,
                          size: 14,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {
                context.go('/inventory/packages/create');
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
          ],
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'All Packages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PackageColumn(
                      title: 'Packages, Not Shipped',
                      headerColor: _col1Bg,
                      type: _ColumnType.first,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _PackageColumn(
                      title: 'Shipped Packages',
                      headerColor: _col2Bg,
                      type: _ColumnType.middle,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _PackageColumn(
                      title: 'Delivered Packages',
                      headerColor: _col3Bg,
                      type: _ColumnType.last,
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
}

enum _ColumnType { first, middle, last }

class _PackageColumn extends StatelessWidget {
  final String title;
  final Color headerColor;
  final _ColumnType type;

  const _PackageColumn({
    required this.title,
    required this.headerColor,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Angled Column Header
          ClipPath(
            clipper: _HeaderClipper(type),
            child: Container(
              height: 48,
              padding: EdgeInsets.only(
                left: type == _ColumnType.first ? 16 : 20,
                right: type == _ColumnType.last ? 16 : 20,
              ),
              color: headerColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const _MenuDropdown(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Full-height column panel
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Container(
                height: 120,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Center(
                  child: Text(
                    'No Records Found',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  final _ColumnType type;
  const _HeaderClipper(this.type);

  @override
  Path getClip(Size size) {
    final path = Path();
    final double arrowWidth = 16.0;

    // Start Top Left
    if (type == _ColumnType.first) {
      path.moveTo(0, 0);
    } else {
      path.moveTo(arrowWidth, 0);
    }

    // Top Edge to Top Right
    if (type == _ColumnType.last) {
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.lineTo(size.width - arrowWidth, 0);
      path.lineTo(size.width, size.height / 2); // Arrow point pointing right
      path.lineTo(size.width - arrowWidth, size.height);
    }

    // Bottom Edge to Bottom Left
    if (type == _ColumnType.first) {
      path.lineTo(0, size.height);
      path.lineTo(0, 0);
    } else {
      path.lineTo(arrowWidth, size.height);
      path.lineTo(0, size.height / 2); // Cutout arrow pointing right
      path.lineTo(arrowWidth, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class _MenuDropdown extends StatefulWidget {
  const _MenuDropdown();

  @override
  State<_MenuDropdown> createState() => _MenuDropdownState();
}

class _MenuDropdownState extends State<_MenuDropdown> {
  bool _isHovering = false;
  String _sortField = 'Package Date';
  bool _isAscending = true;
  final LayerLink _layerLink = LayerLink();
  final LayerLink _sortLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  OverlayEntry? _sortOverlayEntry;

  void _showOverlay() {
    _removeOverlay();

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Out-of-bounds tap detector to close menu
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(size.width - 200, size.height + 4),
              showWhenUnlinked: false,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
                child: Container(
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CompositedTransformTarget(
                        link: _sortLayerLink,
                        child: _buildMenuItem(
                          LucideIcons.arrowUpDown,
                          'Sort by',
                          isSortHeader: true,
                          onTap: () {
                            if (_sortOverlayEntry != null) {
                              _removeSortOverlay();
                            } else {
                              _showSortOverlay();
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      _buildMenuItem(LucideIcons.download, 'Import Packages'),
                      _buildMenuItem(LucideIcons.upload, 'Export Packages'),
                      _buildMenuItem(LucideIcons.download, 'Import Shipments'),
                      _buildMenuItem(LucideIcons.upload, 'Export Shipments'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _removeSortOverlay();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _removeSortOverlay() {
    _sortOverlayEntry?.remove();
    _sortOverlayEntry = null;
  }
void _showSortOverlay() {
  _removeSortOverlay();
  final overlay = Overlay.of(context);

  _sortOverlayEntry = OverlayEntry(
    builder: (context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeSortOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _sortLayerLink,
            offset: const Offset(202, 0), // To the right of the main menu
            showWhenUnlinked: false,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSortItem('Package Date'),
                    _buildSortItem('Package#'),
                    _buildSortItem('Carrier'),
                    _buildSortItem('Sales Order#'),
                    _buildSortItem('Shipment Date'),
                    _buildSortItem('Customer Name'),
                    _buildSortItem('Quantity'),
                    _buildSortItem('Created Time'),
                    _buildSortItem('Last Modified Time'),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(_sortOverlayEntry!);
}
  Widget _buildSortItem(String text) {
    final bool isSelected = _sortField == text;
    return _HoverMenuItem(
      icon: isSelected
          ? (_isAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown)
          : LucideIcons.arrowUp,
      text: text,
      isSelected: isSelected,
      onTap: () {
        setState(() {
          if (_sortField == text) {
            _isAscending = !_isAscending;
          } else {
            _sortField = text;
            _isAscending = true;
          }
        });
        _removeOverlay();
      },
    );
  }
  Widget _buildMenuItem(IconData icon, String text,
      {VoidCallback? onTap, bool isSortHeader = false}) {
    return _HoverMenuItem(
      icon: icon,
      text: text,
      trailingIcon: isSortHeader ? LucideIcons.chevronRight : null,
      onTap: onTap ??
          () {
            _removeOverlay();
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: InkWell(
          onTap: () {
            if (_overlayEntry != null) {
              _removeOverlay();
            } else {
              _showOverlay();
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _isHovering
                  ? Colors.black.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              LucideIcons.menu,
              size: 16,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverMenuItem extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final IconData? trailingIcon;

  const _HoverMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isSelected = false,
    this.trailingIcon,
  });

  @override
  State<_HoverMenuItem> createState() => _HoverMenuItemState();
}

class _HoverMenuItemState extends State<_HoverMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isEffectivelySelected = widget.isSelected || _isHovering;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isEffectivelySelected
              ? const Color(0xFF3B82F6)
              : Colors.white,
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: isEffectivelySelected
                    ? Colors.white // White on hover/select
                    : const Color(0xFF3B82F6), // Default to Primary Blue
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: isEffectivelySelected
                        ? Colors.white // White on hover/select
                        : const Color(0xFF1F2937),
                    fontWeight:
                        isEffectivelySelected ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (widget.trailingIcon != null)
                Icon(
                  widget.trailingIcon,
                  size: 14,
                  color: isEffectivelySelected ? Colors.white : const Color(0xFF9CA3AF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
