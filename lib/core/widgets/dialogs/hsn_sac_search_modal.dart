import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/sales/models/hsn_sac_model.dart';
import 'package:zerpai_erp/modules/sales/services/hsn_sac_lookup_service.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';

class HsnSacSearchModal extends StatefulWidget {
  final String type; // 'HSN' or 'SAC'
  final String? initialQuery;

  const HsnSacSearchModal({super.key, required this.type, this.initialQuery});

  @override
  State<HsnSacSearchModal> createState() => _HsnSacSearchModalState();
}

class _HsnSacSearchModalState extends State<HsnSacSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  final HsnSacLookupService _lookupService = HsnSacLookupService(ApiClient());

  List<HsnSacCode> _results = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.length < 2) {
      setState(() {
        _results = [];
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Both searchHsn and searchSac now call the unified endpoint internally
      // if using the updated HsnSacLookupService.
      final results = widget.type == 'HSN'
          ? await _lookupService.searchHsn(query)
          : await _lookupService.searchSac(query);

      if (!mounted) return;

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error searching ${widget.type}: $e';
        _isLoading = false;
      });
    }
  }

  Widget _highlightText(String text, String query, {TextStyle? style}) {
    final baseStyle =
        style ?? const TextStyle(fontSize: 13, color: Color(0xFF111827));
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(text, style: baseStyle);
    }

    final children = <TextSpan>[];
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();

    int start = 0;
    int index = lowercaseText.indexOf(lowercaseQuery);

    while (index != -1) {
      if (index > start) {
        children.add(
          TextSpan(text: text.substring(start, index), style: baseStyle),
        );
      }

      children.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: baseStyle.copyWith(
            backgroundColor: const Color(0xFFFEF08A), // Light yellow highlight
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
      index = lowercaseText.indexOf(lowercaseQuery, start);
    }

    if (start < text.length) {
      children.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return RichText(text: TextSpan(children: children));
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search ${widget.type} Code',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: Color(0xFFE11D48),
                    ),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: CustomTextField(
                height: 40,
                controller: _searchController,
                hintText: 'Type at least 2 characters to search...',
                prefixIcon: LucideIcons.search,
                onChanged: _onSearchChanged,
                autoFocus: true,
              ),
            ),

            // Loading Indicator
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                minHeight: 2,
              ),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: Color(0xFFDC2626),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Results List
            Flexible(
              child: _results.isEmpty && !_isLoading
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.search,
                              size: 32,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              query.length < 2
                                  ? 'Type at least 2 characters to search'
                                  : 'No results found for "$query"',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: _results.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      itemBuilder: (context, index) {
                        final item = _results[index];
                        return InkWell(
                          onTap: () => Navigator.of(context).pop(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                  child: Text(
                                    item.code,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _highlightText(item.description, query),
                                      if (item.gstRate != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'GST Rate: ${item.gstRate}%',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  LucideIcons.chevronRight,
                                  size: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
