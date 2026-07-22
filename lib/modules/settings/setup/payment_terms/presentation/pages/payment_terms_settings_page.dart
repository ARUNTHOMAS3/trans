import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/settings_navigation_sidebar.dart';
import 'package:zerpai_erp/shared/widgets/settings_search_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _PaymentTerm {
  _PaymentTerm({
    this.id,
    required this.name,
    this.days = 0,
    this.isDefault = false,
    this.isActive = true,
    this.hasInfo = false,
    this.isLink = false,
  });

  final String? id;
  final String name;
  final int days;
  final bool isDefault;
  final bool isActive;
  final bool hasInfo;
  final bool isLink;

  _PaymentTerm copyWith({
    String? id,
    String? name,
    int? days,
    bool? isDefault,
    bool? isActive,
    bool? hasInfo,
    bool? isLink,
  }) {
    return _PaymentTerm(
      id: id ?? this.id,
      name: name ?? this.name,
      days: days ?? this.days,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      hasInfo: hasInfo ?? this.hasInfo,
      isLink: isLink ?? this.isLink,
    );
  }
}

class _PaymentTermDraft {
  const _PaymentTermDraft({required this.name, required this.days});

  final String name;
  final String days;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class PaymentTermsSettingsPage extends ConsumerStatefulWidget {
  const PaymentTermsSettingsPage({super.key});

  @override
  ConsumerState<PaymentTermsSettingsPage> createState() =>
      _PaymentTermsSettingsPageState();
}

class _PaymentTermsSettingsPageState
    extends ConsumerState<PaymentTermsSettingsPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<_PaymentTerm> _terms = [];
  final Set<int> _selectedIndices = {};
  bool _headerChecked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentTerms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _withOrgPrefix(String route) {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    return '/$orgSystemId$route';
  }

  Future<void> _loadPaymentTerms() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get(
        'settings-setup/payment-terms',
        useCache: false,
      );
      final rows = response.data is List ? response.data as List : const [];
      if (!mounted) return;
      setState(() {
        _terms
          ..clear()
          ..addAll(
            rows.whereType<Map>().map((row) {
              final json = Map<String, dynamic>.from(row);
              return _PaymentTerm(
                id: json['id']?.toString(),
                name: json['term_name']?.toString() ?? '',
                days: _toInt(json['number_of_days']),
                isDefault: json['is_default'] == true,
                isActive: json['is_active'] != false,
              );
            }),
          );
        _selectedIndices.clear();
        _headerChecked = false;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ZerpaiToast.error(context, 'Failed to load payment terms');
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _toggleHeader(bool? value) {
    setState(() {
      _headerChecked = value ?? false;
      if (_headerChecked) {
        _selectedIndices.addAll(List.generate(_terms.length, (i) => i));
      } else {
        _selectedIndices.clear();
      }
    });
  }

  void _toggleRow(int index, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
      _headerChecked = _selectedIndices.length == _terms.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final orgName =
        ref.watch(orgSettingsProvider).valueOrNull?.name ??
        'ZABNIX PRIVATE LIMITED';
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // ── Top header ──────────────────────────────────────────────────
          _buildTopBar(orgName, context),
          // ── Main layout ─────────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsNavigationSidebar(currentPath: currentPath),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(String orgName, BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          // Back arrow
          IconButton(
            icon: const Icon(
              LucideIcons.chevronLeft,
              size: 18,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => context.go(_withOrgPrefix(AppRoutes.settings)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Settings',
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                orgName,
                style: AppTheme.captionText.copyWith(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: SettingsSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              items: const [],
            ),
          ),
          const SizedBox(width: 24),
          TextButton.icon(
            onPressed: () => context.go(_withOrgPrefix(AppRoutes.settings)),
            icon: const Icon(LucideIcons.x, size: 14),
            label: const Text('Close Settings'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              textStyle: AppTheme.bodyText.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main Content ─────────────────────────────────────────────────────────

  Widget _buildContent() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page heading row
          _buildPageHeader(),
          // Table
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            'Payment Terms',
            style: AppTheme.bodyText.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          _NewPaymentTermButton(onTap: _showNewPaymentTermDialog),
        ],
      ),
    );
  }

  // ── Table ────────────────────────────────────────────────────────────────

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_terms.isEmpty) {
      return Center(
        child: Text(
          'No payment terms found',
          style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_selectedIndices.isNotEmpty) _buildBulkActionBar(),
          // Column header
          _buildTableHeader(),
          const Divider(height: 1, color: AppTheme.borderLight),
          // Rows
          ..._terms.asMap().entries.map((e) {
            return _TermRow(
              term: e.value,
              index: e.key,
              isSelected: _selectedIndices.contains(e.key),
              onChecked: (v) => _toggleRow(e.key, v),
              onTap: () {
                _showNewPaymentTermDialog(
                  name: e.value.name,
                  days: e.value.days.toString(),
                  editIndex: e.key,
                );
              },
              onEdit: () {
                _showNewPaymentTermDialog(
                  name: e.value.name,
                  days: e.value.days.toString(),
                  editIndex: e.key,
                );
              },
              onSetDefault: () => _setDefaultTerm(e.key),
              onToggleActive: () => _toggleTermActive(e.key),
              onDelete: () => _deleteTerm(e.key),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: _headerChecked,
              tristate:
                  _selectedIndices.isNotEmpty &&
                  _selectedIndices.length < _terms.length,
              onChanged: _toggleHeader,
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
              activeColor: const Color(0xFF408DFB),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 250,
            child: Text(
              'TERMS',
              style: AppTheme.captionText.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'STATUS',
              style: AppTheme.captionText.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(
            width: 44,
          ), // Alignment spacing for 3-dots hover button
        ],
      ),
    );
  }

  // ── New Payment Term Dialog ───────────────────────────────────────────────

  Future<void> _showNewPaymentTermDialog({
    String? name,
    String? days,
    int? editIndex,
  }) async {
    final result = await showGeneralDialog<_PaymentTermDraft>(
      context: context,
      barrierLabel: name == null ? 'New Payment Term' : 'Edit Payment Term',
      barrierDismissible: true,
      barrierColor: const Color(0x99000000),
      transitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, __, ___) =>
          _NewPaymentTermDialog(initialName: name, initialDays: days),
      transitionBuilder: (_, animation, __, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    final existingTerm =
        editIndex != null && editIndex >= 0 && editIndex < _terms.length
        ? _terms[editIndex]
        : null;
    final payload = <String, dynamic>{
      'term_name': result.name.trim(),
      'number_of_days': int.tryParse(result.days.trim()) ?? 0,
      'is_active': existingTerm?.isActive ?? true,
    };

    try {
      if (existingTerm?.id != null && existingTerm!.id!.isNotEmpty) {
        await _apiClient.patch(
          'settings-setup/payment-terms/${existingTerm.id}',
          data: payload,
        );
      } else {
        await _apiClient.post('settings-setup/payment-terms', data: payload);
      }
      if (!mounted) return;
      ZerpaiToast.success(context, 'Payment term saved');
      await _loadPaymentTerms();
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to save payment term');
    }
  }

  Future<void> _setDefaultTerm(int index) async {
    final id = index >= 0 && index < _terms.length ? _terms[index].id : null;
    if (id == null || id.isEmpty) return;
    try {
      await _apiClient.post('settings-setup/payment-terms/$id/default');
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _terms.length; i++) {
          _terms[i] = _terms[i].copyWith(isDefault: i == index);
        }
      });
      ZerpaiToast.success(context, 'Default payment term updated');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to update default');
    }
  }

  Future<void> _toggleTermActive(int index) async {
    if (index < 0 || index >= _terms.length) return;
    final term = _terms[index];
    if (term.id == null || term.id!.isEmpty) return;
    final nextActive = !term.isActive;
    try {
      await _apiClient.patch(
        'settings-setup/payment-terms/${term.id}',
        data: {'is_active': nextActive},
      );
      if (!mounted) return;
      setState(() {
        _terms[index] = term.copyWith(isActive: nextActive);
      });
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to update status');
    }
  }

  Future<void> _deleteTerm(int index) async {
    if (index < 0 || index >= _terms.length) return;
    final term = _terms[index];
    if (term.id == null || term.id!.isEmpty) return;
    try {
      await _apiClient.delete('settings-setup/payment-terms/${term.id}');
      if (!mounted) return;
      setState(() {
        _terms[index] = term.copyWith(isActive: false);
        final updatedSelection = <int>{};
        for (final selectedIndex in _selectedIndices) {
          if (selectedIndex == index) {
            continue;
          }
          updatedSelection.add(
            selectedIndex > index ? selectedIndex - 1 : selectedIndex,
          );
        }
        _selectedIndices
          ..clear()
          ..addAll(updatedSelection);
        _headerChecked =
            _terms.isNotEmpty && _selectedIndices.length == _terms.length;
      });
      ZerpaiToast.success(context, 'Payment term marked inactive');
    } catch (_) {
      if (mounted) ZerpaiToast.error(context, 'Failed to delete payment term');
    }
  }

  Widget _buildBulkActionBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _BulkActionButton(
            label: 'Mark as Active',
            onTap: () => _setSelectedTermsActive(true),
          ),
          const SizedBox(width: 8),
          _BulkActionButton(
            label: 'Mark as Inactive',
            onTap: () => _setSelectedTermsActive(false),
          ),
          const SizedBox(width: 8),
          _BulkActionButton(label: 'Delete', onTap: _deleteSelectedTerms),
          const SizedBox(width: 14),
          Container(width: 1, height: 18, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${_selectedIndices.length}',
              style: AppTheme.captionText.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Selected',
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: const Color(0xFF334155),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _clearSelection,
            child: Row(
              children: [
                Text(
                  'Esc',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(LucideIcons.x, size: 14, color: Color(0xFFFF4D4F)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setSelectedTermsActive(bool isActive) async {
    if (_selectedIndices.isEmpty) {
      return;
    }
    try {
      for (final index in _selectedIndices) {
        if (index >= 0 && index < _terms.length) {
          final id = _terms[index].id;
          if (id != null && id.isNotEmpty) {
            await _apiClient.patch(
              'settings-setup/payment-terms/$id',
              data: {'is_active': isActive},
            );
          }
        }
      }
      if (!mounted) return;
      setState(() {
        for (final index in _selectedIndices) {
          if (index >= 0 && index < _terms.length && !_terms[index].hasInfo) {
            _terms[index] = _terms[index].copyWith(isActive: isActive);
          }
        }
      });
      ZerpaiToast.success(context, 'Selected terms updated');
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to update selected terms');
    }
  }

  Future<void> _deleteSelectedTerms() async {
    if (_selectedIndices.isEmpty) {
      return;
    }
    final indexes = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    try {
      for (final index in indexes) {
        if (index >= 0 && index < _terms.length) {
          final id = _terms[index].id;
          if (id != null && id.isNotEmpty) {
            await _apiClient.delete('settings-setup/payment-terms/$id');
          }
        }
      }
      if (!mounted) return;
      setState(() {
        for (final index in indexes) {
          if (index >= 0 && index < _terms.length && !_terms[index].hasInfo) {
            _terms[index] = _terms[index].copyWith(isActive: false);
          }
        }
        _selectedIndices.clear();
        _headerChecked = false;
      });
      ZerpaiToast.success(context, 'Selected terms marked inactive');
    } catch (_) {
      if (mounted)
        ZerpaiToast.error(context, 'Failed to delete selected terms');
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedIndices.clear();
      _headerChecked = false;
    });
  }
}

// ---------------------------------------------------------------------------
// Term Row Widget
// ---------------------------------------------------------------------------

class _TermRow extends StatefulWidget {
  const _TermRow({
    required this.term,
    required this.index,
    required this.isSelected,
    required this.onChecked,
    required this.onTap,
    required this.onEdit,
    required this.onSetDefault,
    required this.onToggleActive,
    required this.onDelete,
  });

  final _PaymentTerm term;
  final int index;
  final bool isSelected;
  final ValueChanged<bool?> onChecked;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  State<_TermRow> createState() => _TermRowState();
}

class _TermRowState extends State<_TermRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? const Color(0xFFF1F5F9) : Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Checkbox
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: widget.term.hasInfo
                        ? ZTooltip(
                            message:
                                "Predefined payment term can't be marked as inactive or deleted.",
                            direction: ZTooltipDirection.right,
                            child: Checkbox(
                              value: false,
                              onChanged: null,
                              side: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                              activeColor: const Color(0xFF408DFB),
                            ),
                          )
                        : Checkbox(
                            value: widget.isSelected,
                            onChanged: widget.onChecked,
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            activeColor: const Color(0xFF408DFB),
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Term name
                  SizedBox(
                    width: 250,
                    child: Row(
                      children: [
                        MouseRegion(
                          cursor: widget.term.hasInfo
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: widget.term.hasInfo ? null : widget.onTap,
                            child: Text(
                              widget.term.name,
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12.5,
                                color: widget.term.hasInfo
                                    ? AppTheme.textPrimary
                                    : const Color(0xFF0066CC),
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                        if (widget.term.hasInfo) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            LucideIcons.lock,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ],
                        if (widget.term.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFA5D6A7),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'Default',
                              style: AppTheme.captionText.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status badge
                  Expanded(
                    child: Row(
                      children: [_StatusBadge(isActive: widget.term.isActive)],
                    ),
                  ),

                  // Hover 3-dots actions button
                  Opacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    child: _HoverActionsButton(
                      isLocked: widget.term.hasInfo,
                      isActive: widget.term.isActive,
                      onTap: () {},
                      onEdit: widget.onEdit,
                      onSetDefault: widget.onSetDefault,
                      onToggleActive: widget.onToggleActive,
                      onDelete: widget.onDelete,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive ? const Color(0xFFA5D6A7) : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: AppTheme.captionText.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: isActive ? const Color(0xFF2E7D32) : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Payment Term button
// ---------------------------------------------------------------------------

class _NewPaymentTermButton extends StatefulWidget {
  const _NewPaymentTermButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NewPaymentTermButton> createState() => _NewPaymentTermButtonState();
}

class _NewPaymentTermButtonState extends State<_NewPaymentTermButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF219F5C) : const Color(0xFF28B36B),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.plus, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(
                'New Payment Term',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New Payment Term Dialog
// ---------------------------------------------------------------------------

class _NewPaymentTermDialog extends StatefulWidget {
  const _NewPaymentTermDialog({this.initialName, this.initialDays});

  final String? initialName;
  final String? initialDays;

  @override
  State<_NewPaymentTermDialog> createState() => _NewPaymentTermDialogState();
}

class _NewPaymentTermDialogState extends State<_NewPaymentTermDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _daysCtrl;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _daysCtrl = TextEditingController(text: widget.initialDays);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameCtrl.text.trim();
    final days = _daysCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _errorText = 'Term name is required');
      return;
    }

    if (days.isEmpty) {
      setState(() => _errorText = 'Due after is required');
      return;
    }

    setState(() => _errorText = null);
    Navigator.of(context).pop(_PaymentTermDraft(name: name, days: days));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 600,
          height: 284.64,
          margin: const EdgeInsets.only(top: 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 18, 12),
                child: Row(
                  children: [
                    Text(
                      widget.initialName != null
                          ? 'Edit Payment Term'
                          : 'New Payment Term',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: Color(0xFFFF4D4F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),

              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Term Name Row
                      Row(
                        children: [
                          SizedBox(
                            width: 166,
                            child: RichText(
                              text: TextSpan(
                                text: 'Term Name',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFFFF3B30),
                                ),
                                children: const [TextSpan(text: '*')],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 263.44,
                            height: 40,
                            child: TextField(
                              controller: _nameCtrl,
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: const Color(0xFF111827),
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Due After Row
                      Row(
                        children: [
                          SizedBox(
                            width: 166,
                            child: RichText(
                              text: TextSpan(
                                text: 'Due After',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFFFF3B30),
                                ),
                                children: const [TextSpan(text: '*')],
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 263.44,
                            height: 40,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 211.72,
                                  height: 40,
                                  child: TextField(
                                    controller: _daysCtrl,
                                    keyboardType: TextInputType.number,
                                    textAlignVertical: TextAlignVertical.center,
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 13,
                                      color: const Color(0xFF111827),
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            height: 40,
                                          ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                      enabledBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                      ),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0xFF3B82F6),
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 51.72,
                                  height: 40,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      width: 51.72,
                                      height: 32,
                                      child: DecoratedBox(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF9F9FB),
                                          border: Border(
                                            top: BorderSide(
                                              color: Color(0xFFCBD5E1),
                                            ),
                                            right: BorderSide(
                                              color: Color(0xFFCBD5E1),
                                            ),
                                            bottom: BorderSide(
                                              color: Color(0xFFCBD5E1),
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(4),
                                            bottomRight: Radius.circular(4),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Days',
                                            style: AppTheme.bodyText.copyWith(
                                              fontSize: 13,
                                              color: const Color(0xFF4B5563),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(left: 166),
                          child: Text(
                            _errorText!,
                            style: AppTheme.captionText.copyWith(
                              fontSize: 11,
                              color: const Color(0xFFFF3B30),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 36,
                      child: _SaveButton(onTap: _handleSave),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 36,
                      child: _CancelButton(
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save Button
// ---------------------------------------------------------------------------

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF219F5C) : const Color(0xFF28B36B),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Save',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _CancelButton extends StatefulWidget {
  const _CancelButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFE2E8F0) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            'Cancel',
            style: AppTheme.bodyText.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkActionButton extends StatefulWidget {
  const _BulkActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_BulkActionButton> createState() => _BulkActionButtonState();
}

class _BulkActionButtonState extends State<_BulkActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF8FAFC) : Colors.white,
            border: Border.all(color: const Color(0xFFCBD5E1)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            widget.label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 12.5,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverActionsButton extends StatefulWidget {
  const _HoverActionsButton({
    required this.onTap,
    required this.onEdit,
    required this.onSetDefault,
    required this.onToggleActive,
    required this.onDelete,
    this.isLocked = false,
    this.isActive = true,
  });

  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onSetDefault;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;
  final bool isLocked;
  final bool isActive;

  @override
  State<_HoverActionsButton> createState() => _HoverActionsButtonState();
}

class _HoverActionsButtonState extends State<_HoverActionsButton> {
  bool _hovered = false;
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      alignmentOffset: const Offset(-120, 4),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(6),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
      ),
      menuChildren: widget.isLocked
          ? [
              _DropdownMenuItem(
                icon: LucideIcons.star,
                label: 'Set As Default',
                onTap: widget.onSetDefault,
              ),
            ]
          : [
              _DropdownMenuItem(
                icon: LucideIcons.penTool,
                label: 'Edit',
                onTap: widget.onEdit,
              ),
              _DropdownMenuItem(
                icon: LucideIcons.star,
                label: 'Set As Default',
                onTap: widget.onSetDefault,
              ),
              _DropdownMenuItem(
                icon: LucideIcons.ban,
                label: widget.isActive ? 'Mark as Inactive' : 'Mark as Active',
                onTap: widget.onToggleActive,
              ),
              _DropdownMenuItem(
                icon: LucideIcons.trash2,
                label: 'Delete',
                onTap: widget.onDelete,
              ),
            ],
      builder: (context, controller, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _hovered || controller.isOpen
                    ? const Color(0xFFEFF6FF)
                    : Colors.white,
                border: Border.all(
                  color: _hovered || controller.isOpen
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFCBD5E1),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(
                LucideIcons.moreHorizontal,
                size: 16,
                color: _hovered || controller.isOpen
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DropdownMenuItem extends StatefulWidget {
  const _DropdownMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_DropdownMenuItem> createState() => _DropdownMenuItemState();
}

class _DropdownMenuItemState extends State<_DropdownMenuItem> {
  bool _itemHovered = false;
  bool _itemPressed = false;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.white;
    Color fg = const Color(0xFF334155);
    Color iconColor = const Color(0xFF3B82F6);

    if (_itemHovered) {
      bg = const Color(0xFF3B82F6);
      fg = Colors.white;
      iconColor = Colors.white;
    } else if (_itemPressed) {
      bg = const Color(0xFFE2E8F0);
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _itemHovered = true),
      onExit: (_) => setState(() => _itemHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _itemPressed = true),
        onTapUp: (_) => setState(() => _itemPressed = false),
        onTapCancel: () => setState(() => _itemPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: iconColor),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
