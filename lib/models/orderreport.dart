// To parse this JSON data, do
//
//     final orderReportModel = orderReportModelFromJson(jsonString);

import 'dart:convert';

List<OrderReportModel> orderReportModelFromJson(String str) =>
    List<OrderReportModel>.from(
      json.decode(str).map((x) => OrderReportModel.fromJson(x)),
    );

String orderReportModelToJson(List<OrderReportModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OrderReportModel {
  int orderId;
  int orderNo;
  DateTime orderDate;
  String customerName;
  String customerMobile;
  String customerAddress;
  String paymentStatus;
  String deliveryStatus;
  String orderStatus;
  double totalDiscount;
  double grandTotal;
  List<OrderItem> orderItems;

  OrderReportModel({
    required this.orderId,
    required this.orderNo,
    required this.orderDate,
    required this.customerName,
    required this.customerMobile,
    required this.customerAddress,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.orderStatus,
    required this.totalDiscount,
    required this.grandTotal,
    required this.orderItems,
  });

  factory OrderReportModel.fromJson(Map<String, dynamic> json) =>
      OrderReportModel(
        orderId: _toInt(json["order_id"]),
        orderNo: _toInt(json["order_no"]),
        orderDate: DateTime.parse(json["order_date"]),
        customerName: json["customer_name"] ?? '',
        customerMobile: json["customer_mobile"] ?? '',
        customerAddress: json["customer_address"] ?? '',
        paymentStatus: json["payment_status"] ?? '',
        deliveryStatus: json["delivery_status"] ?? '',
        orderStatus: json["order_status"] ?? '',
        totalDiscount: _toDouble(json["total_discount"]),
        grandTotal: _toDouble(json["grand_total"]),
        orderItems: List<OrderItem>.from(
          (json["order_items"] ?? []).map((x) => OrderItem.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "order_id": orderId,
    "order_no": orderNo,
    "order_date": orderDate.toIso8601String(),
    "customer_name": customerName,
    "customer_mobile": customerMobile,
    "customer_address": customerAddress,
    "payment_status": paymentStatus,
    "delivery_status": deliveryStatus,
    "order_status": orderStatus,
    "total_discount": totalDiscount,
    "grand_total": grandTotal,
    "order_items": List<dynamic>.from(orderItems.map((x) => x.toJson())),
  };
}

class OrderItem {
  String serviceNameX;
  String serviceType;
  String serviceItemNameX;
  double unitRate;
  double qty;
  double discount;
  double lineTotal;
  String itemStatus;
  String extraNote;
  DateTime? itemDeliveryDate; // Made nullable
  String itemDeliveredBy;

  OrderItem({
    required this.serviceNameX,
    required this.serviceType,
    required this.serviceItemNameX,
    required this.unitRate,
    required this.qty,
    required this.discount,
    required this.lineTotal,
    required this.itemStatus,
    required this.extraNote,
    this.itemDeliveryDate, // No longer required
    required this.itemDeliveredBy,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    serviceNameX: json["service_name_x"] ?? '',
    serviceType: json["service_type"] ?? '',
    serviceItemNameX: json["service_item_name_x"] ?? '',
    unitRate: _toDouble(json["unit_rate"]),
    qty: _toDouble(json["qty"]),
    discount: _toDouble(json["discount"]),
    lineTotal: _toDouble(json["line_total"]),
    itemStatus: json["item_status"] ?? '',
    extraNote: json["extra_note"] ?? '',
    itemDeliveryDate: json["item_delivery_date"] != null
        ? DateTime.parse(json["item_delivery_date"])
        : null,
    itemDeliveredBy: json["item_delivered_by"] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "service_name_x": serviceNameX,
    "service_type": serviceType,
    "service_item_name_x": serviceItemNameX,
    "unit_rate": unitRate,
    "qty": qty,
    "discount": discount,
    "line_total": lineTotal,
    "item_status": itemStatus,
    "extra_note": extraNote,
    "item_delivery_date": itemDeliveryDate?.toIso8601String(),
    "item_delivered_by": itemDeliveredBy,
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}
