import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/pages/settings_users_roles_support.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class SettingsLocationAccessEditor extends StatefulWidget {
  const SettingsLocationAccessEditor({
    super.key,
    required this.locations,
    required this.selectedBranchIds,
    required this.defaultBusinessBranchId,
    required this.defaultWarehouseBranchId,
    required this.onChanged,
    this.showArrow = true,
  });

  final List<SettingsLocationRecord> locations;
  final Set<String> selectedBranchIds;
  final String? defaultBusinessBranchId;
  final String? defaultWarehouseBranchId;
  final void Function(
    Set<String> selectedBranchIds,
    String? defaultBusinessBranchId,
    String? defaultWarehouseBranchId,
  )
  onChanged;
  final bool showArrow;

  @override
  State<SettingsLocationAccessEditor> createState() =>
      _SettingsLocationAccessEditorState();
}

class _SettingsLocationAccessEditorState
    extends State<SettingsLocationAccessEditor> {
  final TextEditingController _searchController = TextEditingController();
  late Set<String> _selectedBranchIds;
  String? _defaultBusinessBranchId;
  String? _defaultWarehouseBranchId;
  bool _locationsExpanded = true;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant SettingsLocationAccessEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBranchIds != widget.selectedBranchIds ||
        oldWidget.defaultBusinessBranchId != widget.defaultBusinessBranchId ||
        oldWidget.defaultWarehouseBranchId != widget.defaultWarehouseBranchId ||
        oldWidget.locations != widget.locations) {
      _syncFromWidget();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncFromWidget() {
    _selectedBranchIds = Set<String>.from(widget.selectedBranchIds);
    _defaultBusinessBranchId = widget.defaultBusinessBranchId;
    _defaultWarehouseBranchId = widget.defaultWarehouseBranchId;
  }

  List<SettingsLocationRecord> get _selectedLocations => widget.locations
      .where((location) => _selectedBranchIds.contains(location.id))
      .toList();

  List<SettingsLocationRecord> get _businessDefaults =>
      _selectedLocations.where((location) => location.isBusiness).toList();

  List<SettingsLocationRecord> get _warehouseDefaults =>
      _selectedLocations.where((location) => location.isWarehouse).toList();

  List<SettingsLocationRecord> _childrenFor(String? parentId) {
    final query = _searchController.text.trim().toLowerCase();
    final children = widget.locations
        .where((location) => location.parentBranchId == parentId)
        .toList();
    if (query.isEmpty) return children;
    return children
        .where((location) => _matchesQuery(location, query))
        .toList();
  }

  bool _matchesQuery(SettingsLocationRecord location, String query) {
    if (location.name.toLowerCase().contains(query)) {
      return true;
    }
    return widget.locations.any(
      (child) =>
          child.parentBranchId == location.id && _matchesQuery(child, query),
    );
  }

  Set<String> _allDescendants(String parentId) {
    final descendants = <String>{};
    final queue = Queue<String>()..add(parentId);
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      for (final child in widget.locations.where(
        (location) => location.parentBranchId == current,
      )) {
        descendants.add(child.id);
        queue.add(child.id);
      }
    }
    return descendants;
  }

  SettingsLocationRecord? _firstWhereOrNull(
    List<SettingsLocationRecord> values,
  ) {
    return values.isEmpty ? null : values.first;
  }

  void _emit() {
    widget.onChanged(
      Set<String>.from(_selectedBranchIds),
      _defaultBusinessBranchId,
      _defaultWarehouseBranchId,
    );
  }

  void _toggleLocation(SettingsLocationRecord location, bool selected) {
    setState(() {
      if (selected) {
        _selectedBranchIds.add(location.id);
        if (location.isBusiness && _defaultBusinessBranchId == null) {
          _defaultBusinessBranchId = location.id;
        }
        if (location.isWarehouse && _defaultWarehouseBranchId == null) {
          _defaultWarehouseBranchId = location.id;
        }
      } else {
        _selectedBranchIds.remove(location.id);
        final descendants = _allDescendants(location.id);
        _selectedBranchIds.removeAll(descendants);

        if (_defaultBusinessBranchId == location.id ||
            descendants.contains(_defaultBusinessBranchId)) {
          _defaultBusinessBranchId = _firstWhereOrNull(
            _businessDefaults.where((item) => item.id != location.id).toList(),
          )?.id;
        }
        if (_defaultWarehouseBranchId == location.id ||
            descendants.contains(_defaultWarehouseBranchId)) {
          _defaultWarehouseBranchId = _firstWhereOrNull(
            _warehouseDefaults.where((item) => item.id != location.id).toList(),
          )?.id;
        }
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDefaultSelector(
                label: "User's Default Business Location",
                required: true,
                value: _defaultBusinessBranchId,
                items: _businessDefaults,
                onChanged: (value) {
                  setState(() => _defaultBusinessBranchId = value);
                  _emit();
                },
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: _buildDefaultSelector(
                label: "User's Default Warehouse Location",
                value: _defaultWarehouseBranchId,
                items: _warehouseDefaults,
                onChanged: (value) {
                  setState(() => _defaultWarehouseBranchId = value);
                  _emit();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: _buildLeftPane()),
            if (widget.showArrow) ...[
              const SizedBox(width: AppTheme.space24),
              Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF7F9FC),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Icon(
                    LucideIcons.arrowRight,
                    size: 18,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space24),
            ],
            Expanded(flex: 2, child: _buildRightPane()),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultSelector({
    required String label,
    required List<SettingsLocationRecord> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            children: required
                ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppTheme.errorRed),
                    ),
                  ]
                : const [],
          ),
        ),
        const SizedBox(height: AppTheme.space8),
        FormDropdown<String>(
          value: value,
          items: items.map((item) => item.id).toList(),
          hint: 'Select location',
          displayStringForValue: (id) {
            final match = items.where((item) => item.id == id).toList();
            return match.isEmpty ? id : match.first.name;
          },
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildLeftPane() {
    final roots = _childrenFor(null);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Type to search Locations',
                      isDense: true,
                      prefixIcon: const Icon(
                        LucideIcons.search,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Row(
                  children: [
                    Checkbox(
                      value:
                          _selectedBranchIds.length ==
                              widget.locations.length &&
                          widget.locations.isNotEmpty,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedBranchIds = widget.locations
                                .map((item) => item.id)
                                .toSet();
                            _defaultBusinessBranchId = _firstWhereOrNull(
                              widget.locations
                                  .where((item) => item.isBusiness)
                                  .toList(),
                            )?.id;
                            _defaultWarehouseBranchId = _firstWhereOrNull(
                              widget.locations
                                  .where((item) => item.isWarehouse)
                                  .toList(),
                            )?.id;
                          } else {
                            _selectedBranchIds.clear();
                            _defaultBusinessBranchId = null;
                            _defaultWarehouseBranchId = null;
                          }
                        });
                        _emit();
                      },
                      side: const BorderSide(color: AppTheme.borderColor),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text('Select All', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
            child: Column(children: roots.map(_buildLocationTile).toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(SettingsLocationRecord location) {
    final children = _childrenFor(location.id);
    final isSelected = _selectedBranchIds.contains(location.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleLocation(location, value == true),
                side: const BorderSide(color: AppTheme.borderColor),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Expanded(
                child: Text(
                  location.name,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          for (final child in children)
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.space24),
              child: _buildLocationTile(child),
            ),
        ],
      ),
    );
  }

  Widget _buildRightPane() {
    final selected = _selectedLocations;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space14,
              vertical: AppTheme.space14,
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.checkCircle2,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: AppTheme.space8),
                Text(
                  'Associated Values',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: AppTheme.space8),
                _CounterBadge(value: selected.length),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          InkWell(
            onTap: () =>
                setState(() => _locationsExpanded = !_locationsExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space14,
                vertical: AppTheme.space12,
              ),
              child: Row(
                children: [
                  Icon(
                    _locationsExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    'Locations',
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  _CounterBadge(value: selected.length, muted: true),
                ],
              ),
            ),
          ),
          if (_locationsExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            if (selected.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Text(
                  'No locations selected.',
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int index = 0; index < selected.length; index++)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space16,
                        vertical: AppTheme.space12,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppTheme.borderLight),
                        ),
                      ),
                      child: Text(
                        '${index + 1}. ${selected[index].name}${selected[index].isWarehouse ? ' (Warehouse)' : ''}',
                        style: AppTheme.bodyText,
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.value, this.muted = false});

  final int value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: muted ? AppTheme.textSecondary : const Color(0xFFE65B4B),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 11,
          height: 1,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
