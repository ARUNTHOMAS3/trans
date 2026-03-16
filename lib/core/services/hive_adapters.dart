import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';

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
