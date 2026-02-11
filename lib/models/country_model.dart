// To parse this JSON data, do
//
//     final countryCodeModel = countryCodeModelFromJson(jsonString);

import 'dart:convert';

CountryCodeModel countryCodeModelFromJson(String str) =>
    CountryCodeModel.fromJson(json.decode(str));

String countryCodeModelToJson(CountryCodeModel data) =>
    json.encode(data.toJson());

class CountryCodeModel {
  final String country;
  final String countryCode;
  final String currencyCode;
  final String currencyNameAr;
  final String companyName;

  CountryCodeModel({
    required this.country,
    required this.countryCode,
    required this.currencyCode,
    required this.currencyNameAr,
    required this.companyName,
  });

  factory CountryCodeModel.fromJson(Map<String, dynamic> json) =>
      CountryCodeModel(
        country: json["country"]?.toString() ?? "",
        countryCode: json["country_code"]?.toString() ?? "",
        currencyCode: json["currency_code"]?.toString() ?? "",
        currencyNameAr: json["currency_name_ar"]?.toString() ?? "",
        companyName: json["company_name"]?.toString() ?? "",
      );

  Map<String, dynamic> toJson() => {
    "country": country,
    "country_code": countryCode,
    "currency_code": currencyCode,
    "currency_name_ar": currencyNameAr,
    "company_name": companyName,
  };

  CountryCodeModel copyWith({
    String? country,
    String? countryCode,
    String? currencyCode,
    String? currencyNameAr,
    String? companyName,
  }) {
    return CountryCodeModel(
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyNameAr: currencyNameAr ?? this.currencyNameAr,
      companyName: companyName ?? this.companyName,
    );
  }
}
