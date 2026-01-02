// To parse this JSON data, do
//
//     final itemModel = itemModelFromJson(jsonString);

import 'dart:convert';

List<ItemModel> itemModelFromJson(String str) =>
    List<ItemModel>.from(json.decode(str).map((x) => ItemModel.fromJson(x)));

String itemModelToJson(List<ItemModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ItemModel {
  int serviceItemId;
  String serviceItemName;

  ItemModel({required this.serviceItemId, required this.serviceItemName});

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
    serviceItemId: _toInt(json["service_item_id"]),
    serviceItemName: (json["service_item_name"] ?? '').toString().trim(),
  );

  Map<String, dynamic> toJson() => {
    "service_item_id": serviceItemId,
    "service_item_name": serviceItemName,
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
