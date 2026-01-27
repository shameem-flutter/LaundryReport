// To parse this JSON data, do
//
//     final countryCodeModel = countryCodeModelFromJson(jsonString);

import 'dart:convert';

CountryCodeModel countryCodeModelFromJson(String str) =>
    CountryCodeModel.fromJson(json.decode(str));

String countryCodeModelToJson(CountryCodeModel data) =>
    json.encode(data.toJson());

class CountryCodeModel {
  String country;
  String countryCode;
  String currencyCode;
  String currencyNameAr;

  CountryCodeModel({
    required this.country,
    required this.countryCode,
    required this.currencyCode,
    required this.currencyNameAr,
  });

  factory CountryCodeModel.fromJson(Map<String, dynamic> json) =>
      CountryCodeModel(
        country: json["country"]?.toString() ?? "",
        countryCode: json["country_code"]?.toString() ?? "",
        currencyCode: json["currency_code"]?.toString() ?? "",
        currencyNameAr: json["currency_name_ar"]?.toString() ?? "",
      );

  Map<String, dynamic> toJson() => {
    "country": country,
    "country_code": countryCode,
    "currency_code": currencyCode,
    "currency_name_ar": currencyNameAr,
  };
}
