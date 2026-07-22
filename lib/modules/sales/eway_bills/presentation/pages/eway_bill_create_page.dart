import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/org_scope_resolver.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';

class EWayBillOverviewPage extends StatefulWidget {
  const EWayBillOverviewPage({super.key});

  @override
  State<EWayBillOverviewPage> createState() => _EWayBillOverviewPageState();
}

class _EWayBillOverviewPageState extends State<EWayBillOverviewPage> {
  static const List<String> _documentTypes = <String>[
    'Invoices',
    'Credit Notes',
    'Delivery Challans',
  ];
  static const List<String> _transactionSubTypes = <String>[
    'Supply',
    'Export',
    'SKD/CKD',
  ];
  static const List<String> _locations = <String>[
    'ZABNIX PRIVATE LIMITED',
    'SAHAKAR TIRUR',
  ];
  static const List<_CustomerOption> _customerOptions = <_CustomerOption>[
    _CustomerOption(
      name: 'althaf m',
      code: 'CUS-00022',
      avatarLetter: 'A',
    ),
    _CustomerOption(
      name: 'CUS-1',
      code: 'CUS-00013',
      subtitle: 'zabnixprivat...',
      trailingInfo: 'CUS-1',
      avatarLetter: 'C',
    ),
    _CustomerOption(
      name: 'CUS-2',
      code: 'CUS-00014',
      trailingInfo: 'CUS-2',
      avatarLetter: 'C',
    ),
    _CustomerOption(
      name: 'CUS-3',
      code: 'CUS-00012',
      subtitle: 'test@gmail.c...',
      trailingInfo: 'CUS-3',
      avatarLetter: 'C',
    ),
  ];
  static const List<String> _customerNames = <String>[
    'althaf m',
    'CUS-1',
    'CUS-2',
    'CUS-3',
  ];
  static const List<String> _invoiceNumbers = <String>['INV-000086'];
  static const List<String> _transactionTypes = <String>[
    'Regular',
    'Bill To - Ship To',
    'Bill From - Dispatch From',
    'Combination of 2 and 3',
  ];
  static const List<String> _deliveryStates = <String>[
    '[AN] - Andaman and Nicobar Islands',
    '[AD] - Andhra Pradesh',
    '[AR] - Arunachal Pradesh',
    '[AS] - Assam',
    '[BR] - Bihar',
    '[CH] - Chandigarh',
    '[CG] - Chhattisgarh',
  ];
  static const List<String> _transporters = <String>[
    'Select the transporter\'s name',
  ];
  static const List<_TransportMode> _transportModes = <_TransportMode>[
    _TransportMode(label: 'Road', icon: LucideIcons.truck),
    _TransportMode(label: 'Rail', icon: LucideIcons.train),
    _TransportMode(label: 'Air', icon: LucideIcons.plane),
    _TransportMode(label: 'Ship', icon: LucideIcons.ship),
  ];
  static const List<_ItemDetailRowData> _itemDetailRows = <_ItemDetailRowData>[
    _ItemDetailRowData(
      index: '1',
      itemDescription: 'BATCH TRACK 2',
      hsnCode: '987654',
      quantity: '6',
      unit: 'pcs',
      taxableAmount: '₹690.00',
      cgst: '₹17.25 (2.5%)',
      sgst: '₹17.25 (2.5%)',
      cess: '₹0.00',
    ),
    _ItemDetailRowData(
      index: '2',
      itemDescription: 'BATCH TRACK 3',
      hsnCode: '123456',
      quantity: '5',
      unit: 'pcs',
      taxableAmount: '₹615.00',
      cgst: '₹15.38 (2.5%)',
      sgst: '₹15.38 (2.5%)',
      cess: '₹0.00',
    ),
    _ItemDetailRowData(
      index: '3',
      itemDescription: 'BATCH TRACK 2',
      hsnCode: '123456',
      quantity: '4',
      unit: 'pcs',
      taxableAmount: '₹460.00',
      cgst: '₹11.50 (2.5%)',
      sgst: '₹11.50 (2.5%)',
      cess: '₹0.00',
    ),
  ];
  static const List<_ItemDetailSummaryRow> _itemDetailSummaryRows =
      <_ItemDetailSummaryRow>[
        _ItemDetailSummaryRow(label: 'Taxable Amount', value: '₹1,765.00'),
        _ItemDetailSummaryRow(label: 'CGST2.5 (2.5%)', value: '₹44.13'),
        _ItemDetailSummaryRow(label: 'SGST2.5 (2.5%)', value: '₹44.13'),
        _ItemDetailSummaryRow(label: 'TOTAL', value: '₹1,853.00', isTotal: true),
      ];

  late String _selectedDocumentType;
  late String _selectedTransactionSubType;
  late String _selectedLocation;
  late String _selectedCustomerName;
  late String _selectedInvoiceNumber;
  late String _selectedTransactionType;
  late String _selectedDeliveryState;
  late String _selectedTransporter;
  String _selectedTransportMode = 'Road';
  String _selectedVehicleType = 'Regular';
  bool _showItemDetails = false;
  final GlobalKey _transporterDocDateKey = GlobalKey();
  DateTime? _transporterDocDateValue;
  late final TextEditingController _distanceController;
  late final TextEditingController _vehicleNumberController;
  late final TextEditingController _transporterDocNumberController;
  late final TextEditingController _transporterDocDateController;

  @override
  void initState() {
    super.initState();
    _selectedDocumentType = _documentTypes.first;
    _selectedTransactionSubType = _transactionSubTypes.first;
    _selectedLocation = _locations.first;
    _selectedCustomerName = _customerNames.first;
    _selectedInvoiceNumber = _invoiceNumbers.first;
    _selectedTransactionType = _transactionTypes.first;
    _selectedDeliveryState = _deliveryStates.first;
    _selectedTransporter = _transporters.first;
    _distanceController = TextEditingController(text: '0');
    _vehicleNumberController = TextEditingController();
    _transporterDocNumberController = TextEditingController();
    _transporterDocDateController = TextEditingController();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _vehicleNumberController.dispose();
    _transporterDocNumberController.dispose();
    _transporterDocDateController.dispose();
    super.dispose();
  }

  void _closePage() {
    final orgId = resolveOrgSystemId(context);
    context.go('/$orgId${AppRoutes.salesEWayBills}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopSection(),
                  _buildMiddleSection(),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.fileSpreadsheet,
            size: 24,
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 10),
          Text(
            'New e-Way Bill',
            style: AppTheme.pageTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _closePage,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                LucideIcons.x,
                size: 24,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      color: AppTheme.bgLight,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        children: [
          _buildFormRow(
            label: 'Document Type*',
            child: _buildDropdown(
              value: _selectedDocumentType,
              items: _documentTypes,
              width: 315,
              showSearch: true,
              menuMaxHeight: 160,
              fieldFontSize: 13.5,
              itemFontSize: 13.5,
              showSelectedBanner: true,
              showSelectedTick: true,
              onChanged: (value) => setState(() => _selectedDocumentType = value),
            ),
          ),
          const SizedBox(height: 14),
          _buildFormRow(
            label: 'Transaction Sub Type*',
            child: _buildDropdown(
              value: _selectedTransactionSubType,
              items: _transactionSubTypes,
              width: 315,
              showSearch: true,
              menuMaxHeight: 160,
              fieldFontSize: 13.5,
              itemFontSize: 13.5,
              showSelectedBanner: true,
              showSelectedTick: true,
              onChanged: (value) =>
                  setState(() => _selectedTransactionSubType = value),
            ),
          ),
          const SizedBox(height: 14),
          _buildFormRow(
            label: 'Location*',
            child: _buildDropdown(
              value: _selectedLocation,
              items: _locations,
              width: 315,
              showSearch: true,
              menuMaxHeight: 140,
              fieldFontSize: 13.5,
              itemFontSize: 13.5,
              showSelectedBanner: true,
              showSelectedTick: true,
              onChanged: (value) => setState(() => _selectedLocation = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
      child: Column(
        children: [
          _buildFormRow(
            label: 'Customer Name*',
            child: _buildDropdown(
              value: _selectedCustomerName,
              items: _customerNames,
              width: 315,
              showSearch: true,
              menuMaxHeight: 260,
              fieldFontSize: 13.5,
              itemFontSize: 13.5,
              showSelectedBanner: true,
              showSelectedTick: true,
              itemHeight: 58,
              customItemBuilder: _buildCustomerDropdownItem,
              onChanged: (value) => setState(() => _selectedCustomerName = value),
            ),
          ),
          const SizedBox(height: 12),
          _buildInvoiceDateRow(),
          const SizedBox(height: 12),
          _buildFormRow(
            label: 'Transaction Type*',
            child: _buildDropdown(
              value: _selectedTransactionType,
              items: _transactionTypes,
              width: 315,
              showSearch: true,
              menuMaxHeight: 180,
              fieldFontSize: 13.5,
              itemFontSize: 13.5,
              showSelectedBanner: true,
              showSelectedTick: true,
              onChanged: (value) =>
                  setState(() => _selectedTransactionType = value),
            ),
          ),
          const SizedBox(height: 18),
          _buildAddressSection(),
          const SizedBox(height: 22),
          _buildFormRow(
            label: 'Place of Delivery*',
            child: _buildDropdown(
              value: _selectedDeliveryState,
              items: _deliveryStates,
              width: 315,
              showSearch: true,
              menuMaxHeight: 220,
              fieldFontSize: 13.5,
              itemFontSize: 13.5,
              showSelectedBanner: true,
              showSelectedTick: true,
              onChanged: (value) =>
                  setState(() => _selectedDeliveryState = value),
            ),
          ),
          const SizedBox(height: 14),
          _buildItemDetailsRow(),
          if (_showItemDetails) ...[
            const SizedBox(height: 16),
            _buildItemDetailsTable(),
          ],
          const SizedBox(height: 22),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 24),
          _buildTransportationSection(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildInvoiceDateRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 255,
          child: Text(
            'Invoice*',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.errorRed,
              fontFamily: 'Inter',
            ),
          ),
        ),
        _buildDropdown(
          value: _selectedInvoiceNumber,
          items: _invoiceNumbers,
          width: 315,
          onChanged: (value) => setState(() => _selectedInvoiceNumber = value),
        ),
        const SizedBox(width: 28),
        const SizedBox(
          width: 58,
          child: Text(
            'Date',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ),
        _buildReadOnlyField(
          value: '30-05-2026',
          width: 144,
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 255,
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Address Details',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildAddressColumn(
                  title: 'DISPATCH FROM',
                  showEditIcon: true,
                  lines: const [
                    'PERINTHALMANNA',
                    'MALAPPURAM',
                    'Kerala',
                    'India - 679322',
                  ],
                ),
              ),
              Expanded(
                child: _buildAddressColumn(
                  title: 'BILL FROM',
                  lines: const [
                    'PERINTHALMANNA',
                    'MALAPPURAM',
                    'Kerala',
                    'India - 679322',
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 104,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: AppTheme.borderLight,
              ),
              Expanded(
                child: _buildAddressColumn(
                  title: 'BILL TO',
                  lines: const [
                    'malayanakath(h) vengoor (po)',
                    'perinthalmanna',
                    'Kerala',
                    'India - 679322',
                  ],
                ),
              ),
              Expanded(
                child: _buildAddressColumn(
                  title: 'SHIP TO',
                  lines: const [
                    'malayanakath(h) vengoor',
                    'PERINTHALMANNA',
                    'perinthalmanna',
                    'India - 679322',
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressColumn({
    required String title,
    required List<String> lines,
    bool showEditIcon = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
            if (showEditIcon) ...[
              const SizedBox(width: 6),
              Icon(
                LucideIcons.pencil,
                size: 12,
                color: AppTheme.textSecondary,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
                height: 1.25,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemDetailsRow() {
    return Row(
      children: [
        InkWell(
          onTap: () => setState(() => _showItemDetails = !_showItemDetails),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 15,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Item Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showItemDetails
                      ? Icons.keyboard_arrow_down
                      : Icons.chevron_right,
                  size: 16,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemDetailsTable() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderLight),
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Column(
            children: [
              _buildItemDetailsHeader(),
              for (int index = 0; index < _itemDetailRows.length; index++) ...[
                _buildItemDetailsDataRow(_itemDetailRows[index]),
                if (index != _itemDetailRows.length - 1)
                  const Divider(height: 1, color: AppTheme.borderLight),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(right: 96),
          child: Align(
            alignment: Alignment.centerRight,
            child: _buildItemDetailsSummaryCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemDetailsHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(10, 12, 10, 11),
      child: Row(
        children: [
          SizedBox(width: 36, child: _ItemTableHeaderCell('#')),
          SizedBox(width: 192, child: _ItemTableHeaderCell('Item & Description')),
          SizedBox(width: 130, child: _ItemTableHeaderCell('HSN Code')),
          SizedBox(width: 130, child: _ItemTableHeaderCell('Quantity')),
          SizedBox(width: 166, child: _ItemTableHeaderCell('Taxable Amount')),
          SizedBox(width: 148, child: _ItemTableHeaderCell('CGST')),
          SizedBox(width: 118, child: _ItemTableHeaderCell('SGST')),
          SizedBox(width: 50, child: _ItemTableHeaderCell('Cess')),
        ],
      ),
    );
  }

  Widget _buildItemDetailsDataRow(_ItemDetailRowData row) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 36, child: _buildItemTableText(row.index)),
          SizedBox(width: 192, child: _buildItemTableText(row.itemDescription)),
          SizedBox(width: 130, child: _buildItemTableText(row.hsnCode)),
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildItemTableText(row.quantity, textAlign: TextAlign.center),
                const SizedBox(height: 2),
                _buildItemTableText(
                  row.unit,
                  textAlign: TextAlign.center,
                  color: const Color(0xFF475467),
                ),
              ],
            ),
          ),
          SizedBox(width: 166, child: _buildItemTableText(row.taxableAmount)),
          SizedBox(width: 148, child: _buildItemTableText(row.cgst)),
          SizedBox(width: 118, child: _buildItemTableText(row.sgst)),
          SizedBox(width: 50, child: _buildItemTableText(row.cess)),
        ],
      ),
    );
  }

  Widget _buildItemTableText(
    String value, {
    TextAlign textAlign = TextAlign.left,
    Color color = AppTheme.textPrimary,
  }) {
    return Text(
      value,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
        fontFamily: 'Inter',
        height: 1.35,
      ),
    );
  }

  Widget _buildItemDetailsSummaryCard() {
    return Container(
      width: 344,
      padding: const EdgeInsets.fromLTRB(30, 20, 20, 18),
      color: const Color(0xFFFAFBFC),
      child: Column(
        children: _itemDetailSummaryRows.map((row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row.isTotal ? 0 : 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    row.label,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: row.isTotal ? 14 : 13,
                      fontWeight:
                          row.isTotal ? FontWeight.w700 : FontWeight.w500,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                SizedBox(
                  width: 86,
                  child: Text(
                    row.value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: row.isTotal ? 14 : 13,
                      fontWeight:
                          row.isTotal ? FontWeight.w700 : FontWeight.w500,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildTransportationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TRANSPORTATION DETAILS',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 22),
        _buildFormRow(
          label: 'Transporter',
          labelColor: AppTheme.textPrimary,
          child: _buildDropdown(
            value: _selectedTransporter,
            items: _transporters,
            width: 315,
            textColor: AppTheme.textPrimary,
            onChanged: (value) => setState(() => _selectedTransporter = value),
          ),
        ),
        const SizedBox(height: 14),
        _buildDistanceRow(),
        const SizedBox(height: 30),
        const Text(
          'PART B',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 22),
        _buildTransportModeRow(),
        const SizedBox(height: 16),
        _buildVehicleTypeRow(),
        const SizedBox(height: 16),
        _buildFormRow(
          label: 'Vehicle No',
          labelColor: AppTheme.textPrimary,
          child: _buildTextField(
            controller: _vehicleNumberController,
          ),
        ),
        const SizedBox(height: 12),
        _buildFormRow(
          label: _partBDocNumberLabel,
          labelColor: AppTheme.textPrimary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _transporterDocNumberController,
              ),
              if (_partBDocNumberHelper != null) ...[
                const SizedBox(height: 7),
                SizedBox(
                  width: 315,
                  child: Text(
                    _partBDocNumberHelper!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475467),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildFormRow(
          label: _partBDocDateLabel,
          labelColor: AppTheme.textPrimary,
          child: Container(
            key: _transporterDocDateKey,
            child: _buildTextField(
              controller: _transporterDocDateController,
              hintText: 'dd-MM-yyyy',
              hintColor: AppTheme.textPrimary,
              readOnly: true,
              suffixWidget: const Icon(
                LucideIcons.calendar,
                size: 15,
                color: AppTheme.textSecondary,
              ),
              onTap: () async {
                final picked = await ZerpaiDatePicker.show(
                  context,
                  initialDate: _transporterDocDateValue ?? DateTime.now(),
                  targetKey: _transporterDocDateKey,
                  openAbove: true,
                );
                if (picked == null) return;
                setState(() {
                  _transporterDocDateValue = picked;
                  _transporterDocDateController.text = DateFormat(
                    'dd-MM-yyyy',
                  ).format(picked);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 255,
          child: Padding(
            padding: EdgeInsets.only(top: 9),
            child: Text(
              'Distance (in Km)*',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.errorRed,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 7),
            const SizedBox(
              width: 382,
              child: Text(
                'If you enter 0 as the distance, e-Way Bill system will\n'
                'automatically calculate it based on the dispatch and\n'
                'delivery locations.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475467),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 28),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: InkWell(
            onTap: () {},
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Calculate Distance',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.open_in_new,
                  size: 13,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String get _partBDocNumberLabel {
    switch (_selectedTransportMode) {
      case 'Rail':
        return 'RR No';
      case 'Air':
        return 'Airway Bill No';
      case 'Ship':
        return 'Bill of Lading No';
      case 'Road':
      default:
        return 'Transporter\'s Doc No';
    }
  }

  String get _partBDocDateLabel {
    switch (_selectedTransportMode) {
      case 'Rail':
        return 'RR Date';
      case 'Air':
        return 'Airway Bill Date';
      case 'Ship':
        return 'Bill of Lading Date';
      case 'Road':
      default:
        return 'Transporter\'s Doc Date';
    }
  }

  String? get _partBDocNumberHelper {
    if (_selectedTransportMode != 'Rail') return null;
    return 'Learn more about the RR number format that applies\n'
        'to your parcel system.';
  }

  Widget _buildTransportModeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(
          width: 255,
          child: Text(
            'Mode of Transportation',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _transportModes
              .map((mode) => _buildModeChip(mode))
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildModeChip(_TransportMode mode) {
    final bool isSelected = _selectedTransportMode == mode.label;
    return InkWell(
      onTap: () => setState(() => _selectedTransportMode = mode.label),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FBFF) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF7DB2FF) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(mode.icon, size: 17, color: AppTheme.textPrimary),
            const SizedBox(width: 5),
            Text(
              mode.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeRow() {
    return Row(
      children: [
        const SizedBox(
          width: 255,
          child: Text(
            'Vehicle Type',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Row(
          children: [
            _buildVehicleTypeOption('Regular'),
            const SizedBox(width: 14),
            _buildVehicleTypeOption('Over Dimensional Cargo'),
          ],
        ),
      ],
    );
  }

  Widget _buildVehicleTypeOption(String value) {
    final bool isSelected = _selectedVehicleType == value;
    return InkWell(
      onTap: () => setState(() => _selectedVehicleType = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.borderColor,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow({
    required String label,
    required Widget child,
    Color? labelColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 255,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: labelColor ??
                  (label.contains('*')
                      ? AppTheme.errorRed
                      : AppTheme.textPrimary),
              fontFamily: 'Inter',
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required double width,
    required ValueChanged<String> onChanged,
    Color textColor = AppTheme.textPrimary,
    bool showSearch = false,
    double menuMaxHeight = 160,
    double fieldFontSize = 13,
    double itemFontSize = 13,
    bool showSelectedBanner = false,
    bool showSelectedTick = false,
    double itemHeight = 34,
    Widget Function(String item, bool isSelected, bool isHovered)? customItemBuilder,
  }) {
    return SizedBox(
      width: width,
      child: FormDropdown<String>(
        value: value,
        items: items,
        onChanged: (next) {
          if (next == null) return;
          onChanged(next);
        },
        height: 32,
        showSearch: showSearch,
        showSettings: false,
        boldSelected: false,
        paintSelectionBackground: false,
        menuWidth: width,
        menuMaxHeight: menuMaxHeight,
        maxVisibleItems: items.length,
        itemHeight: itemHeight,
        borderRadius: BorderRadius.circular(5),
        textStyle: TextStyle(
          fontSize: fieldFontSize,
          fontWeight: FontWeight.w500,
          color: textColor,
          fontFamily: 'Inter',
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemBuilder: (item, isSelected, isHovered) {
          if (customItemBuilder != null) {
            return customItemBuilder(item, isSelected, isHovered);
          }
          final bool isActive = isHovered;
          final bool showBanner = showSelectedBanner && isSelected && !isActive;
          return Padding(
            padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryBlue
                    : showBanner
                        ? const Color(0xFFEFF3FB)
                        : Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: itemFontSize,
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : AppTheme.textPrimary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  if (showSelectedTick && isSelected)
                    Icon(
                      Icons.check,
                      size: 15,
                      color: isActive ? Colors.white : const Color(0xFF8B98B6),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomerDropdownItem(
    String item,
    bool isSelected,
    bool isHovered,
  ) {
    final _CustomerOption option = _customerOptions.firstWhere(
      (entry) => entry.name == item,
      orElse: () => _CustomerOption(name: item, code: '', avatarLetter: item[0]),
    );
    final bool showBanner = isSelected && !isHovered;
    final Color backgroundColor = isHovered
        ? AppTheme.primaryBlue
        : showBanner
            ? const Color(0xFFEFF3FB)
            : Colors.white;
    final Color primaryColor = isHovered ? Colors.white : AppTheme.textPrimary;
    final Color secondaryColor = isHovered
        ? Colors.white.withValues(alpha: 0.92)
        : const Color(0xFF8B98B6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHovered ? Colors.white.withValues(alpha: 0.18) : Colors.white,
                border: Border.all(
                  color: isHovered
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                option.avatarLetter,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isHovered ? Colors.white : const Color(0xFF94A3B8),
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          option.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      if (option.code.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            option.code,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: secondaryColor,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (option.subtitle != null || option.trailingInfo != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (option.subtitle != null) ...[
                          Icon(
                            Icons.mail_outline,
                            size: 13,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              option.subtitle!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: secondaryColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                        if (option.trailingInfo != null) ...[
                          if (option.subtitle != null) const SizedBox(width: 10),
                          Icon(
                            Icons.copy_outlined,
                            size: 13,
                            color: secondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              option.trailingInfo!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: secondaryColor,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                size: 16,
                color: isHovered ? Colors.white : const Color(0xFF8B98B6),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required double width,
  }) {
    return Container(
      width: width,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String hintText = '',
    Color hintColor = AppTheme.textPrimary,
    double width = 315,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixWidget,
  }) {
    return SizedBox(
      width: width,
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: hintColor,
                  fontFamily: 'Inter',
                ),
              ),
        ),
        child: CustomTextField(
          controller: controller,
          hintText: hintText,
          height: 32,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          suffixWidget: suffixWidget,
          forceUppercase: false,
          contentCase: ContentCase.none,
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          _buildActionButton(
            label: 'Save',
            onPressed: () {},
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
            horizontalPadding: 14,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            label: 'Save and Generate',
            onPressed: () {},
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
            horizontalPadding: 14,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            label: 'Cancel',
            onPressed: _closePage,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimary,
            borderColor: AppTheme.borderColor,
            horizontalPadding: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    required double horizontalPadding,
  }) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: borderColor ?? backgroundColor),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: foregroundColor,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _TransportMode {
  final String label;
  final IconData icon;

  const _TransportMode({
    required this.label,
    required this.icon,
  });
}

class _ItemDetailRowData {
  final String index;
  final String itemDescription;
  final String hsnCode;
  final String quantity;
  final String unit;
  final String taxableAmount;
  final String cgst;
  final String sgst;
  final String cess;

  const _ItemDetailRowData({
    required this.index,
    required this.itemDescription,
    required this.hsnCode,
    required this.quantity,
    required this.unit,
    required this.taxableAmount,
    required this.cgst,
    required this.sgst,
    required this.cess,
  });
}

class _ItemDetailSummaryRow {
  final String label;
  final String value;
  final bool isTotal;

  const _ItemDetailSummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });
}

class _ItemTableHeaderCell extends StatelessWidget {
  final String label;

  const _ItemTableHeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF667085),
        fontFamily: 'Inter',
      ),
    );
  }
}

class _CustomerOption {
  final String name;
  final String code;
  final String? subtitle;
  final String? trailingInfo;
  final String avatarLetter;

  const _CustomerOption({
    required this.name,
    required this.code,
    this.subtitle,
    this.trailingInfo,
    required this.avatarLetter,
  });
}
