import 'dart:convert';

OrderSummaryReportResponse orderSummaryReportResponseFromJson(String str) =>
    OrderSummaryReportResponse.fromJson(json.decode(str));

class OrderSummaryReportResponse {
  final int totalOrders;
  final double totalOrderQty;
  final double totalCollection;
  final double totalDiscountAmount;
  final double netTotalCashCard;
  final double netTotalCredit;
  final double totalExpressCharges;
  final double totalVatAmount;
  final double totalRoundingAmount;
  final double totalRedeemAmount;
  final List<OrderSummaryItem> results;

  OrderSummaryReportResponse({
    required this.totalOrders,
    this.totalOrderQty = 0.0,
    required this.totalCollection,
    required this.totalDiscountAmount,
    required this.netTotalCashCard,
    required this.netTotalCredit,
    this.totalExpressCharges = 0.0,
    this.totalVatAmount = 0.0,
    this.totalRoundingAmount = 0.0,
    this.totalRedeemAmount = 0.0,
    required this.results,
  });

  factory OrderSummaryReportResponse.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return OrderSummaryReportResponse(
        totalOrders: 0,
        totalOrderQty: 0.0,
        totalCollection: 0.0,
        totalDiscountAmount: 0.0,
        netTotalCashCard: 0.0,
        netTotalCredit: 0.0,
        results: [],
      );
    }

    final rawResults = json['results'];
    final List<OrderSummaryItem> resultsList = rawResults is List
        ? rawResults.map((x) => OrderSummaryItem.fromJson(x)).toList()
        : [];

    final double calculatedQty = resultsList.fold<double>(
      0.0,
      (sum, item) => sum + item.orderQty,
    );

    return OrderSummaryReportResponse(
      totalOrders: _toInt(json['total_orders'] ?? resultsList.length),
      totalOrderQty: json['total_order_qty'] != null
          ? _toDouble(json['total_order_qty'])
          : calculatedQty,
      totalCollection: _toDouble(json['total_collection']),
      totalDiscountAmount: _toDouble(json['total_discount_amount']),
      netTotalCashCard: _toDouble(json['net_total_cash_card']),
      netTotalCredit: _toDouble(json['net_total_credit']),
      totalExpressCharges: _toDouble(json['total_express_charges']),
      totalVatAmount: _toDouble(json['total_vat_amount']),
      totalRoundingAmount: _toDouble(json['total_rounding_amount']),
      totalRedeemAmount: _toDouble(json['total_redeem_amount']),
      results: resultsList,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }
}

class OrderSummaryItem {
  final dynamic orderId;
  final dynamic orderNo;
  final String orderDate;
  final String customerName;
  final String customerMobile;
  final double orderQty;
  final double? discountPercentage;
  final double discountAmount;
  final double totalAmount;
  final double grandTotal;
  final String enteredBy;
  final String paymentReceivedBy;
  final List<OrderSummaryPaymentMode> paymentMode;

  OrderSummaryItem({
    required this.orderId,
    required this.orderNo,
    required this.orderDate,
    required this.customerName,
    required this.customerMobile,
    this.orderQty = 0.0,
    this.discountPercentage,
    required this.discountAmount,
    required this.totalAmount,
    required this.grandTotal,
    required this.enteredBy,
    required this.paymentReceivedBy,
    required this.paymentMode,
  });

  factory OrderSummaryItem.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return OrderSummaryItem(
        orderId: '',
        orderNo: '',
        orderDate: '',
        customerName: '',
        customerMobile: '',
        orderQty: 0.0,
        discountAmount: 0.0,
        totalAmount: 0.0,
        grandTotal: 0.0,
        enteredBy: '',
        paymentReceivedBy: '',
        paymentMode: [],
      );
    }

    final rawModes = json['payment_mode'];
    final List<OrderSummaryPaymentMode> modesList = rawModes is List
        ? rawModes.map((x) => OrderSummaryPaymentMode.fromJson(x)).toList()
        : [];

    return OrderSummaryItem(
      orderId: json['order_id'],
      orderNo: json['order_no'],
      orderDate: json['order_date']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerMobile: json['customer_mobile']?.toString() ?? '',
      orderQty: _toDouble(json['order_qty'] ?? json['qty'] ?? json['total_qty']),
      discountPercentage: json['discount_percentage'] != null
          ? _toDouble(json['discount_percentage'])
          : null,
      discountAmount: _toDouble(json['discount_amount']),
      totalAmount: _toDouble(json['total_amount']),
      grandTotal: _toDouble(json['grand_total']),
      enteredBy: json['entered_by']?.toString() ?? '',
      paymentReceivedBy: json['payment_received_by']?.toString() ?? '',
      paymentMode: modesList,
    );
  }

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }
}

class OrderSummaryPaymentMode {
  final String paymentModeName;
  final double amount;

  OrderSummaryPaymentMode({
    required this.paymentModeName,
    required this.amount,
  });

  factory OrderSummaryPaymentMode.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return OrderSummaryPaymentMode(
        paymentModeName: '',
        amount: 0.0,
      );
    }
    return OrderSummaryPaymentMode(
      paymentModeName: json['payment_mode_name']?.toString() ?? '',
      amount: OrderSummaryItem._toDouble(json['amount']),
    );
  }
}
