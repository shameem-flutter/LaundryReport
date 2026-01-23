// To parse this JSON data, do
//
//     final customerOutstandingModel = customerOutstandingModelFromJson(jsonString);

import 'dart:convert';

List<CustomerOutstandingModel> customerOutstandingModelFromJson(String str) =>
    List<CustomerOutstandingModel>.from(
      json.decode(str).map((x) => CustomerOutstandingModel.fromJson(x)),
    );

String customerOutstandingModelToJson(List<CustomerOutstandingModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CustomerOutstandingModel {
  double customerId;
  String customerName;
  String customerMobile;
  String customerAddress;
  double totalOutstandingAmount;

  CustomerOutstandingModel({
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.totalOutstandingAmount,
  });

  factory CustomerOutstandingModel.fromJson(Map<String, dynamic> json) =>
      CustomerOutstandingModel(
        customerId: json["customer_id"],
        customerName: json["customer_name"],
        customerMobile: json["customer_mobile"],
        customerAddress: json["customer_address"],
        totalOutstandingAmount: json["total_outstanding_amount"],
      );

  Map<String, dynamic> toJson() => {
    "customer_id": customerId,
    "customer_name": customerName,
    "customer_mobile": customerMobile,
    "customer_address": customerAddress,
    "total_outstanding_amount": totalOutstandingAmount,
  };
}
