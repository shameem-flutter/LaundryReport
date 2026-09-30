// To parse this JSON data, do
//
//     final servicesModel = servicesModelFromJson(jsonString);

import 'dart:convert';

List<ServicesModel> servicesModelFromJson(String str) =>
    List<ServicesModel>.from(
      json.decode(str).map((x) => ServicesModel.fromJson(x)),
    );

String servicesModelToJson(List<ServicesModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ServicesModel {
  int serviceId;
  String serviceName;

  ServicesModel({required this.serviceId, required this.serviceName});

  factory ServicesModel.fromJson(Map<String, dynamic> json) => ServicesModel(
    serviceId: _toInt(json["service_id"]),
    serviceName: (json["service_name"] ?? '').toString().trim(),
  );

  Map<String, dynamic> toJson() => {
    "service_id": serviceId,
    "service_name": serviceName,
  };
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
