// To parse this JSON data, do
//
//     final incomeandExpenseModel = incomeandExpenseModelFromJson(jsonString);

import 'dart:convert';

IncomeandExpenseModel incomeandExpenseModelFromJson(String str) =>
    IncomeandExpenseModel.fromJson(json.decode(str));

String incomeandExpenseModelToJson(IncomeandExpenseModel data) =>
    json.encode(data.toJson());

class IncomeandExpenseModel {
  DateTime fromDate;
  DateTime toDate;
  String paymentMode;
  int totalIncome;
  int totalExpense;
  int closingBalance;
  List<Report> report;

  IncomeandExpenseModel({
    required this.fromDate,
    required this.toDate,
    required this.paymentMode,
    required this.totalIncome,
    required this.totalExpense,
    required this.closingBalance,
    required this.report,
  });

  factory IncomeandExpenseModel.fromJson(Map<String, dynamic> json) =>
      IncomeandExpenseModel(
        fromDate: DateTime.parse(json["from_date"]),
        toDate: DateTime.parse(json["to_date"]),
        paymentMode: json["payment_mode"],
        totalIncome: json["total_income"],
        totalExpense: json["total_expense"],
        closingBalance: json["closing_balance"],
        report: List<Report>.from(
          json["report"].map((x) => Report.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "from_date":
        "${fromDate.year.toString().padLeft(4, '0')}-${fromDate.month.toString().padLeft(2, '0')}-${fromDate.day.toString().padLeft(2, '0')}",
    "to_date":
        "${toDate.year.toString().padLeft(4, '0')}-${toDate.month.toString().padLeft(2, '0')}-${toDate.day.toString().padLeft(2, '0')}",
    "payment_mode": paymentMode,
    "total_income": totalIncome,
    "total_expense": totalExpense,
    "closing_balance": closingBalance,
    "report": List<dynamic>.from(report.map((x) => x.toJson())),
  };
}

class Report {
  DateTime trnDate;
  String trnType;
  int trnNo;
  String description;
  String paymentMode;
  int income;
  int expense;
  String narration;
  String enteredBy;
  DateTime entryDate;
  int sortOrder;
  int balance;

  Report({
    required this.trnDate,
    required this.trnType,
    required this.trnNo,
    required this.description,
    required this.paymentMode,
    required this.income,
    required this.expense,
    required this.narration,
    required this.enteredBy,
    required this.entryDate,
    required this.sortOrder,
    required this.balance,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    trnDate: DateTime.parse(json["trn_date"]),
    trnType: json["trn_type"],
    trnNo: json["trn_no"],
    description: json["description"],
    paymentMode: json["payment_mode"],
    income: json["income"],
    expense: json["expense"],
    narration: json["narration"],
    enteredBy: json["entered_by"],
    entryDate: DateTime.parse(json["entry_date"]),
    sortOrder: json["sort_order"],
    balance: json["balance"],
  );

  Map<String, dynamic> toJson() => {
    "trn_date": trnDate.toIso8601String(),
    "trn_type": trnType,
    "trn_no": trnNo,
    "description": description,
    "payment_mode": paymentMode,
    "income": income,
    "expense": expense,
    "narration": narration,
    "entered_by": enteredBy,
    "entry_date": entryDate.toIso8601String(),
    "sort_order": sortOrder,
    "balance": balance,
  };
}
