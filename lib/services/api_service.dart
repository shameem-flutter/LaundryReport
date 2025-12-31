import 'package:dio/dio.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/models/itemwise.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://alleged-buyers-fastest-appearance.trycloudflare.com/api/v1/integration/',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<List<Map<String, dynamic>>> fetchServices() async {
    try {
      final response = await _dio.get('services/');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchItems() async {
    try {
      final response = await _dio.get('items/');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
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
        'order-report/',
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          'order_status': orderStatus,
          'payment_status': paymentStatus,
          'delivery_status': deliveryStatus,
          if (customerId != null && customerId.isNotEmpty) 'customer_id': customerId,
        },
      );

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
        'item-wise-report/',
        queryParameters: {
          'start_date': startDate,
          'end_date': endDate,
          'order_status': orderStatus,
          'payment_status': paymentStatus,
          'delivery_status': deliveryStatus,
          if (customerId != null && customerId.isNotEmpty) 'customer_id': customerId,
          if (serviceName != null) 'service_id': serviceName,
          if (itemName != null) 'item_id': itemName,
          if (serviceType != null) 'service_type': serviceType,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ItemWiseorderreportModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load item-wise report');
      }
    } catch (e) {
      throw Exception('Error fetching item-wise report: $e');
    }
  }
}
