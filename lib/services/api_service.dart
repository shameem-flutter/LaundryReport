import 'dart:math';

import 'package:dio/dio.dart';
import 'package:laundry/models/customer.dart';
import 'package:laundry/models/customerbased/customer_details.dart';
import 'package:laundry/models/customerbased/customerledger_model.dart';
import 'package:laundry/models/customeroutstandingmodel.dart';
import 'package:laundry/models/deliveryboy.dart';
import 'package:laundry/models/itemwise.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/models/item.dart';
import 'package:laundry/models/services.dart';
import 'package:laundry/services/api_endpoints.dart';

class ApiService {
  Dio get _dio {
    return Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<bool> checkLicenseStatus() async {
    try {
      final response = await _dio.get(ApiEndpoints.checkLicense);
      if (response.statusCode == 200) {
        final data = response.data;
        return data['status'] == 'active';
      }
      return false;
    } catch (e) {
      print('Error checking license status: $e');
      return false;
    }
  }

  Future<String> fetchSystemCode() async {
    try {
      final response = await _dio.get(ApiEndpoints.machineCode);
      if (response.statusCode == 200) {
        final data = response.data;
        return data['system_code'] ?? "";
      }
      return "";
    } catch (e) {
      print('Error fetching system code: $e');
      return "";
    }
  }

  Future<List<ServicesModel>> fetchServices() async {
    try {
      final response = await _dio.get(ApiEndpoints.services);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ServicesModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<ItemModel>> fetchItems() async {
    try {
      final response = await _dio.get(ApiEndpoints.items);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ItemModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<CustomerModel>> fetchCustName() async {
    try {
      final response = await _dio.get(ApiEndpoints.custName);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CustomerModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<OrderReportModel>> fetchOrderReport({
    required String startDate,
    required String endDate,
    required String orderStatus,
    required String paymentStatus,
    required String deliveryStatus,
    String? customerId,
    String? orderNo,
    String? orderId, // 1. Added the optional parameter here
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.orderReport,
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          'order_status': orderStatus,
          'payment_status': paymentStatus,
          'delivery_status': deliveryStatus,
          // 2. Added logic to include it in the API request
          if (orderNo != null && orderNo.isNotEmpty) 'order_no': orderNo,
          if (orderId != null && orderId.isNotEmpty) 'order_id': orderId,
          if (customerId != null &&
              customerId.isNotEmpty &&
              customerId != "All")
            'customer_id': customerId,
        },
      );
      //   print('🔍 API URL: ${response.realUri}');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OrderReportModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load order report');
      }
    } catch (e) {
      throw Exception('Error fetching order report: $e');
    }
  }

  Future<List<ItemWiseorderreportModel>> fetchItemWiseReport({
    required String startDate,
    required String endDate,
    required String orderStatus,
    required String paymentStatus,
    required String deliveryStatus,
    String? customerId,
    String? orderNo,
    String? serviceName,
    String? itemName,
    String? serviceType,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.itemWiseReport,
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          'order_status': orderStatus,
          'payment_status': paymentStatus,
          'delivery_status': deliveryStatus,
          if (orderNo != null && orderNo.isNotEmpty) 'order_no': orderNo,
          if (customerId != null && customerId != "All")
            'customer_id': customerId,
          if (serviceName != null) 'service_id': serviceName,
          if (itemName != null) 'item_id': itemName,
          if (serviceType != null) 'service_type': serviceType,
        },
      );
      print('🔍 API URL (ItemWise): ${response.realUri}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => ItemWiseorderreportModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load item-wise report');
      }
    } catch (e) {
      throw Exception('Error fetching item-wise report: $e');
    }
  }

  Future<String> postKey(String activationKey) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.activateLicenseKey,
        data: {"activation_key": activationKey},
      );

      // Success: 200 or 201
      if (response.statusCode == 200 || response.statusCode == 201) {
        // You can extract a message from response if the API returns one
        final String successMessage =
            response.data['message'] ??
            response.data.toString() ??
            "License activated successfully!";

        print(successMessage);
        return successMessage; // Return success message
      } else {
        // Non-2xx status code
        throw Exception(
          "Activation failed with status: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      String errorMessage = "Failed to activate license";

      if (e.response != null) {
        // Server responded with error (400, 401, 422, 500, etc.)
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          errorMessage = data['message'] ?? data['detail'] ?? data.toString();
        } else {
          errorMessage = data.toString();
        }
        errorMessage += " (${e.response?.statusCode})";
      } else {
        // No response: network issue, timeout, etc.
        errorMessage =
            e.message ?? "Network error. Please check your connection.";
      }

      print("Activation Error: $errorMessage");

      // Throw with meaningful message so UI can show it
      throw Exception(errorMessage);
    } catch (e) {
      // Unexpected errors
      print("Unexpected error: $e");
      throw Exception("An unexpected error occurred");
    }
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.orderUpdate,
        data: {'order_id': orderId, 'order_status': status},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Order status updated successfully');
        return;
      } else {
        throw Exception(
          'Failed to update order status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error updating order status: $e');
    }
  }

  Future<void> updateDeliveryStatus({
    required String orderId,
    required String deliveryStage,
    String? deliveredBy,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deliveryUpdate,
        data: {
          "order_id": orderId,
          "delivery_stage": deliveryStage,
          "delivered_by": deliveredBy,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception(
          "Failed to Update delivery status:${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error updating order status: $e");
    }
  }

  Future<List<DeliveryboyModel>> deliveryBoy() async {
    try {
      final response = await _dio.get(ApiEndpoints.deliveryBoy);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => DeliveryboyModel.fromJson(json)).toList();
      } else {
        throw Exception("Failed to get delivery boy data ");
      }
    } catch (e) {
      throw Exception("error in getting data (delivery boy)$e");
    }
  }

  Future<List<CustomerListModel>> customerDetails() async {
    try {
      final response = await _dio.get(ApiEndpoints.customerDetails);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = response.data;
        return data.map((json) => CustomerListModel.fromJson(json)).toList();
      } else {
        throw Exception("failed to fetch customer details:$e");
      }
    } catch (e) {
      throw Exception("error fetching customer details:$e");
    }
  }

  Future<void> updateCreditReceipt({
    required String customerId,
    required String paymentMode,
    required int amount,
    String? narration,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.updateCreditReceipt,
        data: {
          "customer_id": customerId,
          "payment_mode": paymentMode,
          "amount": amount,
          "narration": narration,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return;
      } else {
        throw Exception("failed to update Credit amount");
      }
    } catch (e) {
      throw Exception("Error updating credit receipt: $e");
    }
  }

  Future<CustomerLedgerModel> getCustomerledger({
    required String customerId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.getCustomerLedger,
      queryParameters: {
        "customer_id": customerId,
        "from_date": startDate,
        "to_date": endDate,
      },
    );
    if (response.statusCode == 200) {
      return CustomerLedgerModel.fromJson(response.data);
    } else {
      throw Exception("Error occured while parsing Customer Ledger");
    }
  }

  Future<List<CustomerOutstandingModel>> getCustomerOutstanding() async {
    try {
      final response = await _dio.get(ApiEndpoints.getCustomeroutstanding);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map(
              (json) => CustomerOutstandingModel.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        throw Exception("failed to get customeroutstanding data $e");
      }
    } catch (e) {
      throw Exception("error while parsing customeroutstanding $e");
    }
  }
}
