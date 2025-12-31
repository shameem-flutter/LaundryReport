// To parse this JSON data, do
//
//     final itemWiseorderreportModel = itemWiseorderreportModelFromJson(jsonString);

import 'dart:convert';

List<ItemWiseorderreportModel> itemWiseorderreportModelFromJson(String str) =>
    List<ItemWiseorderreportModel>.from(
      json.decode(str).map((x) => ItemWiseorderreportModel.fromJson(x)),
    );

String itemWiseorderreportModelToJson(List<ItemWiseorderreportModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ItemWiseorderreportModel {
  int orderNo;
  DateTime orderDate;
  String serviceName;
  String serviceType;
  String item;
  String itemStatus;
  String customerName;
  String customerMobile;
  String customerAddress;
  String paymentStatus;
  String orderStatus;
  String deliveryStatus;

  ItemWiseorderreportModel({
    required this.orderNo,
    required this.orderDate,
    required this.serviceName,
    required this.serviceType,
    required this.item,
    required this.itemStatus,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.paymentStatus,
    required this.orderStatus,
    required this.deliveryStatus,
  });

  factory ItemWiseorderreportModel.fromJson(Map<String, dynamic> json) =>
      ItemWiseorderreportModel(
        orderNo: _toInt(json["order_no"]),
        orderDate: json["order_date"] != null ? DateTime.parse(json["order_date"]) : DateTime.now(),
        serviceName: json["service_name"] ?? '',
        serviceType: json["service_type"] ?? '',
        item: json["item"] ?? '',
        itemStatus: json["item_status"] ?? '',
        customerName: json["customer_name"] ?? '',
        customerMobile: json["customer_mobile"] ?? '',
        customerAddress: json["customer_address"] ?? '',
        paymentStatus: json["payment_status"] ?? '',
        orderStatus: json["order_status"] ?? '',
        deliveryStatus: json["delivery_status"] ?? '',
      );

  Map<String, dynamic> toJson() => {
    "order_no": orderNo,
    "order_date": orderDate.toIso8601String(),
    "service_name": serviceName,
    "service_type": serviceType,
    "item": item,
    "item_status": itemStatus,
    "customer_name": customerName,
    "customer_mobile": customerMobile,
    "customer_address": customerAddress,
    "payment_status": paymentStatus,
    "order_status": orderStatus,
    "delivery_status": deliveryStatus,
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
