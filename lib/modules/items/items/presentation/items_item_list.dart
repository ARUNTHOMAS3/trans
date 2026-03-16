import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';

import '../controllers/items_controller.dart';
import '../controllers/items_state.dart';
import '../models/item_model.dart';

class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsState = ref.watch(itemsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.4,
        title: const Text(
          "Items",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1F1F),
          ),
        ),
        actions: [
          _searchBar(),
          const SizedBox(width: 12),
          _newItemButton(context),
          const SizedBox(width: 20),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _buildItemsTable(context, itemsState),
      ),
    );
  }

  // -------------------------------
  // SEARCH BAR (zerpai style)
  // -------------------------------
  Widget _searchBar() {
    return Container(
      width: 300,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xffd5d5d5)),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: "Search by name, SKU, category...",
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 8),
        ),
      ),
    );
  }

  // -------------------------------
  // NEW ITEM BUTTON
  // -------------------------------
  Widget _newItemButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.pushNamed(AppRoutes.itemsCreate),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A73E8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      icon: const Icon(Icons.add, color: Colors.white, size: 18),
      label: const Text(
        "New Item",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  // -------------------------------
  // ITEMS TABLE
  // -------------------------------
  Widget _buildItemsTable(BuildContext context, ItemsState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffe3e3e3)),
      ),
      child: Column(
        children: [
          _buildTableer(),
          const Divider(height: 1),
          ...state.items.map((item) => _tableRow(context, item, state)),
        ],
      ),
    );
  }

  // -------------------------------
  // TABLE ER
  // -------------------------------
  Widget _buildTableer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: const [
          Expanded(flex: 4, child: Text("Item Name", style: _erStyle)),
          Expanded(flex: 2, child: Text("SKU", style: _erStyle)),
          Expanded(flex: 2, child: Text("Category", style: _erStyle)),
          Expanded(flex: 2, child: Text("MRP", style: _erStyle)),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  // -------------------------------
  // TABLE ROWS
  // -------------------------------
  Widget _tableRow(BuildContext context, Item item, ItemsState state) {
    return InkWell(
      onTap: () {
        // item details page
        // context.go("/items/${item.id}");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                item.productName,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1F1F1F)),
              ),
            ),
            Expanded(flex: 2, child: Text(item.sku ?? "-", style: _rowStyle)),
            Expanded(
              flex: 2,
              child: Text(
                _getCategoryName(state.categories, item.categoryId),
                style: _rowStyle,
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    size: 16,
                    color: Color(0xff2E2E2E),
                  ),
                  Text(
                    item.mrp?.toStringAsFixed(2) ?? "0.00",
                    style: _rowStyle,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(List<Map<String, dynamic>> categories, String? id) {
    if (id == null || id.isEmpty) return "-";
    try {
      final cat = categories.firstWhere((c) => c['id'] == id);
      return cat['name'] ?? id;
    } catch (_) {
      return id;
    }
  }
}

// -------------------------------
// TEXT STYLES
// -------------------------------
const _erStyle = TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: Color(0xff666666),
);

const _rowStyle = TextStyle(fontSize: 14, color: Color(0xff2E2E2E));
