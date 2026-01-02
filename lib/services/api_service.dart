import 'package:dio/dio.dart';
import 'package:laundry/models/customer.dart';
import 'package:laundry/models/itemwise.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/models/item.dart';
import 'package:laundry/models/services.dart';
import 'package:laundry/services/api_endpoints.dart';

class ApiService {
  Dio get _dio => Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

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
          if (customerId != null &&
              customerId.isNotEmpty &&
              customerId != "All")
            'customer_id': customerId,
        },
      );
      print('🔍 API URL: ${response.realUri}');
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
}
