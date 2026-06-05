import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class AdvancedVendorSearchDialog extends StatefulWidget {
  final List<Vendor> vendors;
  final Function(Vendor) onSelect;

  const AdvancedVendorSearchDialog({
    super.key,
    required this.vendors,
    required this.onSelect,
  });

  @override
  State<AdvancedVendorSearchDialog> createState() =>
      _AdvancedVendorSearchDialogState();
}

class _AdvancedVendorSearchDialogState
    extends State<AdvancedVendorSearchDialog> {
  String _selectedCategory = 'Vendor Number';
  final TextEditingController _searchCtrl = TextEditingController();
  List<Vendor> _filteredVendors = [];

  final List<String> _categories = [
    'Vendor Number',
    'Display Name',
    'Company Name',
    'First Name',
    'Last Name',
    'Email',
    'Phone',
  ];

  @override
  void initState() {
    super.initState();
    _filteredVendors = widget.vendors;
  }

  void _onSearch() {
    setState(() {
      final query = _searchCtrl.text.toLowerCase();
      if (query.isEmpty) {
        _filteredVendors = widget.vendors;
        return;
      }

      _filteredVendors = widget.vendors.where((v) {
        switch (_selectedCategory) {
          case 'Vendor Number':
            return (v.vendorNumber ?? '').toLowerCase().contains(query);
          case 'Display Name':
            return v.displayName.toLowerCase().contains(query);
          case 'Company Name':
            return (v.companyName ?? '').toLowerCase().contains(query);
          case 'First Name':
            return (v.firstName ?? '').toLowerCase().contains(query);
          case 'Last Name':
            return (v.lastName ?? '').toLowerCase().contains(query);
          case 'Email':
            return (v.email ?? '').toLowerCase().contains(query);
          case 'Phone':
            return (v.phone ?? '').toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 1000,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      const Text(
                        'Advanced Vendor Search',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textBody,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 480,
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      hoverColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                    ),
                                    child: PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      offset: const Offset(0, 34), // Displays on the bottom of selection list bar nicely
                                      constraints: const BoxConstraints(
                                        minWidth: 190,
                                        maxWidth: 190,
                                      ),
                                      onSelected: (val) =>
                                          setState(() => _selectedCategory = val),
                                      itemBuilder: (ctx) => _categories
                                          .map((c) {
                                            bool isHovered = false;
                                            return PopupMenuItem<String>(
                                              value: c,
                                              padding: EdgeInsets.zero,
                                              height: 38,
                                              child: StatefulBuilder(
                                                builder: (ctx, setStateItem) {
                                                  return MouseRegion(
                                                    onEnter: (_) => setStateItem(() => isHovered = true),
                                                    onExit: (_) => setStateItem(() => isHovered = false),
                                                    child: Container(
                                                      width: double.infinity,
                                                      height: 38,
                                                      alignment: Alignment.centerLeft,
                                                      color: isHovered
                                                          ? const Color(0xFF0052CC)
                                                          : Colors.transparent,
                                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                                      child: Text(
                                                        c,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: isHovered
                                                              ? Colors.white
                                                              : AppTheme.textBody,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          })
                                          .toList(),
                                      child: Container(
                                        width: 190,
                                        height: 32,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.bgLight,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(5),
                                            bottomLeft: Radius.circular(5),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _selectedCategory,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: AppTheme.textBody,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.arrow_drop_down,
                                              color: AppTheme.textSecondary,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const VerticalDivider(
                                    width: 1,
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchCtrl,
                                      onChanged: (_) => _onSearch(),
                                      onSubmitted: (_) => _onSearch(),
                                      style: const TextStyle(fontSize: 14),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        suffixIcon: _searchCtrl.text.isNotEmpty
                                            ? IconButton(
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.clear,
                                                  size: 16,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                onPressed: () {
                                                  _searchCtrl.clear();
                                                  _onSearch();
                                                },
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        color: AppTheme.bgLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'VENDOR NAME',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Text(
                                'EMAIL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'COMPANY NAME',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'PHONE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: _filteredVendors.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    'No vendors found',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: _filteredVendors.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),
                                itemBuilder: (ctx, index) {
                                  final v = _filteredVendors[index];
                                  return InkWell(
                                    onTap: () {
                                      widget.onSelect(v);
                                      Navigator.pop(context);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  v.displayName,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.primaryBlueDark,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                if (v.vendorNumber != null)
                                                  Text(
                                                    v.vendorNumber!,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 5,
                                            child: Text(
                                              v.email ?? '',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSubtle,
                                              ),
                                              softWrap: true,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              v.companyName ?? '-',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSubtle,
                                              ),
                                              softWrap: true,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              v.phone ?? v.mobilePhone ?? '-',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSubtle,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      // Pagination Footer
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.chevronLeft,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '1 - ${_filteredVendors.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    LucideIcons.chevronRight,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
