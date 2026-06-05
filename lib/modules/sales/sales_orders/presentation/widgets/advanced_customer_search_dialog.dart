import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';

// ─── Colour constants (matching Invoice Plus style) ──────────────────────────
const _kBorder = Color(0xFFE5E7EB);
const _kLabelGrey = AppTheme.textSecondary;
const _kBodyText = Color(0xFF111827);
const _kBlue = AppTheme.primaryBlueDark;

class AdvancedCustomerSearchDialog extends StatefulWidget {
  final List<SalesCustomer> customers;
  final ValueChanged<SalesCustomer> onSelect;

  const AdvancedCustomerSearchDialog({
    super.key,
    required this.customers,
    required this.onSelect,
  });

  @override
  State<AdvancedCustomerSearchDialog> createState() =>
      _AdvancedCustomerSearchDialogState();
}

class _AdvancedCustomerSearchDialogState
    extends State<AdvancedCustomerSearchDialog> {
  final _searchCtrl = TextEditingController();
  String _filterBy = 'Customer Number';
  List<SalesCustomer> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.customers;
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = widget.customers.where((c) {
        if (query.isEmpty) return true;
        if (_filterBy == 'Customer Number') {
          return c.customerNumber?.toLowerCase().contains(query) ?? false;
        } else if (_filterBy == 'Customer Name' || _filterBy == 'Display Name') {
          return c.displayName.toLowerCase().contains(query);
        } else if (_filterBy == 'Company Name') {
          return c.companyName?.toLowerCase().contains(query) ?? false;
        } else if (_filterBy == 'First Name') {
          return c.firstName?.toLowerCase().contains(query) ?? false;
        } else if (_filterBy == 'Last Name') {
          return c.lastName?.toLowerCase().contains(query) ?? false;
        } else if (_filterBy == 'Email') {
          return c.email?.toLowerCase().contains(query) ?? false;
        } else if (_filterBy == 'Phone') {
          return c.phone?.toLowerCase().contains(query) ?? false;
        } else if (_filterBy == 'GSTIN') {
          return c.gstin?.toLowerCase().contains(query) ?? false;
        }
        return true;
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
            width: 880,
            constraints: const BoxConstraints(maxHeight: 800),
            margin: const EdgeInsets.symmetric(horizontal: 40),
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
                // ── Header ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                  child: Row(
                    children: [
                      const Text(
                        'Advanced Customer Search',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _kBodyText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Color(0xFFEF4444),
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: _kBorder),

                // ── Search Form ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Combined Filter + Input
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
                                          setState(() => _filterBy = val),
                                      itemBuilder: (ctx) => [
                                            'Customer Number',
                                            'Display Name',
                                            'Company Name',
                                            'First Name',
                                            'Last Name',
                                            'Email',
                                            'Phone',
                                            'GSTIN',
                                          ]
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
                                                _filterBy,
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

                      // ── Table Header ────────────────────────────────────
                      Container(
                        color: AppTheme.bgLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: const Row(
                          children: [
                            Expanded(flex: 3, child: _TH('CUSTOMER NAME')),
                            Expanded(flex: 3, child: _TH('EMAIL')),
                            Expanded(flex: 3, child: _TH('COMPANY NAME')),
                            Expanded(flex: 3, child: _TH('PHONE')),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _kBorder),

                      // ── Table Body ─────────────────────────────────────
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: _kBorder),
                          itemBuilder: (ctx, idx) {
                            final c = _filtered[idx];
                            return InkWell(
                              onTap: () {
                                widget.onSelect(c);
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
                                            c.displayName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: _kBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            c.customerNumber ?? '',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: _kLabelGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        c.email ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSubtle,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        c.companyName ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSubtle,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        c.phone ?? '',
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
                      const Divider(height: 1, color: _kBorder),

                      // ── Footer / Pagination ────────────────────────────
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
                                    '1 - ${_filtered.length}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _kBodyText,
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

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: _kLabelGrey,
        letterSpacing: 0.4,
      ),
    );
  }
}
