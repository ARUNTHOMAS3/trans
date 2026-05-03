import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';

// ─── Colour constants (matching Invoice Plus style) ──────────────────────────
const _kBorder = Color(0xFFE5E7EB);
const _kLabelGrey = AppTheme.textSecondary;
const _kBodyText = Color(0xFF111827);
const _kBlue = AppTheme.primaryBlueDark;
const _kGreen = Color(0xFF16A34A);

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
        } else if (_filterBy == 'Customer Name') {
          return c.displayName.toLowerCase().contains(query);
        } else if (_filterBy == 'Email') {
          return c.email?.toLowerCase().contains(query) ?? false;
        } else if (_filterBy == 'Phone') {
          return c.phone?.toLowerCase().contains(query) ?? false;
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
                          Container(
                            width: 580,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  onSelected: (v) =>
                                      setState(() => _filterBy = v),
                                  itemBuilder: (ctx) => [
                                    'Customer Number',
                                    'Customer Name',
                                    'Email',
                                    'Phone',
                                  ]
                                      .map(
                                        (e) => PopupMenuItem(
                                          value: e,
                                          padding: EdgeInsets.zero,
                                          height: 38,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text(
                                              e,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
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
                                const VerticalDivider(
                                  width: 1,
                                  color: Color(0xFFD1D5DB),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _searchCtrl,
                                    style: const TextStyle(fontSize: 14),
                                    decoration: const InputDecoration(
                                      hintText: null,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                    ),
                                    onSubmitted: (_) => _onSearch(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(90, 32),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: _onSearch,
                            child: const Text(
                              'Search',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
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
