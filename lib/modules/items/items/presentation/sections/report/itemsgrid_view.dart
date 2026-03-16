import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/services/storage_service.dart';

import 'item_row.dart';

class ItemsGridView extends StatelessWidget {
  final List<dynamic> items;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final ValueChanged<ItemRow>? onItemTap;

  const ItemsGridView({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final int crossAxisCount = width > 1200
        ? 4
        : width > 900
        ? 3
        : 2;

    Color stockColor(String? value) {
      final double qty = double.tryParse(value ?? '') ?? 0;
      return qty <= 0 ? const Color(0xFFE11D48) : const Color(0xFF16A34A);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.7, // increased height for content
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isSelected = selectedIds.contains(item.selectionId);
        final ValueNotifier<bool> hover = ValueNotifier(false);

        void toggleSelection(bool? value) {
          final updated = Set<String>.from(selectedIds);
          if (value == true) {
            updated.add(item.selectionId);
          } else {
            updated.remove(item.selectionId);
          }
          onSelectionChanged(updated);
        }

        return AspectRatio(
          aspectRatio: 1,
          child: MouseRegion(
            onEnter: (_) => hover.value = true,
            onExit: (_) => hover.value = false,
            child: ValueListenableBuilder<bool>(
              valueListenable: hover,
              builder: (context, isHovered, _) {
                final bool showCheckbox = isHovered || isSelected;
                final Color borderColor = isSelected
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFE5E7EB);

                return GestureDetector(
                  onTap: () => onItemTap?.call(item),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        constraints: const BoxConstraints.expand(),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 86,
                                height: 86,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFDBEAFE),
                                ),
                                alignment: Alignment.center,
                                child:
                                    item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          StorageService.thumbnailUrl(
                                            item.imageUrl!,
                                          ),
                                          width: 86,
                                          height: 86,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons
                                                      .image_not_supported_outlined,
                                                  size: 36,
                                                  color: Color(0xFF94A3B8),
                                                );
                                              },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image_outlined,
                                        size: 36,
                                        color: Color(0xFF2563EB),
                                      ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                item.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Stock on Hand : ${item.stockOnHand ?? '0'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: stockColor(item.stockOnHand),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _PriceRow(
                                label: 'Selling Price',
                                value: item.sellingPrice,
                              ),
                              const SizedBox(height: 6),
                              _PriceRow(
                                label: 'Cost Price',
                                value: item.costPrice,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (showCheckbox)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: toggleSelection,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String? value;

  const _PriceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final display = (value == null || value!.isEmpty) ? '0.00' : value!;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
        children: [
          TextSpan(
            text: '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: display),
        ],
      ),
    );
  }
}
