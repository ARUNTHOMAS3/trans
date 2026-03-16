// lib/modules/items/items/presentation/sections/components/items_stock_find_panels.dart

import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';

class SerialFindPanel extends StatefulWidget {
  final List<SerialData> serials;

  const SerialFindPanel({super.key, required this.serials});

  @override
  State<SerialFindPanel> createState() => _SerialFindPanelState();
}

class _SerialFindPanelState extends State<SerialFindPanel> {
  bool isDropdownOpen = false;
  String searchQuery = '';
  SerialData? selectedSerial;
  String? hoveredSerial;

  void toggleDropdown() {
    setState(() => isDropdownOpen = !isDropdownOpen);
  }

  void selectSerial(SerialData serial) {
    setState(() {
      selectedSerial = serial;
      isDropdownOpen = false;
      searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.serials
        .where(
          (serial) => serial.serialNumber.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Material(
      color: Colors.white,
      elevation: 8,
      child: Container(
        width: 360,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: toggleDropdown,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF60A5FA)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedSerial?.serialNumber ??
                                      'Click or Type to select',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedSerial == null
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Icon(
                                isDropdownOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                                color: const Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isDropdownOpen) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: TextField(
                                    autofocus: true,
                                    onChanged: (value) {
                                      setState(() => searchQuery = value);
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Search',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: 18,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              if (filtered.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'No matches',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map((serial) {
                                  final isSelected =
                                      selectedSerial?.serialNumber ==
                                      serial.serialNumber;
                                  final isHovered =
                                      hoveredSerial == serial.serialNumber;
                                  final showBlue = isHovered;
                                  final showGray = !isHovered && isSelected;

                                  return MouseRegion(
                                    onEnter: (_) => setState(
                                      () => hoveredSerial = serial.serialNumber,
                                    ),
                                    onExit: (_) =>
                                        setState(() => hoveredSerial = null),
                                    child: InkWell(
                                      onTap: () => selectSerial(serial),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        color: showBlue
                                            ? const Color(0xFF3B82F6)
                                            : (showGray
                                                  ? const Color(0xFFE5E7EB)
                                                  : Colors.white),
                                        child: Text(
                                          serial.serialNumber,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: showBlue
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                            fontWeight: showBlue
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            if (selectedSerial == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'No serial number selected',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Serial Number - ${selectedSerial!.serialNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              selectedSerial!.warehouseName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              const Text(
                                'IN',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF22C55E),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFF60A5FA),
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 36,
                                color: const Color(0xFF60A5FA),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Opening Balance',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BatchFindPanel extends StatefulWidget {
  final List<BatchData> batches;

  const BatchFindPanel({super.key, required this.batches});

  @override
  State<BatchFindPanel> createState() => _BatchFindPanelState();
}

class _BatchFindPanelState extends State<BatchFindPanel> {
  bool isDropdownOpen = false;
  String searchQuery = '';
  BatchData? selectedBatch;
  bool showInTransactions = true;
  String? hoveredBatchRef;

  void toggleDropdown() {
    setState(() => isDropdownOpen = !isDropdownOpen);
  }

  void selectBatch(BatchData batch) {
    setState(() {
      selectedBatch = batch;
      isDropdownOpen = false;
      searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.batches
        .where(
          (batch) => batch.batchReference.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Material(
      color: Colors.white,
      elevation: 8,
      child: Container(
        width: 360,
        height: MediaQuery.of(context).size.height,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: toggleDropdown,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF60A5FA)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  selectedBatch?.batchReference ??
                                      'Click or Type to select',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: selectedBatch == null
                                        ? const Color(0xFF6B7280)
                                        : const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Icon(
                                isDropdownOpen
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                                color: const Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isDropdownOpen) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 12,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Container(
                                  height: 36,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFD1D5DB),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: TextField(
                                    autofocus: true,
                                    onChanged: (value) {
                                      setState(() => searchQuery = value);
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Search',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: 18,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ),
                              if (filtered.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text(
                                    'No matches',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map((batch) {
                                  final isSelected =
                                      selectedBatch?.batchReference ==
                                      batch.batchReference;
                                  final isHovered =
                                      hoveredBatchRef == batch.batchReference;
                                  final showBlue = isHovered;
                                  final showGray = !isHovered && isSelected;

                                  return MouseRegion(
                                    onEnter: (_) => setState(
                                      () => hoveredBatchRef =
                                          batch.batchReference,
                                    ),
                                    onExit: (_) =>
                                        setState(() => hoveredBatchRef = null),
                                    child: InkWell(
                                      onTap: () => selectBatch(batch),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        color: showBlue
                                            ? const Color(0xFF3B82F6)
                                            : (showGray
                                                  ? const Color(0xFFE5E7EB)
                                                  : Colors.white),
                                        child: Text(
                                          batch.batchReference,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: showBlue
                                                ? Colors.white
                                                : const Color(0xFF111827),
                                            fontWeight: showBlue
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            if (selectedBatch == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'No batches selected',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedBatch!.batchReference,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manufacturer/Patent Batch#: '
                        '${selectedBatch!.manufacturerBatch.isEmpty ? 'N/A' : selectedBatch!.manufacturerBatch}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            'Manufactured date: '
                            '${selectedBatch!.manufacturedDate.isEmpty ? 'N/A' : selectedBatch!.manufacturedDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Expiry Date: '
                            '${selectedBatch!.expiryDate.isEmpty ? 'N/A' : selectedBatch!.expiryDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quantity In',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedBatch!.quantityIn.toDouble().toStringAsFixed(2)} pcs',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Quantity Available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedBatch!.quantityAvailable.toDouble().toStringAsFixed(2)} pcs',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => showInTransactions = true),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'IN TRANSACTIONS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: showInTransactions
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 2,
                                    color: showInTransactions
                                        ? const Color(0xFF2563EB)
                                        : Colors.transparent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () =>
                                  setState(() => showInTransactions = false),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    'OUT TRANSACTIONS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: !showInTransactions
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 2,
                                    color: !showInTransactions
                                        ? const Color(0xFF2563EB)
                                        : Colors.transparent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (showInTransactions)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Bill : 000099',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Vendor: TEST VENDOR',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Quantity: 5.00    Date: 24-02-2025',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const Center(
                          child: Text(
                            'No outward transactions found.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
