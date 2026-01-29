// To parse this JSON data, do
//
//     final customerLedgerModel = customerLedgerModelFromJson(jsonString);

import 'dart:convert';

CustomerLedgerModel customerLedgerModelFromJson(String str) =>
    CustomerLedgerModel.fromJson(json.decode(str));

String customerLedgerModelToJson(CustomerLedgerModel data) =>
    json.encode(data.toJson());

class CustomerLedgerModel {
  String customerId;
  String customerName;
  DateTime? fromDate;
  DateTime? toDate;
  double closingBalance;
  List<Ledger> ledger;

  CustomerLedgerModel({
    required this.customerId,
    required this.customerName,
    required this.fromDate,
    required this.toDate,
    required this.closingBalance,
    required this.ledger,
  });

  factory CustomerLedgerModel.fromJson(Map<String, dynamic> json) =>
      CustomerLedgerModel(
        customerId: json["customer_id"]?.toString() ?? "",
        customerName: json["customer_name"]?.toString() ?? "",
        fromDate: json["from_date"] != null
            ? DateTime.tryParse(json["from_date"])
            : null,
        toDate: json["to_date"] != null
            ? DateTime.tryParse(json["to_date"])
            : null,
        closingBalance: (json["closing_balance"] ?? 0).toDouble(),
        ledger: json["ledger"] == null
            ? []
            : List<Ledger>.from(json["ledger"].map((x) => Ledger.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
    "customer_id": customerId,
    "customer_name": customerName,
    "from_date": fromDate != null
        ? "${fromDate!.year.toString().padLeft(4, '0')}-${fromDate!.month.toString().padLeft(2, '0')}-${fromDate!.day.toString().padLeft(2, '0')}"
        : null,
    "to_date": toDate != null
        ? "${toDate!.year.toString().padLeft(4, '0')}-${toDate!.month.toString().padLeft(2, '0')}-${toDate!.day.toString().padLeft(2, '0')}"
        : null,
    "closing_balance": closingBalance,
    "ledger": List<dynamic>.from(ledger.map((x) => x.toJson())),
  };
}

class Ledger {
  String rowType;
  int sortOrder;
  DateTime? trnDate;
  dynamic trnNo;
  String description;
  String? paymentMode;
  String? narration;
  double creditAmount;
  double receiptAmount;
  double balance;
  String customerName;

  Ledger({
    required this.rowType,
    required this.sortOrder,
    this.trnDate,
    this.trnNo,
    required this.description,
    this.paymentMode,
    this.narration,
    required this.creditAmount,
    required this.receiptAmount,
    required this.balance,
    required this.customerName,
  });

  factory Ledger.fromJson(Map<String, dynamic> json) => Ledger(
    rowType: json["row_type"]?.toString() ?? "",
    sortOrder: json["sort_order"] ?? 0,
    trnDate: json["trn_date"] != null
        ? DateTime.tryParse(json["trn_date"].toString())
        : null,

    trnNo: json["trn_no"],
    description: json["description"]?.toString() ?? "",
    paymentMode: json["payment_mode"]?.toString(),
    narration: json["narration"]?.toString(),
    creditAmount: (json["credit_amount"] ?? 0).toDouble(),
    receiptAmount: (json["receipt_amount"] ?? 0).toDouble(),
    balance: (json["balance"] ?? 0).toDouble(),
    customerName: json["customer_name"]?.toString() ?? "",
  );

  Map<String, dynamic> toJson() => {
    "row_type": rowType,
    "sort_order": sortOrder,
    "trn_date": trnDate != null
        ? "${trnDate!.year.toString().padLeft(4, '0')}-"
              "${trnDate!.month.toString().padLeft(2, '0')}-"
              "${trnDate!.day.toString().padLeft(2, '0')}"
        : null,

    "trn_no": trnNo,
    "description": description,
    "payment_mode": paymentMode,
    "narration": narration,
    "credit_amount": creditAmount,
    "receipt_amount": receiptAmount,
    "balance": balance,
    "customer_name": customerName,
  };
}
