// To parse this JSON data, do
//
//     final creditRecieptModel = creditRecieptModelFromJson(jsonString);

import 'dart:convert';

CreditRecieptModel creditRecieptModelFromJson(String str) =>
    CreditRecieptModel.fromJson(json.decode(str));

String creditRecieptModelToJson(CreditRecieptModel data) =>
    json.encode(data.toJson());

class CreditRecieptModel {
  String customerId;
  String paymentMode;
  int amount;
  String narration;

  CreditRecieptModel({
    required this.customerId,
    required this.paymentMode,
    required this.amount,
    required this.narration,
  });

  factory CreditRecieptModel.fromJson(Map<String, dynamic> json) =>
      CreditRecieptModel(
        customerId: json["customer_id"],
        paymentMode: json["payment_mode"],
        amount: json["amount"],
        narration: json["narration"],
      );

  Map<String, dynamic> toJson() => {
    "customer_id": customerId,
    "payment_mode": paymentMode,
    "amount": amount,
    "narration": narration,
  };
}
