part of '../items_item_detail.dart';

extension _ItemDetailPriceLists on _ItemDetailScreenState {
  Widget _buildAssociatedPriceLists(ItemsState state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              updateState(() {
                _isPriceListExpanded = !_isPriceListExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Associated Price Lists',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _isPriceListExpanded
                            ? AppTheme.primaryBlueDark
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isPriceListExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.chevron_right,
                    size: 18,
                    color: _isPriceListExpanded
                        ? AppTheme.primaryBlueDark
                        : Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isPriceListExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tabs
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPriceListTab('Sales', 0),
                      _buildPriceListTab('Purchase', 1),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'NAME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'PRICE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'DISCOUNT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price List Rows
                  _buildPriceListRows(state),

                  const SizedBox(height: 8),

                  // Associate Price List button
                  InkWell(
                    onTap: _showAssociatePriceListDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color: AppTheme.primaryBlueDark,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Associate Price List',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlueDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceListTab(String label, int index) {
    final isSelected = _selectedPriceListTab == index;
    return InkWell(
      onTap: () {
        final selectedId =
            widget.itemId ?? ref.read(itemsControllerProvider).selectedItemId;
        final currentItem = ref
            .read(itemsControllerProvider)
            .items
            .cast<Item?>()
            .firstWhere((item) => item?.id == selectedId, orElse: () => null);
        if (currentItem != null) {
          _setSelectedPriceListTab(index, _tabsForItem(currentItem));
        } else {
          updateState(() {
            _selectedPriceListTab = index;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlueDark : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlueDark
                : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textBody,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceListRows(ItemsState state) {
    final type = _selectedPriceListTab == 0 ? 'sales' : 'purchase';
    final filtered = state.associatedPriceLists.where((assoc) {
      final pl = assoc['price_lists'] as Map<String, dynamic>?;
      if (pl == null) return false;
      return pl['transaction_type']?.toString().toLowerCase() == type;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              children: [
                TextSpan(
                  text: _selectedPriceListTab == 0
                      ? 'The sales price lists associated with this item will be displayed here. '
                      : 'The purchase price lists associated with this item will be displayed here. ',
                ),
                const TextSpan(
                  text: 'Create Price List',
                  style: TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((assoc) {
        final pl = assoc['price_lists'] as Map<String, dynamic>;
        final name = pl['name'] ?? 'Unnamed';
        final rate = assoc['custom_rate'] ?? 'N/A';
        final discount = assoc['discount_percentage'] ?? '0.00%';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBody,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  rate.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBody,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  discount.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBody,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showAssociatePriceListDialog() {
    String? selectedId;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            final state = ref.watch(itemsControllerProvider);
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: MediaQuery.of(context).size.width / 2 - 190,
                  child: Material(
                    color: Colors.transparent,
                    child: Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        width: 380,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Associate Price List',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => Navigator.of(context).pop(),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 110,
                                  child: Text(
                                    'Select Price List',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textBody,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 36,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: selectedId,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textBody,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Select a Price List',
                                        hintStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderColor,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.borderColor,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryBlueDark,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                      ),
                                      items: state.priceLists.map((pl) {
                                        return DropdownMenuItem<String>(
                                          value: pl['id']?.toString(),
                                          child: Text(
                                            pl['name'] ?? 'Unnamed',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setPopupState(() {
                                          selectedId = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    if (selectedId != null) {
                                      final success = await ref
                                          .read(
                                            itemsControllerProvider.notifier,
                                          )
                                          .associatePriceList(
                                            productId: widget.itemId!,
                                            priceListId: selectedId!,
                                          );
                                      if (success && mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 9,
                                    ),
                                  ),
                                  child: state.isSaving
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Save',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.textBody,
                                    side: const BorderSide(
                                      color: AppTheme.borderColor,
                                    ),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 9,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
