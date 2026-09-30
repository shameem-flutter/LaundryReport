// To parse this JSON data, do
//
//     final orderReportResponse = orderReportResponseFromJson(jsonString);

import 'dart:convert';

OrderReportResponse orderReportResponseFromJson(String str) =>
    OrderReportResponse.fromJson(json.decode(str));

List<OrderReportModel> orderReportModelFromJson(String str) {
  final decoded = json.decode(str);
  if (decoded is List) {
    return List<OrderReportModel>.from(
      decoded.map((x) => OrderReportModel.fromJson(x)),
    );
  } else if (decoded is Map<String, dynamic> && decoded['results'] != null) {
    return List<OrderReportModel>.from(
      (decoded['results'] as List).map((x) => OrderReportModel.fromJson(x)),
    );
  }
  return [];
}

String orderReportModelToJson(List<OrderReportModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OrderReportResponse {
  final int count;
  final int totalPages;
  final int page;
  final int pageSize;
  final List<OrderReportModel> results;

  OrderReportResponse({
    required this.count,
    required this.totalPages,
    required this.page,
    required this.pageSize,
    required this.results,
  });

  factory OrderReportResponse.fromJson(dynamic json) {
    if (json is List) {
      final list = json.map((x) => OrderReportModel.fromJson(x)).toList();
      return OrderReportResponse(
        count: list.length,
        totalPages: 1,
        page: 1,
        pageSize: list.length,
        results: list,
      );
    }
    if (json is Map<String, dynamic>) {
      final resultsList = (json['results'] as List? ?? [])
          .map((x) => OrderReportModel.fromJson(x))
          .toList();
      return OrderReportResponse(
        count: _toInt(json['count']),
        totalPages: _toInt(json['total_pages'] ?? 1),
        page: _toInt(json['page'] ?? 1),
        pageSize: _toInt(json['page_size'] ?? 20),
        results: resultsList,
      );
    }
    return OrderReportResponse(
      count: 0,
      totalPages: 1,
      page: 1,
      pageSize: 20,
      results: [],
    );
  }

  Map<String, dynamic> toJson() => {
    "count": count,
    "total_pages": totalPages,
    "page": page,
    "page_size": pageSize,
    "results": List<dynamic>.from(results.map((x) => x.toJson())),
  };
}

class PaymentModeItem {
  final String paymentModeName;
  final double amount;

  PaymentModeItem({
    required this.paymentModeName,
    required this.amount,
  });

  factory PaymentModeItem.fromJson(Map<String, dynamic> json) => PaymentModeItem(
        paymentModeName: json["payment_mode_name"] ?? '',
        amount: _toDouble(json["amount"]),
      );

  Map<String, dynamic> toJson() => {
        "payment_mode_name": paymentModeName,
        "amount": amount,
      };
}

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
  String enteredBy;
  String paymentReceivedBy;
  List<PaymentModeItem> paymentMode;
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
    required this.enteredBy,
    required this.paymentReceivedBy,
    this.paymentMode = const [],
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
        enteredBy: json["entered_by"] ?? '',
        paymentReceivedBy: json["payment_received_by"] ?? '',
        paymentMode: json["payment_mode"] != null && json["payment_mode"] is List
            ? List<PaymentModeItem>.from(
                (json["payment_mode"] as List)
                    .map((x) => PaymentModeItem.fromJson(x)),
              )
            : [],
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
    "entered_by": enteredBy,
    "payment_received_by": paymentReceivedBy,
    "payment_mode": List<dynamic>.from(paymentMode.map((x) => x.toJson())),
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
  DateTime? itemDeliveryDate;
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
    this.itemDeliveryDate,
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
  if (value is num) return value.toInt();
  if (value is String) {
    final d = double.tryParse(value);
    if (d != null) return d.toInt();
  }
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}
