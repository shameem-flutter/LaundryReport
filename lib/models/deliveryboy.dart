// To parse this JSON data, do
//
//     final deliveryboyModel = deliveryboyModelFromJson(jsonString);

import 'dart:convert';

List<DeliveryboyModel> deliveryboyModelFromJson(String str) =>
    List<DeliveryboyModel>.from(
      json.decode(str).map((x) => DeliveryboyModel.fromJson(x)),
    );

String deliveryboyModelToJson(List<DeliveryboyModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class DeliveryboyModel {
  int userId;
  String userName;

  DeliveryboyModel({required this.userId, required this.userName});

  factory DeliveryboyModel.fromJson(Map<String, dynamic> json) =>
      DeliveryboyModel(userId: (json["user_id"] as num).toInt(), userName: json["user_name"]);

  Map<String, dynamic> toJson() => {"user_id": userId, "user_name": userName};
}
