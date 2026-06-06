import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';

class FavoriteFilterOption {
  final String label;
  final String value;
  final String? status;

  const FavoriteFilterOption({
    required this.label,
    required this.value,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteFilterOption &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label;

  @override
  int get hashCode => value.hashCode ^ label.hashCode;
}

class FavoriteFilterDropdown extends ConsumerStatefulWidget {
  final String moduleName;
  final List<FavoriteFilterOption> options;
  final FavoriteFilterOption selectedOption;
  final ValueChanged<FavoriteFilterOption> onChanged;
  final bool showChevron;

  const FavoriteFilterDropdown({
    super.key,
    required this.moduleName,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
    this.showChevron = true,
  });

  @override
  ConsumerState<FavoriteFilterDropdown> createState() => _FavoriteFilterDropdownState();
}

class _FavoriteFilterDropdownState extends ConsumerState<FavoriteFilterDropdown> {
  final MenuController _menuController = MenuController();

  String _getDisplayLabel() {
    final label = widget.selectedOption.label;
    if (label.toLowerCase() == 'all') {
      switch (widget.moduleName) {
        case 'purchase_orders':
          return 'All Purchase Orders';
        case 'bills':
          return 'All Bills';
        case 'invoices':
        case 'sales_invoices':
          return 'All Invoices';
        case 'sales_orders':
          return 'All Sales Orders';
        case 'vendors':
          return 'All Vendors';
        case 'customers':
          return 'All Customers';
        default:
          final parts = widget.moduleName.split('_');
          final formatted = parts.map((p) {
            if (p.isEmpty) return '';
            return p[0].toUpperCase() + p.substring(1);
          }).join(' ');
          return 'All $formatted';
      }
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      style: const MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: WidgetStatePropertyAll(Colors.white),
        padding: WidgetStatePropertyAll(EdgeInsets.zero),
        elevation: WidgetStatePropertyAll(8),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return InkWell(
          onTap: () => isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getDisplayLabel(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                if (widget.showChevron) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      menuChildren: [
        _FavoriteFilterMenuContent(
          menuController: _menuController,
          moduleName: widget.moduleName,
          options: widget.options,
          selectedOption: widget.selectedOption,
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}

class _FavoriteFilterMenuContent extends ConsumerStatefulWidget {
  final MenuController menuController;
  final String moduleName;
  final List<FavoriteFilterOption> options;
  final FavoriteFilterOption selectedOption;
  final ValueChanged<FavoriteFilterOption> onChanged;

  const _FavoriteFilterMenuContent({
    required this.menuController,
    required this.moduleName,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  ConsumerState<_FavoriteFilterMenuContent> createState() => _FavoriteFilterMenuContentState();
}

class _FavoriteFilterMenuContentState extends ConsumerState<_FavoriteFilterMenuContent> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _starredValues = {};
  bool _isLoading = true;
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _getUserId() {
    final supabase = Supabase.instance.client;
    final supabaseUserId = supabase.auth.currentUser?.id;
    if (supabaseUserId != null && supabaseUserId.isNotEmpty) {
      return supabaseUserId;
    }
    final authUser = ref.read(authUserProvider);
    if (authUser != null && authUser.id.isNotEmpty) {
      return authUser.id;
    }
    try {
      final box = Hive.box('config');
      final raw = (box.get('user_data') ?? '').toString().trim();
      if (raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        final id = decoded['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
    } catch (_) {}
    return null;
  }

  String? _getEntityId() {
    final entityId = ref.read(entityProvider).entityId;
    if (entityId != null && entityId.isNotEmpty) {
      return entityId;
    }
    final authUser = ref.read(authUserProvider);
    if (authUser != null && authUser.orgEntityId != null && authUser.orgEntityId!.isNotEmpty) {
      return authUser.orgEntityId;
    }
    try {
      final box = Hive.box('config');
      final id = box.get('selected_entity_id') as String?;
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    return null;
  }

  Future<void> _loadFavorites() async {
    try {
      final supabase = Supabase.instance.client;
      final entityId = _getEntityId() ?? '';
      final userId = _getUserId();
      if (userId == null || userId.isEmpty || entityId.isEmpty) {
        debugPrint('userId ($userId) or entityId ($entityId) is null/empty, skipping loading favorites');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final res = await supabase
          .from('favorites')
          .select('column_name')
          .eq('entity_id', entityId)
          .eq('users_id', userId)
          .eq('module_name', widget.moduleName);

      if (mounted) {
        setState(() {
          _starredValues.clear();
          for (final row in res as List<dynamic>) {
            final colName = row['column_name']?.toString();
            if (colName != null) {
              _starredValues.add(colName);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(FavoriteFilterOption option) async {
    try {
      final supabase = Supabase.instance.client;
      final entityId = _getEntityId() ?? '';
      final userId = _getUserId();
      if (userId == null || userId.isEmpty || entityId.isEmpty) return;

      final isStarred = _starredValues.contains(option.value);

      if (isStarred) {
        await supabase
            .from('favorites')
            .delete()
            .eq('entity_id', entityId)
            .eq('users_id', userId)
            .eq('module_name', widget.moduleName)
            .eq('column_name', option.value);

        if (mounted) {
          setState(() {
            _starredValues.remove(option.value);
          });
        }
      } else {
        await supabase.from('favorites').insert({
          'entity_id': entityId,
          'users_id': userId,
          'module_name': widget.moduleName,
          'column_name': option.value,
        });

        if (mounted) {
          setState(() {
            _starredValues.add(option.value);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to update favorite: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 280,
        height: 120,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    final query = _searchQuery.toLowerCase();
    
    // Filter favorites
    final favList = widget.options
        .where((opt) => _starredValues.contains(opt.value))
        .where((opt) => opt.label.toLowerCase().contains(query))
        .toList();

    // Filter defaults
    final defaultList = widget.options
        .where((opt) => opt.label.toLowerCase().contains(query))
        .toList();

    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Field Row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF3B82F6)), // blue border when focused/active
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      LucideIcons.search,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search views...',
                        hintStyle: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 14),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),

          // Scrollable categories
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Favorites Section
                  _sectionHeader(
                    title: 'FAVORITES',
                    count: favList.length,
                    isExpanded: _favoritesExpanded,
                    onTap: () => setState(() => _favoritesExpanded = !_favoritesExpanded),
                  ),
                  if (_favoritesExpanded) ...[
                    if (favList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No favorites found',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      ...favList.map((opt) => _optionRow(opt)),
                  ],

                  // Default Filters Section
                  _sectionHeader(
                    title: 'DEFAULT FILTERS',
                    count: defaultList.length,
                    isExpanded: _defaultFiltersExpanded,
                    onTap: () => setState(() => _defaultFiltersExpanded = !_defaultFiltersExpanded),
                  ),
                  if (_defaultFiltersExpanded) ...[
                    if (defaultList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No filters match search',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      ...defaultList.map((opt) => _optionRow(opt)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required String title,
    required int count,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        color: const Color(0xFFF9FAFB),
        child: Row(
          children: [
            Icon(
              isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
              size: 14,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981), // success green pill badge
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(FavoriteFilterOption opt) {
    final isStarred = _starredValues.contains(opt.value);

    return _FilterOptionRow(
      option: opt,
      isStarred: isStarred,
      onTap: () {
        widget.onChanged(opt);
        widget.menuController.close();
      },
      onStarTap: () => _toggleFavorite(opt),
    );
  }
}

class _FilterOptionRow extends StatefulWidget {
  final FavoriteFilterOption option;
  final bool isStarred;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  const _FilterOptionRow({
    required this.option,
    required this.isStarred,
    required this.onTap,
    required this.onStarTap,
  });

  @override
  State<_FilterOptionRow> createState() => _FilterOptionRowState();
}

class _FilterOptionRowState extends State<_FilterOptionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final rowBgColor = _isHovered ? AppTheme.primaryBlue : Colors.transparent;
    final textColor = _isHovered ? Colors.white : AppTheme.textPrimary;
    final starColor = _isHovered
        ? Colors.white
        : (widget.isStarred ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: rowBgColor,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.option.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              InkWell(
                onTap: widget.onStarTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    widget.isStarred ? Icons.star : Icons.star_border,
                    size: 16,
                    color: starColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
