import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:flutter/services.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../shared/widgets/z_skeletons.dart';

class PurchasesVendorsVendorListScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  const PurchasesVendorsVendorListScreen({super.key, this.initialSearchQuery});

  @override
  ConsumerState<PurchasesVendorsVendorListScreen> createState() =>
      _PurchasesVendorsVendorListScreenState();
}

class _PurchasesVendorsVendorListScreenState
    extends ConsumerState<PurchasesVendorsVendorListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
    Future.microtask(() => ref.read(vendorProvider.notifier).loadVendors());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    ref.read(vendorProvider.notifier).setSearchQuery(query);
    ref.read(vendorProvider.notifier).loadVendors(search: query);
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          _searchFocusNode.requestFocus();
        },
      },
      child: ZerpaiLayout(
        pageTitle: 'Vendors',
        enableBodyScroll: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header / Banner Area
            _buildTopBanner(vendorState),

            // Search and Filter Bar
            _buildFilterBar(),

            // Table Content
            Expanded(child: _buildMainContent(vendorState)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBanner(VendorState vendorState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          _buildViewSelector(),
          const Spacer(),
          _buildMsmeUpdateLink(),
          const SizedBox(width: 16),
          _buildNewButton(),
          const SizedBox(width: 8),
          _buildMoreActionsButton(),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'All Vendors',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  Widget _buildMsmeUpdateLink() {
    return InkWell(
      onTap: () {},
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEA580C)),
          SizedBox(width: 8),
          Text(
            'Update MSME Details',
            style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          Icon(Icons.chevron_right, size: 16, color: Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildNewButton() {
    return ElevatedButton.icon(
      onPressed: () => context.push('/purchases/vendors/create'),
      icon: const Icon(Icons.add, size: 18, color: Colors.white),
      label: const Text(
        'New',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
    );
  }

  Widget _buildMoreActionsButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz, size: 18, color: Color(0xFF374151)),
        padding: EdgeInsets.zero,
        onSelected: (value) {},
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'sort', child: Text('Sort by')),
          const PopupMenuItem(value: 'import', child: Text('Import')),
          const PopupMenuItem(value: 'export', child: Text('Export')),
          const PopupMenuItem(value: 'refresh', child: Text('Refresh List')),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 12),
          SizedBox(
            width: 320,
            height: 32,
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _handleSearch,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search in Vendors ( / )',
                prefixIcon: const Icon(Icons.search, size: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(VendorState vendorState) {
    if (vendorState.error != null) {
      return _buildErrorState(vendorState.error!);
    }
    if (!vendorState.isLoading && vendorState.vendors.isEmpty) {
      return const _EmptyVendorState();
    }

    final vendors =
        vendorState.isLoading ? Vendor.dummyList(10) : vendorState.vendors;

    return Skeletonizer(
      ignoreContainers: true,
      enabled: vendorState.isLoading,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMaxHeight: 56,
                    dataRowMinHeight: 48,
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF9FAFB),
                    ),
                    checkboxHorizontalMargin: 16,
                    headingTextStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                    dataTextStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Vendor Number')),
                      DataColumn(label: Text('Company Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Gst Treatment')),
                      DataColumn(label: Text('Source')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: vendors.map((vendor) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              vendor.displayName,
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DataCell(Text(vendor.vendorNumber ?? '')),
                          DataCell(Text(vendor.companyName ?? '')),
                          DataCell(Text(vendor.email ?? '')),
                          DataCell(Text(vendor.phone ?? '')),
                          DataCell(Text(vendor.gstTreatment ?? '')),
                          DataCell(Text(vendor.source ?? 'User')),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  onPressed:
                                      vendorState.isLoading
                                          ? null
                                          : () {
                                            // context.push('/purchases/vendors/edit/${vendor.id}');
                                          },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      vendorState.isLoading
                                          ? null
                                          : () => _showDeleteConfirmation(
                                            context,
                                            vendor,
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return ZErrorPlaceholder(
      error: error,
      onRetry: () => ref.read(vendorProvider.notifier).loadVendors(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Vendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Are you sure you want to delete ${vendor.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(vendorProvider.notifier).deleteVendor(vendor.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EmptyVendorState extends StatelessWidget {
  const _EmptyVendorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            'No vendors found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first vendor to start managing your purchases.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
