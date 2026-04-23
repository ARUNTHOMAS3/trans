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
      pageTitle: 'All Packages',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      horizontalPaddingValue: 12,
      useTopPadding: true,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, thickness: 1, color: _borderCol),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool useFixedDesktopColumns = constraints.maxWidth >= 1220;

                  if (useFixedDesktopColumns) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SizedBox(
                          width: 405,
                          child: _PackageColumn(
                            title: 'Packages, Not Shipped',
                            headerColor: _col1Bg,
                            type: _ColumnType.first,
                          ),
                        ),
                        SizedBox(width: 24),
                        SizedBox(
                          width: 405,
                          child: _PackageColumn(
                            title: 'Shipped Packages',
                            headerColor: _col2Bg,
                            type: _ColumnType.middle,
                          ),
                        ),
                        SizedBox(width: 24),
                        SizedBox(
                          width: 405,
                          child: _PackageColumn(
                            title: 'Delivered Packages',
                            headerColor: _col3Bg,
                            type: _ColumnType.last,
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: SizedBox.shrink(),
                        ),
                      ],
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 980),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 305,
                            child: _PackageColumn(
                              title: 'Packages, Not Shipped',
                              headerColor: _col1Bg,
                              type: _ColumnType.first,
                            ),
                          ),
                          SizedBox(width: 24),
                          SizedBox(
                            width: 305,
                            child: _PackageColumn(
                              title: 'Shipped Packages',
                              headerColor: _col2Bg,
                              type: _ColumnType.middle,
                            ),
                          ),
                          SizedBox(width: 24),
                          SizedBox(
                            width: 305,
                            child: _PackageColumn(
                              title: 'Delivered Packages',
                              headerColor: _col3Bg,
                              type: _ColumnType.last,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
    // Header height and Arrow expansion values
    const double headerHeight = 60.0;
    const double arrowPadding = 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Angled Column Header with Overflow support
        SizedBox(
          height: headerHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                right: type == _ColumnType.last ? 0 : -arrowPadding,
                child: ClipPath(
                  clipper: _HeaderClipper(type),
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: type == _ColumnType.last ? 16 : 32,
                    ),
                    color: headerColor,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Inter',
                          ),
                        ),
                        const _MenuDropdown(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Full-height column panel (Stretched to fill Row height)
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  height: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.zero,
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'No Records Found',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  final _ColumnType type;
  const _HeaderClipper(this.type);

  @override
  Path getClip(Size size) {
    final path = Path();
    final double arrowWidth = 20.0;

    // Keep a flat left edge for all headers.
    path.moveTo(0, 0);

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
    path.lineTo(0, size.height);
    path.lineTo(0, 0);

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
  String? _sortField;
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
            _isAscending = false;
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
      onHoverChanged: isSortHeader
          ? (isHovering) {
              if (isHovering && _sortOverlayEntry == null) {
                _showSortOverlay();
              }
            }
          : null,
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
  final ValueChanged<bool>? onHoverChanged;

  const _HoverMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.isSelected = false,
    this.trailingIcon,
    this.onHoverChanged,
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
      onEnter: (_) {
        setState(() => _isHovering = true);
        widget.onHoverChanged?.call(true);
      },
      onExit: (_) {
        setState(() => _isHovering = false);
        widget.onHoverChanged?.call(false);
      },
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
