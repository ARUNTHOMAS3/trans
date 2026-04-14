import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/sales/customers/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/payments/models/sales_payment_model.dart';
import 'package:zerpai_erp/modules/sales/eway_bills/models/sales_eway_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_model.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_transfer_model.dart';
import 'package:zerpai_erp/modules/accountant/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 1;

  @override
  Item read(BinaryReader reader) {
    final jsonString = reader.readString();
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return Item.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class SalesCustomerAdapter extends TypeAdapter<SalesCustomer> {
  @override
  final int typeId = 2;

  @override
  SalesCustomer read(BinaryReader reader) {
    final jsonString = reader.readString();
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return SalesCustomer.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, SalesCustomer obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class SalesOrderAdapter extends TypeAdapter<SalesOrder> {
  @override
  final int typeId = 3;

  @override
  SalesOrder read(BinaryReader reader) {
    final jsonString = reader.readString();
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return SalesOrder.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, SalesOrder obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class AccountNodeAdapter extends TypeAdapter<AccountNode> {
  @override
  final int typeId = 4;

  @override
  AccountNode read(BinaryReader reader) {
    final jsonString = reader.readString();
    final Map<String, dynamic> json =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return AccountNode.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AccountNode obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class SalesPaymentAdapter extends TypeAdapter<SalesPayment> {
  @override
  final int typeId = 5;

  @override
  SalesPayment read(BinaryReader reader) {
    final jsonString = reader.readString();
    return SalesPayment.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, SalesPayment obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class SalesEWayBillAdapter extends TypeAdapter<SalesEWayBill> {
  @override
  final int typeId = 6;

  @override
  SalesEWayBill read(BinaryReader reader) {
    final jsonString = reader.readString();
    return SalesEWayBill.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, SalesEWayBill obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class VendorAdapter extends TypeAdapter<Vendor> {
  @override
  final int typeId = 7;

  @override
  Vendor read(BinaryReader reader) {
    final jsonString = reader.readString();
    return Vendor.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, Vendor obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class PurchaseAdapter extends TypeAdapter<PurchaseOrder> {
  @override
  final int typeId = 8;

  @override
  PurchaseOrder read(BinaryReader reader) {
    final jsonString = reader.readString();
    return PurchaseOrder.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, PurchaseOrder obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class PurchaseBillAdapter extends TypeAdapter<PurchasesBill> {
  @override
  final int typeId = 9;

  @override
  PurchasesBill read(BinaryReader reader) {
    final jsonString = reader.readString();
    return PurchasesBill.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, PurchasesBill obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class StockAdapter extends TypeAdapter<Stock> {
  @override
  final int typeId = 10;

  @override
  Stock read(BinaryReader reader) {
    final jsonString = reader.readString();
    return Stock.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, Stock obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class InventoryAdjustmentAdapter extends TypeAdapter<InventoryAdjustment> {
  @override
  final int typeId = 11;

  @override
  InventoryAdjustment read(BinaryReader reader) {
    final jsonString = reader.readString();
    return InventoryAdjustment.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, InventoryAdjustment obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class StockTransferAdapter extends TypeAdapter<StockTransfer> {
  @override
  final int typeId = 12;

  @override
  StockTransfer read(BinaryReader reader) {
    final jsonString = reader.readString();
    return StockTransfer.fromJson(jsonDecode(jsonString));
  }

  @override
  void write(BinaryWriter writer, StockTransfer obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class BatchDataAdapter extends TypeAdapter<BatchData> {
  @override
  final int typeId = 13;

  @override
  BatchData read(BinaryReader reader) {
    return BatchData.fromJson(jsonDecode(reader.readString()));
  }

  @override
  void write(BinaryWriter writer, BatchData obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class SerialDataAdapter extends TypeAdapter<SerialData> {
  @override
  final int typeId = 14;

  @override
  SerialData read(BinaryReader reader) {
    return SerialData.fromJson(jsonDecode(reader.readString()));
  }

  @override
  void write(BinaryWriter writer, SerialData obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}

class TransactionDataAdapter extends TypeAdapter<TransactionData> {
  @override
  final int typeId = 15;

  @override
  TransactionData read(BinaryReader reader) {
    return TransactionData.fromJson(jsonDecode(reader.readString()));
  }

  @override
  void write(BinaryWriter writer, TransactionData obj) {
    writer.writeString(jsonEncode(obj.toJson()));
  }
}
