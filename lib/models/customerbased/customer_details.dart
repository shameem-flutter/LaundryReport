// To parse this JSON data, do
//
//     final customerModel = customerModelFromJson(jsonString);

import 'dart:convert';

List<CustomerListModel> customerModelFromJson(String str) =>
    List<CustomerListModel>.from(
      json.decode(str).map((x) => CustomerListModel.fromJson(x)),
    );

String customerModelToJson(List<CustomerListModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CustomerListModel {
  int customerId;
  String customerName;
  String mobile;
  String address;
  String note;
  dynamic enteredBy;
  dynamic entryDate;
  int? openingBalance;
  int currentBalance;

  CustomerListModel({
    required this.customerId,
    required this.customerName,
    required this.mobile,
    required this.address,
    required this.note,
    required this.enteredBy,
    required this.entryDate,
    required this.openingBalance,
    required this.currentBalance,
  });

  factory CustomerListModel.fromJson(Map<String, dynamic> json) =>
      CustomerListModel(
        customerId: (json["customer_id"] as num).toInt(),
        customerName: json["customer_name"],
        mobile: json["mobile"],
        address: json["address"],
        note: json["note"],
        enteredBy: json["entered_by"],
        entryDate: json["entry_date"],
        openingBalance: json["opening_balance"] == null
            ? null
            : (json["opening_balance"] as num).toInt(),
        currentBalance: (json["current_balance"] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
    "customer_id": customerId,
    "customer_name": customerName,
    "mobile": mobile,
    "address": address,
    "note": note,
    "entered_by": enteredBy,
    "entry_date": entryDate,
    "opening_balance": openingBalance,
    "current_balance": currentBalance,
  };
}
