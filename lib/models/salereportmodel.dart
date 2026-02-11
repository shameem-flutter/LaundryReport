// To parse this JSON data, do
//
//     final salereportModel = salereportModelFromJson(jsonString);

import 'dart:convert';

SalereportModel salereportModelFromJson(String str) =>
    SalereportModel.fromJson(json.decode(str));

String salereportModelToJson(SalereportModel data) =>
    json.encode(data.toJson());

class SalereportModel {
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<PaymentSummary> paymentSummary;
  final double grandTotal;

  SalereportModel({
    this.fromDate,
    this.toDate,
    required this.paymentSummary,
    required this.grandTotal,
  });

  factory SalereportModel.fromJson(Map<String, dynamic> json) {
    return SalereportModel(
      fromDate: json["from_date"] != null
          ? DateTime.tryParse(json["from_date"])
          : null,
      toDate: json["to_date"] != null
          ? DateTime.tryParse(json["to_date"])
          : null,
      paymentSummary: json["payment_summary"] != null
          ? List<PaymentSummary>.from(
              (json["payment_summary"] as List).map(
                (x) => PaymentSummary.fromJson(x),
              ),
            )
          : [],
      grandTotal: (json["grand_total"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    "from_date": fromDate?.toIso8601String(),
    "to_date": toDate?.toIso8601String(),
    "payment_summary": paymentSummary.map((x) => x.toJson()).toList(),
    "grand_total": grandTotal,
  };
}

class PaymentSummary {
  final String paymentModeName;
  final double totalAmount;

  PaymentSummary({required this.paymentModeName, required this.totalAmount});

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      paymentModeName: json["payment_mode_name"] ?? "",
      totalAmount: (json["total_amount"] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    "payment_mode_name": paymentModeName,
    "total_amount": totalAmount,
  };
}
