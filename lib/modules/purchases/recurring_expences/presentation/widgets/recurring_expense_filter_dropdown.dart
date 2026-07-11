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
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

class RecurringExpenseFilterDropdown extends ConsumerStatefulWidget {
  final String moduleName;
  final List<FavoriteFilterOption> options;
  final FavoriteFilterOption selectedOption;
  final ValueChanged<FavoriteFilterOption> onChanged;
  final bool showChevron;
  final bool isCompact;

  const RecurringExpenseFilterDropdown({
    super.key,
    required this.moduleName,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
    this.showChevron = true,
    this.isCompact = false,
  });

  @override
  ConsumerState<RecurringExpenseFilterDropdown> createState() =>
      _RecurringExpenseFilterDropdownState();
}

class _RecurringExpenseFilterDropdownState
    extends ConsumerState<RecurringExpenseFilterDropdown> {
  final MenuController _menuController = MenuController();

  String _getDisplayLabel() {
    final label = widget.selectedOption.label;
    if (label.toLowerCase() == 'all') {
      return 'All Profiles';
    }
    return '${label} Profiles';
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
          borderRadius: BorderRadius.circular(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isOpen
                  ? AppTheme.selectionInactiveBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 2 : 10,
              vertical: widget.isCompact ? 4 : 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getDisplayLabel(),
                  style: TextStyle(
                    fontSize: widget.isCompact ? 16 : 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                if (widget.showChevron) ...[
                  const SizedBox(width: 6),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: widget.isCompact ? 18 : 22,
                    color: AppTheme.primaryBlueDark,
                  ),
                ],
              ],
            ),
          ),
        );
      },
      menuChildren: [
        _RecurringExpenseFilterMenuContent(
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

class _RecurringExpenseFilterMenuContent extends ConsumerStatefulWidget {
  final MenuController menuController;
  final String moduleName;
  final List<FavoriteFilterOption> options;
  final FavoriteFilterOption selectedOption;
  final ValueChanged<FavoriteFilterOption> onChanged;

  const _RecurringExpenseFilterMenuContent({
    required this.menuController,
    required this.moduleName,
    required this.options,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  ConsumerState<_RecurringExpenseFilterMenuContent> createState() =>
      _RecurringExpenseFilterMenuContentState();
}

class _RecurringExpenseFilterMenuContentState
    extends ConsumerState<_RecurringExpenseFilterMenuContent> {
  final Set<String> _starredValues = {};
  bool _isLoading = true;
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
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
    if (authUser != null &&
        authUser.orgEntityId != null &&
        authUser.orgEntityId!.isNotEmpty) {
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
        debugPrint(
          'userId ($userId) or entityId ($entityId) is null/empty, skipping loading favorites',
        );
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
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZBone(width: 120, height: 16),
              SizedBox(height: AppTheme.space12),
              ZBone(height: 14),
              SizedBox(height: AppTheme.space10),
              ZBone(width: 220, height: 14),
              SizedBox(height: AppTheme.space10),
              ZBone(width: 180, height: 14),
            ],
          ),
        ),
      );
    }

    // Filter favorites
    final favList = widget.options
        .where((opt) => _starredValues.contains(opt.value))
        .toList();

    // Filter defaults
    final defaultList = widget.options.toList();

    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // Scrollable categories
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 360),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_starredValues.isNotEmpty) ...[
                    // Favorites Section
                    _sectionHeader(
                      title: 'FAVORITES',
                      count: favList.length,
                      isExpanded: _favoritesExpanded,
                      onTap: () => setState(
                        () => _favoritesExpanded = !_favoritesExpanded,
                      ),
                    ),
                    if (_favoritesExpanded) ...[
                      if (favList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No favorites found',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
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
                      onTap: () => setState(
                        () => _defaultFiltersExpanded = !_defaultFiltersExpanded,
                      ),
                    ),
                    if (_defaultFiltersExpanded) ...[
                      if (defaultList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'No filters match search',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        )
                      else
                        ...defaultList.map((opt) => _optionRow(opt)),
                    ],
                  ] else ...[
                    // Flat list structure matching user screenshot when no favorites selected
                    if (defaultList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No filters match search',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
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

    return _RecurringFilterOptionRow(
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

class _RecurringFilterOptionRow extends StatefulWidget {
  final FavoriteFilterOption option;
  final bool isStarred;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  const _RecurringFilterOptionRow({
    required this.option,
    required this.isStarred,
    required this.onTap,
    required this.onStarTap,
  });

  @override
  State<_RecurringFilterOptionRow> createState() => _RecurringFilterOptionRowState();
}

class _RecurringFilterOptionRowState extends State<_RecurringFilterOptionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final rowBgColor = _isHovered ? AppTheme.primaryBlue : Colors.transparent;
    final textColor = _isHovered ? Colors.white : AppTheme.textPrimary;
    final starColor = _isHovered
        ? Colors.white
        : (widget.isStarred
            ? const Color(0xFFF59E0B)
            : const Color(0xFFD1D5DB));

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
