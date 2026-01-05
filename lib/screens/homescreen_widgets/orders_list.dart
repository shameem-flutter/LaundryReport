import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/screens/homescreen_widgets/common_widgets.dart';
import 'package:laundry/utilities/colors.dart';

class OrderList extends StatelessWidget {
  final List<OrderReportModel> orders;

  const OrderList({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: orders.map((order) => OrderCard(order: order)).toList(),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderReportModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 12),
                Text(
                  "Order #${order.orderNo}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  "${_formatDate(order.orderDate)} / ${_formatTime(order.orderDate)}",
                ),
              ],
            ),
            const SizedBox(height: 12),
            InfoRow(
              icon: Icons.person_outline,
              label: "Customer",
              value: order.customerName,
            ),
            const SizedBox(height: 8),
            InfoRow(
              icon: Icons.phone_outlined,
              label: "Mobile",
              value: order.customerMobile,
            ),
            if (order.customerAddress.isNotEmpty &&
                order.customerAddress != "-") ...[
              const SizedBox(height: 8),
              InfoRow(
                icon: Icons.location_on_outlined,
                label: "Address",
                value: order.customerAddress,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        "Payment",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        status: order.paymentStatus,
                        color: getStatusColor(order.paymentStatus),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        "Order Status",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        status: order.orderStatus,
                        color: getStatusColor(order.orderStatus),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        "Delivery Status",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: blackColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        status: order.deliveryStatus,
                        color: getStatusColor(order.deliveryStatus),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _formatTime(DateTime d) => DateFormat('h:mm a').format(d);
}
