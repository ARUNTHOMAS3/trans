// ignore_for_file: unused_element, unused_field, dead_code, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/modules/sales/recurring_invoices/models/recurring_invoices_model.dart' as provider_model;
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/file_upload_button.dart';
import 'package:zerpai_erp/shared/widgets/document/zerpai_document_view.dart';



// ─── Models ─────────────────────────────────────────────────────────────────



class ChildInvoiceUI {

  final String id;

  final String date;

  final double amount;

  final String status;

  final String source;

  const ChildInvoiceUI({

    required this.id,

    required this.date,

    required this.amount,

    required this.status,

    required this.source,

  });

}



class RecurringInvoiceUI {

  final String id;

  final String customerName;

  final String date;

  final double amount;

  final double balanceDue;

  final String status;

  final String drawStatus;

  final String companyName;

  final List<String> companyAddress;

  final String companyGstin;

  final String companyPhone;

  final String companyEmail;

  final List<String> billToAddress;

  final List<RetainerInvoiceItem> items;

  final String profileName;

  final String billingFrequency;

  final String nextInvoiceDate;

  final int manuallyCreatedInvoices;

  final List<String> billingAddress;

  final List<String> shippingAddress;

  final List<ChildInvoiceUI> childInvoices;

  final String startDate;

  final String endDate;

  final String paymentTerms;

  final String salesperson;



  const RecurringInvoiceUI({

    required this.id,

    required this.customerName,

    required this.date,

    required this.amount,

    required this.balanceDue,

    required this.status,

    required this.drawStatus,

    required this.companyName,

    required this.companyAddress,

    required this.companyGstin,

    required this.companyPhone,

    required this.companyEmail,

    required this.billToAddress,

    required this.items,

    required this.profileName,

    required this.billingFrequency,

    required this.nextInvoiceDate,

    required this.manuallyCreatedInvoices,

    required this.billingAddress,

    required this.shippingAddress,

    required this.childInvoices,

    required this.startDate,

    required this.endDate,

    required this.paymentTerms,

    required this.salesperson,

  });

}



class RetainerInvoiceItem {

  final int index;

  final String description;

  final double amount;



  const RetainerInvoiceItem({

    required this.index,

    required this.description,

    required this.amount,

  });

}



class FilterItem {

  final String label;

  const FilterItem(this.label);

}

class _ItemMappingReportRow {
  final String vendorName;
  final String vendorProductName;
  final String vendorProductCode;
  final String status;

  const _ItemMappingReportRow({
    required this.vendorName,
    required this.vendorProductName,
    required this.vendorProductCode,
    this.status = 'Active',
  });
}

class _PurchaseOfferReportRow {
  final String vendorName;
  final String offerScheme;
  final String validityFrom;
  final String validityTill;
  final String status;

  const _PurchaseOfferReportRow({
    required this.vendorName,
    required this.offerScheme,
    required this.validityFrom,
    required this.validityTill,
    this.status = 'Active',
  });
}

class _SalesOfferReportRow {
  final String customerName;
  final String offerScheme;
  final String validityFrom;
  final String validityTill;
  final String status;

  const _SalesOfferReportRow({
    required this.customerName,
    required this.offerScheme,
    required this.validityFrom,
    required this.validityTill,
    this.status = 'Active',
  });
}

const List<_ItemMappingReportRow> _dummyItemMappingRows = [

  _ItemMappingReportRow(

    vendorName: 'Alpha Distributors',

    vendorProductName: 'Paracetamol 650mg Tablet',

    vendorProductCode: 'ALP-PCM-650',

  ),

  _ItemMappingReportRow(

    vendorName: 'Medisource Traders',

    vendorProductName: 'Azithromycin 500mg Tablet',

    vendorProductCode: 'MED-VITC-500',

  ),

  _ItemMappingReportRow(

    vendorName: 'CarePlus Wholesale',

    vendorProductName: 'Amoxicillin 250mg Capsule',

    vendorProductCode: 'CP-AMX-250',

  ),

];

List<_ItemMappingReportRow> _dummyRowsForItem(String itemName) {

  switch (itemName) {

    case 'Paracetamol 650mg Tablet':
      return const [
        _ItemMappingReportRow(
          vendorName: 'Alpha Distributors',
          vendorProductName: 'Paracetamol 650mg Tablet',
          vendorProductCode: 'ALP-PCM-650',
        ),
        _ItemMappingReportRow(
          vendorName: 'Medline Agencies',
          vendorProductName: 'PCM 650 Tab',
          vendorProductCode: 'MLA-PCM-650',
        ),
        _ItemMappingReportRow(
          vendorName: 'HealthBridge Pharma',
          vendorProductName: 'Paracetamol 650',
          vendorProductCode: 'HBP-P650',
        ),
      ];

    case 'Azithromycin 500mg Tablet':
      return const [
        _ItemMappingReportRow(
          vendorName: 'Medisource Traders',
          vendorProductName: 'Azithromycin 500mg Tablet',
          vendorProductCode: 'MED-AZM-500',
        ),
        _ItemMappingReportRow(
          vendorName: 'Curewell Suppliers',
          vendorProductName: 'Azithro 500 Tab',
          vendorProductCode: 'CWS-AZI-500',
        ),
        _ItemMappingReportRow(
          vendorName: 'PrimeRx Wholesale',
          vendorProductName: 'Azithromycin 500',
          vendorProductCode: 'PRX-AZM500',
        ),
      ];

    case 'Amoxicillin 250mg Capsule':
      return const [
        _ItemMappingReportRow(
          vendorName: 'CarePlus Wholesale',
          vendorProductName: 'Amoxicillin 250mg Capsule',
          vendorProductCode: 'CP-AMX-250',
        ),
        _ItemMappingReportRow(
          vendorName: 'Metro Medico',
          vendorProductName: 'Amoxycillin 250 Cap',
          vendorProductCode: 'MM-AMX-250',
        ),
        _ItemMappingReportRow(
          vendorName: 'LifeCare Distributors',
          vendorProductName: 'Amoxicillin 250',
          vendorProductCode: 'LCD-AMO250',
        ),
      ];

    case 'Cetirizine 10mg Tablet':
      return const [
        _ItemMappingReportRow(
          vendorName: 'Nova Pharma Supply',
          vendorProductName: 'Cetirizine 10mg Tablet',
          vendorProductCode: 'NPS-CTZ-010',
        ),
        _ItemMappingReportRow(
          vendorName: 'Wellness Drug House',
          vendorProductName: 'Cetri 10 Tab',
          vendorProductCode: 'WDH-CTZ-010',
        ),
        _ItemMappingReportRow(
          vendorName: 'Apex Pharma Links',
          vendorProductName: 'Cetirizine 10',
          vendorProductCode: 'APL-CET10',
        ),
      ];

    case 'Pantoprazole 40mg Tablet':
      return const [
        _ItemMappingReportRow(
          vendorName: 'Zenmed Agencies',
          vendorProductName: 'Pantoprazole 40mg Tablet',
          vendorProductCode: 'ZEN-PAN-040',
        ),
        _ItemMappingReportRow(
          vendorName: 'GastroCare Pharma',
          vendorProductName: 'Pantop 40 Tab',
          vendorProductCode: 'GCP-PAN-040',
        ),
        _ItemMappingReportRow(
          vendorName: 'Southline Medics',
          vendorProductName: 'Pantoprazole 40',
          vendorProductCode: 'SLM-P40',
        ),
      ];

    default:
      return _dummyItemMappingRows;

  }

}

List<_PurchaseOfferReportRow> _dummyPurchaseOffersForItem(String itemName) {

  switch (itemName) {

    case 'Paracetamol 650mg Tablet':
      return const [
        _PurchaseOfferReportRow(
          vendorName: 'Alpha Distributors',
          offerScheme: 'BUY 10 GET 1 FREE',
          validityFrom: '01-09-2026',
          validityTill: '30-09-2026',
        ),
        _PurchaseOfferReportRow(
          vendorName: 'Medline Agencies',
          offerScheme: 'BUY 20 GET 3 FREE',
          validityFrom: '16-09-2026',
          validityTill: '15-10-2026',
        ),
      ];

    case 'Azithromycin 500mg Tablet':
      return const [
        _PurchaseOfferReportRow(
          vendorName: 'Medisource Traders',
          offerScheme: 'BUY 5 GET 1 FREE',
          validityFrom: '01-08-2026',
          validityTill: '31-08-2026',
        ),
        _PurchaseOfferReportRow(
          vendorName: 'PrimeRx Wholesale',
          offerScheme: 'BUY 12 GET 2 FREE',
          validityFrom: '21-08-2026',
          validityTill: '20-09-2026',
        ),
      ];

    case 'Amoxicillin 250mg Capsule':
      return const [
        _PurchaseOfferReportRow(
          vendorName: 'CarePlus Wholesale',
          offerScheme: 'BUY 15 GET 2 FREE',
          validityFrom: '13-10-2026',
          validityTill: '12-11-2026',
        ),
        _PurchaseOfferReportRow(
          vendorName: 'Metro Medico',
          offerScheme: 'BUY 8 GET 1 FREE',
          validityFrom: '26-11-2026',
          validityTill: '25-12-2026',
        ),
      ];

    case 'Cetirizine 10mg Tablet':
      return const [
        _PurchaseOfferReportRow(
          vendorName: 'Nova Pharma Supply',
          offerScheme: 'BUY 10 GET 2 FREE',
          validityFrom: '06-09-2026',
          validityTill: '05-10-2026',
        ),
        _PurchaseOfferReportRow(
          vendorName: 'Wellness Drug House',
          offerScheme: 'BUY 25 GET 5 FREE',
          validityFrom: '01-12-2026',
          validityTill: '31-12-2026',
        ),
      ];

    case 'Pantoprazole 40mg Tablet':
      return const [
        _PurchaseOfferReportRow(
          vendorName: 'Zenmed Agencies',
          offerScheme: 'BUY 6 GET 1 FREE',
          validityFrom: '19-08-2026',
          validityTill: '18-09-2026',
        ),
        _PurchaseOfferReportRow(
          vendorName: 'GastroCare Pharma',
          offerScheme: 'BUY 18 GET 3 FREE',
          validityFrom: '01-11-2026',
          validityTill: '30-11-2026',
        ),
      ];

    default:
      return const [
        _PurchaseOfferReportRow(
          vendorName: 'Alpha Distributors',
          offerScheme: 'BUY 10 GET 1 FREE',
          validityFrom: '01-09-2026',
          validityTill: '30-09-2026',
        ),
      ];

  }

}

List<_SalesOfferReportRow> _dummySalesOffersForItem(String itemName) {

  switch (itemName) {

    case 'Paracetamol 650mg Tablet':
      return const [
        _SalesOfferReportRow(
          customerName: 'City Care Pharmacy',
          offerScheme: 'BUY 10 GET 1 FREE',
          validityFrom: '01-09-2026',
          validityTill: '30-09-2026',
        ),
        _SalesOfferReportRow(
          customerName: 'Wellness Medicals',
          offerScheme: 'BUY 20 GET 2 FREE',
          validityFrom: '05-09-2026',
          validityTill: '05-10-2026',
        ),
      ];

    case 'Azithromycin 500mg Tablet':
      return const [
        _SalesOfferReportRow(
          customerName: 'Apollo Drug House',
          offerScheme: 'BUY 5 GET 1 FREE',
          validityFrom: '01-08-2026',
          validityTill: '31-08-2026',
        ),
        _SalesOfferReportRow(
          customerName: 'Metro Pharma Retail',
          offerScheme: 'BUY 12 GET 2 FREE',
          validityFrom: '15-08-2026',
          validityTill: '20-09-2026',
        ),
      ];

    case 'Amoxicillin 250mg Capsule':
      return const [
        _SalesOfferReportRow(
          customerName: 'Green Cross Medicals',
          offerScheme: 'BUY 15 GET 2 FREE',
          validityFrom: '10-10-2026',
          validityTill: '12-11-2026',
        ),
        _SalesOfferReportRow(
          customerName: 'CareOne Pharmacy',
          offerScheme: 'BUY 8 GET 1 FREE',
          validityFrom: '26-11-2026',
          validityTill: '25-12-2026',
        ),
      ];

    case 'Cetirizine 10mg Tablet':
      return const [
        _SalesOfferReportRow(
          customerName: 'Relief Medicos',
          offerScheme: 'BUY 10 GET 2 FREE',
          validityFrom: '06-09-2026',
          validityTill: '05-10-2026',
        ),
        _SalesOfferReportRow(
          customerName: 'Family Health Pharmacy',
          offerScheme: 'BUY 25 GET 5 FREE',
          validityFrom: '01-12-2026',
          validityTill: '31-12-2026',
        ),
      ];

    case 'Pantoprazole 40mg Tablet':
      return const [
        _SalesOfferReportRow(
          customerName: 'Digestive Care Pharmacy',
          offerScheme: 'BUY 6 GET 1 FREE',
          validityFrom: '19-08-2026',
          validityTill: '18-09-2026',
        ),
        _SalesOfferReportRow(
          customerName: 'Prime Wellness Store',
          offerScheme: 'BUY 18 GET 3 FREE',
          validityFrom: '01-11-2026',
          validityTill: '30-11-2026',
        ),
      ];

    default:
      return const [
        _SalesOfferReportRow(
          customerName: 'City Care Pharmacy',
          offerScheme: 'BUY 10 GET 1 FREE',
          validityFrom: '01-09-2026',
          validityTill: '30-09-2026',
        ),
      ];

  }

}



// ─── Mock Data ───────────────────────────────────────────────────────────────



const List<RecurringInvoiceUI> _mockInvoices = [

  RecurringInvoiceUI(

    id: '1',

    customerName: 'Paracetamol 650mg Tablet',

    date: '20-06-2026',

    amount: 238.00,

    balanceDue: 0.0,

    status: 'ACTIVE',

    drawStatus: 'ACTIVE',

    companyName: 'ZABNIX PRIVATE LIMITED',

    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],

    companyGstin: '32AACCZ4912F1ZL',

    companyPhone: '8086355500',

    companyEmail: 'zabnixprivatelimited@gmail.com',

    billToAddress: ['althafm', 'vengoor'],

    items: [

      RetainerInvoiceItem(

        index: 1,

        description: 'Recurring Profile: PCM 650 Profile',

        amount: 238.00,

      ),

    ],

    profileName: 'PCM 650 Profile',

    billingFrequency: 'Weekly',

    nextInvoiceDate: '20-06-2026',

    manuallyCreatedInvoices: 1,

    billingAddress: [

      'Tablet Section',

      'Rack A3',

      'Main Medical Store',

      'Perinthalmanna',

      'Kerala 679322',

      'India',

      'Stock Point: +91-8086355500',

    ],

    shippingAddress: [

      'Dispatch Shelf 2',

      'Pharma Bay',

      'Main Medical Store',

      'PERINTHALMANNA',

      'Kerala',

    ],

    childInvoices: [

      ChildInvoiceUI(

        id: 'INV-000088',

        date: '13-06-2026',

        amount: 238.00,

        status: 'DRAFT',

        source: 'Manually Added',

      ),

    ],

    startDate: '13-06-2026',

    endDate: 'Never Expires',

    paymentTerms: 'Net 360',

    salesperson: 'ALTHAF',

  ),

  RecurringInvoiceUI(

    id: '2',

    customerName: 'Azithromycin 500mg Tablet',

    date: '01-07-2026',

    amount: 12000.00,

    balanceDue: 0.0,

    status: 'ACTIVE',

    drawStatus: 'ACTIVE',

    companyName: 'ZABNIX PRIVATE LIMITED',

    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],

    companyGstin: '32AACCZ4912F1ZL',

    companyPhone: '8086355500',

    companyEmail: 'zabnixprivatelimited@gmail.com',

    billToAddress: ['product@sample.com'],

    items: [

      RetainerInvoiceItem(

        index: 1,

        description: 'Recurring Profile: AZM 500 Profile',

        amount: 12000.00,

      ),

    ],

    profileName: 'AZM 500 Profile',

    billingFrequency: 'Monthly',

    nextInvoiceDate: '01-07-2026',

    manuallyCreatedInvoices: 1,

    billingAddress: ['product@sample.com', 'Main Warehouse'],

    shippingAddress: ['Main Warehouse'],

    childInvoices: [],

    startDate: '01-07-2026',

    endDate: 'Never Expires',

    paymentTerms: 'Due on Receipt',

    salesperson: 'Salesperson',

  ),

  RecurringInvoiceUI(

    id: '3',

    customerName: 'Amoxicillin 250mg Capsule',

    date: '30-06-2026',

    amount: 5000.00,

    balanceDue: 0.0,

    status: 'DRAFT',

    drawStatus: 'INACTIVE',

    companyName: 'ZABNIX PRIVATE LIMITED',

    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],

    companyGstin: '32AACCZ4912F1ZL',

    companyPhone: '8086355500',

    companyEmail: 'zabnixprivatelimited@gmail.com',

    billToAddress: ['product@sample.com'],

    items: [

      RetainerInvoiceItem(

        index: 1,

        description: 'Recurring Profile: AMX 250 Profile',

        amount: 5000.00,

      ),

    ],

    profileName: 'AMX 250 Profile',

    billingFrequency: 'Monthly',

    nextInvoiceDate: '30-06-2026',

    manuallyCreatedInvoices: 1,

    billingAddress: ['product@sample.com', 'Capsule Rack'],

    shippingAddress: ['Capsule Rack'],

    childInvoices: [],

    startDate: '30-06-2026',

    endDate: 'Never Expires',

    paymentTerms: 'Due on Receipt',

    salesperson: 'Salesperson',

  ),

  RecurringInvoiceUI(

    id: '4',

    customerName: 'Cetirizine 10mg Tablet',

    date: '01-01-2027',

    amount: 150000.00,

    balanceDue: 0.0,

    status: 'STOPPED',

    drawStatus: 'INACTIVE',

    companyName: 'ZABNIX PRIVATE LIMITED',

    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],

    companyGstin: '32AACCZ4912F1ZL',

    companyPhone: '8086355500',

    companyEmail: 'zabnixprivatelimited@gmail.com',

    billToAddress: ['product@sample.com'],

    items: [

      RetainerInvoiceItem(

        index: 1,

        description: 'Recurring Profile: CTZ 10 Profile',

        amount: 150000.00,

      ),

    ],

    profileName: 'CTZ 10 Profile',

    billingFrequency: 'Yearly',

    nextInvoiceDate: '01-01-2027',

    manuallyCreatedInvoices: 1,

    billingAddress: ['product@sample.com', 'Tablet Rack'],

    shippingAddress: ['Tablet Rack'],

    childInvoices: [],

    startDate: '01-01-2027',

    endDate: 'Never Expires',

    paymentTerms: 'Due on Receipt',

    salesperson: 'Salesperson',

  ),

  RecurringInvoiceUI(

    id: '5',

    customerName: 'Pantoprazole 40mg Tablet',

    date: '15-07-2026',

    amount: 80000.00,

    balanceDue: 0.0,

    status: 'ACTIVE',

    drawStatus: 'ACTIVE',

    companyName: 'ZABNIX PRIVATE LIMITED',

    companyAddress: ['PERINTHALMANNA', 'MALAPPURAM Kerala 679322', 'India'],

    companyGstin: '32AACCZ4912F1ZL',

    companyPhone: '8086355500',

    companyEmail: 'zabnixprivatelimited@gmail.com',

    billToAddress: ['product@sample.com'],

    items: [

      RetainerInvoiceItem(

        index: 1,

        description: 'Recurring Profile: PAN 40 Profile',

        amount: 80000.00,

      ),

    ],

    profileName: 'PAN 40 Profile',

    billingFrequency: 'Monthly',

    nextInvoiceDate: '15-07-2026',

    manuallyCreatedInvoices: 1,

    billingAddress: ['product@sample.com', 'GI Medicine Rack'],

    shippingAddress: ['GI Medicine Rack'],

    childInvoices: [],

    startDate: '15-07-2026',

    endDate: 'Never Expires',

    paymentTerms: 'Due on Receipt',

    salesperson: 'Salesperson',

  ),

];



// ─── Screen Widget ────────────────────────────────────────────────────────────



// ─── Provider → Local model mapper ──────────────────────────────────────────



RecurringInvoiceUI _fromProviderInvoice(provider_model.RecurringInvoice src) {

  final df = DateFormat('dd-MM-yyyy');

  String statusLabel;

  switch (src.status) {

    case provider_model.RecurringStatus.draft:

      statusLabel = 'DRAFT';

      break;

    case provider_model.RecurringStatus.active:

      statusLabel = 'ACTIVE';

      break;

    case provider_model.RecurringStatus.stopped:

      statusLabel = 'STOPPED';

      break;

    case provider_model.RecurringStatus.expired:

      statusLabel = 'EXPIRED';

      break;

  }

  final drawStatus = src.status == provider_model.RecurringStatus.active

      ? 'ACTIVE'

      : 'INACTIVE';

  final nextInvDateStr = src.nextInvoiceDate != null

      ? df.format(src.nextInvoiceDate!)

      : '20-06-2026';

  return RecurringInvoiceUI(

    id: src.id,

    customerName: src.customerName,

    date: src.nextInvoiceDate != null ? df.format(src.nextInvoiceDate!) : '',

    amount: src.amount,

    balanceDue: 0.0,

    status: statusLabel,

    drawStatus: drawStatus,

    companyName: 'ZABNIX PRIVATE LIMITED',

    companyAddress: const [

      'PERINTHALMANNA',

      'MALAPPURAM Kerala 679322',

      'India',

    ],

    companyGstin: '32AACCZ4912F1ZL',

    companyPhone: '8086355500',

    companyEmail: 'zabnixprivatelimited@gmail.com',

    billToAddress: ['', src.customerName],

    items: [

      RetainerInvoiceItem(

        index: 1,

        description: 'Recurring Profile: ${src.profileName}',

        amount: src.amount,

      ),

    ],

    profileName: src.profileName,

    billingFrequency: src.billingFrequency,

    nextInvoiceDate: nextInvDateStr,

    manuallyCreatedInvoices: 1,

    billingAddress: const [

      'althafm',

      'malayanakath(h)',

      'vengoor (po)',

      'perinthalmanna',

      'Kerala 679322',

      'India',

      'Phone: +91-9895357101',

    ],

    shippingAddress: const [

      'althaf.m',

      'malayanakath(h)',

      'vengoor',

      'PERINTHALMANNA',

      'perinthalmanna',

    ],

    childInvoices: [

      ChildInvoiceUI(

        id: 'INV-000088',

        date: '13-06-2026',

        amount: src.amount,

        status: 'DRAFT',

        source: 'Manually Added',

      ),

    ],

    startDate: src.nextInvoiceDate != null

        ? df.format(src.nextInvoiceDate!)

        : '13-06-2026',

    endDate: 'Never Expires',

    paymentTerms: 'Net 360',

    salesperson: 'ALTHAF',

  );

}



class ItemTradeSetupOverviewPage extends ConsumerStatefulWidget {
  final String? id;
  const ItemTradeSetupOverviewPage({super.key, this.id});

  static final List<RecurringInvoiceUI> customInvoices = [];
  static final Map<String, List<Map<String, String>>> customMappings = {};
  static final Map<String, List<Map<String, String>>> customPurchaseOffers = {};
  static final Map<String, List<Map<String, String>>> customSalesOffers = {};



  @override

  ConsumerState<ItemTradeSetupOverviewPage> createState() =>

      _ItemTradeSetupOverviewPageState();

}



// ─── State ────────────────────────────────────────────────────────────────────



class _ItemTradeSetupOverviewPageState

    extends ConsumerState<ItemTradeSetupOverviewPage> {

  late RecurringInvoiceUI _selectedInvoice;

  String _selectedFilter = 'All';

  String _activeTab = 'Item Mapping';



  String get _orgId =>

      GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

  NumberFormat get currencyFormat =>
      NumberFormat.currency(symbol: '₹', decimalDigits: 2);



  // Filter dropdown (MenuAnchor)

  final MenuController _filterMenuController = MenuController();

  // Bulk Actions dropdown (MenuAnchor)

  final MenuController _bulkMenuController = MenuController();

  // PDF/Print dropdown (MenuAnchor)

  final MenuController _pdfPrintMenuController = MenuController();

  // Record Payment dropdown (MenuAnchor)

  final MenuController _recordPaymentMenuController = MenuController();

  // Right action bar more dropdown (MenuAnchor)

  final MenuController _rightMoreMenuController = MenuController();

  // Customize dropdown (MenuAnchor)

  final MenuController _customizeMenuController = MenuController();

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  final Set<String> _starredValues = {

    'All',

    'Draft',

    'Active',

    'Stopped',

    'Expired',

  };

  bool _favoritesExpanded = true;

  bool _defaultFiltersExpanded = true;



  // More-menu overlay (three-dot in left header)

  final LayerLink _moreLink = LayerLink();

  OverlayEntry? _moreMenuOverlayEntry;

  bool _isMoreMenuOpen = false;

  String? _activeSubMenu;



  final LayerLink _attachmentLink = LayerLink();

  OverlayEntry? _attachmentOverlayEntry;

  bool _isAttachmentPopoverOpen = false;

  bool _showCommentsPanel = false;

  String? _customerPan;

  final TextEditingController _panTextController = TextEditingController();

  final LayerLink _panLayerLink = LayerLink();

  OverlayEntry? _panOverlayEntry;

  bool _isPanOverlayOpen = false;



  // Row checkbox selection

  final Set<String> _checkedIds = {};

  String? _hoveredId;



  // Template chooser panel

  bool _showTemplatePanel = false;

  String _selectedTemplate = 'Standard Template';

  bool _isInvoiceHovered = false;



  // Preferences Overlay state

  bool _showPreferencesOverlay = false;

  String _preferencesSelectedOption = 'drafts'; // 'drafts', 'send', 'charge'

  bool _sendDraftNotifications = true;

  String _selectedChildInvoiceFilter = 'All';

  String _templateSearchQuery = '';

  final TextEditingController _templateSearchController =

      TextEditingController();



  bool _showRecordPaymentPage = false;

  bool _showChildInvoiceDetail = false;

  ChildInvoiceUI? _selectedChildInvoice;

  bool _showCustomerDetailsPanel = false;

  String _customerDetailTab = 'Details'; // 'Details' | 'Activity Log'

  final TextEditingController _paymentAmountController =

      TextEditingController();

  final TextEditingController _paymentReferenceController =

      TextEditingController();

  final TextEditingController _paymentNotesController = TextEditingController();

  final TextEditingController _paymentDateController = TextEditingController();

  final TextEditingController _paymentNumberController = TextEditingController(

    text: '305',

  );

  final GlobalKey _paymentDateKey = GlobalKey();

  String _paymentMode = 'Cash';

  String _paymentDepositTo = 'Petty Cash';

  String _paymentLocation = 'ZABNIX PRIVATE LIMITED';

  String _paymentTransactionSeries = 'Default Transaction Series';

  DateTime _paymentDateVal = DateTime.now();

  final TextEditingController _bankChargesController = TextEditingController();

  List<PlatformFile> _uploadedFiles = [];



  final List<FilterItem> _allFilters = [

    const FilterItem('All'),

    const FilterItem('Draft'),

    const FilterItem('Active'),

    const FilterItem('Stopped'),

    const FilterItem('Expired'),

  ];



  // ── Lifecycle ──────────────────────────────────────────────────────────────



  // Live list built from provider (populated in didChangeDependencies)

  List<RecurringInvoiceUI> _liveInvoices = _mockInvoices;
  bool _isItemMappingLoading = false;
  String _itemMappingTitle = 'Item Trade Setup';
  List<_ItemMappingReportRow> _itemMappingRows = const [];



  @override

  void initState() {

    super.initState();

    // Initial selection will be refined in didChangeDependencies once

    // the ref is available.

    _selectedInvoice = _mockInvoices.first;

  }



  @override

  void didChangeDependencies() {

    super.didChangeDependencies();

    _syncFromProvider();

  }



  @override

  void didUpdateWidget(covariant ItemTradeSetupOverviewPage oldWidget) {

    super.didUpdateWidget(oldWidget);

    if (widget.id != oldWidget.id) {

      _syncFromProvider();

    }

  }



  void _syncFromProvider() {
    _liveInvoices = [..._mockInvoices, ...ItemTradeSetupOverviewPage.customInvoices];



    final targetId = widget.id;

    if (targetId != null) {

      _selectedInvoice = _liveInvoices.firstWhere(

        (i) => i.id == targetId,

        orElse: () => _liveInvoices.first,

      );

    } else {

      _selectedInvoice = _liveInvoices.first;

    }



    _paymentAmountController.text = _selectedInvoice.balanceDue.toStringAsFixed(

      2,

    );

    _paymentDateController.text = _selectedInvoice.date;

    try {

      _paymentDateVal = DateFormat('dd-MM-yyyy').parse(_selectedInvoice.date);

    } catch (_) {

      _paymentDateVal = DateTime.now();

    }

    _itemMappingTitle = _selectedInvoice.customerName;
    _loadItemMappingReport(_selectedInvoice.id);

  }

  Future<void> _loadItemMappingReport(String? productId) async {
    final selectedItemName = _selectedInvoice.customerName;

    if (productId != null && ItemTradeSetupOverviewPage.customMappings.containsKey(productId)) {
      if (!mounted) return;
      setState(() {
        _itemMappingTitle = selectedItemName;
        _itemMappingRows = ItemTradeSetupOverviewPage.customMappings[productId]!
            .map((m) => _ItemMappingReportRow(
                  vendorName: m['vendorName'] ?? '',
                  vendorProductName: m['vendorProductName'] ?? '',
                  vendorProductCode: m['vendorProductCode'] ?? '',
                  status: m['status'] ?? 'Active',
                ))
            .toList();
        _isItemMappingLoading = false;
      });
      return;
    }

    if (productId == null || productId.isEmpty) {

      if (!mounted) return;

      setState(() {

        _itemMappingTitle = selectedItemName;

        _itemMappingRows = _dummyRowsForItem(selectedItemName);

        _isItemMappingLoading = false;

      });

      return;

    }

    setState(() => _isItemMappingLoading = true);

    try {

      final productRes = await Supabase.instance.client
          .from('products')
          .select('id, product_name')
          .eq('id', productId)
          .maybeSingle();

      final mappingRes = await Supabase.instance.client
          .from('product_vendor_mappings')
          .select(
            'mapping_name, vendor_product_code, vendors(display_name)',
          )
          .eq('item_id', productId);

      final rows = (mappingRes as List<dynamic>).map((row) {

        final map = row as Map<String, dynamic>;

        final vendor = map['vendors'] as Map<String, dynamic>?;

        return _ItemMappingReportRow(

          vendorName: vendor?['display_name'] as String? ?? '',

          vendorProductName: map['mapping_name'] as String? ?? '',

          vendorProductCode: map['vendor_product_code'] as String? ?? '',

        );

      }).toList();

      if (!mounted) return;

      setState(() {

        _itemMappingTitle =
            productRes?['product_name'] as String? ?? selectedItemName;

        _itemMappingRows =
            rows.isEmpty ? _dummyRowsForItem(selectedItemName) : rows;

        _isItemMappingLoading = false;

      });

    } catch (_) {

      if (!mounted) return;

      setState(() {

        _itemMappingTitle = selectedItemName;

        _itemMappingRows = _dummyRowsForItem(selectedItemName);

        _isItemMappingLoading = false;

      });

    }

  }



  @override

  void dispose() {

    _searchController.dispose();

    _templateSearchController.dispose();

    _paymentAmountController.dispose();

    _paymentReferenceController.dispose();

    _paymentNotesController.dispose();

    _paymentDateController.dispose();

    _paymentNumberController.dispose();

    _bankChargesController.dispose();

    _closeMoreMenu();

    _closeAttachmentPopover();

    _closePanOverlay();

    _panTextController.dispose();

    super.dispose();

  }



  void _showPanOverlay() {

    if (_isPanOverlayOpen) return;



    _panTextController.text = _customerPan ?? '';



    _panOverlayEntry = OverlayEntry(

      builder: (context) {

        return Stack(

          children: [

            Positioned.fill(

              child: GestureDetector(

                behavior: HitTestBehavior.translucent,

                onTap: _closePanOverlay,

                child: Container(color: Colors.transparent),

              ),

            ),

            Positioned(

              width: 300,

              child: CompositedTransformFollower(

                link: _panLayerLink,

                showWhenUnlinked: false,

                targetAnchor: Alignment.bottomCenter,

                followerAnchor: Alignment.topCenter,

                offset: const Offset(0, 4),

                child: Material(

                  color: Colors.transparent,

                  child: Stack(

                    clipBehavior: Clip.none,

                    children: [

                      Padding(

                        padding: const EdgeInsets.only(top: 8),

                        child: Container(

                          decoration: BoxDecoration(

                            color: Colors.white,

                            borderRadius: BorderRadius.circular(6),

                            border: Border.all(color: AppTheme.borderColor),

                            boxShadow: [

                              BoxShadow(

                                color: Colors.black.withValues(alpha: 0.08),

                                blurRadius: 8,

                                offset: const Offset(0, 4),

                              ),

                            ],

                          ),

                          child: Column(

                            mainAxisSize: MainAxisSize.min,

                            crossAxisAlignment: CrossAxisAlignment.stretch,

                            children: [

                              Padding(

                                padding: const EdgeInsets.fromLTRB(

                                  16,

                                  12,

                                  12,

                                  12,

                                ),

                                child: Row(

                                  children: [

                                    const Expanded(

                                      child: Text(

                                        'Add PAN',

                                        style: TextStyle(

                                          fontSize: 14,

                                          fontWeight: FontWeight.w600,

                                          color: AppTheme.textPrimary,

                                        ),

                                      ),

                                    ),

                                    InkWell(

                                      onTap: _closePanOverlay,

                                      borderRadius: BorderRadius.circular(4),

                                      child: const Padding(

                                        padding: EdgeInsets.all(4),

                                        child: Icon(

                                          LucideIcons.x,

                                          size: 16,

                                          color: Color(0xFFD32F2F),

                                        ),

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                              const Divider(

                                height: 1,

                                color: AppTheme.borderColor,

                              ),

                              Padding(

                                padding: const EdgeInsets.all(16),

                                child: Column(

                                  crossAxisAlignment:

                                      CrossAxisAlignment.stretch,

                                  children: [

                                    CustomTextField(

                                      controller: _panTextController,

                                      height: 36,

                                      hintText: 'Enter PAN',

                                    ),

                                    const SizedBox(height: 12),

                                    Row(

                                      crossAxisAlignment:

                                          CrossAxisAlignment.start,

                                      children: [

                                        const Padding(

                                          padding: EdgeInsets.only(top: 2),

                                          child: Icon(

                                            LucideIcons.info,

                                            size: 13,

                                            color: AppTheme.textSecondary,

                                          ),

                                        ),

                                        const SizedBox(width: 8),

                                        Expanded(

                                          child: Text(

                                            'This PAN will be updated in contact and further transactions.',

                                            style: TextStyle(

                                              fontSize: 11,

                                              color: AppTheme.textSecondary,

                                              height: 1.3,

                                            ),

                                          ),

                                        ),

                                      ],

                                    ),

                                  ],

                                ),

                              ),

                              const Divider(

                                height: 1,

                                color: AppTheme.borderColor,

                              ),

                              Padding(

                                padding: const EdgeInsets.fromLTRB(

                                  16,

                                  10,

                                  16,

                                  12,

                                ),

                                child: Row(

                                  children: [

                                    ElevatedButton(

                                      style: ElevatedButton.styleFrom(

                                        backgroundColor: AppTheme.successGreen,

                                        foregroundColor: Colors.white,

                                        elevation: 0,

                                        padding: const EdgeInsets.symmetric(

                                          horizontal: 16,

                                          vertical: 8,

                                        ),

                                        minimumSize: const Size(64, 32),

                                        shape: RoundedRectangleBorder(

                                          borderRadius: BorderRadius.circular(

                                            4,

                                          ),

                                        ),

                                      ),

                                      onPressed: () {

                                        setState(() {

                                          _customerPan = _panTextController.text

                                              .trim();

                                        });

                                        _closePanOverlay();

                                      },

                                      child: const Text(

                                        'Save',

                                        style: TextStyle(

                                          fontSize: 12,

                                          fontWeight: FontWeight.w600,

                                        ),

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                            ],

                          ),

                        ),

                      ),

                      Positioned(

                        top: 1,

                        left: 0,

                        right: 0,

                        child: Align(

                          alignment: Alignment.topCenter,

                          child: CustomPaint(

                            size: const Size(14, 8),

                            painter: _PopoverArrowPainter(

                              color: Colors.white,

                              borderColor: AppTheme.borderColor,

                            ),

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

              ),

            ),

          ],

        );

      },

    );



    Overlay.of(context).insert(_panOverlayEntry!);

    setState(() {

      _isPanOverlayOpen = true;

    });

  }



  void _closePanOverlay() {

    if (!_isPanOverlayOpen) return;

    _panOverlayEntry?.remove();

    _panOverlayEntry = null;

    setState(() {

      _isPanOverlayOpen = false;

    });

  }



  void _togglePanOverlay() {

    if (_isPanOverlayOpen) {

      _closePanOverlay();

    } else {

      _showPanOverlay();

    }

  }



  Widget _buildRecordPaymentForm(NumberFormat currencyFormat) {

    return Container(

      width: double.infinity,

      color: Colors.white,

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          // ── Customer detail fields (red-boxed section) ──────────────────

          Container(

            color: AppTheme.selectionActiveBg,

            padding: const EdgeInsets.fromLTRB(56, 24, 56, 24),

            child: Stack(

              clipBehavior: Clip.none,

              children: [

                Container(

                  padding: EdgeInsets.zero,

                  child: Column(

                    children: [

                      // Row 1 — Customer Name

                      _buildPaymentFormRow(

                        label: 'Customer Name',

                        required: true,

                        child: CustomTextField(

                          controller: TextEditingController(

                            text: _selectedInvoice.customerName,

                          ),

                          height: 36,

                          readOnly: true,

                        ),

                      ),

                      const SizedBox(height: 12),



                      // Row 2 — Payment #

                      _buildPaymentFormRow(

                        label: 'Payment #',

                        required: true,

                        child: Row(

                          children: [

                            Expanded(

                              child: CustomTextField(

                                controller: _paymentNumberController,

                                keyboardType: TextInputType.number,

                                height: 36,

                              ),

                            ),

                            const SizedBox(width: 8),

                            InkWell(

                              onTap: () async {

                                final result =

                                    await showDialog<Map<String, dynamic>>(

                                      context: context,

                                      builder: (context) =>

                                          _ConfigurePaymentNumberPreferencesDialog(

                                            currentLocation: _paymentLocation,

                                            currentSeries:

                                                _paymentTransactionSeries,

                                          ),

                                    );

                                if (result != null) {

                                  setState(() {

                                    final prefix = result['prefix'] as String;

                                    final nextNum =

                                        result['nextNumber'] as String;

                                    _paymentNumberController.text =

                                        "$prefix$nextNum";

                                  });

                                }

                              },

                              borderRadius: BorderRadius.circular(4),

                              child: Container(

                                height: 36,

                                width: 36,

                                decoration: BoxDecoration(

                                  border: Border.all(

                                    color: AppTheme.borderColor,

                                  ),

                                  borderRadius: BorderRadius.circular(4),

                                  color: Colors.white,

                                ),

                                child: const Icon(

                                  LucideIcons.settings,

                                  size: 14,

                                  color: AppTheme.textSecondary,

                                ),
                              ),
                            ),
                          ],

                        ),

                      ),

                      const SizedBox(height: 12),



                      // Row 3 — Transaction Series

                      _buildPaymentFormRow(

                        label: 'Transaction Series',

                        required: true,

                        child: FormDropdown<String>(

                          value: _paymentTransactionSeries,

                          items: const [

                            'Default Transaction Series',

                            'SERIES 1',

                          ],

                          onChanged: (val) {

                            if (val == null) return;

                            setState(() => _paymentTransactionSeries = val);

                          },

                          height: 36,

                          showSearch: false,

                        ),

                      ),

                      const SizedBox(height: 12),



                      // Row 4 — Location

                      _buildPaymentFormRow(

                        label: 'Location',

                        required: false,

                        child: FormDropdown<String>(

                          value: _paymentLocation,

                          items: const ['ZABNIX PRIVATE LIMITED'],

                          onChanged: (val) {

                            if (val == null) return;

                            setState(() => _paymentLocation = val);

                          },

                          height: 36,

                          showSearch: false,

                        ),

                      ),

                    ],

                  ),

                ),

                if (!_showCustomerDetailsPanel)

                  Positioned(

                    top: 16,

                    right: -56,

                    child: GestureDetector(

                      onTap: () =>

                          setState(() => _showCustomerDetailsPanel = true),

                      child: Container(

                        height: 36,

                        padding: const EdgeInsets.symmetric(horizontal: 12),

                        decoration: const BoxDecoration(

                          color: Color(0xFF2D3748),

                          borderRadius: BorderRadius.only(

                            topLeft: Radius.circular(6),

                            bottomLeft: Radius.circular(6),

                          ),

                        ),

                        child: Row(

                          mainAxisSize: MainAxisSize.min,

                          children: [

                            Text(

                              "${_selectedInvoice.customerName}'s Details",

                              style: const TextStyle(

                                fontSize: 12,

                                fontWeight: FontWeight.w500,

                                color: Colors.white,

                              ),

                            ),

                            const SizedBox(width: 6),

                            const Icon(

                              LucideIcons.chevronRight,

                              size: 13,

                              color: Colors.white,

                            ),

                          ],

                        ),

                      ),

                    ),

                  ),

              ],

            ),

          ),



          // ── Bottom section fields ───────────────────────────────────────

          Padding(

            padding: const EdgeInsets.fromLTRB(56, 24, 56, 24),

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                // Amount & Bank Charges row

                Row(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.stretch,

                        children: [

                          _buildPaymentFormRow(

                            label: 'Amount Received (INR)',

                            child: CustomTextField(

                              controller: _paymentAmountController,

                              keyboardType:

                                  const TextInputType.numberWithOptions(

                                    decimal: true,

                                  ),

                              height: 36,

                              textAlign: TextAlign.end,

                            ),

                          ),

                          const SizedBox(height: 4),

                          Padding(

                            padding: const EdgeInsets.only(left: 160),

                            child: CompositedTransformTarget(

                              link: _panLayerLink,

                              child: GestureDetector(

                                onTap: _togglePanOverlay,

                                child: MouseRegion(

                                  cursor: SystemMouseCursors.click,

                                  child: Text(

                                    _customerPan == null ||

                                            _customerPan!.isEmpty

                                        ? 'PAN: Add PAN'

                                        : 'PAN: $_customerPan',

                                    style: const TextStyle(

                                      fontSize: 12,

                                      color: AppTheme.primaryBlue,

                                    ),

                                  ),

                                ),

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(width: 48),

                    Expanded(

                      child: _buildPaymentFormRow(

                        label: 'Bank Charges (if any)',

                        child: CustomTextField(

                          controller: _bankChargesController,

                          keyboardType: const TextInputType.numberWithOptions(

                            decimal: true,

                          ),

                          height: 36,

                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 24),



                // Payment Date & Payment Mode row

                Row(

                  children: [

                    Expanded(

                      child: _buildPaymentFormRow(

                        label: 'Payment Date',

                        required: true,

                        child: Container(

                          key: _paymentDateKey,

                          child: CustomTextField(

                            controller: _paymentDateController,

                            readOnly: true,

                            height: 36,

                            suffixWidget: const Icon(

                              LucideIcons.calendar,

                              size: 15,

                              color: AppTheme.textSecondary,

                            ),

                            onTap: () async {

                              final picked = await ZerpaiDatePicker.show(

                                context,

                                initialDate: _paymentDateVal,

                                targetKey: _paymentDateKey,

                              );

                              if (picked == null) return;

                              setState(() {

                                _paymentDateVal = picked;

                                _paymentDateController.text = DateFormat(

                                  'dd-MM-yyyy',

                                ).format(picked);

                              });

                            },

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(width: 48),

                    Expanded(

                      child: _buildPaymentFormRow(

                        label: 'Payment Mode',

                        child: FormDropdown<String>(

                          value: _paymentMode,

                          items: const [

                            'Cash',

                            'Bank Transfer',

                            'UPI',

                            'Cheque',

                            'Credit Card',

                          ],

                          onChanged: (val) {

                            if (val == null) return;

                            setState(() => _paymentMode = val);

                          },

                          height: 36,

                          showSearch: false,

                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 18),



                // Deposit To & Reference# row

                Row(

                  children: [

                    Expanded(

                      child: _buildPaymentFormRow(

                        label: 'Deposit To',

                        required: true,

                        child: FormDropdown<String>(

                          value: _paymentDepositTo,

                          items: const [

                            'Petty Cash',

                            'Undeposited Funds',

                            'Bank Account',

                          ],

                          onChanged: (val) {

                            if (val == null) return;

                            setState(() => _paymentDepositTo = val);

                          },

                          height: 36,

                          showSearch: false,

                        ),

                      ),

                    ),

                    const SizedBox(width: 48),

                    Expanded(

                      child: _buildPaymentFormRow(

                        label: 'Reference#',

                        child: CustomTextField(

                          controller: _paymentReferenceController,

                          height: 36,

                        ),

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 18),



                // Notes

                _buildPaymentFormRow(

                  label: 'Notes',

                  crossAxisAlignment: CrossAxisAlignment.start,

                  child: CustomTextField(

                    controller: _paymentNotesController,

                    minHeight: 80,

                    maxLines: 4,

                  ),

                ),

                const SizedBox(height: 24),

                const Divider(height: 1, color: AppTheme.borderColor),

                const SizedBox(height: 24),



                // Attachments

                const Text(

                  'Attachments',

                  style: TextStyle(

                    fontSize: 13,

                    fontWeight: FontWeight.bold,

                    color: AppTheme.textPrimary,

                  ),

                ),

                const SizedBox(height: 12),

                Row(

                  children: [

                    FileUploadButton(

                      files: _uploadedFiles,

                      onFilesChanged: (updated) => setState(() {

                        _uploadedFiles = updated;

                      }),

                      height: 32,

                    ),

                  ],

                ),

                const SizedBox(height: 8),

                Text(

                  'You can upload a maximum of 5 files, 5MB each',

                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),

                ),

                const SizedBox(height: 24),

                const Divider(height: 1, color: AppTheme.borderColor),

                const SizedBox(height: 24),



                // Actions

                Row(

                  children: [

                    ElevatedButton(

                      onPressed: () {

                        setState(() {

                          _showRecordPaymentPage = false;

                        });

                      },

                      style: ElevatedButton.styleFrom(

                        backgroundColor: AppTheme.successGreen,

                        foregroundColor: Colors.white,

                        padding: const EdgeInsets.symmetric(

                          horizontal: 16,

                          vertical: 12,

                        ),

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(4),

                        ),

                      ),

                      child: const Text(

                        'Record Payment',

                        style: TextStyle(

                          fontSize: 13,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                    ),

                    const SizedBox(width: 12),

                    OutlinedButton(

                      onPressed: () {

                        setState(() {

                          _showRecordPaymentPage = false;

                        });

                      },

                      style: OutlinedButton.styleFrom(

                        foregroundColor: AppTheme.textPrimary,

                        side: const BorderSide(color: AppTheme.borderColor),

                        padding: const EdgeInsets.symmetric(

                          horizontal: 16,

                          vertical: 12,

                        ),

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(4),

                        ),

                      ),

                      child: const Text(

                        'Cancel',

                        style: TextStyle(fontSize: 13),

                      ),

                    ),

                  ],

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildPaymentFormRow({

    required String label,

    required Widget child,

    bool required = false,

    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,

  }) {

    return Row(

      crossAxisAlignment: crossAxisAlignment,

      children: [

        SizedBox(

          width: 160,

          child: Padding(

            padding: EdgeInsets.only(

              top: crossAxisAlignment == CrossAxisAlignment.start ? 8 : 0,

            ),

            child: RichText(

              text: TextSpan(

                text: label,

                style: TextStyle(

                  fontSize: 13,

                  color: required ? AppTheme.errorRed : AppTheme.textPrimary,

                ),

                children: [

                  if (required)

                    const TextSpan(

                      text: ' *',

                      style: TextStyle(color: AppTheme.errorRed),

                    ),

                ],

              ),

            ),

          ),

        ),

        Expanded(

          child: Align(

            alignment: Alignment.centerLeft,

            child: SizedBox(width: 320.0, child: child),

          ),

        ),

      ],

    );

  }



  Future<void> _pickAttachmentFiles() async {

    final result = await FilePicker.platform.pickFiles(

      type: FileType.custom,

      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],

      allowMultiple: true,

      withData: true,

    );



    if (result == null || result.files.isEmpty) return;



    final remaining = 5 - _uploadedFiles.length;

    if (remaining <= 0) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Maximum 5 files allowed')),

        );

      }

      return;

    }



    final List<PlatformFile> validFiles = [];

    for (final file in result.files.take(remaining)) {

      if (file.size <= 10 * 1024 * 1024) {

        validFiles.add(file);

      } else {

        if (mounted) {

          ScaffoldMessenger.of(context).showSnackBar(

            SnackBar(content: Text('${file.name} exceeds 10MB size limit')),

          );

        }

      }

    }



    if (validFiles.isNotEmpty) {

      setState(() {

        _uploadedFiles = [..._uploadedFiles, ...validFiles];

      });

      _attachmentOverlayEntry?.markNeedsBuild();

    }

  }



  void _removeAttachmentFile(int index) {

    setState(() {

      _uploadedFiles = List<PlatformFile>.from(_uploadedFiles)..removeAt(index);

    });

    _attachmentOverlayEntry?.markNeedsBuild();

  }



  String _formatFileSize(int bytes) {

    if (bytes < 1024) return '$bytes B';

    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';

    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  }



  void _toggleAttachmentPopover() {

    if (_isAttachmentPopoverOpen) {

      _closeAttachmentPopover();

    } else {

      _openAttachmentPopover();

    }

  }



  void _openAttachmentPopover() {

    _closeAttachmentPopover();

    _attachmentOverlayEntry = _createAttachmentOverlayEntry();

    Overlay.of(context).insert(_attachmentOverlayEntry!);

    setState(() => _isAttachmentPopoverOpen = true);

  }



  void _closeAttachmentPopover() {

    _attachmentOverlayEntry?.remove();

    _attachmentOverlayEntry = null;

    if (mounted && _isAttachmentPopoverOpen) {

      setState(() => _isAttachmentPopoverOpen = false);

    }

  }



  OverlayEntry _createAttachmentOverlayEntry() {

    return OverlayEntry(

      builder: (context) {

        return GestureDetector(

          behavior: HitTestBehavior.translucent,

          onTap: _closeAttachmentPopover,

          child: Stack(

            children: [

              Positioned.fill(child: Container(color: Colors.transparent)),

              CompositedTransformFollower(

                link: _attachmentLink,

                showWhenUnlinked: false,

                offset: const Offset(-244, 32),

                child: Material(

                  color: Colors.white,

                  surfaceTintColor: Colors.white,

                  elevation: 10,

                  shadowColor: Colors.black.withValues(alpha: 0.14),

                  borderRadius: BorderRadius.circular(4),

                  child: Container(

                    width: 272,

                    decoration: BoxDecoration(

                      color: Colors.white,

                      border: Border.all(color: AppTheme.borderColor),

                      borderRadius: BorderRadius.circular(4),

                    ),

                    child: Column(

                      mainAxisSize: MainAxisSize.min,

                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: [

                        SizedBox(

                          height: 42,

                          child: Padding(

                            padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),

                            child: Row(

                              children: [

                                const Expanded(

                                  child: Text(

                                    'Attachments',

                                    style: TextStyle(

                                      fontSize: 13,

                                      fontWeight: FontWeight.w600,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                                InkWell(

                                  onTap: _closeAttachmentPopover,

                                  borderRadius: BorderRadius.circular(4),

                                  child: Padding(

                                    padding: const EdgeInsets.all(6),

                                    child: Icon(

                                      LucideIcons.x,

                                      size: 13,

                                      color: Colors.red.shade500,

                                    ),

                                  ),

                                ),

                              ],

                            ),

                          ),

                        ),

                        const SizedBox(height: 12),

                        if (_uploadedFiles.isEmpty)

                          const Center(

                            child: Padding(

                              padding: EdgeInsets.symmetric(vertical: 8),

                              child: Text(

                                'No Files Attached',

                                style: TextStyle(

                                  fontSize: 12,

                                  color: AppTheme.textSecondary,

                                ),

                              ),

                            ),

                          )

                        else

                          ConstrainedBox(

                            constraints: const BoxConstraints(maxHeight: 180),

                            child: SingleChildScrollView(

                              child: Column(

                                children: _uploadedFiles.asMap().entries.map((

                                  entry,

                                ) {

                                  final index = entry.key;

                                  final file = entry.value;

                                  return Container(

                                    padding: const EdgeInsets.symmetric(

                                      horizontal: 14,

                                      vertical: 6,

                                    ),

                                    child: Row(

                                      children: [

                                        const Icon(

                                          LucideIcons.fileText,

                                          size: 14,

                                          color: AppTheme.primaryBlue,

                                        ),

                                        const SizedBox(width: 8),

                                        Expanded(

                                          child: Text(

                                            file.name,

                                            maxLines: 1,

                                            overflow: TextOverflow.ellipsis,

                                            style: const TextStyle(

                                              fontSize: 12,

                                              color: AppTheme.textPrimary,

                                            ),

                                          ),

                                        ),

                                        const SizedBox(width: 8),

                                        Text(

                                          _formatFileSize(file.size),

                                          style: const TextStyle(

                                            fontSize: 10,

                                            color: AppTheme.textSecondary,

                                          ),

                                        ),

                                        const SizedBox(width: 8),

                                        GestureDetector(

                                          onTap: () =>

                                              _removeAttachmentFile(index),

                                          child: const Icon(

                                            LucideIcons.trash2,

                                            size: 13,

                                            color: Colors.red,

                                          ),

                                        ),

                                      ],

                                    ),

                                  );

                                }).toList(),

                              ),

                            ),

                          ),

                        const SizedBox(height: 24),

                        Padding(

                          padding: const EdgeInsets.symmetric(horizontal: 12),

                          child: InkWell(

                            onTap: _pickAttachmentFiles,

                            borderRadius: BorderRadius.circular(5),

                            child: CustomPaint(

                              painter: _DashedBorderPainter(

                                color: AppTheme.borderColor,

                                radius: 5,

                              ),

                              child: SizedBox(

                                height: 52,

                                child: Row(

                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [

                                    const Icon(

                                      LucideIcons.upload,

                                      size: 15,

                                      color: AppTheme.primaryBlue,

                                    ),

                                    const SizedBox(width: 8),

                                    const Text(

                                      'Upload your Files',

                                      style: TextStyle(

                                        fontSize: 12,

                                        color: AppTheme.textPrimary,

                                      ),

                                    ),

                                    const SizedBox(width: 4),

                                    Icon(

                                      LucideIcons.chevronDown,

                                      size: 12,

                                      color: AppTheme.textSecondary,

                                    ),

                                  ],

                                ),

                              ),

                            ),

                          ),

                        ),

                        const SizedBox(height: 8),

                        const Padding(

                          padding: EdgeInsets.only(bottom: 10),

                          child: Center(

                            child: Text(

                              'You can upload a maximum of 5 files, 10MB each',

                              style: TextStyle(

                                fontSize: 9,

                                color: AppTheme.textSecondary,

                              ),

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                ),

              ),

            ],

          ),

        );

      },

    );

  }



  Widget _buildCommentsHistoryPanel(NumberFormat currencyFormat) {

    return Positioned(

      top: 0,

      right: 0,

      bottom: 0,

      child: Material(

        color: Colors.white,

        surfaceTintColor: Colors.white,

        elevation: 10,

        shadowColor: Colors.black.withValues(alpha: 0.12),

        child: Container(

          width: 360,

          decoration: const BoxDecoration(

            color: Colors.white,

            border: Border(left: BorderSide(color: AppTheme.borderColor)),

          ),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              SizedBox(

                height: 48,

                child: Padding(

                  padding: const EdgeInsets.fromLTRB(18, 0, 14, 0),

                  child: Row(

                    children: [

                      const Expanded(

                        child: Text(

                          'Comments & History',

                          style: TextStyle(

                            fontSize: 16,

                            fontWeight: FontWeight.w500,

                            color: AppTheme.textPrimary,

                          ),

                        ),

                      ),

                      InkWell(

                        onTap: () => setState(() => _showCommentsPanel = false),

                        borderRadius: BorderRadius.circular(4),

                        child: Padding(

                          padding: const EdgeInsets.all(6),

                          child: Icon(

                            LucideIcons.x,

                            size: 16,

                            color: Colors.red.shade500,

                          ),

                        ),

                      ),

                    ],

                  ),

                ),

              ),

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      _buildCommentComposer(),

                      const SizedBox(height: 22),

                      Row(

                        children: [

                          const Text(

                            'ALL COMMENTS',

                            style: TextStyle(

                              fontSize: 12,

                              fontWeight: FontWeight.w700,

                              color: AppTheme.textSecondary,

                            ),

                          ),

                          const SizedBox(width: 4),

                          Container(

                            width: 16,

                            height: 16,

                            alignment: Alignment.center,

                            decoration: BoxDecoration(

                              color: AppTheme.successGreen,

                              borderRadius: BorderRadius.circular(8),

                            ),

                            child: const Text(

                              '1',

                              style: TextStyle(

                                fontSize: 10,

                                fontWeight: FontWeight.w700,

                                color: Colors.white,

                              ),

                            ),

                          ),

                        ],

                      ),

                      const SizedBox(height: 12),

                      const Divider(height: 1, color: AppTheme.borderColor),

                      const SizedBox(height: 22),

                      Row(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Container(

                            width: 22,

                            height: 22,

                            decoration: BoxDecoration(

                              color: const Color(0xFFFFFBEB),

                              border: Border.all(

                                color: const Color(0xFFFDE68A),

                              ),

                              borderRadius: BorderRadius.circular(11),

                            ),

                            child: const Icon(

                              LucideIcons.fileText,

                              size: 13,

                              color: Color(0xFFF59E0B),

                            ),

                          ),

                          const SizedBox(width: 12),

                          Expanded(

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Row(

                                  children: [

                                    const Flexible(

                                      child: Text(

                                        'zabnixprivatelimited',

                                        overflow: TextOverflow.ellipsis,

                                        style: TextStyle(

                                          fontSize: 12,

                                          fontWeight: FontWeight.w700,

                                          color: AppTheme.textPrimary,

                                        ),

                                      ),

                                    ),

                                    const SizedBox(width: 6),

                                    Text(

                                      '• ${_selectedInvoice.date} 07:40 PM',

                                      style: const TextStyle(

                                        fontSize: 10,

                                        color: AppTheme.textSecondary,

                                      ),

                                    ),

                                  ],

                                ),

                                const SizedBox(height: 8),

                                Container(

                                  padding: const EdgeInsets.symmetric(

                                    horizontal: 14,

                                    vertical: 10,

                                  ),

                                  decoration: BoxDecoration(

                                    color: const Color(0xFFF8FAFC),

                                    borderRadius: BorderRadius.circular(4),

                                  ),

                                  child: Text(

                                    'Recurring Invoice created for '

                                    '${currencyFormat.format(_selectedInvoice.amount)}',

                                    style: const TextStyle(

                                      fontSize: 12,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ],

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

      ),

    );

  }



  Widget _buildCommentComposer() {

    return Container(

      height: 118,

      decoration: BoxDecoration(

        color: Colors.white,

        border: Border.all(color: AppTheme.borderColor),

        borderRadius: BorderRadius.circular(4),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          Container(

            height: 34,

            color: const Color(0xFFF4F6F8),

            padding: const EdgeInsets.symmetric(horizontal: 14),

            child: const Row(

              children: [

                Text(

                  'B',

                  style: TextStyle(

                    fontSize: 13,

                    fontWeight: FontWeight.w700,

                    color: AppTheme.textPrimary,

                  ),

                ),

                SizedBox(width: 22),

                Text(

                  'I',

                  style: TextStyle(

                    fontSize: 13,

                    fontStyle: FontStyle.italic,

                    color: AppTheme.textPrimary,

                  ),

                ),

                SizedBox(width: 22),

                Text(

                  'U',

                  style: TextStyle(

                    fontSize: 13,

                    decoration: TextDecoration.underline,

                    color: AppTheme.textPrimary,

                  ),

                ),

              ],

            ),

          ),

          const Spacer(),

          Padding(

            padding: const EdgeInsets.fromLTRB(12, 0, 0, 10),

            child: Align(

              alignment: Alignment.centerLeft,

              child: OutlinedButton(

                onPressed: () {},

                style: OutlinedButton.styleFrom(

                  minimumSize: const Size(0, 30),

                  padding: const EdgeInsets.symmetric(horizontal: 10),

                  foregroundColor: AppTheme.textSecondary,

                  side: const BorderSide(color: AppTheme.borderColor),

                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(4),

                  ),

                ),

                child: const Text(

                  'Add Comment',

                  style: TextStyle(fontSize: 11),

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }



  Color _getStatusColor(String status) {

    switch (status.toUpperCase()) {

      case 'APPROVED':

        return AppTheme.accentGreen;

      case 'PENDING APPROVAL':

        return AppTheme.warningOrange;

      case 'SENT':

        return AppTheme.primaryBlue;

      case 'OVERDUE':

        return AppTheme.errorRed;

      case 'DRAFT':

      default:

        return Colors.blueGrey.shade300;

    }

  }



  @override

  Widget build(BuildContext context) {

    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Scaffold(

      backgroundColor: Colors.white,

      body: Stack(

        children: [

          SplitListDetailLayout(

            leftWidth: 300,

            leftHeader: _buildLeftHeader(),

            leftBody: _buildLeftList(currencyFormat),

            rightHeader: _buildRightHeader(),

            rightBody: _buildRightBody(currencyFormat),

          ),

          if (_showCommentsPanel) _buildCommentsHistoryPanel(currencyFormat),

          if (_showPreferencesOverlay) _buildPreferencesOverlay(),

        ],

      ),

    );

  }



  // ── Filter Dropdown ────────────────────────────────────────────────────────



  Widget _buildFilterDropdownContent() {

    final query = _searchQuery.toLowerCase();

    final favList = _allFilters

        .where((f) => _starredValues.contains(f.label))

        .where((f) => f.label.toLowerCase().contains(query))

        .toList();

    final defaultList = _allFilters

        .where((f) => f.label.toLowerCase().contains(query))

        .toList();



    return StatefulBuilder(

      builder: (context, setMenu) {

        return Container(

          width: 270,

          color: Colors.white,

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              // Search bar

              Padding(

                padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),

                child: Container(

                  height: 34,

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius: BorderRadius.circular(5),

                    border: Border.all(color: AppTheme.borderColor),

                  ),

                  child: Row(

                    children: [

                      const Padding(

                        padding: EdgeInsets.symmetric(horizontal: 8),

                        child: Icon(

                          LucideIcons.search,

                          size: 14,

                          color: AppTheme.textSecondary,

                        ),

                      ),

                      Expanded(

                        child: TextField(

                          controller: _searchController,

                          onChanged: (val) {

                            setState(() => _searchQuery = val);

                            setMenu(() {});

                          },

                          style: const TextStyle(

                            fontSize: 12,

                            color: AppTheme.textPrimary,

                          ),

                          decoration: const InputDecoration(

                            hintText: 'Search views...',

                            hintStyle: TextStyle(

                              fontSize: 12,

                              color: AppTheme.textSecondary,

                            ),

                            border: InputBorder.none,

                            isDense: true,

                            contentPadding: EdgeInsets.symmetric(vertical: 8),

                          ),

                        ),

                      ),

                      if (_searchQuery.isNotEmpty)

                        GestureDetector(

                          onTap: () {

                            _searchController.clear();

                            setState(() => _searchQuery = '');

                            setMenu(() {});

                          },

                          child: const Padding(

                            padding: EdgeInsets.symmetric(horizontal: 6),

                            child: Icon(

                              LucideIcons.x,

                              size: 12,

                              color: AppTheme.textSecondary,

                            ),

                          ),

                        ),

                    ],

                  ),

                ),

              ),



              // Scrollable sections

              ConstrainedBox(

                constraints: const BoxConstraints(maxHeight: 340),

                child: SingleChildScrollView(

                  child: Column(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      // FAVORITES

                      if (favList.isNotEmpty) ...[

                        _filterSectionHeader(

                          title: 'FAVORITES',

                          count: favList.length,

                          isExpanded: _favoritesExpanded,

                          onTap: () => setState(

                            () => _favoritesExpanded = !_favoritesExpanded,

                          ),

                        ),

                        if (_favoritesExpanded)

                          ...favList.map(

                            (f) => _filterOptionRow(

                              label: f.label,

                              isStarred: true,

                            ),

                          ),

                      ],



                      // DEFAULT FILTERS

                      if (favList.isNotEmpty)

                        _filterSectionHeader(

                          title: 'DEFAULT FILTERS',

                          count: defaultList.length,

                          isExpanded: _defaultFiltersExpanded,

                          onTap: () => setState(

                            () => _defaultFiltersExpanded =

                                !_defaultFiltersExpanded,

                          ),

                        ),

                      if (favList.isEmpty || _defaultFiltersExpanded)

                        ...defaultList.map(

                          (f) => _filterOptionRow(

                            label: f.label,

                            isStarred: _starredValues.contains(f.label),

                          ),

                        ),

                    ],

                  ),

                ),

              ),

            ],

          ),

        );

      },

    );

  }



  Widget _filterSectionHeader({

    required String title,

    required int count,

    required bool isExpanded,

    required VoidCallback onTap,

  }) {

    return InkWell(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

        color: const Color(0xFFF9FAFB),

        child: Row(

          children: [

            Icon(

              isExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,

              size: 13,

              color: AppTheme.textSecondary,

            ),

            const SizedBox(width: 6),

            Text(

              title,

              style: const TextStyle(

                fontSize: 10,

                fontWeight: FontWeight.bold,

                letterSpacing: 0.5,

                color: AppTheme.textSecondary,

              ),

            ),

            const Spacer(),

            Container(

              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

              decoration: BoxDecoration(

                color: isExpanded

                    ? AppTheme.successGreen

                    : const Color(0xFF9CA3AF),

                borderRadius: BorderRadius.circular(10),

              ),

              child: Text(

                '$count',

                style: const TextStyle(

                  fontSize: 9,

                  fontWeight: FontWeight.bold,

                  color: Colors.white,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _filterOptionRow({required String label, required bool isStarred}) {

    final isSelected = _selectedFilter == label;

    return _FilterOptionRow(

      label: label,

      isStarred: isStarred,

      isSelected: isSelected,

      onTap: () {

        setState(() => _selectedFilter = label);

        _filterMenuController.close();

      },

      onStarTap: () {

        setState(() {

          if (_starredValues.contains(label)) {

            _starredValues.remove(label);

          } else {

            _starredValues.add(label);

          }

        });

      },

    );

  }



  // ── More Menu (left header three-dot) ──────────────────────────────────────



  void _toggleMoreMenu() {

    if (_isMoreMenuOpen) {

      _closeMoreMenu();

    } else {

      _openMoreMenu();

    }

  }



  void _openMoreMenu() {

    _moreMenuOverlayEntry = _createMoreMenuOverlayEntry();

    Overlay.of(context).insert(_moreMenuOverlayEntry!);

    setState(() {

      _isMoreMenuOpen = true;

      _activeSubMenu = null;

    });

  }



  void _closeMoreMenu() {

    _moreMenuOverlayEntry?.remove();

    _moreMenuOverlayEntry = null;

    if (mounted) {

      setState(() {

        _isMoreMenuOpen = false;

        _activeSubMenu = null;

      });

    }

  }



  OverlayEntry _createMoreMenuOverlayEntry() {

    String? hoveredSubMenuItem;

    return OverlayEntry(

      builder: (context) => StatefulBuilder(

        builder: (context, setStateOverlay) {

          Widget? subMenuWidget;

          if (_activeSubMenu == 'Sort by') {

            subMenuWidget = _buildSortBySubMenu(

              setStateOverlay,

              hoveredSubMenuItem,

              (val) => setStateOverlay(() => hoveredSubMenuItem = val),

            );

          } else if (_activeSubMenu == 'Export') {

            subMenuWidget = _buildExportSubMenu(

              setStateOverlay,

              hoveredSubMenuItem,

              (val) => setStateOverlay(() => hoveredSubMenuItem = val),

            );

          }



          return GestureDetector(

            behavior: HitTestBehavior.translucent,

            onTap: _closeMoreMenu,

            child: Stack(

              children: [

                Positioned.fill(child: Container(color: Colors.transparent)),

                CompositedTransformFollower(

                  link: _moreLink,

                  showWhenUnlinked: false,

                  offset: const Offset(0, 28),

                  child: Row(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Material(

                        elevation: 8,

                        borderRadius: BorderRadius.circular(4),

                        color: Colors.white,

                        child: Container(

                          width: 220,

                          padding: const EdgeInsets.symmetric(vertical: 4),

                          decoration: BoxDecoration(

                            color: Colors.white,

                            border: Border.all(color: AppTheme.borderColor),

                            borderRadius: BorderRadius.circular(4),

                          ),

                          child: Column(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              _MainMenuItemWidget(

                                icon: LucideIcons.arrowUpDown,

                                label: 'Sort by',

                                hasSubMenu: true,

                                isActive: _activeSubMenu == 'Sort by',

                                onHover: () => setStateOverlay(() {

                                  _activeSubMenu = 'Sort by';

                                  hoveredSubMenuItem = null;

                                }),

                                onTap: () {},

                              ),

                              _MainMenuItemWidget(

                                icon: LucideIcons.download,

                                label: 'Import Recurring Invoices',

                                onHover: () => setStateOverlay(() {

                                  _activeSubMenu = null;

                                  hoveredSubMenuItem = null;

                                }),

                                onTap: _closeMoreMenu,

                              ),

                              _MainMenuItemWidget(

                                icon: LucideIcons.upload,

                                label: 'Export',

                                hasSubMenu: true,

                                isActive: _activeSubMenu == 'Export',

                                onHover: () => setStateOverlay(() {

                                  _activeSubMenu = 'Export';

                                  hoveredSubMenuItem = null;

                                }),

                                onTap: () {},

                              ),

                              const Divider(

                                height: 8,

                                color: Color(0xFFD0D0D0),

                              ),

                              _MainMenuItemWidget(

                                icon: LucideIcons.settings,

                                label: 'Preferences',

                                onHover: () => setStateOverlay(() {

                                  _activeSubMenu = null;

                                  hoveredSubMenuItem = null;

                                }),

                                onTap: () {

                                  _closeMoreMenu();

                                  setState(() {

                                    _showPreferencesOverlay = true;

                                  });

                                },

                              ),

                              _MainMenuItemWidget(

                                icon: LucideIcons.sliders,

                                label: 'Manage Custom Fields',

                                onHover: () => setStateOverlay(() {

                                  _activeSubMenu = null;

                                  hoveredSubMenuItem = null;

                                }),

                                onTap: _closeMoreMenu,

                              ),

                              const Divider(

                                height: 8,

                                color: Color(0xFFD0D0D0),

                              ),

                              _MainMenuItemWidget(

                                icon: LucideIcons.refreshCw,

                                label: 'Refresh List',

                                onHover: () => setStateOverlay(() {

                                  _activeSubMenu = null;

                                  hoveredSubMenuItem = null;

                                }),

                                onTap: _closeMoreMenu,

                              ),

                              _MainMenuItemWidget(

                                icon: LucideIcons.columns,

                                label: 'Reset Column Width',

                                onHover: () => setStateOverlay(() {

                                  _activeSubMenu = null;

                                  hoveredSubMenuItem = null;

                                }),

                                onTap: _closeMoreMenu,

                              ),

                            ],

                          ),

                        ),

                      ),

                      if (subMenuWidget != null) ...[

                        const SizedBox(width: 4),

                        Padding(

                          padding: EdgeInsets.only(

                            top: _activeSubMenu == 'Export' ? 76 : 4,

                          ),

                          child: Material(

                            elevation: 8,

                            borderRadius: BorderRadius.circular(4),

                            color: Colors.white,

                            child: Container(

                              decoration: BoxDecoration(

                                color: Colors.white,

                                border: Border.all(color: AppTheme.borderColor),

                                borderRadius: BorderRadius.circular(4),

                              ),

                              child: subMenuWidget,

                            ),

                          ),

                        ),

                      ],

                    ],

                  ),

                ),

              ],

            ),

          );

        },

      ),

    );

  }



  Widget _buildSortBySubMenu(

    StateSetter setStateOverlay,

    String? hoveredItem,

    Function(String?) setHovered,

  ) {

    final sortOptions = [

      'Date',

      'Recurring Invoice Number',

      'Reference#',

      'Customer Name',

      'Total',

      'Balance',

      'Issued Date',

      'Created Time',

      'Last Modified Time',

    ];



    return Container(

      width: 200,

      color: Colors.white,

      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Column(

        mainAxisSize: MainAxisSize.min,

        crossAxisAlignment: CrossAxisAlignment.start,

        children: sortOptions.map((opt) {

          final isSelected = opt == 'Created Time';

          final isHovered = hoveredItem == opt;

          return MouseRegion(

            onEnter: (_) => setHovered(opt),

            onExit: (_) => setHovered(null),

            child: InkWell(

              onTap: () => _closeMoreMenu(),

              child: Container(

                height: 36,

                width: double.infinity,

                padding: const EdgeInsets.symmetric(

                  horizontal: AppTheme.space16,

                ),

                color: isHovered

                    ? AppTheme.primaryBlue

                    : (isSelected

                          ? const Color(0xFFE2E8F0)

                          : Colors.transparent),

                alignment: Alignment.centerLeft,

                child: Row(

                  children: [

                    Expanded(

                      child: Text(

                        opt,

                        style: TextStyle(

                          fontSize: 12,

                          color: isHovered

                              ? Colors.white

                              : (isSelected

                                    ? AppTheme.primaryBlue

                                    : AppTheme.textPrimary),

                          fontWeight: isSelected

                              ? FontWeight.w500

                              : FontWeight.w400,

                        ),

                      ),

                    ),

                    if (isSelected ||

                        (isHovered && opt == 'Recurring Invoice Number'))

                      Icon(

                        isSelected

                            ? LucideIcons.arrowDown

                            : LucideIcons.arrowUp,

                        size: 12,

                        color: isHovered ? Colors.white : AppTheme.primaryBlue,

                      ),

                  ],

                ),

              ),

            ),

          );

        }).toList(),

      ),

    );

  }



  Widget _buildExportSubMenu(

    StateSetter setStateOverlay,

    String? hoveredItem,

    Function(String?) setHovered,

  ) {

    final exportOptions = ['Export Recurring Invoices', 'Export Current View'];



    return Container(

      width: 180,

      color: Colors.white,

      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Column(

        mainAxisSize: MainAxisSize.min,

        crossAxisAlignment: CrossAxisAlignment.start,

        children: exportOptions.map((opt) {

          final isHovered = hoveredItem == opt;

          return MouseRegion(

            onEnter: (_) => setHovered(opt),

            onExit: (_) => setHovered(null),

            child: InkWell(

              onTap: () => _closeMoreMenu(),

              child: Container(

                height: 36,

                width: double.infinity,

                padding: const EdgeInsets.symmetric(

                  horizontal: AppTheme.space16,

                ),

                color: isHovered ? AppTheme.primaryBlue : Colors.transparent,

                alignment: Alignment.centerLeft,

                child: Text(

                  opt,

                  style: TextStyle(

                    fontSize: 12,

                    color: isHovered ? Colors.white : AppTheme.textPrimary,

                    fontWeight: FontWeight.w400,

                  ),

                ),

              ),

            ),

          );

        }).toList(),

      ),

    );

  }



  // ── Left Header ────────────────────────────────────────────────────────────



  Widget _buildLeftHeader() {

    // Bulk-actions bar when ≥1 row is checkbox-selected

    if (_checkedIds.isNotEmpty) {

      return Container(

        height: 50,

        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),

        decoration: const BoxDecoration(

          color: Colors.white,

          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),

        ),

        child: Row(

          children: [

            SizedBox(

              width: 18,

              height: 18,

              child: Checkbox(

                value: true,

                activeColor: AppTheme.primaryBlue,

                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

                visualDensity: VisualDensity.compact,

                onChanged: (_) {

                  setState(() {

                    if (_checkedIds.length == _liveInvoices.length) {

                      _checkedIds.clear();

                    } else {

                      _checkedIds

                        ..clear()

                        ..addAll(_liveInvoices.map((e) => e.id));

                    }

                  });

                },

              ),

            ),

            const SizedBox(width: AppTheme.space8),

            MenuAnchor(

              controller: _bulkMenuController,

              style: const MenuStyle(

                backgroundColor: WidgetStatePropertyAll(Colors.white),

                surfaceTintColor: WidgetStatePropertyAll(Colors.white),

                padding: WidgetStatePropertyAll(EdgeInsets.zero),

                elevation: WidgetStatePropertyAll(8),

                shape: WidgetStatePropertyAll(

                  RoundedRectangleBorder(

                    side: BorderSide(color: AppTheme.borderColor),

                    borderRadius: BorderRadius.all(Radius.circular(4)),

                  ),

                ),

              ),

              builder: (context, controller, child) {

                return InkWell(

                  onTap: () {

                    if (controller.isOpen) {

                      controller.close();

                    } else {

                      controller.open();

                    }

                  },

                  child: Container(

                    height: 28,

                    padding: const EdgeInsets.symmetric(horizontal: 8),

                    decoration: BoxDecoration(

                      border: Border.all(color: AppTheme.borderColor),

                      borderRadius: BorderRadius.circular(4),

                      color: Colors.white,

                    ),

                    child: Row(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        const Text(

                          'Bulk Actions',

                          style: TextStyle(

                            fontSize: 12,

                            fontWeight: FontWeight.w500,

                            color: AppTheme.textPrimary,

                          ),

                        ),

                        const SizedBox(width: 4),

                        Icon(

                          controller.isOpen

                              ? LucideIcons.chevronUp

                              : LucideIcons.chevronDown,

                          size: 12,

                          color: AppTheme.textSecondary,

                        ),

                      ],

                    ),

                  ),

                );

              },

              menuChildren: [
                _BulkActionMenuItem(
                  label: 'Export as PDF',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                  width: 140,
                ),
                _BulkActionMenuItem(
                  label: 'Print',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                  width: 140,
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                _BulkActionMenuItem(
                  label: 'Delete',
                  onTap: () {
                    _bulkMenuController.close();
                  },
                  width: 140,
                ),
              ],

            ),

            const SizedBox(width: AppTheme.space12),

            Container(width: 1, height: 20, color: AppTheme.borderColor),

            const SizedBox(width: AppTheme.space12),

            Text(

              '${_checkedIds.length} Selected',

              style: const TextStyle(

                fontSize: 12,

                fontWeight: FontWeight.w500,

                color: AppTheme.textPrimary,

              ),

            ),

            const Spacer(),

            InkWell(

              onTap: () => setState(() => _checkedIds.clear()),

              child: const Icon(LucideIcons.x, size: 16, color: Colors.red),

            ),

          ],

        ),

      );

    }



    // Normal header with MenuAnchor filter dropdown

    return Container(

      height: 50,

      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),

      decoration: const BoxDecoration(

        color: Colors.white,

        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),

      ),

      child: Row(

        children: [

          MenuAnchor(

            controller: _filterMenuController,

            style: const MenuStyle(

              backgroundColor: WidgetStatePropertyAll(Colors.white),

              surfaceTintColor: WidgetStatePropertyAll(Colors.white),

              padding: WidgetStatePropertyAll(EdgeInsets.zero),

              elevation: WidgetStatePropertyAll(8),

            ),

            builder: (context, controller, child) {

              final isOpen = controller.isOpen;

              return InkWell(

                onTap: () => isOpen ? controller.close() : controller.open(),

                borderRadius: BorderRadius.circular(4),

                child: Padding(

                  padding: const EdgeInsets.symmetric(

                    horizontal: 2,

                    vertical: 4,

                  ),

                  child: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      Text(

                        _selectedFilter == 'All'

                            ? 'All Item Trade Setups'

                            : _selectedFilter,

                        style: const TextStyle(

                          fontSize: 14,

                          fontWeight: FontWeight.bold,

                          color: AppTheme.textPrimary,

                        ),

                      ),

                      const SizedBox(width: AppTheme.space4),

                      Icon(

                        isOpen

                            ? LucideIcons.chevronUp

                            : LucideIcons.chevronDown,

                        size: 14,

                        color: AppTheme.primaryBlue,

                      ),

                    ],

                  ),

                ),

              );

            },

            menuChildren: [_buildFilterDropdownContent()],

          ),

          const Spacer(),

          Container(

            width: 24,

            height: 24,

            decoration: BoxDecoration(

              color: AppTheme.successGreen,

              borderRadius: BorderRadius.circular(4),

            ),

            child: IconButton(

              padding: EdgeInsets.zero,

              icon: const Icon(LucideIcons.plus, size: 14, color: Colors.white),

              onPressed: () {

                final orgId =

                    GoRouterState.of(context).pathParameters['orgSystemId'] ??

                    '6000000000';

                context.go('/$orgId${AppRoutes.itemTradeSetupCreate}');

              },

            ),

          ),

          const SizedBox(width: AppTheme.space8),

          CompositedTransformTarget(

            link: _moreLink,

            child: Container(

              width: 24,

              height: 24,

              decoration: BoxDecoration(

                border: Border.all(color: AppTheme.borderColor),

                borderRadius: BorderRadius.circular(4),

                color: _isMoreMenuOpen ? AppTheme.bgHover : Colors.white,

              ),

              child: IconButton(

                padding: EdgeInsets.zero,

                icon: const Icon(

                  LucideIcons.moreHorizontal,

                  size: 14,

                  color: AppTheme.textSecondary,

                ),

                onPressed: _toggleMoreMenu,

              ),

            ),

          ),

        ],

      ),

    );

  }



  // ── Left List ──────────────────────────────────────────────────────────────



  Widget _buildLeftList(NumberFormat currencyFormat) {

    return Container(

      color: Colors.white,

      child: ListView.separated(

        itemCount: _liveInvoices.length,

        separatorBuilder: (context, index) =>

            const Divider(height: 1, color: AppTheme.borderColor),

        itemBuilder: (context, index) {

          final inv = _liveInvoices[index];

          final isDetailSelected = inv.id == _selectedInvoice.id;

          final isChecked = _checkedIds.contains(inv.id);

          final isHovered = _hoveredId == inv.id;

          final showCheckbox = true;



          Color rowBg = Colors.transparent;

          if (isChecked) {

            rowBg = AppTheme.primaryBlue.withValues(alpha: 0.06);

          } else if (isDetailSelected) {

            rowBg = const Color(0xFFF1F1FA);

          } else if (isHovered) {

            rowBg = const Color(0xFFF8FAFC);

          }



          return MouseRegion(

            onEnter: (_) => setState(() => _hoveredId = inv.id),

            onExit: (_) => setState(() {

              if (_hoveredId == inv.id) _hoveredId = null;

            }),

            child: GestureDetector(

              onTap: () {

                setState(() {

                  _selectedInvoice = inv;
                  _itemMappingTitle = inv.customerName;

                  _showRecordPaymentPage = false;

                  _showChildInvoiceDetail = false;

                  _selectedChildInvoice = null;

                  _showCustomerDetailsPanel = false;

                  _paymentAmountController.text = inv.balanceDue

                      .toStringAsFixed(2);

                  _paymentDateController.text = inv.date;

                  try {

                    _paymentDateVal = DateFormat('dd-MM-yyyy').parse(inv.date);

                  } catch (_) {

                    _paymentDateVal = DateTime.now();

                  }

                });

                _loadItemMappingReport(inv.id);

              },

              child: Container(

                color: rowBg,

                padding: const EdgeInsets.symmetric(

                  horizontal: AppTheme.space8,

                  vertical: AppTheme.space12,

                ),

                child: Row(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // Checkbox column — always 28 px wide to avoid layout jump

                    SizedBox(

                      width: 28,

                      child: AnimatedOpacity(

                        opacity: showCheckbox ? 1.0 : 0.0,

                        duration: const Duration(milliseconds: 120),

                        child: SizedBox(

                          width: 18,

                          height: 18,

                          child: Checkbox(

                            value: isChecked,

                            activeColor: AppTheme.primaryBlue,

                            materialTapTargetSize:

                                MaterialTapTargetSize.shrinkWrap,

                            visualDensity: VisualDensity.compact,

                            side: const BorderSide(

                              color: Color(0xFFB0B8C1),

                              width: 1.5,

                            ),

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(3),

                            ),

                            onChanged: (checked) {

                              setState(() {

                                if (checked == true) {

                                  _checkedIds.add(inv.id);

                                } else {

                                  _checkedIds.remove(inv.id);

                                }

                              });

                            },

                          ),

                        ),

                      ),

                    ),

                    // Invoice content

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Row(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Expanded(

                                child: Text(

                                  inv.customerName,

                                  style: const TextStyle(

                                    fontSize: 13,

                                    fontWeight: FontWeight.w500,

                                    color: AppTheme.textPrimary,

                                  ),

                                ),

                              ),


                            ],

                          ),

                          const SizedBox(height: AppTheme.space4),

                          Row(

                            mainAxisAlignment: MainAxisAlignment.start,

                            children: [

                              Text(

                                inv.profileName,

                                style: const TextStyle(

                                  fontSize: 12,

                                  color: AppTheme.textSecondary,

                                ),

                              ),


                            ],

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

            ),

          );

        },

      ),

    );

  }



  // ── Right Header ───────────────────────────────────────────────────────────



  Widget? _buildRightHeader() {

    final showChild =

        (_showRecordPaymentPage || _showChildInvoiceDetail) &&

        _selectedChildInvoice != null;

    if (showChild) {

      return Column(

        mainAxisSize: MainAxisSize.min,

        children: [

          // Row 1: breadcrumb/title + utility icons

          Container(

            height: 50,

            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),

            color: Colors.white,

            child: Row(

              children: [

                Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Row(

                      children: [

                        const Text(

                          'Location: ',

                          style: TextStyle(

                            fontSize: 11,

                            fontWeight: FontWeight.bold,

                            color: AppTheme.textSecondary,

                          ),

                        ),

                        Text(

                          _selectedInvoice.companyName,

                          style: const TextStyle(

                            fontSize: 11,

                            color: AppTheme.textSecondary,

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 2),

                    Text(

                      _selectedChildInvoice!.id,

                      style: const TextStyle(

                        fontSize: 15,

                        fontWeight: FontWeight.bold,

                        color: AppTheme.textPrimary,

                      ),

                    ),

                  ],

                ),

                const Spacer(),

                InkWell(

                  onTap: () {

                    setState(() {

                      _showRecordPaymentPage = false;

                      _showChildInvoiceDetail = false;

                    });

                  },

                  child: const Icon(

                    LucideIcons.x,

                    size: 22,

                    color: Colors.black,

                  ),

                ),

              ],

            ),

          ),

          // Row 2: action tabs

          Container(

            height: 42,

            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),

            decoration: const BoxDecoration(

              color: Colors.white,

              border: Border(

                bottom: BorderSide(color: AppTheme.borderColor),

                top: BorderSide(color: AppTheme.borderColor),

              ),

            ),

            child: Row(

              children: [

                _buildFlatActionTab(

                  LucideIcons.pencil,

                  'Edit',

                  onTap: () {

                    context.go(

                      '/$_orgId${AppRoutes.itemTradeSetupCreate}?id=${_selectedInvoice.id}',

                    );

                  },

                ),

                _buildTabSeparator(),

                _buildFlatActionTab(LucideIcons.mail, 'Send Email'),

                _buildTabSeparator(),

                // PDF/Print dropdown

                MenuAnchor(

                  controller: _pdfPrintMenuController,

                  style: const MenuStyle(

                    backgroundColor: WidgetStatePropertyAll(Colors.white),

                    surfaceTintColor: WidgetStatePropertyAll(Colors.white),

                    padding: WidgetStatePropertyAll(EdgeInsets.zero),

                    elevation: WidgetStatePropertyAll(8),

                    shape: WidgetStatePropertyAll(

                      RoundedRectangleBorder(

                        side: BorderSide(color: AppTheme.borderColor),

                        borderRadius: BorderRadius.all(Radius.circular(4)),

                      ),

                    ),

                  ),

                  builder: (context, controller, child) {

                    return InkWell(

                      onTap: () {

                        if (controller.isOpen) {

                          controller.close();

                        } else {

                          controller.open();

                        }

                      },

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          const Icon(

                            LucideIcons.fileText,

                            size: 14,

                            color: AppTheme.textSecondary,

                          ),

                          const SizedBox(width: AppTheme.space6),

                          const Text(

                            'PDF/Print',

                            style: TextStyle(

                              fontSize: 12,

                              fontWeight: FontWeight.w400,

                              color: AppTheme.textPrimary,

                            ),

                          ),

                          const SizedBox(width: AppTheme.space2),

                          Icon(

                            controller.isOpen

                                ? LucideIcons.chevronUp

                                : LucideIcons.chevronDown,

                            size: 10,

                            color: AppTheme.textSecondary,

                          ),

                        ],

                      ),

                    );

                  },

                  menuChildren: [

                    _BulkActionMenuItem(

                      label: 'PDF',

                      icon: LucideIcons.fileText,

                      onTap: () {

                        _pdfPrintMenuController.close();

                      },

                    ),

                    _BulkActionMenuItem(

                      label: 'Print',

                      icon: LucideIcons.printer,

                      onTap: () {

                        _pdfPrintMenuController.close();

                      },

                    ),

                  ],

                ),

                _buildTabSeparator(),

                // Record Payment dropdown menu

                MenuAnchor(

                  controller: _recordPaymentMenuController,

                  style: const MenuStyle(

                    backgroundColor: WidgetStatePropertyAll(Colors.white),

                    surfaceTintColor: WidgetStatePropertyAll(Colors.white),

                    padding: WidgetStatePropertyAll(EdgeInsets.zero),

                    elevation: WidgetStatePropertyAll(8),

                    shape: WidgetStatePropertyAll(

                      RoundedRectangleBorder(

                        side: BorderSide(color: AppTheme.borderColor),

                        borderRadius: BorderRadius.all(Radius.circular(4)),

                      ),

                    ),

                  ),

                  builder: (context, controller, child) {

                    return InkWell(

                      onTap: () {

                        if (controller.isOpen) {

                          controller.close();

                        } else {

                          controller.open();

                        }

                      },

                      child: Row(

                        mainAxisSize: MainAxisSize.min,

                        children: [

                          const Icon(

                            LucideIcons.creditCard,

                            size: 14,

                            color: AppTheme.textSecondary,

                          ),

                          const SizedBox(width: AppTheme.space6),

                          const Text(

                            'Record Payment',

                            style: TextStyle(

                              fontSize: 12,

                              fontWeight: FontWeight.w400,

                              color: AppTheme.textPrimary,

                            ),

                          ),

                          const SizedBox(width: AppTheme.space2),

                          Icon(

                            controller.isOpen

                                ? LucideIcons.chevronUp

                                : LucideIcons.chevronDown,

                            size: 10,

                            color: AppTheme.textSecondary,

                          ),

                        ],

                      ),

                    );

                  },

                  menuChildren: [

                    _BulkActionMenuItem(

                      label: 'Record Payment',

                      icon: LucideIcons.creditCard,

                      onTap: () {

                        _recordPaymentMenuController.close();

                        setState(() {

                          _showRecordPaymentPage = true;

                          _showChildInvoiceDetail = false;

                          if (_selectedChildInvoice != null) {

                            _paymentAmountController.text =

                                _selectedChildInvoice!.amount.toStringAsFixed(

                                  2,

                                );

                          }

                        });

                      },

                    ),

                  ],

                ),

                _buildTabSeparator(),

                // Three-dot more menu

                MenuAnchor(

                  controller: _rightMoreMenuController,

                  style: const MenuStyle(

                    backgroundColor: WidgetStatePropertyAll(Colors.white),

                    surfaceTintColor: WidgetStatePropertyAll(Colors.white),

                    padding: WidgetStatePropertyAll(EdgeInsets.zero),

                    elevation: WidgetStatePropertyAll(8),

                    shape: WidgetStatePropertyAll(

                      RoundedRectangleBorder(

                        side: BorderSide(color: AppTheme.borderColor),

                        borderRadius: BorderRadius.all(Radius.circular(4)),

                      ),

                    ),

                  ),

                  builder: (context, controller, child) {

                    return InkWell(

                      onTap: () {

                        if (controller.isOpen) {

                          controller.close();

                        } else {

                          controller.open();

                        }

                      },

                      child: const Padding(

                        padding: EdgeInsets.symmetric(horizontal: 4),

                        child: Icon(

                          LucideIcons.moreHorizontal,

                          size: 16,

                          color: AppTheme.textSecondary,

                        ),

                      ),

                    );

                  },

                  menuChildren: [

                    _BulkActionMenuItem(

                      label: 'Mark As Sent',

                      icon: LucideIcons.mail,

                      onTap: () => _rightMoreMenuController.close(),

                    ),

                    _BulkActionMenuItem(

                      label: 'Clone',

                      icon: LucideIcons.copy,

                      onTap: () => _rightMoreMenuController.close(),

                    ),

                    _BulkActionMenuItem(

                      label: 'Stop',

                      icon: LucideIcons.ban,

                      onTap: () => _rightMoreMenuController.close(),

                    ),

                    _BulkActionMenuItem(

                      label: 'Delete',

                      icon: LucideIcons.trash2,

                      onTap: () => _rightMoreMenuController.close(),

                    ),

                  ],

                ),

              ],

            ),

          ),

        ],

      );

    } else {

      return Container(

        height: 50,

        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),

        color: Colors.white,

        child: Row(

          children: [

            Text(

              _selectedInvoice.profileName.isNotEmpty

                  ? _selectedInvoice.profileName

                  : _selectedInvoice.customerName,

              style: const TextStyle(

                fontSize: 18,

                fontWeight: FontWeight.bold,

                color: AppTheme.textPrimary,

              ),

            ),

            const Spacer(),

            _buildIconButton(

              LucideIcons.pencil,

              onTap: () {

                context.go(

                  '/$_orgId${AppRoutes.itemTradeSetupCreate}?id=${_selectedInvoice.id}',

                );

              },

            ),

            const SizedBox(width: AppTheme.space8),

            MenuAnchor(

              controller: _rightMoreMenuController,

              style: const MenuStyle(

                backgroundColor: WidgetStatePropertyAll(Colors.white),

                surfaceTintColor: WidgetStatePropertyAll(Colors.white),

                padding: WidgetStatePropertyAll(EdgeInsets.zero),

                elevation: WidgetStatePropertyAll(8),

                shape: WidgetStatePropertyAll(

                  RoundedRectangleBorder(

                    side: BorderSide(color: AppTheme.borderColor),

                    borderRadius: BorderRadius.all(Radius.circular(4)),

                  ),

                ),

              ),

              builder: (context, controller, child) {

                return OutlinedButton(

                  onPressed: () {

                    if (controller.isOpen) {

                      controller.close();

                    } else {

                      controller.open();

                    }

                  },

                  style: OutlinedButton.styleFrom(

                    backgroundColor: const Color(0xFFF4F4F4),

                    foregroundColor: AppTheme.textPrimary,

                    side: const BorderSide(color: AppTheme.borderColor),

                    padding: const EdgeInsets.symmetric(

                      horizontal: 12,

                      vertical: 8,

                    ),

                    shape: RoundedRectangleBorder(

                      borderRadius: BorderRadius.circular(4),

                    ),

                  ),

                  child: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: [

                      const Text(

                        'More',

                        style: TextStyle(

                          fontSize: 12,

                          fontWeight: FontWeight.w500,

                        ),

                      ),

                      const SizedBox(width: 4),

                      Icon(

                        controller.isOpen

                            ? LucideIcons.chevronUp

                            : LucideIcons.chevronDown,

                        size: 10,

                      ),

                    ],

                  ),

                );

              },

              menuChildren: [

                _BulkActionMenuItem(

                  label: 'Delete',

                  onTap: () => _rightMoreMenuController.close(),

                  width: 140,

                ),

              ],

            ),

            const SizedBox(width: AppTheme.space8),

            InkWell(

              onTap: () {

                context.go('/$_orgId${AppRoutes.itemTradeSetup}');

              },

              child: const Icon(LucideIcons.x, size: 22, color: Colors.black),

            ),

          ],

        ),

      );

    }

  }



  Widget _buildFlatActionTab(

    IconData icon,

    String label, {

    VoidCallback? onTap,

  }) {

    return InkWell(

      onTap: onTap ?? () {},

      child: Row(

        mainAxisSize: MainAxisSize.min,

        children: [

          Icon(icon, size: 14, color: AppTheme.textSecondary),

          const SizedBox(width: AppTheme.space6),

          Text(

            label,

            style: const TextStyle(

              fontSize: 12,

              fontWeight: FontWeight.w400,

              color: AppTheme.textPrimary,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildRightBody(NumberFormat currencyFormat) {

    if (_showRecordPaymentPage) {

      return _buildChildInvoiceDetailView(currencyFormat);

    }

    if (_showChildInvoiceDetail) {

      return _buildChildInvoiceDetailView(currencyFormat);

    }



    return Container(

      color: Colors.white,

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          // Tabs row

          Container(

            color: Colors.white,

            padding: const EdgeInsets.symmetric(horizontal: 24),

            height: 48,

            child: Row(

              children: [

                _buildTabItem('Item Mapping'),

                const SizedBox(width: 24),

                _buildTabItem('Purchase Offer'),

                const SizedBox(width: 24),

                _buildTabItem('Sales Offer'),

              ],

            ),

          ),

          const Divider(height: 1, color: AppTheme.borderColor),

          Expanded(

            child: _activeTab == 'Item Mapping'

                ? _buildItemMappingReportTab()

                : _activeTab == 'Purchase Offer'

                ? _buildPurchaseOfferReportTab()

                : _activeTab == 'Sales Offer'

                ? _buildSalesOfferReportTab()

                : _buildOtherTabsPlaceholder(),

          ),

        ],

      ),

    );

  }



  Widget _buildTabItem(String tabName) {

    final isActive = _activeTab == tabName;

    return InkWell(

      onTap: () => setState(() => _activeTab = tabName),

      child: Container(

        height: 48,

        alignment: Alignment.center,

        decoration: BoxDecoration(

          border: Border(

            bottom: BorderSide(

              color: isActive ? AppTheme.successGreen : Colors.transparent,

              width: 2,

            ),

          ),

        ),

        child: Text(

          tabName,

          style: TextStyle(

            fontSize: 13,

            fontWeight: isActive ? FontWeight.bold : FontWeight.w400,

            color: isActive ? Colors.black : AppTheme.textSecondary,

          ),

        ),

      ),

    );

  }



  Widget _buildOverviewTab(NumberFormat currencyFormat) {

    return _buildItemMappingReportTab();

  }



  Widget _buildItemMappingReportTab() {

    return Container(

      color: Colors.white,

      padding: const EdgeInsets.all(24),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            _itemMappingTitle,

            style: const TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.w700,

              color: AppTheme.textPrimary,

            ),

          ),

          const SizedBox(height: 6),

          const Text(

            'Item mapping report from the create page.',

            style: TextStyle(

              fontSize: 13,

              color: AppTheme.textSecondary,

            ),

          ),

          const SizedBox(height: 20),

          Flexible(

            child: Container(

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(8),

                border: Border.all(color: AppTheme.borderColor),

              ),

              child: _isItemMappingLoading

                  ? const Center(child: CircularProgressIndicator())

                  : _itemMappingRows.isEmpty

                  ? const Center(

                      child: Text(

                        'No item mappings available.',

                        style: TextStyle(

                          fontSize: 13,

                          color: AppTheme.textSecondary,

                        ),

                      ),

                    )

                  : Column(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Container(

                          height: 44,

                          decoration: const BoxDecoration(

                            color: Color(0xFFF9FAFB),

                            border: Border(

                              bottom: BorderSide(

                                color: AppTheme.borderColor,

                              ),

                            ),

                          ),

                          child: const Row(

                            children: [

                              Expanded(

                                child: Padding(

                                  padding: EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    'VENDOR NAME',

                                    style: TextStyle(

                                      fontSize: 11,

                                      fontWeight: FontWeight.w700,

                                      color: AppTheme.textSecondary,

                                      letterSpacing: 0.3,

                                    ),

                                  ),

                                ),

                              ),

                              SizedBox(

                                width: 1,

                                child: DecoratedBox(

                                  decoration: BoxDecoration(

                                    color: AppTheme.borderColor,

                                  ),

                                ),

                              ),

                              Expanded(

                                child: Padding(

                                  padding: EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    'VENDOR PRODUCT NAME',

                                    style: TextStyle(

                                      fontSize: 11,

                                      fontWeight: FontWeight.w700,

                                      color: AppTheme.textSecondary,

                                      letterSpacing: 0.3,

                                    ),

                                  ),

                                ),

                              ),

                              SizedBox(

                                width: 1,

                                child: DecoratedBox(

                                  decoration: BoxDecoration(

                                    color: AppTheme.borderColor,

                                  ),

                                ),

                              ),

                              Expanded(

                                child: Padding(

                                  padding: EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    'VENDOR PRODUCT CODE',

                                    style: TextStyle(

                                      fontSize: 11,

                                      fontWeight: FontWeight.w700,

                                      color: AppTheme.textSecondary,

                                      letterSpacing: 0.3,

                                    ),

                                  ),

                                ),

                              ),

                              SizedBox(
                                width: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppTheme.borderColor,
                                  ),
                                ),
                              ),

                              Expanded(

                                child: Padding(

                                  padding: EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    'STATUS',

                                    style: TextStyle(

                                      fontSize: 11,

                                      fontWeight: FontWeight.w700,

                                      color: AppTheme.textSecondary,

                                      letterSpacing: 0.3,

                                    ),

                                  ),

                                ),

                              ),

                            ],

                          ),

                        ),

                        Flexible(

                          child: ListView.separated(

                            shrinkWrap: true,

                            padding: EdgeInsets.zero,

                            itemCount: _itemMappingRows.length,

                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: AppTheme.borderColor,
                            ),

                            itemBuilder: (context, index) {

                              final row = _itemMappingRows[index];

                              return SizedBox(

                                height: 52,

                                child: Row(

                                  children: [

                                    Expanded(

                                      child: Padding(

                                        padding: const EdgeInsets.symmetric(horizontal: 16),

                                        child: Text(

                                          row.vendorName.isEmpty ? '--' : row.vendorName,

                                          style: const TextStyle(

                                            fontSize: 13,

                                            color: AppTheme.textPrimary,

                                          ),

                                        ),

                                      ),

                                    ),

                                    Container(
                                      width: 1,
                                      height: double.infinity,
                                      color: AppTheme.borderColor,
                                    ),

                                    Expanded(

                                      child: Padding(

                                        padding: const EdgeInsets.symmetric(horizontal: 16),

                                        child: Text(

                                          row.vendorProductName.isEmpty
                                              ? '--'
                                              : row.vendorProductName,

                                          style: const TextStyle(

                                            fontSize: 13,

                                            color: AppTheme.textPrimary,

                                          ),

                                        ),

                                      ),

                                    ),

                                    Container(
                                      width: 1,
                                      height: double.infinity,
                                      color: AppTheme.borderColor,
                                    ),

                                    Expanded(

                                      child: Padding(

                                        padding: const EdgeInsets.symmetric(horizontal: 16),

                                        child: Text(

                                          row.vendorProductCode.isEmpty
                                              ? '--'
                                              : row.vendorProductCode,

                                          style: const TextStyle(

                                            fontSize: 13,

                                            color: AppTheme.textPrimary,

                                          ),

                                        ),

                                      ),

                                    ),

                                    Container(
                                      width: 1,
                                      height: double.infinity,
                                      color: AppTheme.borderColor,
                                    ),

                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: row.status.toUpperCase() == 'ACTIVE'
                                                  ? const Color(0xFFE8F5E9)
                                                  : const Color(0xFFFFEEEF),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              row.status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: row.status.toUpperCase() == 'ACTIVE'
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFFC62828),
                                              ),
                                            ),
                                          ),
                                        ),
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

          ),

        ],

      ),

    );

    final inv = _selectedInvoice;

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        // Left Column (Details & Address)

        Expanded(

          flex: 3,

          child: Container(

            color: const Color(0xFFFAFCF9),

            padding: const EdgeInsets.all(24),

            child: SingleChildScrollView(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // Profile/Customer Header

                  Row(

                    children: [

                      Container(

                        width: 40,

                        height: 40,

                        decoration: BoxDecoration(

                          color: const Color(0xFFF3F4F6),

                          borderRadius: BorderRadius.circular(20),

                        ),

                        child: const Icon(

                          LucideIcons.user,

                          color: Color(0xFF9CA3AF),

                          size: 20,

                        ),

                      ),

                      const SizedBox(width: 16),

                      Text(

                        inv.customerName,

                        style: const TextStyle(

                          fontSize: 14,

                          fontWeight: FontWeight.w500,

                          color: Color(0xFF3B82F6),

                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 24),

                  const Text(

                    'DETAILS',

                    style: TextStyle(

                      fontSize: 12,

                      fontWeight: FontWeight.bold,

                      color: Color(0xFF374151),

                      letterSpacing: 0.5,

                    ),

                  ),

                  const SizedBox(height: 16),

                  _buildDetailRow(

                    'Profile Status:',

                    _buildStatusBadge(inv.status),

                  ),

                  _buildDetailRow(

                    'Location:',

                    Text(

                      inv.companyName,

                      style: const TextStyle(

                        fontSize: 13,

                        color: Color(0xFF1F2937),

                      ),

                    ),

                  ),

                  _buildDetailRow(

                    'Start Date:',

                    Text(

                      inv.startDate,

                      style: const TextStyle(

                        fontSize: 13,

                        color: Color(0xFF1F2937),

                      ),

                    ),

                  ),

                  _buildDetailRow(

                    'End Date:',

                    Text(

                      inv.endDate,

                      style: const TextStyle(

                        fontSize: 13,

                        color: Color(0xFF1F2937),

                      ),

                    ),

                  ),

                  _buildDetailRow(

                    'Payment Terms:',

                    Text(

                      inv.paymentTerms,

                      style: const TextStyle(

                        fontSize: 13,

                        color: Color(0xFF1F2937),

                      ),

                    ),

                  ),

                  _buildDetailRow(

                    'Salesperson:',

                    Text(

                      inv.salesperson.toUpperCase(),

                      style: const TextStyle(

                        fontSize: 13,

                        color: Color(0xFF1F2937),

                      ),

                    ),

                  ),

                  _buildDetailRow(

                    'Manually Created Invoices:',

                    Text(

                      inv.manuallyCreatedInvoices.toString(),

                      style: const TextStyle(

                        fontSize: 13,

                        color: Color(0xFF1F2937),

                      ),

                    ),

                  ),

                  const SizedBox(height: 20),

                  // Preference banner

                  Container(

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(

                      color: const Color(0xFFF3F4F6),

                      borderRadius: BorderRadius.circular(6),

                    ),

                    child: const Row(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Icon(

                          LucideIcons.info,

                          size: 14,

                          color: Color(0xFF3B82F6),

                        ),

                        SizedBox(width: 8),

                        Expanded(

                          child: Text(

                            "Recurring Invoice preference has been set to \"Create Invoices as Drafts\"",

                            style: TextStyle(

                              fontSize: 11.5,

                              color: Color(0xFF1F2937),

                              height: 1.4,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                  const SizedBox(height: 24),

                  const Text(

                    'ADDRESS',

                    style: TextStyle(

                      fontSize: 12,

                      fontWeight: FontWeight.bold,

                      color: Color(0xFF374151),

                      letterSpacing: 0.5,

                    ),

                  ),

                  const SizedBox(height: 16),

                  const Text(

                    'Billing Address',

                    style: TextStyle(

                      fontSize: 12.5,

                      fontWeight: FontWeight.w600,

                      color: Color(0xFF4B5563),

                    ),

                  ),

                  const SizedBox(height: 6),

                  ...inv.billingAddress.map(

                    (line) => Padding(

                      padding: const EdgeInsets.only(bottom: 3),

                      child: Text(

                        line,

                        style: TextStyle(

                          fontSize: 12.5,

                          color: line.startsWith('Phone:')

                              ? const Color(0xFFEF4444)

                              : const Color(0xFF4B5563),

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: 16),

                  const Text(

                    'Shipping Address',

                    style: TextStyle(

                      fontSize: 12.5,

                      fontWeight: FontWeight.w600,

                      color: Color(0xFF4B5563),

                    ),

                  ),

                  const SizedBox(height: 6),

                  ...inv.shippingAddress.map(

                    (line) => Padding(

                      padding: const EdgeInsets.only(bottom: 3),

                      child: Text(

                        line,

                        style: const TextStyle(

                          fontSize: 12.5,

                          color: Color(0xFF4B5563),

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ),

        ),

        const VerticalDivider(width: 1, color: AppTheme.borderColor),

        // Right Column (KPI Cards & Child Invoices Table)

        Expanded(

          flex: 7,

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [

              // 3 KPI Boxes

              Container(

                padding: const EdgeInsets.symmetric(vertical: 16),

                decoration: const BoxDecoration(color: Color(0xFFFAFAFC)),

                child: Row(

                  children: [

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [

                          const Text(

                            'Invoice Amount',

                            style: TextStyle(

                              fontSize: 11,

                              color: Color(0xFF6B7280),

                            ),

                          ),

                          const SizedBox(height: 8),

                          Text(

                            currencyFormat.format(inv.amount),

                            style: const TextStyle(

                              fontSize: 14,

                              fontWeight: FontWeight.bold,

                              color: Color(0xFF1F2937),

                            ),

                          ),

                        ],

                      ),

                    ),

                    Container(

                      width: 1,

                      height: 36,

                      color: const Color(0xFFE5E7EB),

                    ),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [

                          const Text(

                            'Next Invoice Date',

                            style: TextStyle(

                              fontSize: 11,

                              color: Color(0xFF6B7280),

                            ),

                          ),

                          const SizedBox(height: 8),

                          Text(

                            inv.nextInvoiceDate,

                            style: const TextStyle(

                              fontSize: 14,

                              color: Color(0xFF3B82F6),

                            ),

                          ),

                        ],

                      ),

                    ),

                    Container(

                      width: 1,

                      height: 36,

                      color: const Color(0xFFE5E7EB),

                    ),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.center,

                        children: [

                          const Text(

                            'Recurring Period',

                            style: TextStyle(

                              fontSize: 11,

                              color: Color(0xFF6B7280),

                            ),

                          ),

                          const SizedBox(height: 8),

                          Text(

                            inv.billingFrequency,

                            style: const TextStyle(

                              fontSize: 14,

                              color: Color(0xFF10B981),

                              fontWeight: FontWeight.w500,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

              Expanded(

                child: Padding(

                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [

                      // Child Invoices Section

                      Row(

                        children: [

                          MenuAnchor(

                            builder: (context, controller, child) {

                              return InkWell(

                                onTap: () {

                                  if (controller.isOpen) {

                                    controller.close();

                                  } else {

                                    controller.open();

                                  }

                                },

                                child: Row(

                                  mainAxisSize: MainAxisSize.min,

                                  children: [

                                    Text(

                                      _selectedChildInvoiceFilter == 'All'

                                          ? 'All Child Invoices'

                                          : '${_selectedChildInvoiceFilter} Child Invoices',

                                      style: const TextStyle(

                                        fontSize: 17,

                                        fontWeight: FontWeight.bold,

                                        color: Color(0xFF1F2937),

                                      ),

                                    ),

                                    const SizedBox(width: 4),

                                    const Icon(

                                      LucideIcons.chevronDown,

                                      size: 15,

                                      color: Color(0xFF1F2937),

                                    ),

                                  ],

                                ),

                              );

                            },

                            menuChildren: [

                              MenuItemButton(

                                onPressed: () => setState(

                                  () => _selectedChildInvoiceFilter = 'All',

                                ),

                                style: MenuItemButton.styleFrom(

                                  foregroundColor:

                                      _selectedChildInvoiceFilter == 'All'

                                      ? Colors.white

                                      : AppTheme.textPrimary,

                                  backgroundColor:

                                      _selectedChildInvoiceFilter == 'All'

                                      ? AppTheme.primaryBlue

                                      : Colors.transparent,

                                ),

                                child: const SizedBox(

                                  width: 180,

                                  child: Text('All'),

                                ),

                              ),

                              MenuItemButton(

                                onPressed: () => setState(

                                  () => _selectedChildInvoiceFilter = 'Unpaid',

                                ),

                                style: MenuItemButton.styleFrom(

                                  foregroundColor:

                                      _selectedChildInvoiceFilter == 'Unpaid'

                                      ? Colors.white

                                      : AppTheme.textPrimary,

                                  backgroundColor:

                                      _selectedChildInvoiceFilter == 'Unpaid'

                                      ? AppTheme.primaryBlue

                                      : Colors.transparent,

                                ),

                                child: const SizedBox(

                                  width: 180,

                                  child: Text('Unpaid'),

                                ),

                              ),

                              MenuItemButton(

                                onPressed: () => setState(

                                  () => _selectedChildInvoiceFilter = 'Paid',

                                ),

                                style: MenuItemButton.styleFrom(

                                  foregroundColor:

                                      _selectedChildInvoiceFilter == 'Paid'

                                      ? Colors.white

                                      : AppTheme.textPrimary,

                                  backgroundColor:

                                      _selectedChildInvoiceFilter == 'Paid'

                                      ? AppTheme.primaryBlue

                                      : Colors.transparent,

                                ),

                                child: const SizedBox(

                                  width: 180,

                                  child: Text('Paid'),

                                ),

                              ),

                            ],

                          ),

                          const Spacer(),

                          const Text(

                            'Unpaid Invoices : \u20B90.00',

                            style: TextStyle(

                              fontSize: 12.5,

                              fontWeight: FontWeight.w600,

                              color: Color(0xFF4B5563),

                            ),

                          ),

                        ],

                      ),

                      const SizedBox(height: 12),

                      const Divider(height: 1, color: Color(0xFFE5E7EB)),

                      const SizedBox(height: 12),

                      Expanded(

                        child: Builder(

                          builder: (context) {

                            final filteredList = inv.childInvoices.where((

                              child,

                            ) {

                              if (_selectedChildInvoiceFilter == 'Unpaid') {

                                return child.status.toUpperCase() != 'PAID';

                              } else if (_selectedChildInvoiceFilter ==

                                  'Paid') {

                                return child.status.toUpperCase() == 'PAID';

                              }

                              return true;

                            }).toList();



                            if (filteredList.isEmpty) {

                              return const Center(

                                child: Text(

                                  'No child invoices generated yet.',

                                  style: TextStyle(color: Colors.grey),

                                ),

                              );

                            }



                            return Column(

                              mainAxisSize: MainAxisSize.min,

                              children: [

                                Flexible(

                                  child: ListView.separated(

                                    shrinkWrap: true,

                                    physics:

                                        const NeverScrollableScrollPhysics(),

                                    itemCount: filteredList.length,

                                    separatorBuilder: (_, __) => const Divider(

                                      height: 1,

                                      color: Color(0xFFE5E7EB),

                                    ),

                                    itemBuilder: (context, index) {

                                      final child = filteredList[index];

                                      return Padding(

                                        padding: const EdgeInsets.symmetric(

                                          vertical: 16,

                                        ),

                                        child: Row(

                                          crossAxisAlignment:

                                              CrossAxisAlignment.start,

                                          children: [

                                            Expanded(

                                              child: Column(

                                                crossAxisAlignment:

                                                    CrossAxisAlignment.start,

                                                children: [

                                                  Text(

                                                    inv.customerName,

                                                    style: const TextStyle(

                                                      fontSize: 13,

                                                      fontWeight:

                                                          FontWeight.w600,

                                                      color: Color(0xFF1F2937),

                                                    ),

                                                  ),

                                                  const SizedBox(height: 4),

                                                  Row(

                                                    children: [

                                                      InkWell(

                                                        onTap: () {

                                                          setState(() {

                                                            _selectedChildInvoice =

                                                                child;

                                                            _showChildInvoiceDetail =

                                                                true;

                                                            _showRecordPaymentPage =

                                                                false;

                                                          });

                                                        },

                                                        child: Text(

                                                          child.id,

                                                          style: const TextStyle(

                                                            fontSize: 12,

                                                            color: Color(

                                                              0xFF3B82F6,

                                                            ),

                                                            decoration:

                                                                TextDecoration

                                                                    .underline,

                                                          ),

                                                        ),

                                                      ),

                                                      const SizedBox(width: 8),

                                                      Text(

                                                        child.date,

                                                        style: const TextStyle(

                                                          fontSize: 12,

                                                          color: Color(

                                                            0xFF6B7280,

                                                          ),

                                                        ),

                                                      ),

                                                    ],

                                                  ),

                                                  const SizedBox(height: 4),

                                                  Row(

                                                    children: [

                                                      const Icon(

                                                        LucideIcons.info,

                                                        size: 12,

                                                        color: Color(

                                                          0xFF9CA3AF,

                                                        ),

                                                      ),

                                                      const SizedBox(width: 4),

                                                      Text(

                                                        child.source,

                                                        style: const TextStyle(

                                                          fontSize: 11,

                                                          color: Color(

                                                            0xFF9CA3AF,

                                                          ),

                                                        ),

                                                      ),

                                                    ],

                                                  ),

                                                ],

                                              ),

                                            ),

                                            Column(

                                              crossAxisAlignment:

                                                  CrossAxisAlignment.end,

                                              children: [

                                                Text(

                                                  currencyFormat.format(

                                                    child.amount,

                                                  ),

                                                  style: const TextStyle(

                                                    fontSize: 13,

                                                    fontWeight: FontWeight.bold,

                                                    color: Color(0xFF1F2937),

                                                  ),

                                                ),

                                                const SizedBox(height: 4),

                                                Text(

                                                  child.status,

                                                  style: const TextStyle(

                                                    fontSize: 10,

                                                    fontWeight: FontWeight.bold,

                                                    color: Colors.grey,

                                                  ),

                                                ),

                                                const SizedBox(height: 8),

                                                ElevatedButton(

                                                  onPressed: () {

                                                    setState(() {

                                                      _showRecordPaymentPage =

                                                          true;

                                                      _showChildInvoiceDetail =

                                                          false;

                                                      _selectedChildInvoice =

                                                          child;

                                                    });

                                                  },

                                                  style: ElevatedButton.styleFrom(

                                                    backgroundColor:

                                                        const Color(0xFF10B981),

                                                    foregroundColor:

                                                        Colors.white,

                                                    elevation: 0,

                                                    padding:

                                                        const EdgeInsets.symmetric(

                                                          horizontal: 12,

                                                          vertical: 6,

                                                        ),

                                                    minimumSize: Size.zero,

                                                    tapTargetSize:

                                                        MaterialTapTargetSize

                                                            .shrinkWrap,

                                                    shape: RoundedRectangleBorder(

                                                      borderRadius:

                                                          BorderRadius.circular(

                                                            4,

                                                          ),

                                                    ),

                                                  ),

                                                  child: const Text(

                                                    'Record Payment',

                                                    style: TextStyle(

                                                      fontSize: 11,

                                                      fontWeight:

                                                          FontWeight.w600,

                                                    ),

                                                  ),

                                                ),

                                              ],

                                            ),

                                          ],

                                        ),

                                      );

                                    },

                                  ),

                                ),

                                const Divider(

                                  height: 1,

                                  color: Color(0xFFE5E7EB),

                                ),

                              ],

                            );

                          },

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

    );

  }

  Widget _buildPurchaseOfferReportTab() {

    final List<_PurchaseOfferReportRow> rows = ItemTradeSetupOverviewPage.customPurchaseOffers.containsKey(_selectedInvoice.id)
        ? ItemTradeSetupOverviewPage.customPurchaseOffers[_selectedInvoice.id]!
            .map((m) => _PurchaseOfferReportRow(
                  vendorName: m['vendorName'] ?? '',
                  offerScheme: m['offerScheme'] ?? '',
                  validityFrom: m['validityFrom'] ?? '',
                  validityTill: m['validityTill'] ?? '',
                  status: m['status'] ?? 'Active',
                ))
            .toList()
        : _dummyPurchaseOffersForItem(_selectedInvoice.customerName);

    return Container(

      color: Colors.white,

      padding: const EdgeInsets.all(24),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            _selectedInvoice.customerName,

            style: const TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.w700,

              color: AppTheme.textPrimary,

            ),

          ),

          const SizedBox(height: 6),

          const Text(

            'Purchase offer report from the create page.',

            style: TextStyle(

              fontSize: 13,

              color: AppTheme.textSecondary,

            ),

          ),

          const SizedBox(height: 20),

          Flexible(

            child: Container(

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(8),

                border: Border.all(color: AppTheme.borderColor),

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Container(

                    height: 44,

                    decoration: const BoxDecoration(

                      color: Color(0xFFF9FAFB),

                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),

                    ),

                    child: const Row(

                      children: [

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'VENDOR NAME',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                        SizedBox(
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'OFFER SCHEME',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                        SizedBox(
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'VALIDITY FROM',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                        SizedBox(
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'VALIDITY TILL',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                        SizedBox(
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'STATUS',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                  Flexible(

                    child: ListView.separated(

                      shrinkWrap: true,

                      padding: EdgeInsets.zero,

                      itemCount: rows.length,

                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppTheme.borderColor,
                      ),

                      itemBuilder: (context, index) {

                        final row = rows[index];

                        return SizedBox(

                          height: 52,

                          child: Row(

                            children: [

                              Expanded(

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    row.vendorName,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              Container(
                                width: 1,
                                height: double.infinity,
                                color: AppTheme.borderColor,
                              ),

                              Expanded(

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    row.offerScheme,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              Container(
                                width: 1,
                                height: double.infinity,
                                color: AppTheme.borderColor,
                              ),

                              Expanded(

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    row.validityFrom.isEmpty ? '--' : row.validityFrom,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              Container(
                                width: 1,
                                height: double.infinity,
                                color: AppTheme.borderColor,
                              ),

                              Expanded(

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    row.validityTill.isEmpty ? '--' : row.validityTill,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              Container(
                                width: 1,
                                height: double.infinity,
                                color: AppTheme.borderColor,
                              ),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: row.status.toUpperCase() == 'ACTIVE'
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFEEEF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        row.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: row.status.toUpperCase() == 'ACTIVE'
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFFC62828),
                                        ),
                                      ),
                                    ),
                                  ),
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

          ),

        ],

      ),

    );

  }

  Widget _buildSalesOfferReportTab() {

    final List<_SalesOfferReportRow> rows = ItemTradeSetupOverviewPage.customSalesOffers.containsKey(_selectedInvoice.id)
        ? ItemTradeSetupOverviewPage.customSalesOffers[_selectedInvoice.id]!
            .map((m) => _SalesOfferReportRow(
                  customerName: m['customerName'] ?? '',
                  offerScheme: m['offerScheme'] ?? '',
                  validityFrom: m['validityFrom'] ?? '',
                  validityTill: m['validityTill'] ?? '',
                  status: m['status'] ?? 'Active',
                ))
            .toList()
        : _dummySalesOffersForItem(_selectedInvoice.customerName);

    return Container(

      color: Colors.white,

      padding: const EdgeInsets.all(24),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(

            _selectedInvoice.customerName,

            style: const TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.w700,

              color: AppTheme.textPrimary,

            ),

          ),

          const SizedBox(height: 6),

          const Text(

            'Sales offer report from the create page.',

            style: TextStyle(

              fontSize: 13,

              color: AppTheme.textSecondary,

            ),

          ),

          const SizedBox(height: 20),

          Flexible(

            child: Container(

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(8),

                border: Border.all(color: AppTheme.borderColor),

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  Container(

                    height: 44,

                    decoration: const BoxDecoration(

                      color: Color(0xFFF9FAFB),

                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),

                    ),

                    child: const Row(

                      children: [

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'CUSTOMER NAME',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                        SizedBox(
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'OFFER SCHEME',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                        SizedBox(
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'VALIDITY FROM',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                        SizedBox(
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),

                        Expanded(

                          child: Padding(

                            padding: EdgeInsets.symmetric(horizontal: 16),

                            child: Text(

                              'VALIDITY TILL',

                              style: TextStyle(

                                fontSize: 11,

                                fontWeight: FontWeight.w700,

                                color: AppTheme.textSecondary,

                                letterSpacing: 0.3,

                              ),

                            ),

                          ),

                        ),

                        SizedBox(
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppTheme.borderColor,
                            ),
                          ),
                        ),

                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'STATUS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),

                      ],

                    ),

                  ),

                  Flexible(

                    child: ListView.separated(

                      shrinkWrap: true,

                      padding: EdgeInsets.zero,

                      itemCount: rows.length,

                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppTheme.borderColor,
                      ),

                      itemBuilder: (context, index) {

                        final row = rows[index];

                        return SizedBox(

                          height: 52,

                          child: Row(

                            children: [

                              Expanded(

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    row.customerName,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              Container(
                                width: 1,
                                height: double.infinity,
                                color: AppTheme.borderColor,
                              ),

                              Expanded(

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    row.offerScheme,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              Container(
                                width: 1,
                                height: double.infinity,
                                color: AppTheme.borderColor,
                              ),

                              Expanded(

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    row.validityFrom.isEmpty ? '--' : row.validityFrom,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              Container(
                                width: 1,
                                height: double.infinity,
                                color: AppTheme.borderColor,
                              ),

                              Expanded(

                                child: Padding(

                                  padding: const EdgeInsets.symmetric(horizontal: 16),

                                  child: Text(

                                    row.validityTill.isEmpty ? '--' : row.validityTill,

                                    style: const TextStyle(

                                      fontSize: 13,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ),

                              ),

                              Container(
                                width: 1,
                                height: double.infinity,
                                color: AppTheme.borderColor,
                              ),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: row.status.toUpperCase() == 'ACTIVE'
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFEEEF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        row.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: row.status.toUpperCase() == 'ACTIVE'
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFFC62828),
                                        ),
                                      ),
                                    ),
                                  ),
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

          ),

        ],

      ),

    );

  }



  Widget _buildDetailRow(String label, Widget valueWidget) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 12),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(

            width: 180,

            child: Text(

              label,

              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),

            ),

          ),

          Expanded(child: valueWidget),

        ],

      ),

    );

  }



  Widget _buildStatusBadge(String status) {

    Color bg = const Color(0xFFE5E7EB);

    Color text = const Color(0xFF374151);

    if (status.toUpperCase() == 'ACTIVE') {

      bg = const Color(0xFF3B7A12);

      text = Colors.white;

    } else if (status.toUpperCase() == 'STOPPED') {

      bg = const Color(0xFFFEE2E2);

      text = const Color(0xFF991B1B);

    } else if (status.toUpperCase() == 'EXPIRED') {

      bg = const Color(0xFFFEF3C7);

      text = const Color(0xFF92400E);

    }

    return Align(

      alignment: Alignment.centerLeft,

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),

        decoration: BoxDecoration(

          color: bg,

          borderRadius: BorderRadius.circular(2),

        ),

        child: Text(

          status,

          style: TextStyle(

            fontSize: 9.5,

            fontWeight: FontWeight.w600,

            color: text,

          ),

        ),

      ),

    );

  }



  Widget _buildKpiCard(String title, String value) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: const Color(0xFFF9FAFB),

        border: Border.all(color: const Color(0xFFE5E7EB)),

        borderRadius: BorderRadius.circular(6),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.center,

        children: [

          Text(

            title,

            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),

          ),

          const SizedBox(height: 8),

          Text(

            value,

            style: const TextStyle(

              fontSize: 14,

              fontWeight: FontWeight.bold,

              color: Color(0xFF1F2937),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildOtherTabsPlaceholder() {

    return Center(

      child: Text(

        '$_activeTab content',

        style: const TextStyle(fontSize: 16, color: Colors.grey),

      ),

    );

  }



  Widget _buildTabSeparator() {

    return Container(

      height: 20,

      width: 1,

      color: AppTheme.borderColor.withValues(alpha: 0.6),

      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space12),

    );

  }



  Widget _buildIconButton(

    IconData icon, {

    Color? color,

    VoidCallback? onTap,

    bool isActive = false,

  }) {

    return InkWell(

      onTap: onTap ?? () {},

      child: Container(

        width: 28,

        height: 28,

        decoration: BoxDecoration(

          border: Border.all(color: AppTheme.borderColor),

          borderRadius: BorderRadius.circular(4),

          color: isActive ? const Color(0xFFE9EDF0) : const Color(0xFFF4F4F4),

        ),

        child: Center(

          child: Icon(

            icon,

            size: 14,

            color: isActive

                ? AppTheme.primaryBlue

                : color ?? AppTheme.textSecondary,

          ),

        ),

      ),

    );

  }



  // ── Customer Details Side Panel ────────────────────────────────────────────



  Widget _buildCustomerDetailsPanel() {

    final inv = _selectedInvoice;

    final initials = inv.customerName

        .split(' ')

        .map((w) => w.isNotEmpty ? w[0] : '')

        .take(2)

        .join()

        .toUpperCase();



    return Material(

      color: Colors.transparent,

      child: Container(

        width: 300,

        decoration: const BoxDecoration(

          color: Colors.white,

          border: Border(left: BorderSide(color: AppTheme.borderColor)),

          boxShadow: [

            BoxShadow(

              color: Color(0x1A000000),

              blurRadius: 16,

              offset: Offset(-4, 0),

            ),

          ],

        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            // ── TOP HEADER ─────────────────────────────────────────────────

            Container(

              color: const Color(0xFFF7F8FA),

              padding: const EdgeInsets.fromLTRB(12, 12, 8, 0),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // View in module tooltip row + close

                  Row(

                    children: [

                      const Expanded(

                        child: Text(

                          'View in Customers module',

                          style: TextStyle(

                            fontSize: 11,

                            color: AppTheme.primaryBlue,

                            fontWeight: FontWeight.w500,

                          ),

                        ),

                      ),

                      InkWell(

                        onTap: () =>

                            setState(() => _showCustomerDetailsPanel = false),

                        borderRadius: BorderRadius.circular(4),

                        child: Padding(

                          padding: const EdgeInsets.all(4),

                          child: Icon(

                            LucideIcons.x,

                            size: 15,

                            color: Colors.red.shade600,

                          ),

                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 10),



                  // Avatar + name row

                  Row(

                    crossAxisAlignment: CrossAxisAlignment.center,

                    children: [

                      // Circle avatar

                      Container(

                        width: 36,

                        height: 36,

                        decoration: BoxDecoration(

                          color: AppTheme.primaryBlue.withValues(alpha: 0.15),

                          shape: BoxShape.circle,

                        ),

                        alignment: Alignment.center,

                        child: Text(

                          initials,

                          style: const TextStyle(

                            fontSize: 13,

                            fontWeight: FontWeight.bold,

                            color: AppTheme.primaryBlue,

                          ),

                        ),

                      ),

                      const SizedBox(width: 10),

                      Expanded(

                        child: Row(

                          children: [

                            Flexible(

                              child: Text(

                                inv.customerName,

                                style: const TextStyle(

                                  fontSize: 13,

                                  fontWeight: FontWeight.w600,

                                  color: AppTheme.textPrimary,

                                ),

                                overflow: TextOverflow.ellipsis,

                              ),

                            ),

                            const SizedBox(width: 4),

                            const Icon(

                              LucideIcons.externalLink,

                              size: 12,

                              color: AppTheme.primaryBlue,

                            ),

                          ],

                        ),

                      ),

                    ],

                  ),

                  const SizedBox(height: 10),



                  // Sub-icons row (lock, comment)

                  Row(

                    children: [

                      _buildPanelIconBtn(LucideIcons.lock),

                      const SizedBox(width: 8),

                      _buildPanelIconBtn(LucideIcons.messageSquare),

                    ],

                  ),

                  const SizedBox(height: 10),



                  // Tabs: Details / Activity Log

                  Row(

                    children: [

                      _buildPanelTab('Details'),

                      const SizedBox(width: 20),

                      _buildPanelTab('Activity Log'),

                    ],

                  ),

                ],

              ),

            ),



            // ── BODY ───────────────────────────────────────────────────────

            Expanded(

              child: SingleChildScrollView(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    // Stat cards row

                    Padding(

                      padding: const EdgeInsets.all(12),

                      child: IntrinsicHeight(

                        child: Row(

                          crossAxisAlignment: CrossAxisAlignment.stretch,

                          children: [

                            Expanded(

                              child: _buildStatCard(

                                icon: LucideIcons.alertTriangle,

                                iconColor: const Color(0xFFD97706),

                                label: 'Outstanding Receivables',

                                value: '\u20B90.00',

                              ),

                            ),

                            const SizedBox(width: 8),

                            Expanded(

                              child: _buildStatCard(

                                icon: LucideIcons.checkCircle,

                                iconColor: const Color(0xFF0E9F6E),

                                label: 'Unused Credits',

                                value: '\u20B90.00',

                              ),

                            ),

                          ],

                        ),

                      ),

                    ),



                    // Contact Details section

                    _buildPanelSection(

                      title: 'Contact Details',

                      child: Column(

                        children: [

                          _buildKVRow('Customer Type', 'Individual'),

                          _buildKVRow(

                            'Currency',

                            'INR',

                            valueColor: AppTheme.primaryBlue,

                          ),

                          _buildKVRow('Credit Limit', '\u20B90.00'),

                          _buildKVRow('Payment Terms', 'Net 360'),

                          _buildKVRow('Portal Status', 'Disabled'),

                          _buildKVRow(

                            'Customer Language',

                            'English',

                            showInfo: true,

                          ),

                          _buildKVRow('Price List', 'Pricelist'),

                          _buildKVRow('GST Treatment', 'Unregistered Business'),

                          _buildKVRow('Place of Supply', 'Kerala'),

                          _buildKVRow('Tax Preference', 'Taxable'),

                        ],

                      ),

                    ),



                    // Contact Persons accordion

                    _buildPanelAccordion('Contact Persons', '1'),

                  ],

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildPanelTab(String label) {

    final isActive = _customerDetailTab == label;

    return GestureDetector(

      onTap: () => setState(() => _customerDetailTab = label),

      child: Column(

        children: [

          Text(

            label,

            style: TextStyle(

              fontSize: 12,

              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,

              color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary,

            ),

          ),

          const SizedBox(height: 6),

          Container(

            height: 2,

            width: 60,

            color: isActive ? AppTheme.primaryBlue : Colors.transparent,

          ),

        ],

      ),

    );

  }



  Widget _buildPanelIconBtn(IconData icon) {

    return Container(

      width: 26,

      height: 26,

      decoration: BoxDecoration(

        border: Border.all(color: AppTheme.borderColor),

        borderRadius: BorderRadius.circular(4),

        color: Colors.white,

      ),

      child: Icon(icon, size: 13, color: AppTheme.textSecondary),

    );

  }



  Widget _buildStatCard({

    required IconData icon,

    required Color iconColor,

    required String label,

    required String value,

  }) {

    return Container(

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(

        color: Colors.white,

        border: Border.all(color: AppTheme.borderColor),

        borderRadius: BorderRadius.circular(6),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(icon, size: 16, color: iconColor),

          const SizedBox(height: 6),

          Text(

            label,

            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),

          ),

          const SizedBox(height: 4),

          Text(

            value,

            style: const TextStyle(

              fontSize: 13,

              fontWeight: FontWeight.w600,

              color: AppTheme.textPrimary,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildPanelSection({required String title, required Widget child}) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Padding(

          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),

          child: Text(

            title,

            style: const TextStyle(

              fontSize: 12,

              fontWeight: FontWeight.w600,

              color: AppTheme.textPrimary,

            ),

          ),

        ),

        child,

        const Divider(height: 1, color: AppTheme.borderColor),

      ],

    );

  }



  Widget _buildKVRow(

    String label,

    String value, {

    Color? valueColor,

    bool showInfo = false,

  }) {

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Expanded(

            flex: 5,

            child: Row(

              children: [

                Text(

                  label,

                  style: const TextStyle(

                    fontSize: 11,

                    color: AppTheme.textSecondary,

                  ),

                ),

                if (showInfo) ...[

                  const SizedBox(width: 3),

                  const Icon(

                    LucideIcons.info,

                    size: 11,

                    color: AppTheme.textSecondary,

                  ),

                ],

              ],

            ),

          ),

          Expanded(

            flex: 5,

            child: Text(

              value,

              style: TextStyle(

                fontSize: 11,

                fontWeight: FontWeight.w500,

                color: valueColor ?? AppTheme.textPrimary,

              ),

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildPanelAccordion(String title, String badge) {

    return Container(

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

      decoration: const BoxDecoration(

        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),

      ),

      child: Row(

        children: [

          Expanded(

            child: Text(

              title,

              style: const TextStyle(

                fontSize: 12,

                fontWeight: FontWeight.w600,

                color: AppTheme.textPrimary,

              ),

            ),

          ),

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),

            decoration: BoxDecoration(

              color: AppTheme.primaryBlue.withValues(alpha: 0.10),

              borderRadius: BorderRadius.circular(10),

            ),

            child: Text(

              badge,

              style: const TextStyle(

                fontSize: 10,

                color: AppTheme.primaryBlue,

                fontWeight: FontWeight.w600,

              ),

            ),

          ),

          const SizedBox(width: 8),

          const Icon(

            LucideIcons.chevronRight,

            size: 14,

            color: AppTheme.textSecondary,

          ),

        ],

      ),

    );

  }



  Widget _buildItemsTable(NumberFormat currencyFormat) {

    return Column(

      children: [

        Container(

          color: const Color(0xFF2D3748),

          padding: const EdgeInsets.symmetric(

            horizontal: AppTheme.space12,

            vertical: AppTheme.space8,

          ),

          child: const Row(

            children: [

              SizedBox(

                width: 30,

                child: Text(

                  '#',

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: 11,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

              Expanded(

                child: Text(

                  'Description',

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: 11,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

              SizedBox(

                width: 100,

                child: Text(

                  'Amount',

                  textAlign: TextAlign.end,

                  style: TextStyle(

                    color: Colors.white,

                    fontSize: 11,

                    fontWeight: FontWeight.bold,

                  ),

                ),

              ),

            ],

          ),

        ),

        ..._selectedInvoice.items.map((item) {

          return Container(

            padding: const EdgeInsets.symmetric(

              horizontal: AppTheme.space12,

              vertical: AppTheme.space8,

            ),

            decoration: const BoxDecoration(

              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),

            ),

            child: Row(

              children: [

                SizedBox(

                  width: 30,

                  child: Text(

                    item.index.toString(),

                    style: const TextStyle(

                      fontSize: 11,

                      color: AppTheme.textPrimary,

                    ),

                  ),

                ),

                Expanded(

                  child: Text(

                    item.description,

                    style: const TextStyle(

                      fontSize: 11,

                      color: AppTheme.textPrimary,

                    ),

                  ),

                ),

                SizedBox(

                  width: 100,

                  child: Text(

                    currencyFormat.format(item.amount),

                    textAlign: TextAlign.end,

                    style: const TextStyle(

                      fontSize: 11,

                      color: AppTheme.textPrimary,

                    ),

                  ),

                ),

              ],

            ),

          );

        }),

      ],

    );

  }



  // ── Choose Template Panel ──────────────────────────────────────────────────



  Widget _buildChooseTemplatePanel() {

    final templates = [

      'Standard Template',

      'Modern Template',

      'Minimal Template',

    ];

    final filtered = _templateSearchQuery.isEmpty

        ? templates

        : templates

              .where(

                (t) => t.toLowerCase().contains(

                  _templateSearchQuery.toLowerCase(),

                ),

              )

              .toList();



    return Material(

      color: Colors.transparent,

      child: Container(

        width: 270,

        decoration: const BoxDecoration(

          color: Colors.white,

          border: Border(left: BorderSide(color: AppTheme.borderColor)),

          boxShadow: [

            BoxShadow(

              color: Color(0x18000000),

              blurRadius: 12,

              offset: Offset(-4, 0),

            ),

          ],

        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // Header

            Container(

              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),

              decoration: const BoxDecoration(

                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),

              ),

              child: Row(

                children: [

                  const Text(

                    'Choose Template',

                    style: TextStyle(

                      fontSize: 14,

                      fontWeight: FontWeight.bold,

                      color: AppTheme.textPrimary,

                    ),

                  ),

                  const Spacer(),

                  InkWell(

                    onTap: () => setState(() => _showTemplatePanel = false),

                    borderRadius: BorderRadius.circular(4),

                    child: const Padding(

                      padding: EdgeInsets.all(4),

                      child: Icon(

                        LucideIcons.x,

                        size: 16,

                        color: AppTheme.textSecondary,

                      ),

                    ),

                  ),

                ],

              ),

            ),

            // Search bar

            Padding(

              padding: const EdgeInsets.all(12),

              child: Container(

                height: 34,

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius: BorderRadius.circular(5),

                  border: Border.all(color: AppTheme.borderColor),

                ),

                child: Row(

                  children: [

                    const Padding(

                      padding: EdgeInsets.symmetric(horizontal: 8),

                      child: Icon(

                        LucideIcons.search,

                        size: 13,

                        color: AppTheme.textSecondary,

                      ),

                    ),

                    Expanded(

                      child: TextField(

                        controller: _templateSearchController,

                        onChanged: (val) =>

                            setState(() => _templateSearchQuery = val),

                        style: const TextStyle(

                          fontSize: 12,

                          color: AppTheme.textPrimary,

                        ),

                        decoration: const InputDecoration(

                          hintText: 'Search Template',

                          hintStyle: TextStyle(

                            fontSize: 12,

                            color: AppTheme.textSecondary,

                          ),

                          border: InputBorder.none,

                          isDense: true,

                          contentPadding: EdgeInsets.symmetric(vertical: 8),

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ),

            // Template cards

            Expanded(

              child: ListView.builder(

                padding: const EdgeInsets.symmetric(

                  horizontal: 12,

                  vertical: 4,

                ),

                itemCount: filtered.length,

                itemBuilder: (context, i) {

                  return _buildTemplateCard(filtered[i]);

                },

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildTemplateCard(String templateName) {

    final isSelected = templateName == _selectedTemplate;

    return GestureDetector(

      onTap: () => setState(() => _selectedTemplate = templateName),

      child: Container(

        margin: const EdgeInsets.only(bottom: 12),

        child: Column(

          children: [

            // Thumbnail

            Container(

              height: 160,

              decoration: BoxDecoration(

                color: const Color(0xFFF8FAFC),

                border: Border.all(

                  color: isSelected

                      ? AppTheme.primaryBlue

                      : AppTheme.borderColor,

                  width: isSelected ? 2 : 1,

                ),

                borderRadius: BorderRadius.circular(4),

              ),

              child: Stack(

                children: [

                  // Mini invoice preview

                  Padding(

                    padding: const EdgeInsets.all(10),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Row(

                          children: [

                            Container(

                              width: 32,

                              height: 12,

                              color: const Color(0xFF2D3748),

                            ),

                            const Spacer(),

                            Container(

                              width: 50,

                              height: 8,

                              color: const Color(0xFFE2E8F0),

                            ),

                          ],

                        ),

                        const SizedBox(height: 8),

                        Container(

                          width: 60,

                          height: 6,

                          color: const Color(0xFFE2E8F0),

                        ),

                        const SizedBox(height: 3),

                        Container(

                          width: 40,

                          height: 5,

                          color: const Color(0xFFE2E8F0),

                        ),

                        const SizedBox(height: 3),

                        Container(

                          width: 50,

                          height: 5,

                          color: const Color(0xFFE2E8F0),

                        ),

                        const Spacer(),

                        Container(

                          height: 16,

                          color: const Color(0xFF2D3748),

                          child: Row(

                            children: [

                              Container(

                                width: 20,

                                color: const Color(0xFF2D3748),

                              ),

                              Expanded(

                                child: Container(

                                  color: const Color(0xFF2D3748),

                                ),

                              ),

                              Container(

                                width: 30,

                                color: const Color(0xFF2D3748),

                              ),

                            ],

                          ),

                        ),

                        const SizedBox(height: 4),

                        Row(

                          mainAxisAlignment: MainAxisAlignment.end,

                          children: [

                            Column(

                              crossAxisAlignment: CrossAxisAlignment.end,

                              children: [

                                Container(

                                  width: 40,

                                  height: 5,

                                  color: const Color(0xFFE2E8F0),

                                ),

                                const SizedBox(height: 2),

                                Container(

                                  width: 50,

                                  height: 5,

                                  color: const Color(0xFFE2E8F0),

                                ),

                                const SizedBox(height: 2),

                                Container(

                                  width: 45,

                                  height: 5,

                                  color: const Color(0xFFCBD5E0),

                                ),

                              ],

                            ),

                          ],

                        ),

                      ],

                    ),

                  ),

                  // SELECTED badge

                  if (isSelected)

                    Positioned(

                      bottom: 8,

                      left: 0,

                      right: 0,

                      child: Center(

                        child: Container(

                          padding: const EdgeInsets.symmetric(

                            horizontal: 10,

                            vertical: 4,

                          ),

                          decoration: BoxDecoration(

                            color: AppTheme.primaryBlue,

                            borderRadius: BorderRadius.circular(12),

                          ),

                          child: const Row(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              Icon(Icons.circle, size: 7, color: Colors.white),

                              SizedBox(width: 4),

                              Text(

                                'SELECTED',

                                style: TextStyle(

                                  fontSize: 10,

                                  fontWeight: FontWeight.bold,

                                  color: Colors.white,

                                  letterSpacing: 0.5,

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

            // Label

            Padding(

              padding: const EdgeInsets.only(top: 6, bottom: 2),

              child: Text(

                templateName,

                style: TextStyle(

                  fontSize: 12,

                  fontWeight: FontWeight.w500,

                  color: isSelected

                      ? AppTheme.primaryBlue

                      : AppTheme.textPrimary,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildPreferencesOverlay() {

    return Positioned.fill(

      child: Container(

        color: Colors.white,

        child: Column(

          children: [

            // Top Bar

            Container(

              height: 56,

              padding: const EdgeInsets.symmetric(horizontal: 24),

              decoration: const BoxDecoration(

                border: Border(bottom: BorderSide(color: AppTheme.borderColor)),

              ),

              child: Row(

                children: [

                  const Text(

                    'LIMITED',

                    style: TextStyle(

                      fontSize: 12,

                      fontWeight: FontWeight.bold,

                      color: AppTheme.textSecondary,

                      letterSpacing: 1.2,

                    ),

                  ),

                  const Spacer(),

                  // Search Bar Visual

                  Container(

                    width: 320,

                    height: 36,

                    padding: const EdgeInsets.symmetric(horizontal: 12),

                    decoration: BoxDecoration(

                      color: Colors.white,

                      border: Border.all(

                        color: AppTheme.primaryBlue.withValues(alpha: 0.5),

                      ),

                      borderRadius: BorderRadius.circular(8),

                    ),

                    child: const Row(

                      children: [

                        Icon(

                          LucideIcons.search,

                          size: 14,

                          color: AppTheme.primaryBlue,

                        ),

                        SizedBox(width: 8),

                        Text(

                          'Search settings ( / )',

                          style: TextStyle(

                            fontSize: 12,

                            color: AppTheme.textSecondary,

                          ),

                        ),

                      ],

                    ),

                  ),

                  const Spacer(),

                  // Close Settings Button

                  InkWell(

                    onTap: () =>

                        setState(() => _showPreferencesOverlay = false),

                    child: const Row(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Text(

                          'Close Settings',

                          style: TextStyle(

                            fontSize: 12,

                            fontWeight: FontWeight.w500,

                            color: AppTheme.textSecondary,

                          ),

                        ),

                        SizedBox(width: 4),

                        Icon(LucideIcons.x, size: 14, color: Colors.red),

                      ],

                    ),

                  ),

                ],

              ),

            ),

            // Main Content Area

            Expanded(

              child: SingleChildScrollView(

                padding: const EdgeInsets.symmetric(

                  horizontal: 32,

                  vertical: 24,

                ),

                child: Align(

                  alignment: Alignment.topLeft,

                  child: ConstrainedBox(

                    constraints: const BoxConstraints(maxWidth: 800),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        // Title

                        const Text(

                          'Recurring Invoices',

                          style: TextStyle(

                            fontSize: 20,

                            fontWeight: FontWeight.bold,

                            color: AppTheme.textPrimary,

                          ),

                        ),

                        const SizedBox(height: 16),

                        // Tab (General)

                        Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            const Text(

                              'General',

                              style: TextStyle(

                                fontSize: 13,

                                fontWeight: FontWeight.bold,

                                color: AppTheme.textPrimary,

                              ),

                            ),

                            const SizedBox(height: 8),

                            Container(

                              width: 50,

                              height: 2,

                              color: AppTheme.primaryBlue,

                            ),

                          ],

                        ),

                        const Divider(height: 1, color: AppTheme.borderColor),

                        const SizedBox(height: 24),

                        // Blue Info Box

                        Container(

                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(

                            color: const Color(0xFFEFF6FF),

                            borderRadius: BorderRadius.circular(6),

                          ),

                          child: Row(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Icon(

                                LucideIcons.info,

                                size: 16,

                                color: AppTheme.primaryBlue.withValues(

                                  alpha: 0.8,

                                ),

                              ),

                              const SizedBox(width: 8),

                              const Expanded(

                                child: Text(

                                  'Recurring Invoices are automatically created based on a configured schedule. Here you can configure the auto-charging option and the process of sending these invoices to your customers.',

                                  style: TextStyle(

                                    fontSize: 12,

                                    color: Color(0xFF1E3A8A),

                                    height: 1.4,

                                  ),

                                ),

                              ),

                            ],

                          ),

                        ),

                        const SizedBox(height: 24),

                        // Option 1

                        _buildPreferenceOption(

                          value: 'drafts',

                          title: 'Create Invoices as Drafts',

                          description:

                              'Invoices will be saved as drafts. You can review and send them to your customers for payment.',

                          nestedChild: Column(

                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              const Text(

                                'Notification Preferences',

                                style: TextStyle(

                                  fontSize: 12,

                                  fontWeight: FontWeight.bold,

                                  color: AppTheme.textPrimary,

                                ),

                              ),

                              const SizedBox(height: 8),

                              Row(

                                children: [

                                  SizedBox(

                                    width: 20,

                                    height: 20,

                                    child: Checkbox(

                                      value: _sendDraftNotifications,

                                      activeColor: AppTheme.primaryBlue,

                                      onChanged: (val) {

                                        setState(() {

                                          _sendDraftNotifications =

                                              val ?? false;

                                        });

                                      },

                                    ),

                                  ),

                                  const SizedBox(width: 8),

                                  const Text(

                                    'Send email notifications when invoices are created as drafts.',

                                    style: TextStyle(

                                      fontSize: 12,

                                      color: AppTheme.textPrimary,

                                    ),

                                  ),

                                ],

                              ),

                            ],

                          ),

                        ),

                        const SizedBox(height: 24),

                        // Option 2

                        _buildPreferenceOption(

                          value: 'send',

                          title: 'Create and Send Invoices',

                          description:

                              'Invoices will be automatically sent to your customers for payment.',

                        ),

                        const SizedBox(height: 24),

                        // Option 3

                        _buildPreferenceOption(

                          value: 'charge',

                          title: 'Create, Charge and Send Invoices',

                          description:

                              "Your customer's credit card associated with the recurring invoice is charged automatically and invoices are sent for their reference.",

                        ),

                        const SizedBox(height: 32),

                        const Divider(color: AppTheme.borderColor),

                        const SizedBox(height: 20),

                        // Save Button

                        ElevatedButton(

                          onPressed: () {

                            setState(() {

                              _showPreferencesOverlay = false;

                            });

                          },

                          style: ElevatedButton.styleFrom(

                            backgroundColor: AppTheme.successGreen,

                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(

                              horizontal: 20,

                              vertical: 12,

                            ),

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(4),

                            ),

                            elevation: 0,

                          ),

                          child: const Text(

                            'Save',

                            style: TextStyle(

                              fontSize: 13,

                              fontWeight: FontWeight.w600,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildPreferenceOption({

    required String value,

    required String title,

    required String description,

    Widget? nestedChild,

  }) {

    final isSelected = _preferencesSelectedOption == value;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Row(

          crossAxisAlignment: CrossAxisAlignment.center,

          children: [

            SizedBox(

              width: 20,

              height: 20,

              child: Radio<String>(

                value: value,

                groupValue: _preferencesSelectedOption,

                activeColor: AppTheme.primaryBlue,

                onChanged: (val) {

                  setState(() {

                    _preferencesSelectedOption = val!;

                  });

                },

              ),

            ),

            const SizedBox(width: 8),

            Text(

              title,

              style: const TextStyle(

                fontSize: 13,

                fontWeight: FontWeight.bold,

                color: AppTheme.textPrimary,

              ),

            ),

          ],

        ),

        Padding(

          padding: const EdgeInsets.only(left: 28, top: 4),

          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(

                description,

                style: const TextStyle(

                  fontSize: 12,

                  color: AppTheme.textSecondary,

                  height: 1.4,

                ),

              ),

              if (isSelected && nestedChild != null) ...[

                const SizedBox(height: 16),

                nestedChild,

              ],

            ],

          ),

        ),

      ],

    );

  }



  // ── Child Invoice Detail View (shown when Record Payment is clicked) ─────

  Widget _buildChildInvoiceDetailView(NumberFormat currencyFormat) {

    final inv = _selectedInvoice;

    final child = _selectedChildInvoice;

    if (child == null) {

      return const Center(child: Text('No child invoice selected'));

    }



    return Container(

      color: Colors.white,

      child: SingleChildScrollView(

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            // Credits Available banner

            Container(

              color: Colors.white,

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),

              child: Row(

                children: [

                  const Icon(

                    Icons.copyright,

                    size: 16,

                    color: Color(0xFF10B981),

                  ),

                  const SizedBox(width: 8),

                  const Text(

                    'Credits Available: ',

                    style: TextStyle(

                      fontSize: 12,

                      fontWeight: FontWeight.w600,

                      color: Color(0xFF10B981),

                    ),

                  ),

                  Text(

                    currencyFormat.format(200.00),

                    style: const TextStyle(

                      fontSize: 12,

                      fontWeight: FontWeight.bold,

                      color: Color(0xFF10B981),

                    ),

                  ),

                  const SizedBox(width: 8),

                  GestureDetector(

                    onTap: () {},

                    child: const Text(

                      'Apply Now',

                      style: TextStyle(

                        fontSize: 12,

                        color: AppTheme.primaryBlue,

                        fontWeight: FontWeight.w500,

                      ),

                    ),

                  ),

                ],

              ),

            ),

            const Divider(height: 1, color: AppTheme.borderColor),



            // What's Next? banner

            Container(

              color: Colors.white,

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),

              child: Row(

                children: [

                  const Text('✨', style: TextStyle(fontSize: 14)),

                  const SizedBox(width: 8),

                  const Text(

                    "WHAT'S NEXT?",

                    style: TextStyle(

                      fontSize: 12,

                      fontWeight: FontWeight.bold,

                      color: Color(0xFF1F2937),

                    ),

                  ),

                  const SizedBox(width: 8),

                  const Expanded(

                    child: Text(

                      'Send this Invoice to your customer or mark it as Sent.',

                      style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),

                    ),

                  ),

                  const SizedBox(width: 12),

                  ElevatedButton(

                    onPressed: () {},

                    style: ElevatedButton.styleFrom(

                      backgroundColor: const Color(0xFF10B981),

                      foregroundColor: Colors.white,

                      elevation: 0,

                      padding: const EdgeInsets.symmetric(

                        horizontal: 14,

                        vertical: 8,

                      ),

                      minimumSize: Size.zero,

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(4),

                      ),

                    ),

                    child: const Text(

                      'Send Invoice',

                      style: TextStyle(

                        fontSize: 12,

                        fontWeight: FontWeight.w600,

                      ),

                    ),

                  ),

                  const SizedBox(width: 8),

                  OutlinedButton(

                    onPressed: () {},

                    style: OutlinedButton.styleFrom(

                      foregroundColor: const Color(0xFF1F2937),

                      side: const BorderSide(color: Color(0xFFD1D5DB)),

                      padding: const EdgeInsets.symmetric(

                        horizontal: 14,

                        vertical: 8,

                      ),

                      minimumSize: Size.zero,

                      shape: RoundedRectangleBorder(

                        borderRadius: BorderRadius.circular(4),

                      ),

                    ),

                    child: const Text(

                      'Mark As Sent',

                      style: TextStyle(

                        fontSize: 12,

                        fontWeight: FontWeight.w500,

                      ),

                    ),

                  ),

                ],

              ),

            ),

            const Divider(height: 1, color: AppTheme.borderColor),



            // TAX INVOICE Document Preview

            Padding(

              padding: const EdgeInsets.all(24),

              child: Center(

                child: ConstrainedBox(

                  constraints: const BoxConstraints(maxWidth: 850),

                  child: MouseRegion(

                    onEnter: (_) => setState(() => _isInvoiceHovered = true),

                    onExit: (_) => setState(() => _isInvoiceHovered = false),

                    child: Container(

                      decoration: BoxDecoration(

                        color: Colors.white,

                        border: Border.all(color: AppTheme.borderColor),

                        boxShadow: const [

                          BoxShadow(

                            color: Color(0x0A000000),

                            blurRadius: 8,

                            offset: Offset(0, 4),

                          ),

                        ],

                      ),

                      child: Stack(

                        children: [

                          Positioned(

                            top: 12,

                            right: 12,

                            child: AnimatedOpacity(

                              opacity:

                                  (_isInvoiceHovered ||

                                      _customizeMenuController.isOpen)

                                  ? 1.0

                                  : 0.0,

                              duration: const Duration(milliseconds: 150),

                              child: IgnorePointer(

                                ignoring:

                                    !(_isInvoiceHovered ||

                                        _customizeMenuController.isOpen),

                                child: MenuAnchor(

                                  controller: _customizeMenuController,

                                  onClose: () => setState(() {}),

                                  style: const MenuStyle(

                                    alignment: AlignmentDirectional.bottomEnd,

                                    minimumSize: WidgetStatePropertyAll(

                                      Size(200, 0),

                                    ),

                                    backgroundColor: WidgetStatePropertyAll(

                                      Colors.white,

                                    ),

                                    surfaceTintColor: WidgetStatePropertyAll(

                                      Colors.white,

                                    ),

                                    padding: WidgetStatePropertyAll(

                                      EdgeInsets.zero,

                                    ),

                                    elevation: WidgetStatePropertyAll(8),

                                    shape: WidgetStatePropertyAll(

                                      RoundedRectangleBorder(

                                        side: BorderSide(

                                          color: AppTheme.borderColor,

                                        ),

                                        borderRadius: BorderRadius.all(

                                          Radius.circular(4),

                                        ),

                                      ),

                                    ),

                                  ),

                                  builder: (context, controller, child) {

                                    return InkWell(

                                      onTap: () {

                                        if (controller.isOpen) {

                                          controller.close();

                                        } else {

                                          controller.open();

                                        }

                                        setState(() {});

                                      },

                                      borderRadius: BorderRadius.circular(4),

                                      child: Container(

                                        padding: const EdgeInsets.symmetric(

                                          horizontal: 12,

                                          vertical: 6,

                                        ),

                                        decoration: BoxDecoration(

                                          color: AppTheme.successGreen,

                                          borderRadius: BorderRadius.circular(

                                            4,

                                          ),

                                        ),

                                        child: Row(

                                          mainAxisSize: MainAxisSize.min,

                                          children: [

                                            const Icon(

                                              LucideIcons.settings,

                                              size: 14,

                                              color: Colors.white,

                                            ),

                                            const SizedBox(width: 6),

                                            const Text(

                                              'Customize',

                                              style: TextStyle(

                                                fontSize: 12,

                                                fontWeight: FontWeight.w500,

                                                color: Colors.white,

                                              ),

                                            ),

                                            const SizedBox(width: 4),

                                            Icon(

                                              controller.isOpen

                                                  ? LucideIcons.chevronUp

                                                  : LucideIcons.chevronDown,

                                              size: 12,

                                              color: Colors.white,

                                            ),

                                          ],

                                        ),

                                      ),

                                    );

                                  },

                                  menuChildren: [

                                    _BulkActionMenuItem(

                                      label: 'Standard Template',

                                      width: 200,

                                      onTap: () {

                                        setState(

                                          () => _selectedTemplate =

                                              'Standard Template',

                                        );

                                        _customizeMenuController.close();

                                      },

                                    ),

                                    _BulkActionMenuItem(

                                      label: 'Change Template',

                                      width: 200,

                                      onTap: () {

                                        setState(

                                          () => _showTemplatePanel = true,

                                        );

                                        _customizeMenuController.close();

                                      },

                                    ),

                                    _BulkActionMenuItem(

                                      label: 'Edit Template',

                                      width: 200,

                                      onTap: () {

                                        _customizeMenuController.close();

                                      },

                                    ),

                                    _BulkActionMenuItem(

                                      label: 'Update Logo & Address',

                                      width: 200,

                                      onTap: () {

                                        _customizeMenuController.close();

                                      },

                                    ),

                                    _BulkActionMenuItem(

                                      label: 'Manage Custom Fields',

                                      width: 185,

                                      onTap: () {

                                        _customizeMenuController.close();

                                      },

                                    ),

                                    _BulkActionMenuItem(

                                      label: 'Terms & Conditions',

                                      width: 185,

                                      onTap: () {

                                        _customizeMenuController.close();

                                      },

                                    ),

                                  ],

                                ),

                              ),

                            ),

                          ),

                          Padding(

                            padding: const EdgeInsets.all(40),

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Container(

                                  decoration: BoxDecoration(

                                    border: Border.all(

                                      color: const Color(0xFFD1D5DB),

                                    ),

                                  ),

                                  child: Column(

                                    crossAxisAlignment:

                                        CrossAxisAlignment.stretch,

                                    children: [

                                      // Row 0: Logo block

                                      Padding(

                                        padding: const EdgeInsets.all(16),

                                        child: Row(

                                          crossAxisAlignment:

                                              CrossAxisAlignment.start,

                                          children: [

                                            Container(

                                              width: 120,

                                              height: 50,

                                              color: const Color(0xFF101820),

                                              alignment: Alignment.center,

                                              child: const Text(

                                                'LOGO',

                                                style: TextStyle(

                                                  color: Colors.white,

                                                  fontSize: 12,

                                                  fontWeight: FontWeight.bold,

                                                ),

                                              ),

                                            ),

                                            const SizedBox(width: 20),

                                            Expanded(

                                              child: Column(

                                                crossAxisAlignment:

                                                    CrossAxisAlignment.start,

                                                children: [

                                                  Text(

                                                    inv.companyName

                                                        .toUpperCase(),

                                                    style: const TextStyle(

                                                      fontSize: 13,

                                                      fontWeight:

                                                          FontWeight.bold,

                                                      color:

                                                          AppTheme.textPrimary,

                                                    ),

                                                  ),

                                                  const SizedBox(height: 4),

                                                  ...inv.companyAddress.map(

                                                    (line) => Padding(

                                                      padding:

                                                          const EdgeInsets.only(

                                                            bottom: 2,

                                                          ),

                                                      child: Text(

                                                        line,

                                                        style: const TextStyle(

                                                          fontSize: 11,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                    ),

                                                  ),

                                                  const SizedBox(height: 4),

                                                  Text(

                                                    'GSTIN ${inv.companyGstin}',

                                                    style: const TextStyle(

                                                      fontSize: 11,

                                                      color: AppTheme

                                                          .textSecondary,

                                                    ),

                                                  ),

                                                  Text(

                                                    inv.companyPhone,

                                                    style: const TextStyle(

                                                      fontSize: 11,

                                                      color: AppTheme

                                                          .textSecondary,

                                                    ),

                                                  ),

                                                  Text(

                                                    inv.companyEmail,

                                                    style: const TextStyle(

                                                      fontSize: 11,

                                                      color: AppTheme

                                                          .textSecondary,

                                                    ),

                                                  ),

                                                ],

                                              ),

                                            ),

                                            const Text(

                                              'TAX INVOICE',

                                              style: TextStyle(

                                                fontSize: 24,

                                                fontWeight: FontWeight.bold,

                                                color: Color(0xFF1F2937),

                                              ),

                                            ),

                                          ],

                                        ),

                                      ),

                                      const Divider(

                                        height: 1,

                                        color: Color(0xFFD1D5DB),

                                      ),



                                      // Row 1: Info block

                                      Row(

                                        crossAxisAlignment:

                                            CrossAxisAlignment.start,

                                        children: [

                                          Expanded(

                                            child: Container(

                                              padding: const EdgeInsets.all(12),

                                              decoration: const BoxDecoration(

                                                border: Border(

                                                  right: BorderSide(

                                                    color: Color(0xFFD1D5DB),

                                                  ),

                                                ),

                                              ),

                                              child: Table(

                                                columnWidths: const {

                                                  0: FixedColumnWidth(100),

                                                  1: FlexColumnWidth(),

                                                },

                                                children: [

                                                  _buildInfoRow(

                                                    '#',

                                                    child.id,

                                                    isValBold: true,

                                                  ),

                                                  _buildInfoRow(

                                                    'Invoice Date',

                                                    child.date,

                                                  ),

                                                  _buildInfoRow(

                                                    'Terms',

                                                    inv.paymentTerms,

                                                  ),

                                                  _buildInfoRow(

                                                    'Due Date',

                                                    '05-06-2027',

                                                  ),

                                                ],

                                              ),

                                            ),

                                          ),

                                          Expanded(

                                            child: Container(

                                              padding: const EdgeInsets.all(12),

                                              child: Table(

                                                columnWidths: const {

                                                  0: FixedColumnWidth(120),

                                                  1: FlexColumnWidth(),

                                                },

                                                children: [

                                                  _buildInfoRow(

                                                    'Place Of Supply',

                                                    'Kerala (32)',

                                                  ),

                                                ],

                                              ),

                                            ),

                                          ),

                                        ],

                                      ),

                                      const Divider(

                                        height: 1,

                                        color: Color(0xFFD1D5DB),

                                      ),



                                      // Row 2: Bill To / Ship To

                                      Row(

                                        crossAxisAlignment:

                                            CrossAxisAlignment.start,

                                        children: [

                                          Expanded(

                                            child: Container(

                                              padding: const EdgeInsets.all(12),

                                              decoration: const BoxDecoration(

                                                border: Border(

                                                  right: BorderSide(

                                                    color: Color(0xFFD1D5DB),

                                                  ),

                                                ),

                                              ),

                                              child: Column(

                                                crossAxisAlignment:

                                                    CrossAxisAlignment.start,

                                                children: [

                                                  const Text(

                                                    'Bill To',

                                                    style: TextStyle(

                                                      fontSize: 11,

                                                      fontWeight:

                                                          FontWeight.bold,

                                                      color: AppTheme

                                                          .textSecondary,

                                                    ),

                                                  ),

                                                  const SizedBox(height: 6),

                                                  Text(

                                                    inv.customerName,

                                                    style: const TextStyle(

                                                      fontSize: 12,

                                                      fontWeight:

                                                          FontWeight.bold,

                                                      color:

                                                          AppTheme.primaryBlue,

                                                    ),

                                                  ),

                                                  ...inv.billingAddress.map(

                                                    (line) => Padding(

                                                      padding:

                                                          const EdgeInsets.only(

                                                            top: 2,

                                                          ),

                                                      child: Text(

                                                        line,

                                                        style: const TextStyle(

                                                          fontSize: 11,

                                                          color: AppTheme

                                                              .textPrimary,

                                                        ),

                                                      ),

                                                    ),

                                                  ),

                                                ],

                                              ),

                                            ),

                                          ),

                                          Expanded(

                                            child: Container(

                                              padding: const EdgeInsets.all(12),

                                              child: Column(

                                                crossAxisAlignment:

                                                    CrossAxisAlignment.start,

                                                children: [

                                                  const Text(

                                                    'Ship To',

                                                    style: TextStyle(

                                                      fontSize: 11,

                                                      fontWeight:

                                                          FontWeight.bold,

                                                      color: AppTheme

                                                          .textSecondary,

                                                    ),

                                                  ),

                                                  const SizedBox(height: 6),

                                                  ...inv.shippingAddress.map(

                                                    (line) => Padding(

                                                      padding:

                                                          const EdgeInsets.only(

                                                            top: 2,

                                                          ),

                                                      child: Text(

                                                        line,

                                                        style: const TextStyle(

                                                          fontSize: 11,

                                                          color: AppTheme

                                                              .textPrimary,

                                                        ),

                                                      ),

                                                    ),

                                                  ),

                                                ],

                                              ),

                                            ),

                                          ),

                                        ],

                                      ),

                                    ],

                                  ),

                                ),

                                const SizedBox(height: 52),



                                // Items table header

                                Container(

                                  color: const Color(0xFFF1F5F9),

                                  padding: const EdgeInsets.symmetric(

                                    horizontal: 8,

                                    vertical: 5,

                                  ),

                                  child: const Row(

                                    children: [

                                      SizedBox(

                                        width: 30,

                                        child: Text(

                                          '#',

                                          style: TextStyle(

                                            fontSize: 10,

                                            fontWeight: FontWeight.bold,

                                          ),

                                        ),

                                      ),

                                      Expanded(

                                        child: Text(

                                          'Item & Description',

                                          style: TextStyle(

                                            fontSize: 10,

                                            fontWeight: FontWeight.bold,

                                          ),

                                        ),

                                      ),

                                      SizedBox(

                                        width: 80,

                                        child: Text(

                                          'HSN/SAC',

                                          style: TextStyle(

                                            fontSize: 10,

                                            fontWeight: FontWeight.bold,

                                          ),

                                        ),

                                      ),

                                      SizedBox(

                                        width: 50,

                                        child: Text(

                                          'Qty',

                                          style: TextStyle(

                                            fontSize: 10,

                                            fontWeight: FontWeight.bold,

                                          ),

                                          textAlign: TextAlign.right,

                                        ),

                                      ),

                                      SizedBox(

                                        width: 80,

                                        child: Text(

                                          'Rate',

                                          style: TextStyle(

                                            fontSize: 10,

                                            fontWeight: FontWeight.bold,

                                          ),

                                          textAlign: TextAlign.right,

                                        ),

                                      ),

                                      SizedBox(

                                        width: 90,

                                        child: Text(

                                          'Amount',

                                          style: TextStyle(

                                            fontSize: 10,

                                            fontWeight: FontWeight.bold,

                                          ),

                                          textAlign: TextAlign.right,

                                        ),

                                      ),

                                    ],

                                  ),

                                ),

                                const Divider(

                                  height: 1,

                                  color: AppTheme.borderColor,

                                ),



                                // Items rows

                                ...inv.items.map(

                                  (item) => Container(

                                    padding: const EdgeInsets.symmetric(

                                      horizontal: 8,

                                      vertical: 6,

                                    ),

                                    decoration: const BoxDecoration(

                                      border: Border(

                                        bottom: BorderSide(

                                          color: AppTheme.borderColor,

                                        ),

                                      ),

                                    ),

                                    child: Row(

                                      children: [

                                        SizedBox(

                                          width: 30,

                                          child: Text(

                                            '${item.index}',

                                            style: const TextStyle(

                                              fontSize: 10,

                                            ),

                                          ),

                                        ),

                                        Expanded(

                                          child: Text(

                                            item.description,

                                            style: const TextStyle(

                                              fontSize: 10,

                                            ),

                                          ),

                                        ),

                                        const SizedBox(

                                          width: 80,

                                          child: Text(

                                            '342441',

                                            style: TextStyle(fontSize: 10),

                                          ),

                                        ),

                                        const SizedBox(

                                          width: 50,

                                          child: Text(

                                            '1.00',

                                            style: TextStyle(fontSize: 10),

                                            textAlign: TextAlign.right,

                                          ),

                                        ),

                                        SizedBox(

                                          width: 80,

                                          child: Text(

                                            child.amount.toStringAsFixed(2),

                                            style: const TextStyle(

                                              fontSize: 10,

                                            ),

                                            textAlign: TextAlign.right,

                                          ),

                                        ),

                                        SizedBox(

                                          width: 90,

                                          child: Text(

                                            child.amount.toStringAsFixed(2),

                                            style: const TextStyle(

                                              fontSize: 10,

                                            ),

                                            textAlign: TextAlign.right,

                                          ),

                                        ),

                                      ],

                                    ),

                                  ),

                                ),

                                const SizedBox(height: 20),



                                // Totals + Notes

                                Row(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Expanded(

                                      flex: 3,

                                      child: Column(

                                        crossAxisAlignment:

                                            CrossAxisAlignment.start,

                                        children: [

                                          const Text(

                                            'Total In Words',

                                            style: TextStyle(

                                              fontSize: 11,

                                              fontWeight: FontWeight.bold,

                                              color: AppTheme.textSecondary,

                                            ),

                                          ),

                                          const SizedBox(height: 4),

                                          Text(

                                            'Indian Rupee ${_amountToWords(child.amount)} Only',

                                            style: const TextStyle(

                                              fontSize: 11,

                                              fontStyle: FontStyle.italic,

                                              fontWeight: FontWeight.bold,

                                            ),

                                          ),

                                          const SizedBox(height: 16),

                                          const Text(

                                            'Notes',

                                            style: TextStyle(

                                              fontSize: 11,

                                              fontWeight: FontWeight.bold,

                                              color: AppTheme.textSecondary,

                                            ),

                                          ),

                                          const SizedBox(height: 4),

                                          const Text(

                                            'Thanks for your business.',

                                            style: TextStyle(

                                              fontSize: 11,

                                              fontWeight: FontWeight.bold,

                                              color: AppTheme.textPrimary,

                                            ),

                                          ),

                                        ],

                                      ),

                                    ),

                                    const SizedBox(width: 40),

                                    Expanded(

                                      flex: 2,

                                      child: Column(

                                        children: [

                                          _buildTotalRow(

                                            'Sub Total',

                                            child.amount.toStringAsFixed(2),

                                          ),

                                          _buildTotalRow(

                                            'Total',

                                            '₹${child.amount.toStringAsFixed(2)}',

                                            isBold: true,

                                          ),

                                          _buildTotalRow(

                                            'Balance Due',

                                            '₹${child.amount.toStringAsFixed(2)}',

                                            isBold: true,

                                          ),

                                        ],

                                      ),

                                    ),

                                  ],

                                ),

                              ],

                            ),

                          ),

                          // Draft ribbon

                          Positioned(

                            top: 0,

                            left: 0,

                            child: ZerpaiDocumentCornerRibbon(

                              label: child.status,

                              color: child.status.toUpperCase() == 'PAID'

                                  ? AppTheme.successGreen

                                  : child.status.toUpperCase() == 'DRAFT'

                                  ? Colors.blueGrey.shade400

                                  : AppTheme.warningOrange,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  String _amountToWords(double amount) {

    final intAmount = amount.toInt();

    if (intAmount == 0) return 'Zero';

    final ones = [

      '',

      'One',

      'Two',

      'Three',

      'Four',

      'Five',

      'Six',

      'Seven',

      'Eight',

      'Nine',

      'Ten',

      'Eleven',

      'Twelve',

      'Thirteen',

      'Fourteen',

      'Fifteen',

      'Sixteen',

      'Seventeen',

      'Eighteen',

      'Nineteen',

    ];

    final tens = [

      '',

      '',

      'Twenty',

      'Thirty',

      'Forty',

      'Fifty',

      'Sixty',

      'Seventy',

      'Eighty',

      'Ninety',

    ];

    String convert(int n) {

      if (n < 20) return ones[n];

      if (n < 100)

        return '${tens[n ~/ 10]}${n % 10 > 0 ? ' ${ones[n % 10]}' : ''}';

      if (n < 1000)

        return '${ones[n ~/ 100]} Hundred${n % 100 > 0 ? ' ${convert(n % 100)}' : ''}';

      if (n < 100000)

        return '${convert(n ~/ 1000)} Thousand${n % 1000 > 0 ? ' ${convert(n % 1000)}' : ''}';

      if (n < 10000000)

        return '${convert(n ~/ 100000)} Lakh${n % 100000 > 0 ? ' ${convert(n % 100000)}' : ''}';

      return '${convert(n ~/ 10000000)} Crore${n % 10000000 > 0 ? ' ${convert(n % 10000000)}' : ''}';

    }



    return convert(intAmount);

  }



  Widget _buildNextInvoiceTab() {

    final inv = _selectedInvoice;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.stretch,

      children: [

        Expanded(

          child: SingleChildScrollView(

            child: Container(

              color: Colors.white,

              padding: const EdgeInsets.symmetric(vertical: 24),

              child: Center(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    ConstrainedBox(

                      constraints: const BoxConstraints(maxWidth: 850),

                      child: MouseRegion(

                        onEnter: (_) =>

                            setState(() => _isInvoiceHovered = true),

                        onExit: (_) =>

                            setState(() => _isInvoiceHovered = false),

                        child: Container(

                          decoration: BoxDecoration(

                            color: Colors.white,

                            border: Border.all(color: AppTheme.borderColor),

                            boxShadow: const [

                              BoxShadow(

                                color: Color(0x0A000000),

                                blurRadius: 8,

                                offset: Offset(0, 4),

                              ),

                            ],

                          ),

                          child: Stack(

                            children: [

                              Positioned(

                                top: 12,

                                right: 12,

                                child: AnimatedOpacity(

                                  opacity:

                                      (_isInvoiceHovered ||

                                          _customizeMenuController.isOpen)

                                      ? 1.0

                                      : 0.0,

                                  duration: const Duration(milliseconds: 150),

                                  child: IgnorePointer(

                                    ignoring:

                                        !(_isInvoiceHovered ||

                                            _customizeMenuController.isOpen),

                                    child: MenuAnchor(

                                      controller: _customizeMenuController,

                                      onClose: () => setState(() {}),

                                      style: const MenuStyle(

                                        alignment:

                                            AlignmentDirectional.bottomEnd,

                                        minimumSize: WidgetStatePropertyAll(

                                          Size(200, 0),

                                        ),

                                        backgroundColor: WidgetStatePropertyAll(

                                          Colors.white,

                                        ),

                                        surfaceTintColor:

                                            WidgetStatePropertyAll(

                                              Colors.white,

                                            ),

                                        padding: WidgetStatePropertyAll(

                                          EdgeInsets.zero,

                                        ),

                                        elevation: WidgetStatePropertyAll(8),

                                        shape: WidgetStatePropertyAll(

                                          RoundedRectangleBorder(

                                            side: BorderSide(

                                              color: AppTheme.borderColor,

                                            ),

                                            borderRadius: BorderRadius.all(

                                              Radius.circular(4),

                                            ),

                                          ),

                                        ),

                                      ),

                                      builder: (context, controller, child) {

                                        return InkWell(

                                          onTap: () {

                                            if (controller.isOpen) {

                                              controller.close();

                                            } else {

                                              controller.open();

                                            }

                                            setState(() {});

                                          },

                                          borderRadius: BorderRadius.circular(

                                            4,

                                          ),

                                          child: Container(

                                            padding: const EdgeInsets.symmetric(

                                              horizontal: 12,

                                              vertical: 6,

                                            ),

                                            decoration: BoxDecoration(

                                              color: AppTheme.successGreen,

                                              borderRadius:

                                                  BorderRadius.circular(4),

                                            ),

                                            child: Row(

                                              mainAxisSize: MainAxisSize.min,

                                              children: [

                                                const Icon(

                                                  LucideIcons.settings,

                                                  size: 14,

                                                  color: Colors.white,

                                                ),

                                                const SizedBox(width: 6),

                                                const Text(

                                                  'Customize',

                                                  style: TextStyle(

                                                    fontSize: 12,

                                                    fontWeight: FontWeight.w500,

                                                    color: Colors.white,

                                                  ),

                                                ),

                                                const SizedBox(width: 4),

                                                Icon(

                                                  controller.isOpen

                                                      ? LucideIcons.chevronUp

                                                      : LucideIcons.chevronDown,

                                                  size: 12,

                                                  color: Colors.white,

                                                ),

                                              ],

                                            ),

                                          ),

                                        );

                                      },

                                      menuChildren: [

                                        _BulkActionMenuItem(

                                          label: 'Standard Template',

                                          width: 200,

                                          onTap: () {

                                            setState(

                                              () => _selectedTemplate =

                                                  'Standard Template',

                                            );

                                            _customizeMenuController.close();

                                          },

                                        ),

                                        _BulkActionMenuItem(

                                          label: 'Change Template',

                                          width: 200,

                                          onTap: () {

                                            setState(

                                              () => _showTemplatePanel = true,

                                            );

                                            _customizeMenuController.close();

                                          },

                                        ),

                                        _BulkActionMenuItem(

                                          label: 'Edit Template',

                                          width: 200,

                                          onTap: () {

                                            _customizeMenuController.close();

                                          },

                                        ),

                                        _BulkActionMenuItem(

                                          label: 'Update Logo & Address',

                                          width: 200,

                                          onTap: () {

                                            _customizeMenuController.close();

                                          },

                                        ),

                                        _BulkActionMenuItem(

                                          label: 'Manage Custom Fields',

                                          width: 185,

                                          onTap: () {

                                            _customizeMenuController.close();

                                          },

                                        ),

                                        _BulkActionMenuItem(

                                          label: 'Terms & Conditions',

                                          width: 185,

                                          onTap: () {

                                            _customizeMenuController.close();

                                          },

                                        ),

                                      ],

                                    ),

                                  ),

                                ),

                              ),

                              Padding(

                                padding: const EdgeInsets.all(40),

                                child: Column(

                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [

                                    Container(

                                      decoration: BoxDecoration(

                                        border: Border.all(

                                          color: const Color(0xFFD1D5DB),

                                        ),

                                      ),

                                      child: Column(

                                        crossAxisAlignment:

                                            CrossAxisAlignment.stretch,

                                        children: [

                                          // Row 0: Logo block

                                          Padding(

                                            padding: const EdgeInsets.all(16),

                                            child: Row(

                                              crossAxisAlignment:

                                                  CrossAxisAlignment.start,

                                              children: [

                                                Container(

                                                  width: 120,

                                                  height: 50,

                                                  color: const Color(

                                                    0xFF101820,

                                                  ),

                                                  alignment: Alignment.center,

                                                  child: const Text(

                                                    'LOGO',

                                                    style: TextStyle(

                                                      color: Colors.white,

                                                      fontSize: 12,

                                                      fontWeight:

                                                          FontWeight.bold,

                                                    ),

                                                  ),

                                                ),

                                                const SizedBox(width: 20),

                                                Expanded(

                                                  child: Column(

                                                    crossAxisAlignment:

                                                        CrossAxisAlignment

                                                            .start,

                                                    children: [

                                                      Text(

                                                        inv.companyName

                                                            .toUpperCase(),

                                                        style: const TextStyle(

                                                          fontSize: 13,

                                                          fontWeight:

                                                              FontWeight.bold,

                                                          color: AppTheme

                                                              .textPrimary,

                                                        ),

                                                      ),

                                                      const SizedBox(height: 4),

                                                      ...inv.companyAddress.map(

                                                        (line) => Padding(

                                                          padding:

                                                              const EdgeInsets.only(

                                                                bottom: 2,

                                                              ),

                                                          child: Text(

                                                            line,

                                                            style: const TextStyle(

                                                              fontSize: 11,

                                                              color: AppTheme

                                                                  .textSecondary,

                                                            ),

                                                          ),

                                                        ),

                                                      ),

                                                      const SizedBox(height: 4),

                                                      Text(

                                                        'GSTIN ${inv.companyGstin}',

                                                        style: const TextStyle(

                                                          fontSize: 11,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                      Text(

                                                        inv.companyPhone,

                                                        style: const TextStyle(

                                                          fontSize: 11,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                      Text(

                                                        inv.companyEmail,

                                                        style: const TextStyle(

                                                          fontSize: 11,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                    ],

                                                  ),

                                                ),

                                                const Text(

                                                  'TAX INVOICE',

                                                  style: TextStyle(

                                                    fontSize: 24,

                                                    fontWeight: FontWeight.bold,

                                                    color: Color(0xFF1F2937),

                                                  ),

                                                ),

                                              ],

                                            ),

                                          ),

                                          const Divider(

                                            height: 1,

                                            color: Color(0xFFD1D5DB),

                                          ),



                                          // Row 1: Info block

                                          Row(

                                            crossAxisAlignment:

                                                CrossAxisAlignment.start,

                                            children: [

                                              Expanded(

                                                child: Container(

                                                  padding: const EdgeInsets.all(

                                                    12,

                                                  ),

                                                  decoration:

                                                      const BoxDecoration(

                                                        border: Border(

                                                          right: BorderSide(

                                                            color: Color(

                                                              0xFFD1D5DB,

                                                            ),

                                                          ),

                                                        ),

                                                      ),

                                                  child: Table(

                                                    columnWidths: const {

                                                      0: FixedColumnWidth(100),

                                                      1: FlexColumnWidth(),

                                                    },

                                                    children: [

                                                      _buildInfoRow(

                                                        '#',

                                                        'Will be generated automatically',

                                                        isValBold: true,

                                                      ),

                                                      _buildInfoRow(

                                                        'Invoice Date',

                                                        inv.date,

                                                      ),

                                                      _buildInfoRow(

                                                        'Terms',

                                                        inv.paymentTerms,

                                                      ),

                                                      _buildInfoRow(

                                                        'Due Date',

                                                        '15-06-2027',

                                                      ),

                                                    ],

                                                  ),

                                                ),

                                              ),

                                              Expanded(

                                                child: Container(

                                                  padding: const EdgeInsets.all(

                                                    12,

                                                  ),

                                                  child: Table(

                                                    columnWidths: const {

                                                      0: FixedColumnWidth(120),

                                                      1: FlexColumnWidth(),

                                                    },

                                                    children: [

                                                      _buildInfoRow(

                                                        'Place Of Supply',

                                                        'Kerala (32)',

                                                      ),

                                                    ],

                                                  ),

                                                ),

                                              ),

                                            ],

                                          ),

                                          const Divider(

                                            height: 1,

                                            color: Color(0xFFD1D5DB),

                                          ),



                                          // Row 2: Bill To / Ship To

                                          Row(

                                            crossAxisAlignment:

                                                CrossAxisAlignment.start,

                                            children: [

                                              Expanded(

                                                child: Container(

                                                  padding: const EdgeInsets.all(

                                                    12,

                                                  ),

                                                  decoration:

                                                      const BoxDecoration(

                                                        border: Border(

                                                          right: BorderSide(

                                                            color: Color(

                                                              0xFFD1D5DB,

                                                            ),

                                                          ),

                                                        ),

                                                      ),

                                                  child: Column(

                                                    crossAxisAlignment:

                                                        CrossAxisAlignment

                                                            .start,

                                                    children: [

                                                      const Text(

                                                        'Bill To',

                                                        style: TextStyle(

                                                          fontSize: 11,

                                                          fontWeight:

                                                              FontWeight.bold,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                      const SizedBox(height: 6),

                                                      Text(

                                                        inv.customerName,

                                                        style: const TextStyle(

                                                          fontSize: 12,

                                                          fontWeight:

                                                              FontWeight.bold,

                                                          color: AppTheme

                                                              .primaryBlue,

                                                        ),

                                                      ),

                                                      ...inv.billingAddress.map(

                                                        (line) => Padding(

                                                          padding:

                                                              const EdgeInsets.only(

                                                                top: 2,

                                                              ),

                                                          child: Text(

                                                            line,

                                                            style: const TextStyle(

                                                              fontSize: 11,

                                                              color: AppTheme

                                                                  .textPrimary,

                                                            ),

                                                          ),

                                                        ),

                                                      ),

                                                    ],

                                                  ),

                                                ),

                                              ),

                                              Expanded(

                                                child: Container(

                                                  padding: const EdgeInsets.all(

                                                    12,

                                                  ),

                                                  child: Column(

                                                    crossAxisAlignment:

                                                        CrossAxisAlignment

                                                            .start,

                                                    children: [

                                                      const Text(

                                                        'Ship To',

                                                        style: TextStyle(

                                                          fontSize: 11,

                                                          fontWeight:

                                                              FontWeight.bold,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                      const SizedBox(height: 6),

                                                      ...inv.shippingAddress.map(

                                                        (line) => Padding(

                                                          padding:

                                                              const EdgeInsets.only(

                                                                top: 2,

                                                              ),

                                                          child: Text(

                                                            line,

                                                            style: const TextStyle(

                                                              fontSize: 11,

                                                              color: AppTheme

                                                                  .textPrimary,

                                                            ),

                                                          ),

                                                        ),

                                                      ),

                                                    ],

                                                  ),

                                                ),

                                              ),

                                            ],

                                          ),

                                          const Divider(

                                            height: 1,

                                            color: Color(0xFFD1D5DB),

                                          ),

                                          const SizedBox(height: 60),



                                          // Items table wrapper (less wide)

                                          Padding(

                                            padding: const EdgeInsets.symmetric(

                                              horizontal: 24,

                                            ),

                                            child: Column(

                                              crossAxisAlignment:

                                                  CrossAxisAlignment.stretch,

                                              children: [

                                                // Row 3: Items table header

                                                Container(

                                                  color: const Color(0xFFF9FAFB),

                                                  padding: const EdgeInsets.symmetric(

                                                    horizontal: 8,

                                                    vertical: 5,

                                                  ),

                                                  child: IntrinsicHeight(

                                                    child: Row(

                                                      children: [

                                                        const SizedBox(

                                                          width: 30,

                                                          child: Text(

                                                            '#',

                                                            style: TextStyle(

                                                              fontSize: 10,

                                                              fontWeight:

                                                                  FontWeight.bold,

                                                            ),

                                                          ),

                                                        ),

                                                        Container(

                                                          width: 1,

                                                          color: const Color(

                                                            0xFFD1D5DB,

                                                          ),

                                                        ),

                                                        const SizedBox(width: 8),

                                                        const Expanded(

                                                          child: Text(

                                                            'Item & Description',

                                                            style: TextStyle(

                                                              fontSize: 10,

                                                              fontWeight:

                                                                  FontWeight.bold,

                                                            ),

                                                          ),

                                                        ),

                                                        Container(

                                                          width: 1,

                                                          color: const Color(

                                                            0xFFD1D5DB,

                                                          ),

                                                        ),

                                                        const SizedBox(width: 8),

                                                        const SizedBox(

                                                          width: 80,

                                                          child: Text(

                                                            'HSN/SAC',

                                                            style: TextStyle(

                                                              fontSize: 10,

                                                              fontWeight:

                                                                  FontWeight.bold,

                                                            ),

                                                          ),

                                                        ),

                                                        Container(

                                                          width: 1,

                                                          color: const Color(

                                                            0xFFD1D5DB,

                                                          ),

                                                        ),

                                                        const SizedBox(width: 8),

                                                        const SizedBox(

                                                          width: 50,

                                                          child: Text(

                                                            'Qty',

                                                            style: TextStyle(

                                                              fontSize: 10,

                                                              fontWeight:

                                                                  FontWeight.bold,

                                                            ),

                                                            textAlign: TextAlign.right,

                                                          ),

                                                        ),

                                                        Container(

                                                          width: 1,

                                                          color: const Color(

                                                            0xFFD1D5DB,

                                                          ),

                                                        ),

                                                        const SizedBox(width: 8),

                                                        const SizedBox(

                                                          width: 80,

                                                          child: Text(

                                                            'Rate',

                                                            style: TextStyle(

                                                              fontSize: 10,

                                                              fontWeight:

                                                                  FontWeight.bold,

                                                            ),

                                                            textAlign: TextAlign.right,

                                                          ),

                                                        ),

                                                        Container(

                                                          width: 1,

                                                          color: const Color(

                                                            0xFFD1D5DB,

                                                          ),

                                                        ),

                                                        const SizedBox(width: 8),

                                                        const SizedBox(

                                                          width: 90,

                                                          child: Text(

                                                            'Amount',

                                                            style: TextStyle(

                                                              fontSize: 10,

                                                              fontWeight:

                                                                  FontWeight.bold,

                                                            ),

                                                            textAlign: TextAlign.right,

                                                          ),

                                                        ),

                                                      ],

                                                    ),

                                                  ),

                                                ),

                                                const Divider(

                                                  height: 1,

                                                  color: AppTheme.borderColor,

                                                ),



                                                // Items rows

                                                ...inv.items.map(

                                                  (item) => Container(

                                                    padding: const EdgeInsets.symmetric(

                                                      vertical: 6,

                                                    ),

                                                    decoration: const BoxDecoration(

                                                      border: Border(

                                                        bottom: BorderSide(

                                                          color: Color(0xFFD1D5DB),

                                                        ),

                                                      ),

                                                    ),

                                                    child: IntrinsicHeight(

                                                      child: Row(

                                                        children: [

                                                          SizedBox(

                                                            width: 30,

                                                            child: Text(

                                                              '${item.index}',

                                                              style: const TextStyle(

                                                                fontSize: 10,

                                                              ),

                                                            ),

                                                          ),

                                                          Container(

                                                            width: 1,

                                                            color: const Color(

                                                              0xFFD1D5DB,

                                                            ),

                                                          ),

                                                          const SizedBox(width: 8),

                                                          Expanded(

                                                            child: Text(

                                                              item.description,

                                                              style: const TextStyle(

                                                                fontSize: 10,

                                                              ),

                                                            ),

                                                          ),

                                                          Container(

                                                            width: 1,

                                                            color: const Color(

                                                              0xFFD1D5DB,

                                                            ),

                                                          ),

                                                          const SizedBox(width: 8),

                                                          const SizedBox(

                                                            width: 80,

                                                            child: Text(

                                                              '342441',

                                                              style: TextStyle(

                                                                fontSize: 10,

                                                              ),

                                                            ),

                                                          ),

                                                          Container(

                                                            width: 1,

                                                            color: const Color(

                                                              0xFFD1D5DB,

                                                            ),

                                                          ),

                                                          const SizedBox(width: 8),

                                                          const SizedBox(

                                                            width: 50,

                                                            child: Text(

                                                              '1.00',

                                                              style: TextStyle(

                                                                fontSize: 10,

                                                              ),

                                                              textAlign:

                                                                  TextAlign.right,

                                                            ),

                                                          ),

                                                          Container(

                                                            width: 1,

                                                            color: const Color(

                                                              0xFFD1D5DB,

                                                            ),

                                                          ),

                                                          const SizedBox(width: 8),

                                                          SizedBox(

                                                            width: 80,

                                                            child: Text(

                                                              item.amount

                                                                  .toStringAsFixed(2),

                                                              style: const TextStyle(

                                                                fontSize: 10,

                                                              ),

                                                              textAlign:

                                                                  TextAlign.right,

                                                            ),

                                                          ),

                                                          Container(

                                                            width: 1,

                                                            color: const Color(

                                                              0xFFD1D5DB,

                                                            ),

                                                          ),

                                                          const SizedBox(width: 8),

                                                          SizedBox(

                                                            width: 90,

                                                            child: Text(

                                                              item.amount

                                                                  .toStringAsFixed(2),

                                                              style: const TextStyle(

                                                                fontSize: 10,

                                                              ),

                                                              textAlign:

                                                                  TextAlign.right,

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



                                          // Row 5: Footer block

                                          Row(

                                            crossAxisAlignment:

                                                CrossAxisAlignment.start,

                                            children: [

                                              Expanded(

                                                flex: 3,

                                                child: Container(

                                                  padding: const EdgeInsets.all(

                                                    12,

                                                  ),

                                                  decoration:

                                                      const BoxDecoration(

                                                        border: Border(

                                                          right: BorderSide(

                                                            color: Color(

                                                              0xFFD1D5DB,

                                                            ),

                                                          ),

                                                        ),

                                                      ),

                                                  child: const Column(

                                                    crossAxisAlignment:

                                                        CrossAxisAlignment

                                                            .start,

                                                    children: [

                                                      Text(

                                                        'Total In Words',

                                                        style: TextStyle(

                                                          fontSize: 11,

                                                          fontWeight:

                                                              FontWeight.bold,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                      SizedBox(height: 4),

                                                      Text(

                                                        'Indian Rupee Two Hundred Thirty-Eight Only',

                                                        style: TextStyle(

                                                          fontSize: 11,

                                                          fontStyle:

                                                              FontStyle.italic,

                                                          fontWeight:

                                                              FontWeight.bold,

                                                        ),

                                                      ),

                                                      SizedBox(height: 16),

                                                      Text(

                                                        'Notes',

                                                        style: TextStyle(

                                                          fontSize: 11,

                                                          fontWeight:

                                                              FontWeight.bold,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                      SizedBox(height: 4),

                                                      Text(

                                                        'Thanks for your business.',

                                                        style: TextStyle(

                                                          fontSize: 11,

                                                          color: AppTheme

                                                              .textPrimary,

                                                        ),

                                                      ),

                                                    ],

                                                  ),

                                                ),

                                              ),

                                              Expanded(

                                                flex: 2,

                                                child: Column(

                                                  crossAxisAlignment:

                                                      CrossAxisAlignment

                                                          .stretch,

                                                  children: [

                                                    Padding(

                                                      padding:

                                                          const EdgeInsets.all(

                                                            12,

                                                          ),

                                                      child: Column(

                                                        children: [

                                                          _buildTotalRow(

                                                            'Sub Total',

                                                            inv.amount

                                                                .toStringAsFixed(

                                                                  2,

                                                                ),

                                                          ),

                                                          _buildTotalRow(

                                                            'Total',

                                                            '₹${inv.amount.toStringAsFixed(2)}',

                                                            isBold: true,

                                                          ),

                                                          _buildTotalRow(

                                                            'Balance Due',

                                                            '₹${inv.amount.toStringAsFixed(2)}',

                                                            isBold: true,

                                                          ),

                                                        ],

                                                      ),

                                                    ),

                                                    const Divider(

                                                      height: 1,

                                                      color: Color(0xFFD1D5DB),

                                                    ),

                                                    Container(

                                                      height: 90,

                                                      alignment: Alignment

                                                          .bottomCenter,

                                                      padding:

                                                          const EdgeInsets.only(

                                                            bottom: 12,

                                                          ),

                                                      child: const Text(

                                                        'Authorized Signature',

                                                        style: TextStyle(

                                                          fontSize: 11,

                                                          color: AppTheme

                                                              .textSecondary,

                                                        ),

                                                      ),

                                                    ),

                                                  ],

                                                ),

                                              ),

                                            ],

                                          ),

                                        ],

                                      ),

                                    ),

                                  ],

                                ),

                              ),

                              Positioned(

                                top: 0,

                                left: 0,

                                child: ZerpaiDocumentCornerRibbon(

                                  label: 'Active',

                                  color: AppTheme.successGreen,

                                ),

                              ),

                            ],

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(height: 16),

                    SizedBox(

                      width: 850,

                      child: Row(

                        children: [

                          Container(

                            padding: const EdgeInsets.symmetric(

                              horizontal: 8,

                              vertical: 4,

                            ),

                            color: const Color(0xFFE2E8F0),

                            child: Text(

                              'Salesperson: ${inv.salesperson}',

                              style: const TextStyle(

                                fontSize: 11,

                                color: AppTheme.textSecondary,

                              ),

                            ),

                          ),

                          const Spacer(),

                          Row(

                            mainAxisSize: MainAxisSize.min,

                            children: [

                              const Text(

                                'PDF Template : ',

                                style: TextStyle(

                                  fontSize: 11,

                                  color: AppTheme.textSecondary,

                                ),

                              ),

                              Text(

                                "'$_selectedTemplate'",

                                style: const TextStyle(

                                  fontSize: 11,

                                  fontWeight: FontWeight.bold,

                                  color: AppTheme.textPrimary,

                                ),

                              ),

                              const SizedBox(width: 8),

                              GestureDetector(

                                onTap: () =>

                                    setState(() => _showTemplatePanel = true),

                                child: const Text(

                                  'Change',

                                  style: TextStyle(

                                    fontSize: 11,

                                    color: AppTheme.primaryBlue,

                                    fontWeight: FontWeight.w600,

                                  ),

                                ),

                              ),

                              const SizedBox(width: 8),

                              const Text(

                                '|',

                                style: TextStyle(color: AppTheme.borderColor),

                              ),

                              const SizedBox(width: 8),

                              const Text(

                                '( View sample PDF )',

                                style: TextStyle(

                                  fontSize: 11,

                                  color: AppTheme.primaryBlue,

                                  fontWeight: FontWeight.w600,

                                ),

                              ),

                            ],

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

            ),

          ),

        ),

      ],

    );

  }



  TableRow _buildInfoRow(String label, String value, {bool isValBold = false}) {

    return TableRow(

      children: [

        Padding(

          padding: const EdgeInsets.symmetric(vertical: 4),

          child: Row(

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [

              Text(

                label,

                style: const TextStyle(

                  fontSize: 11,

                  color: AppTheme.textSecondary,

                ),

              ),

              const Text(

                ':',

                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),

              ),

            ],

          ),

        ),

        Padding(

          padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),

          child: Text(

            value,

            style: TextStyle(

              fontSize: 11,

              fontWeight: isValBold ? FontWeight.bold : FontWeight.normal,

              color: AppTheme.textPrimary,

            ),

          ),

        ),

      ],

    );

  }



  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 4),

      child: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [

          Text(

            label,

            style: TextStyle(

              fontSize: 11,

              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,

              color: AppTheme.textSecondary,

            ),

          ),

          Text(

            value,

            style: TextStyle(

              fontSize: 11,

              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,

              color: AppTheme.textPrimary,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildRecentActivitiesTab() {

    return Container(

      color: Colors.white,

      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),

      child: ListView(

        children: [

          _buildActivityTimelineItem(

            date: '13-06-2026',

            time: '09:21 AM',

            title: 'Invoice created - INV-000088. Saved as draft',

            subtitle: 'by zabnixprivatelimited',

            linkText: 'View the invoice',

            onLinkTap: () {

              // Click action to view the invoice or similar

            },

            isFirst: true,

          ),

          _buildActivityTimelineItem(

            date: '13-06-2026',

            time: '09:21 AM',

            title: 'Recurring Invoice created for ₹238.00',

            subtitle: 'by zabnixprivatelimited',

            isLast: true,

          ),

        ],

      ),

    );

  }



  Widget _buildActivityTimelineItem({

    required String date,

    required String time,

    required String title,

    required String subtitle,

    String? linkText,

    VoidCallback? onLinkTap,

    bool isFirst = false,

    bool isLast = false,

  }) {

    return IntrinsicHeight(

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          // Date & Time Column

          SizedBox(

            width: 90,

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.end,

              children: [

                const SizedBox(height: 12),

                Text(

                  date,

                  style: const TextStyle(

                    fontSize: 11,

                    fontWeight: FontWeight.w500,

                    color: AppTheme.textSecondary,

                  ),

                ),

                const SizedBox(height: 2),

                Text(

                  time,

                  style: const TextStyle(

                    fontSize: 10,

                    color: AppTheme.textSecondary,

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(width: 16),

          // Timeline indicator (dot + line)

          Column(

            children: [

              if (!isFirst)

                Container(

                  width: 1.5,

                  height: 16,

                  color: const Color(0xFF90CAF9),

                )

              else

                const SizedBox(height: 16),

              Container(

                width: 8,

                height: 8,

                decoration: const BoxDecoration(

                  color: AppTheme.primaryBlue,

                  shape: BoxShape.circle,

                ),

              ),

              Expanded(

                child: Container(

                  width: 1.5,

                  color: isLast ? Colors.transparent : const Color(0xFF90CAF9),

                ),

              ),

            ],

          ),

          const SizedBox(width: 16),

          // Content Card

          Expanded(

            child: Container(

              margin: const EdgeInsets.only(bottom: 16),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(4),

                border: Border.all(color: const Color(0xFFE2E8F0)),

              ),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    style: const TextStyle(

                      fontSize: 12,

                      fontWeight: FontWeight.w600,

                      color: AppTheme.textPrimary,

                    ),

                  ),

                  const SizedBox(height: 6),

                  Row(

                    children: [

                      Text(

                        subtitle,

                        style: const TextStyle(

                          fontSize: 11,

                          color: AppTheme.textSecondary,

                        ),

                      ),

                      if (linkText != null) ...[

                        const SizedBox(width: 6),

                        GestureDetector(

                          onTap: onLinkTap,

                          child: Text(

                            linkText,

                            style: const TextStyle(

                              fontSize: 11,

                              color: AppTheme.primaryBlue,

                              fontWeight: FontWeight.w600,

                            ),

                          ),

                        ),

                      ],

                    ],

                  ),

                ],

              ),

            ),

          ),

        ],

      ),

    );

  }

}



// ─── _FilterOptionRow ─────────────────────────────────────────────────────────



class _DashedBorderPainter extends CustomPainter {

  final Color color;

  final double radius;



  const _DashedBorderPainter({required this.color, required this.radius});



  @override

  void paint(Canvas canvas, Size size) {

    final paint = Paint()

      ..color = color

      ..strokeWidth = 1

      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(

      Offset.zero & size,

      Radius.circular(radius),

    );

    final path = Path()..addRRect(rect);



    for (final metric in path.computeMetrics()) {

      var distance = 0.0;

      const dashWidth = 4.0;

      const dashSpace = 3.0;

      while (distance < metric.length) {

        canvas.drawPath(

          metric.extractPath(distance, distance + dashWidth),

          paint,

        );

        distance += dashWidth + dashSpace;

      }

    }

  }



  @override

  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {

    return oldDelegate.color != color || oldDelegate.radius != radius;

  }

}



class _FilterOptionRow extends StatefulWidget {

  final String label;

  final bool isStarred;

  final bool isSelected;

  final VoidCallback onTap;

  final VoidCallback onStarTap;



  const _FilterOptionRow({

    required this.label,

    required this.isStarred,

    required this.isSelected,

    required this.onTap,

    required this.onStarTap,

  });



  @override

  State<_FilterOptionRow> createState() => _FilterOptionRowState();

}



class _FilterOptionRowState extends State<_FilterOptionRow> {

  bool _isHovered = false;



  @override

  Widget build(BuildContext context) {

    final bg = _isHovered

        ? AppTheme.primaryBlue

        : (widget.isSelected

              ? AppTheme.primaryBlue.withValues(alpha: 0.08)

              : Colors.transparent);

    final textColor = _isHovered

        ? Colors.white

        : (widget.isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary);

    final starColor = _isHovered

        ? Colors.white

        : (widget.isStarred

              ? const Color(0xFFF59E0B)

              : const Color(0xFFD1D5DB));



    return MouseRegion(

      onEnter: (_) => setState(() => _isHovered = true),

      onExit: (_) => setState(() => _isHovered = false),

      child: InkWell(

        onTap: widget.onTap,

        child: Container(

          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

          color: bg,

          child: Row(

            children: [

              Expanded(

                child: Text(

                  widget.label,

                  style: TextStyle(

                    fontSize: 13,

                    fontWeight: FontWeight.w500,

                    color: textColor,

                  ),

                ),

              ),

              InkWell(

                onTap: widget.onStarTap,

                borderRadius: BorderRadius.circular(12),

                child: Padding(

                  padding: const EdgeInsets.all(4),

                  child: Icon(

                    widget.isStarred ? Icons.star : Icons.star_border,

                    size: 16,

                    color: starColor,

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



// ─── _BulkActionMenuItem ──────────────────────────────────────────────────────



class _BulkActionMenuItem extends StatefulWidget {

  final String label;

  final VoidCallback onTap;

  final IconData? icon;

  final double width;



  const _BulkActionMenuItem({

    required this.label,

    required this.onTap,

    this.icon,

    this.width = 160,

  });



  @override

  State<_BulkActionMenuItem> createState() => _BulkActionMenuItemState();

}



class _BulkActionMenuItemState extends State<_BulkActionMenuItem> {

  bool _isHovered = false;



  @override

  Widget build(BuildContext context) {

    final bg = _isHovered ? AppTheme.primaryBlue : Colors.transparent;

    final textColor = _isHovered ? Colors.white : AppTheme.textPrimary;

    final iconColor = _isHovered ? Colors.white : AppTheme.textSecondary;



    return MouseRegion(

      onEnter: (_) => setState(() => _isHovered = true),

      onExit: (_) => setState(() => _isHovered = false),

      child: InkWell(

        onTap: widget.onTap,

        child: Container(

          width: widget.width,

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

          color: bg,

          alignment: Alignment.centerLeft,

          child: Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              if (widget.icon != null) ...[

                Icon(widget.icon, size: 14, color: iconColor),

                const SizedBox(width: AppTheme.space10),

              ],

              Flexible(

                child: Text(

                  widget.label,

                  style: TextStyle(

                    fontSize: 13,

                    fontWeight: FontWeight.w400,

                    color: textColor,

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _MainMenuItemWidget extends StatefulWidget {

  final IconData icon;

  final String label;

  final bool hasSubMenu;

  final bool isActive;

  final VoidCallback onHover;

  final VoidCallback onTap;



  const _MainMenuItemWidget({

    required this.icon,

    required this.label,

    this.hasSubMenu = false,

    this.isActive = false,

    required this.onHover,

    required this.onTap,

  });



  @override

  State<_MainMenuItemWidget> createState() => _MainMenuItemWidgetState();

}



class _MainMenuItemWidgetState extends State<_MainMenuItemWidget> {

  bool _isHovered = false;



  @override

  Widget build(BuildContext context) {

    final isBlue = widget.isActive || _isHovered;

    final bg = isBlue ? AppTheme.primaryBlue : Colors.transparent;

    final textColor = isBlue ? Colors.white : AppTheme.textPrimary;

    final iconColor = isBlue ? Colors.white : AppTheme.textSecondary;



    return MouseRegion(

      onEnter: (_) {

        widget.onHover();

        setState(() => _isHovered = true);

      },

      onExit: (_) => setState(() => _isHovered = false),

      child: InkWell(

        onTap: widget.onTap,

        child: Container(

          height: 36,

          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),

          color: bg,

          child: Row(

            children: [

              Icon(widget.icon, size: 14, color: iconColor),

              const SizedBox(width: AppTheme.space10),

              Expanded(

                child: Text(

                  widget.label,

                  style: TextStyle(

                    fontSize: 12,

                    fontWeight: FontWeight.w400,

                    color: textColor,

                  ),

                ),

              ),

              if (widget.hasSubMenu)

                Icon(LucideIcons.chevronRight, size: 14, color: iconColor),

            ],

          ),

        ),

      ),

    );

  }

}



class _ConfigurePaymentNumberPreferencesDialog extends StatefulWidget {

  final String currentLocation;

  final String currentSeries;



  const _ConfigurePaymentNumberPreferencesDialog({

    required this.currentLocation,

    required this.currentSeries,

  });



  @override

  State<_ConfigurePaymentNumberPreferencesDialog> createState() =>

      __ConfigurePaymentNumberPreferencesDialogState();

}



class __ConfigurePaymentNumberPreferencesDialogState

    extends State<_ConfigurePaymentNumberPreferencesDialog> {

  bool _autoGenerate = true;

  final TextEditingController _prefixController = TextEditingController();

  final TextEditingController _nextNumberController = TextEditingController(

    text: '308',

  );

  final TextEditingController _manualPrefixController = TextEditingController();

  final TextEditingController _manualPaymentNumberController =

      TextEditingController();

  bool _restartFiscalYear = false;



  @override

  void initState() {

    super.initState();

  }



  @override

  void dispose() {

    _prefixController.dispose();

    _nextNumberController.dispose();

    _manualPrefixController.dispose();

    _manualPaymentNumberController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return Dialog(

      alignment: Alignment.topCenter,

      insetPadding: const EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 24.0),

      backgroundColor: Colors.white,

      surfaceTintColor: Colors.transparent,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),

      child: Container(

        width: 580,

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(4.0),

        ),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            // Header

            Padding(

              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),

              child: Row(

                children: [

                  const Expanded(

                    child: Text(

                      'Configure Payment Number Preferences',

                      style: TextStyle(

                        fontSize: 15,

                        fontWeight: FontWeight.bold,

                        color: AppTheme.textPrimary,

                      ),

                    ),

                  ),

                  InkWell(

                    onTap: () => Navigator.of(context).pop(),

                    borderRadius: BorderRadius.circular(4),

                    child: Padding(

                      padding: const EdgeInsets.all(4),

                      child: Icon(

                        LucideIcons.x,

                        size: 16,

                        color: Colors.red.shade600,

                      ),

                    ),

                  ),

                ],

              ),

            ),

            const Divider(height: 1, color: AppTheme.borderColor),



            // Metadata: Location & Associated Series

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

              child: Row(

                children: [

                  Expanded(

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const Text(

                          'Location',

                          style: TextStyle(

                            fontSize: 11,

                            color: AppTheme.textSecondary,

                          ),

                        ),

                        const SizedBox(height: 4),

                        Text(

                          widget.currentLocation,

                          style: const TextStyle(

                            fontSize: 12,

                            fontWeight: FontWeight.w600,

                            color: AppTheme.textPrimary,

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

                          'Associated Series',

                          style: TextStyle(

                            fontSize: 11,

                            color: AppTheme.textSecondary,

                          ),

                        ),

                        const SizedBox(height: 4),

                        Text(

                          widget.currentSeries,

                          style: const TextStyle(

                            fontSize: 12,

                            fontWeight: FontWeight.w600,

                            color: AppTheme.textPrimary,

                          ),

                        ),

                      ],

                    ),

                  ),

                ],

              ),

            ),

            const Divider(height: 1, color: AppTheme.borderColor),



            // Form Body

            Padding(

              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(

                    'Auto-generating payment numbers can save your time. Would you like to change your current setting?',

                    style: TextStyle(

                      fontSize: 12,

                      color: AppTheme.textSecondary,

                    ),

                  ),

                  const SizedBox(height: 16),



                  // Option 1: Auto-generate

                  Row(

                    children: [

                      Radio<bool>(

                        value: true,

                        groupValue: _autoGenerate,

                        activeColor: AppTheme.primaryBlue,

                        onChanged: (val) {

                          if (val == null) return;

                          setState(() => _autoGenerate = val);

                        },

                      ),

                      const Text(

                        'Auto-generate payment numbers',

                        style: TextStyle(

                          fontSize: 12,

                          fontWeight: FontWeight.w600,

                          color: AppTheme.textPrimary,

                        ),

                      ),

                      const SizedBox(width: 4),

                      const Icon(

                        LucideIcons.helpCircle,

                        size: 13,

                        color: AppTheme.textSecondary,

                      ),

                    ],

                  ),



                  // Fields for Auto-generate

                  if (_autoGenerate) ...[

                    Padding(

                      padding: const EdgeInsets.only(

                        left: 32,

                        top: 8,

                        bottom: 8,

                      ),

                      child: Row(

                        children: [

                          SizedBox(

                            width: 140,

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                const Text(

                                  'Prefix',

                                  style: TextStyle(

                                    fontSize: 11,

                                    color: AppTheme.textSecondary,

                                  ),

                                ),

                                const SizedBox(height: 4),

                                CustomTextField(

                                  controller: _prefixController,

                                  height: 32,

                                  suffixWidget: Builder(

                                    builder: (iconContext) {

                                      return InkWell(

                                        onTap: () async {

                                          final RenderBox button =

                                              iconContext.findRenderObject()

                                                  as RenderBox;

                                          final RenderBox overlay =

                                              Navigator.of(context)

                                                      .overlay!

                                                      .context

                                                      .findRenderObject()

                                                  as RenderBox;

                                          final RelativeRect position =

                                              RelativeRect.fromRect(

                                                Rect.fromPoints(

                                                  button.localToGlobal(

                                                    button.size.bottomLeft(

                                                      Offset.zero,

                                                    ),

                                                    ancestor: overlay,

                                                  ),

                                                  button.localToGlobal(

                                                    button.size.bottomRight(

                                                      Offset.zero,

                                                    ),

                                                    ancestor: overlay,

                                                  ),

                                                ),

                                                Offset.zero & overlay.size,

                                              );



                                          final val = await showMenu<String>(

                                            context: context,

                                            position: position,

                                            color: Colors.white,

                                            surfaceTintColor:

                                                Colors.transparent,

                                            shape: RoundedRectangleBorder(

                                              borderRadius:

                                                  BorderRadius.circular(4),

                                              side: const BorderSide(

                                                color: AppTheme.borderColor,

                                              ),

                                            ),

                                            items: [

                                              PopupMenuItem<String>(

                                                enabled: false,

                                                padding: EdgeInsets.zero,

                                                height: 30,

                                                child: Container(

                                                  height: 30,

                                                  padding:

                                                      const EdgeInsets.symmetric(

                                                        horizontal: 16,

                                                      ),

                                                  alignment:

                                                      Alignment.centerLeft,

                                                  child: Text(

                                                    'PLACEHOLDER',

                                                    style: TextStyle(

                                                      fontSize: 10,

                                                      fontWeight:

                                                          FontWeight.bold,

                                                      color:

                                                          Colors.grey.shade500,

                                                    ),

                                                  ),

                                                ),

                                              ),

                                              PopupMenuItem<String>(

                                                value: 'Fiscal Year Start',

                                                padding: EdgeInsets.zero,

                                                height: 36,

                                                child: _HoverableMenuItem(

                                                  text: 'Fiscal Year Start',

                                                  hasSubmenu: true,

                                                  submenuItems: const [

                                                    'YY',

                                                    'YYYY',

                                                  ],

                                                  onSubmenuSelected: (format) {

                                                    Navigator.of(context).pop(

                                                      '{Fiscal Year Start-$format}',

                                                    );

                                                  },

                                                ),

                                              ),

                                              PopupMenuItem<String>(

                                                value: 'Fiscal Year End',

                                                padding: EdgeInsets.zero,

                                                height: 36,

                                                child: const _HoverableMenuItem(

                                                  text: 'Fiscal Year End',

                                                ),

                                              ),

                                              PopupMenuItem<String>(

                                                value: 'Transaction Year',

                                                padding: EdgeInsets.zero,

                                                height: 36,

                                                child: const _HoverableMenuItem(

                                                  text: 'Transaction Year',

                                                ),

                                              ),

                                              PopupMenuItem<String>(

                                                value: 'Transaction Date',

                                                padding: EdgeInsets.zero,

                                                height: 36,

                                                child: const _HoverableMenuItem(

                                                  text: 'Transaction Date',

                                                ),

                                              ),

                                              PopupMenuItem<String>(

                                                value: 'Transaction Month',

                                                padding: EdgeInsets.zero,

                                                height: 36,

                                                child: const _HoverableMenuItem(

                                                  text: 'Transaction Month',

                                                ),

                                              ),

                                            ],

                                          );

                                          if (val != null) {

                                            setState(() {

                                              _prefixController.text += val;

                                            });

                                          }

                                        },

                                        borderRadius: BorderRadius.circular(7),

                                        child: Container(

                                          width: 14,

                                          height: 14,

                                          decoration: const BoxDecoration(

                                            color: AppTheme.primaryBlue,

                                            shape: BoxShape.circle,

                                          ),

                                          child: const Center(

                                            child: Icon(

                                              Icons.add,

                                              size: 9,

                                              color: Colors.white,

                                            ),

                                          ),

                                        ),

                                      );

                                    },

                                  ),

                                ),

                              ],

                            ),

                          ),

                          const SizedBox(width: 16),

                          SizedBox(

                            width: 140,

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                const Text(

                                  'Next Number',

                                  style: TextStyle(

                                    fontSize: 11,

                                    color: AppTheme.textSecondary,

                                  ),

                                ),

                                const SizedBox(height: 4),

                                CustomTextField(

                                  controller: _nextNumberController,

                                  height: 32,

                                  keyboardType: TextInputType.number,

                                ),

                              ],

                            ),

                          ),

                        ],

                      ),

                    ),

                    Padding(

                      padding: const EdgeInsets.only(left: 20),

                      child: Row(

                        children: [

                          Checkbox(

                            value: _restartFiscalYear,

                            activeColor: AppTheme.primaryBlue,

                            onChanged: (val) {

                              if (val == null) return;

                              setState(() => _restartFiscalYear = val);

                            },

                          ),

                          const Expanded(

                            child: Text(

                              'Restart numbering for payments at the start of each fiscal year.',

                              style: TextStyle(

                                fontSize: 11,

                                color: AppTheme.textPrimary,

                              ),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                  const SizedBox(height: 12),



                  // Option 2: Manual

                  Row(

                    children: [

                      Radio<bool>(

                        value: false,

                        groupValue: _autoGenerate,

                        activeColor: AppTheme.primaryBlue,

                        onChanged: (val) {

                          if (val == null) return;

                          setState(() => _autoGenerate = val);

                        },

                      ),

                      const Text(

                        'Add payment number manually for this payment',

                        style: TextStyle(

                          fontSize: 12,

                          fontWeight: FontWeight.w600,

                          color: AppTheme.textPrimary,

                        ),

                      ),

                    ],

                  ),

                  if (!_autoGenerate) ...[

                    Padding(

                      padding: const EdgeInsets.only(

                        left: 32,

                        top: 8,

                        bottom: 8,

                      ),

                      child: Row(

                        children: [

                          SizedBox(

                            width: 140,

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                const Text(

                                  'Prefix',

                                  style: TextStyle(

                                    fontSize: 11,

                                    color: AppTheme.textSecondary,

                                  ),

                                ),

                                const SizedBox(height: 4),

                                CustomTextField(

                                  controller: _manualPrefixController,

                                  height: 32,

                                ),

                              ],

                            ),

                          ),

                          const SizedBox(width: 16),

                          SizedBox(

                            width: 140,

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                const Text(

                                  'Payment Number',

                                  style: TextStyle(

                                    fontSize: 11,

                                    color: AppTheme.textSecondary,

                                  ),

                                ),

                                const SizedBox(height: 4),

                                CustomTextField(

                                  controller: _manualPaymentNumberController,

                                  height: 32,

                                ),

                              ],

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                  const SizedBox(height: 24),



                  // Actions

                  Row(

                    children: [

                      ElevatedButton(

                        onPressed: () {

                          Navigator.of(context).pop({

                            'autoGenerate': _autoGenerate,

                            'prefix': _autoGenerate

                                ? _prefixController.text

                                : _manualPrefixController.text,

                            'nextNumber': _autoGenerate

                                ? _nextNumberController.text

                                : _manualPaymentNumberController.text,

                            'restartFiscalYear': _restartFiscalYear,

                          });

                        },

                        style: ElevatedButton.styleFrom(

                          backgroundColor: AppTheme.successGreen,

                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(

                            horizontal: 16,

                            vertical: 12,

                          ),

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(4),

                          ),

                        ),

                        child: const Text(

                          'Save',

                          style: TextStyle(

                            fontSize: 13,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                      ),

                      const SizedBox(width: 12),

                      OutlinedButton(

                        onPressed: () => Navigator.of(context).pop(),

                        style: OutlinedButton.styleFrom(

                          foregroundColor: AppTheme.textPrimary,

                          side: const BorderSide(color: AppTheme.borderColor),

                          padding: const EdgeInsets.symmetric(

                            horizontal: 16,

                            vertical: 12,

                          ),

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(4),

                          ),

                        ),

                        child: const Text(

                          'Cancel',

                          style: TextStyle(fontSize: 13),

                        ),

                      ),

                    ],

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}



class _HoverableMenuItem extends StatefulWidget {

  final String text;

  final bool hasSubmenu;

  final List<String> submenuItems;

  final ValueChanged<String>? onSubmenuSelected;



  const _HoverableMenuItem({

    required this.text,

    this.hasSubmenu = false,

    this.submenuItems = const [],

    this.onSubmenuSelected,

  });



  @override

  State<_HoverableMenuItem> createState() => _HoverableMenuItemState();

}



class _HoverableMenuItemState extends State<_HoverableMenuItem> {

  bool _isHovered = false;

  OverlayEntry? _submenuOverlay;

  final LayerLink _layerLink = LayerLink();

  bool _isHoveringSubmenu = false;



  void _showSubmenu() {

    if (_submenuOverlay != null) return;



    final overlay = Overlay.of(context);

    _submenuOverlay = OverlayEntry(

      builder: (context) {

        return Stack(

          children: [

            Positioned.fill(

              child: GestureDetector(

                behavior: HitTestBehavior.translucent,

                onTap: _hideSubmenu,

                child: const SizedBox.expand(),

              ),

            ),

            CompositedTransformFollower(

              link: _layerLink,

              showWhenUnlinked: false,

              targetAnchor: Alignment.topRight,

              followerAnchor: Alignment.topLeft,

              offset: const Offset(4, 0),

              child: Material(

                elevation: 6,

                color: Colors.transparent,

                child: MouseRegion(

                  onEnter: (_) {

                    _isHoveringSubmenu = true;

                  },

                  onExit: (_) {

                    _isHoveringSubmenu = false;

                    Future.delayed(const Duration(milliseconds: 50), () {

                      if (!_isHovered && !_isHoveringSubmenu) {

                        _hideSubmenu();

                      }

                    });

                  },

                  child: Container(

                    width: 100,

                    padding: const EdgeInsets.symmetric(vertical: 4),

                    decoration: BoxDecoration(

                      color: Colors.white,

                      borderRadius: BorderRadius.circular(4),

                      border: Border.all(color: AppTheme.borderColor),

                      boxShadow: [

                        BoxShadow(

                          color: Colors.black.withValues(alpha: 0.1),

                          blurRadius: 8,

                          offset: const Offset(0, 2),

                        ),

                      ],

                    ),

                    child: Column(

                      mainAxisSize: MainAxisSize.min,

                      crossAxisAlignment: CrossAxisAlignment.stretch,

                      children: widget.submenuItems.map((item) {

                        return _SubmenuItem(

                          text: item,

                          onTap: () {

                            _hideSubmenu();

                            widget.onSubmenuSelected?.call(item);

                          },

                        );

                      }).toList(),

                    ),

                  ),

                ),

              ),

            ),

          ],

        );

      },

    );



    overlay.insert(_submenuOverlay!);

  }



  void _hideSubmenu() {

    _submenuOverlay?.remove();

    _submenuOverlay = null;

  }



  @override

  void dispose() {

    _hideSubmenu();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    Widget content = MouseRegion(

      onEnter: (_) {

        setState(() => _isHovered = true);

        if (widget.hasSubmenu) {

          _showSubmenu();

        }

      },

      onExit: (_) {

        setState(() => _isHovered = false);

        if (widget.hasSubmenu) {

          Future.delayed(const Duration(milliseconds: 50), () {

            if (!_isHovered && !_isHoveringSubmenu) {

              _hideSubmenu();

            }

          });

        }

      },

      child: Container(

        height: 36,

        padding: const EdgeInsets.symmetric(horizontal: 16),

        alignment: Alignment.centerLeft,

        color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,

        child: Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [

            Expanded(

              child: Text(

                widget.text,

                style: TextStyle(

                  fontSize: 12,

                  color: _isHovered ? Colors.white : AppTheme.textPrimary,

                ),

              ),

            ),

            if (widget.hasSubmenu)

              Icon(

                Icons.chevron_right,

                size: 14,

                color: _isHovered ? Colors.white : AppTheme.textSecondary,

              ),

          ],

        ),

      ),

    );



    if (widget.hasSubmenu) {

      content = CompositedTransformTarget(link: _layerLink, child: content);

    }



    return content;

  }

}



class _SubmenuItem extends StatefulWidget {

  final String text;

  final VoidCallback onTap;



  const _SubmenuItem({required this.text, required this.onTap});



  @override

  State<_SubmenuItem> createState() => _SubmenuItemState();

}



class _SubmenuItemState extends State<_SubmenuItem> {

  bool _isHovered = false;



  @override

  Widget build(BuildContext context) {

    return MouseRegion(

      onEnter: (_) => setState(() => _isHovered = true),

      onExit: (_) => setState(() => _isHovered = false),

      child: InkWell(

        onTap: widget.onTap,

        hoverColor: Colors.transparent,

        child: Container(

          height: 32,

          padding: const EdgeInsets.symmetric(horizontal: 12),

          alignment: Alignment.centerLeft,

          color: _isHovered ? const Color(0xFF3B82F6) : Colors.transparent,

          child: Text(

            widget.text,

            style: TextStyle(

              fontSize: 12,

              color: _isHovered ? Colors.white : AppTheme.textPrimary,

            ),

          ),

        ),

      ),

    );

  }

}



class _PopoverArrowPainter extends CustomPainter {

  final Color color;

  final Color borderColor;



  _PopoverArrowPainter({required this.color, required this.borderColor});



  @override

  void paint(Canvas canvas, Size size) {

    final paint = Paint()

      ..color = color

      ..style = PaintingStyle.fill;



    final borderPaint = Paint()

      ..color = borderColor

      ..style = PaintingStyle.stroke

      ..strokeWidth = 1;



    final path = Path()

      ..moveTo(0, size.height)

      ..lineTo(size.width / 2, 0)

      ..lineTo(size.width, size.height)

      ..close();



    canvas.drawPath(path, paint);



    final borderPath = Path()

      ..moveTo(0, size.height)

      ..lineTo(size.width / 2, 0)

      ..lineTo(size.width, size.height);

    canvas.drawPath(borderPath, borderPaint);

  }



  @override

  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

}
