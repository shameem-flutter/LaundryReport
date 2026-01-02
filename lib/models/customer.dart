// To parse this JSON data, do
//
//     final customerModel = customerModelFromJson(jsonString);

import 'dart:convert';

List<CustomerModel> customerModelFromJson(String str) =>
    List<CustomerModel>.from(
      json.decode(str).map((x) => CustomerModel.fromJson(x)),
    );

String customerModelToJson(List<CustomerModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CustomerModel {
  int customerId;
  String customerName;

  CustomerModel({required this.customerId, required this.customerName});

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    customerId: _toInt(json["customer_id"]),
    customerName: (json["customer_name"] ?? '').toString().trim(),
  );

  Map<String, dynamic> toJson() => {
    "customer_id": customerId,
    "customer_name": customerName,
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
