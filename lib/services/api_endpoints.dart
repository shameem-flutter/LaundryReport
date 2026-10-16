import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  static String baseUrl = '';
  static const String _baseUrlKey = 'api_base_url';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null) {
      baseUrl = savedUrl;
    }
  }

  static Future<void> updateBaseUrl(String protocol, String host) async {
    String formattedHost = host.trim();
    if (formattedHost.startsWith('https://')) {
      protocol = 'https://';
      formattedHost = formattedHost.replaceFirst('https://', '');
    } else if (formattedHost.startsWith('http://')) {
      protocol = 'http://';
      formattedHost = formattedHost.replaceFirst('http://', '');
    }
    if (formattedHost.endsWith('/')) {
      formattedHost = formattedHost.substring(0, formattedHost.length - 1);
    }

    final newUrl = '$protocol$formattedHost/';
    baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, newUrl);
  }

  static const String services = 'api/v1/integration/services/';
  static const String items = 'api/v1/integration/items/';
  static const String custName = 'api/v1/integration/customer/';
  static const String orderReport = 'api/v1/integration/order-report/';
  static const String itemWiseReport = 'api/v1/integration/item-wise-report/';
  static const String orderSummaryReport =
      'api/v1/integration/order-summary-report/';
  static const String checkLicense = 'api/v2/license/check_license_status/';
  static const String machineCode = 'api/v2/license/get_system_code/';
  static const String activateLicenseKey = 'api/v2/license/activate_license/';
  static const String orderUpdate = 'api/v1/integration/update-order-status/';
  static const String deliveryUpdate =
      'api/v1/integration/update-delivery-status/';
  static const String deliveryBoy = 'api/v1/integration/delivered-by/';
  static const String customerDetails = 'api/v1/integration/customer/';
  static const String updateCreditReceipt =
      'api/v1/integration/customer-credit-receipts/';
  static const String getCustomerLedger = 'api/v1/integration/customer-ledger/';
  static const String getCustomeroutstanding =
      'api/v1/integration/customer-outstanding-report/';
  static const String getCountrycode = 'api/v1/integration/country-details/';
  static const String incomeandExpense =
      'api/v1/integration/income-expense-report/';
  static const String saleReport = 'api/v1/integration/sale-summary-report/';
}
