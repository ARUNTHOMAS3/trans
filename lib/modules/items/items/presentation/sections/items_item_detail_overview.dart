part of '../items_item_detail.dart';

extension _ItemDetailOverview on _ItemDetailScreenState {
  Widget _buildOverviewTab(
    ItemsState state,
    Item item,
    String? unitName,
    String? categoryName,
    String? manufacturerName,
    String? brandName,
    String? purchaseAccountName,
    String? inventoryAccountName,
    String? salesAccountName,
    String? intraStateTaxName,
    String? interStateTaxName,
  ) {
    final reorderTermName = state.reorderTerms
        .firstWhere(
          (rt) => rt['id'] == item.reorderTermId,
          orElse: () => {'name': 'N/A'},
        )['name']
        .toString();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1100;

              final left = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Item Information'),
                  _buildInfoContent([
                    _buildInfoRow(
                      'Item Type',
                      _buildTextValue(
                        item.type == 'service' ? 'Service' : 'Inventory Items',
                      ),
                    ),
                    _buildInfoRow('SKU', _buildTextValue(item.sku)),
                    _buildInfoRow('Item Code', _buildTextValue(item.itemCode)),
                    _buildInfoRow('Unit', _buildTextValue(unitName)),
                    _buildInfoRow('Category', _buildTextValue(categoryName)),
                    _buildInfoRow(
                      'Manufacturer/Patent',
                      _buildTextValue(manufacturerName),
                    ),
                    _buildInfoRow('Brand', _buildTextValue(brandName)),
                    _buildInfoRow(
                      'Tax Preference',
                      _buildTextValue(item.taxPreference),
                    ),
                    _buildInfoRow(
                      item.type == 'service' ? 'SAC Code' : 'HSN Code',
                      _buildTextValue(item.hsnCode),
                    ),
                    _buildInfoRow(
                      'Intra State Tax Rate',
                      _buildTextValue(intraStateTaxName),
                    ),
                    _buildInfoRow(
                      'Inter State Tax Rate',
                      _buildTextValue(interStateTaxName),
                    ),
                    _buildInfoRow('Created Source', _buildTextValue('User')),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Purchase Information'),
                  _buildInfoContent([
                    _buildInfoRow(
                      'Cost Price',
                      _buildMoneyValue(item.costPrice),
                    ),
                    _buildInfoRow(
                      'Purchase Account',
                      _buildTextValue(purchaseAccountName),
                    ),
                    _buildInfoRow(
                      'Preferred Vendor',
                      _buildTextValue(
                        item.preferredVendorName ?? item.preferredVendorId,
                      ),
                    ),
                    _buildInfoRow(
                      'Description',
                      _buildTextValue(item.purchaseDescription),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Sales Information'),
                  _buildInfoContent([
                    _buildInfoRow(
                      'Selling Price',
                      _buildMoneyValue(item.sellingPrice),
                    ),
                    _buildInfoRow('MRP', _buildMoneyValue(item.mrp)),
                    if (item.ptr != null && item.ptr! > 0)
                      _buildInfoRow('PTR', _buildMoneyValue(item.ptr)),
                    _buildInfoRow(
                      'Sales Account',
                      _buildTextValue(salesAccountName),
                    ),
                    _buildInfoRow(
                      'Description',
                      _buildTextValue(item.salesDescription),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Inventory Information'),
                  _buildInfoContent([
                    _buildInfoRow(
                      'Inventory Account',
                      _buildTextValue(inventoryAccountName),
                    ),
                    _buildInfoRow(
                      'Inventory Valuation Method',
                      _buildTextValue(
                        item.inventoryValuationMethod ??
                            'FIFO (First In First Out)',
                      ),
                    ),
                    _buildInfoRow(
                      'Reorder Point',
                      _buildTextValue(item.reorderPoint.toString()),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Dimensions & Weight'),
                  _buildInfoContent([
                    _buildInfoRow(
                      'Dimensions',
                      _buildTextValue(
                        '${item.length ?? 0} x ${item.width ?? 0} x ${item.height ?? 0} ${item.dimensionUnit}',
                      ),
                    ),
                    _buildInfoRow(
                      'Weight',
                      _buildTextValue('${item.weight ?? 0} ${item.weightUnit}'),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Identifiers'),
                  _buildInfoContent([
                    _buildInfoRow('MPN', _buildTextValue(item.mpn)),
                    _buildInfoRow('UPC', _buildTextValue(item.upc)),
                    _buildInfoRow('ISBN', _buildTextValue(item.isbn)),
                    _buildInfoRow('EAN', _buildTextValue(item.ean)),
                  ]),
                  if (item.compositions != null &&
                      item.compositions!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle('Active Ingredients (Compositions)'),
                    const SizedBox(height: 16),
                    ...item.compositions!.map((comp) {
                      return _buildInfoRow(
                        comp.contentName ?? 'Unknown',
                        _buildTextValue(comp.strengthName ?? 'N/A'),
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 24),
                  _buildAssociatedPriceLists(),
                ],
              );

              final right = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageUploadBox(),
                  const SizedBox(height: 32),
                  _buildOpeningStockSection(item),
                  const SizedBox(height: 24),
                  _buildAccountingStockSection(item),
                  const SizedBox(height: 24),
                  _buildPhysicalStockSection(item),
                  const SizedBox(height: 32),
                  _buildStockGridCards(item),
                  const SizedBox(height: 32),
                  _buildReorderPointSection(item, reorderTermName),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [right, const SizedBox(height: 48), left],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: left),
                  const SizedBox(width: 60),
                  Expanded(flex: 4, child: right),
                ],
              );
            },
          ),
          const SizedBox(height: 48),
          _buildSalesOrderSummary(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildInfoContent(List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [const SizedBox(height: 18), ...rows],
    );
  }

  Widget _buildInfoRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  Widget _buildTextValue(String? value) {
    return Text(
      (value == null || value.isEmpty) ? 'N/A' : value,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF111827),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMoneyValue(double? value) {
    return Text(
      '₹${_formatMoney(value)}',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildOpeningStockSection(Item item) {
    return Row(
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 18,
          color: Color(0xFF2563EB),
        ),
        const SizedBox(width: 8),
        const Text(
          'Opening Stock ',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF4B5563),
            fontWeight: FontWeight.w500,
          ),
        ),
        Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
        Text(
          ' : ${_formatQty(item.openingStock ?? 0)}',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountingStockSection(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Accounting Stock',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 16),
        _buildStockMiniRow('Stock on Hand', item.stockOnHand ?? 0.0),
        _buildStockMiniRow('Committed Stock', 0.0),
        _buildStockMiniRow('Available for Sale', item.stockOnHand ?? 0.0),
      ],
    );
  }

  Widget _buildPhysicalStockSection(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Physical Stock',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 16),
        _buildStockMiniRow('Stock on Hand', item.stockOnHand ?? 0.0),
        _buildStockMiniRow('Committed Stock', 0.0),
        _buildStockMiniRow('Available for Sale', item.stockOnHand ?? 0.0),
      ],
    );
  }

  Widget _buildStockGridCards(Item item) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStockStatusCard('0', 'Qty', 'To be Shipped'),
        _buildStockStatusCard('0', 'Qty', 'To be Received'),
        _buildStockStatusCard('0', 'Qty', 'To be Invoiced'),
        _buildStockStatusCard('0', 'Qty', 'To be Billed'),
      ],
    );
  }

  Widget _buildStockStatusCard(String value, String unit, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderPointSection(Item item, String reorderTermName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reorder Point',
                key: _reorderPointKey,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dashed,
                  decorationColor: Color(0xFFD1D5DB),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () =>
                    _showReorderPointDialog(item.id ?? '', item.reorderPoint),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.reorderPoint == 0) ...[
                      const Icon(Icons.add, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        item.reorderPoint.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reorder Terms',
                key: _reorderTermsKey,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dashed,
                  decorationColor: Color(0xFFD1D5DB),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () =>
                    _showReorderTermsDialog(item.id ?? '', item.reorderTermId),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (reorderTermName == 'N/A') ...[
                      const Icon(Icons.add, size: 14, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      const Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        reorderTermName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Color(0xFF2563EB),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesOrderSummary() {
    final GlobalKey dropdownKey = GlobalKey();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Sales Order Summary (In INR)',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                InkWell(
                  key: dropdownKey,
                  onTap: () => _showPeriodDropdown(dropdownKey),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPeriod,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          SizedBox(
            height: 350,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 300,
                    padding: const EdgeInsets.fromLTRB(16, 24, 24, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Y-axis labels
                        SizedBox(
                          width: 40,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildYAxisLabel('5 K'),
                              _buildYAxisLabel('4 K'),
                              _buildYAxisLabel('3 K'),
                              _buildYAxisLabel('2 K'),
                              _buildYAxisLabel('1 K'),
                              _buildYAxisLabel('0'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Graph area
                        Expanded(
                          child: Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  children: [
                                    // Grid lines
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: List.generate(
                                        6,
                                        (index) => Container(
                                          height: 1,
                                          color: const Color(0xFFF3F4F6),
                                        ),
                                      ),
                                    ),
                                    // No data message
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.bar_chart,
                                            size: 48,
                                            color: Colors.grey[200],
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'No data found.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // X-axis labels
                              SizedBox(
                                height: 30,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 16,
                                  itemBuilder: (context, index) {
                                    final day = (index * 2 + 1)
                                        .toString()
                                        .padLeft(2, '0');
                                    return Container(
                                      width: 50,
                                      alignment: Alignment.center,
                                      child: Column(
                                        children: [
                                          Text(
                                            day,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          const Text(
                                            'Jan',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Sales',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F9FF),
                            border: Border(
                              left: BorderSide(
                                color: Color(0xFF0EA5E9),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0EA5E9),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'DIRECT SALES',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '₹0.00',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF111827),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxisLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  void _showPeriodDropdown(GlobalKey key) {
    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _periodDropdownEntry?.remove();
    _periodDropdownEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              _periodDropdownEntry?.remove();
              _periodDropdownEntry = null;
            },
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            left: offset.dx - 150,
            top: offset.dy + size.height + 4,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodOption('This Week'),
                    _buildPeriodOption('Previous Week'),
                    _buildPeriodOption('This Month'),
                    _buildPeriodOption('Previous Month'),
                    _buildPeriodOption('This Quarter'),
                    _buildPeriodOption('Previous Quarter'),
                    _buildPeriodOption('This Year'),
                    _buildPeriodOption('Previous Year'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_periodDropdownEntry!);
  }

  Widget _buildPeriodOption(String period) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      onTap: () {
        updateState(() {
          _selectedPeriod = period;
        });
        _periodDropdownEntry?.remove();
        _periodDropdownEntry = null;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: Color(0xFF3B82F6), width: 3),
                )
              : null,
        ),
        child: Row(
          children: [
            Text(
              period,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : const Color(0xFF374151),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockMiniRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: Color(0xFFD1D5DB),
              ),
            ),
          ),
          Text(
            ' : ${_formatQty(value)}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadBox() {
    return DropTarget(
      onDragEntered: (_) => updateState(() => _isImageDragging = true),
      onDragExited: (_) => updateState(() => _isImageDragging = false),
      onDragDone: (details) {
        updateState(() => _isImageDragging = false);
        _onFilesDropped(details);
      },
      child: SizedBox(
        width: 260,
        height: 220,
        child: DottedBorder(
          color: _isImageDragging
              ? const Color(0xFF3B7CFF)
              : const Color(0xFFD1D5DB),
          strokeWidth: _isImageDragging ? 2 : 1,
          dashPattern: _isImageDragging ? const [1, 0] : const [4, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: _isImageDragging ? const Color(0xFFF0F7FF) : Colors.white,
              child: _itemImages.isEmpty
                  ? InkWell(onTap: _pickItemImages, child: _emptyImageState())
                  : Padding(
                      padding: const EdgeInsets.all(12),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              Expanded(child: _primaryImageView()),
                              const SizedBox(height: 12),
                              _primaryStatusRow(),
                              const SizedBox(height: 12),
                              _thumbnailStrip(),
                            ],
                          ),
                          if (_isImageUploading)
                            Positioned.fill(
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.7),
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFF0F6CBD),
                                              ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Uploading...',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF0F6CBD),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyImageState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 42,
              color: const Color(0xFF6B7280),
            ),
            const SizedBox(height: 12),
            const Text(
              "Drag image(s) here or",
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const Text(
              "Browse images",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "You can add up to 15 images, each not exceeding 5 MB in size and 7000 X 7000 pixels resolution.",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryImageView() {
    final image = _itemImages[_primaryImageIndex];
    return GestureDetector(
      onTap: () => _openImagePreview(startIndex: _primaryImageIndex),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: image is String
            ? Image.network(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _errorImagePlaceholder(),
              )
            : Image.memory(
                (image as PlatformFile).bytes!,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _errorImagePlaceholder() {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  Widget _primaryStatusRow() {
    final bool isPrimary = _primaryImageIndex == 0;
    return Row(
      children: [
        if (isPrimary)
          const Text(
            "Primary",
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w600,
            ),
          )
        else
          InkWell(
            onTap: () {
              updateState(() {
                final img = _itemImages.removeAt(_primaryImageIndex);
                _itemImages.insert(0, img);
                _primaryImageIndex = 0;
              });
              _updateItemImages();
            },
            child: const Text(
              "Set as Primary",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF0F6CBD),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () {
            updateState(() {
              _itemImages.removeAt(_primaryImageIndex);
              if (_primaryImageIndex >= _itemImages.length &&
                  _itemImages.isNotEmpty) {
                _primaryImageIndex = _itemImages.length - 1;
              } else if (_itemImages.isEmpty) {
                _primaryImageIndex = 0;
              }
            });
            _updateItemImages();
          },
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _thumbnailStrip() {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _itemImages.length,
              proxyDecorator: (child, index, animation) =>
                  Material(color: Colors.transparent, child: child),
              onReorder: (oldIndex, newIndex) {
                updateState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _itemImages.removeAt(oldIndex);
                  _itemImages.insert(newIndex, item);

                  // Update primary index if it was moved
                  if (_primaryImageIndex == oldIndex) {
                    _primaryImageIndex = newIndex;
                  } else if (oldIndex < _primaryImageIndex &&
                      newIndex >= _primaryImageIndex) {
                    _primaryImageIndex -= 1;
                  } else if (oldIndex > _primaryImageIndex &&
                      newIndex <= _primaryImageIndex) {
                    _primaryImageIndex += 1;
                  }
                });
                _updateItemImages();
              },
              itemBuilder: (context, index) {
                final image = _itemImages[index];
                final isActive = index == _primaryImageIndex;
                final isUploading = _isImageUploading && image is PlatformFile;

                return Padding(
                  key: ValueKey('thumb_$index'),
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => updateState(() => _primaryImageIndex = index),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF0F6CBD)
                              : const Color(0xFFD1D5DB),
                          width: isActive ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: image is String
                                  ? Image.network(
                                      image,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.broken_image,
                                                size: 16,
                                              ),
                                    )
                                  : Image.memory(
                                      (image as PlatformFile).bytes!,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          if (isUploading)
                            Container(
                              color: Colors.white.withValues(alpha: 0.6),
                              child: const Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0F6CBD),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _pickItemImages,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.add, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _openImagePreview({required int startIndex}) {
    if (_itemImages.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Image Preview'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            SizedBox(
              height: 500,
              child: _itemImages[startIndex] is String
                  ? Image.network(_itemImages[startIndex], fit: BoxFit.contain)
                  : Image.memory(
                      (_itemImages[startIndex] as PlatformFile).bytes!,
                      fit: BoxFit.contain,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
