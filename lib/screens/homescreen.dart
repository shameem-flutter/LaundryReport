import 'package:flutter/material.dart';
import 'package:laundry/utilities/gapfunc.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  String _orderStatus = "All";
  String _paymentStatus = "All";
  String _deliveryStatus = "All";
  DateTime _fromDate = DateTime(2025, 12, 24);
  DateTime _toDate = DateTime(2025, 12, 24);
  bool _isItemWise = false;

  final List<String> _statusOptions = [
    "All",
    "Finished",
    "Pending",
    "Cancelled",
  ];

  // Status color mapping
  final Map<String, Color> _statusColors = {
    "Paid": Colors.green,
    "Unpaid": Colors.red,
    "Partial": Colors.orange,
    "Pending": Colors.deepPurple,
    "Finished": Colors.blue,
    "Cancelled": Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildTitleBanner(),
              _buildFilterSection(),
              vertGap(10),
              _buildOrdersTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Image.asset("assets/wasla.jpeg", height: 60),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Laundry Management",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                Text(
                  "Automate, Track, Deliver Effortlessly",
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF34495E),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: const Text(
        "Order List",
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters in a wrapped layout
            Column(
              children: [
                // Top Row: Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Apply filter logic here
                        },
                        icon: const Icon(Icons.filter_list, size: 18),
                        label: const Text("Apply Filter"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _fromDate = DateTime.now();
                            _toDate = DateTime.now();
                            _orderStatus = "All";
                            _paymentStatus = "All";
                            _deliveryStatus = "All";
                            _isItemWise = false;
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text("Reset"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3E2723),
                          side: const BorderSide(color: Color(0xFF3E2723)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Grid-like layout for filters
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDatePicker(
                            "From:",
                            _fromDate,
                            (date) => setState(() => _fromDate = date),
                          ),
                          const SizedBox(height: 12),
                          _buildTextFilter("Customer:"),
                          const SizedBox(height: 12),
                          _buildDropdownFilter(
                            "Order Status:",
                            _orderStatus,
                            (val) => setState(() => _orderStatus = val!),
                          ),
                          const SizedBox(height: 12),
                          _buildDropdownFilter(
                            "Payment Status:",
                            _paymentStatus,
                            (val) => setState(() => _paymentStatus = val!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDatePicker(
                            "To:",
                            _toDate,
                            (date) => setState(() => _toDate = date),
                          ),
                          const SizedBox(height: 12),
                          _buildTextFilter("Order No.:"),
                          const SizedBox(height: 12),
                          _buildDropdownFilter(
                            "Delivery Status:",
                            _deliveryStatus,
                            (val) => setState(() => _deliveryStatus = val!),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 25),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: _isItemWise,
                                  onChanged: (v) =>
                                      setState(() => _isItemWise = v),
                                  activeColor: const Color(0xFF0D47A1),
                                ),
                                horiGap(5),
                                const Text(
                                  "Item wise",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 05),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTable() {
    // Sample data for NORMAL mode (one card per order)
    final List<Map<String, dynamic>> normalOrders = [
      {
        "orderNo": "1",
        "date": "24/12/2025",
        "time": "4:22 AM",
        "customer": "Walk-In Customer",
        "mobile": "123456787754",
        "address": "-",
        "paymentStatus": "Paid",
        "orderStatus": "Finished",
        "deliveryStatus": "Delivered",
      },
      {
        "orderNo": "2",
        "date": "24/12/2025",
        "time": "5:00 AM",
        "customer": "John Doe",
        "mobile": "987654321",
        "address": "123 Main St",
        "paymentStatus": "Pending",
        "orderStatus": "Pending",
        "deliveryStatus": "Pending",
      },
      // Add more orders...
    ];

    // Sample data for ITEM-WISE mode (one row per item)
    final List<Map<String, dynamic>> itemWiseData = [
      {
        "orderNo": "4",
        "date": "24/12/2025",
        "time": "9:38 AM",
        "service": "Washing",
        "type": "Express",
        "item": "Special Dress Big",
        "itemStatus": "Processing",
        "customer": "Akshay",
        "mobile": "654321",
        "address": "345",
        "paymentStatus": "Paid",
        "orderStatus": "Pending",
        "deliveryStatus": "Pending",
      },
      {
        "orderNo": "3",
        "date": "24/12/2025",
        "time": "9:34 AM",
        "service": "Dry Cleaning",
        "type": "Express",
        "item": "Sweater",
        "itemStatus": "Processing",
        "customer": "anandu",
        "mobile": "123456789",
        "address": "test address",
        "paymentStatus": "Paid",
        "orderStatus": "Pending",
        "deliveryStatus": "Pending",
      },
      {
        "orderNo": "2",
        "date": "24/12/2025",
        "time": "8:00 AM",
        "service": "Ironing",
        "type": "Normal",
        "item": "Frock Big",
        "itemStatus": "Ready for Delivery",
        "customer": "anandu",
        "mobile": "123456789",
        "address": "test address",
        "paymentStatus": "Paid",
        "orderStatus": "Finished",
        "deliveryStatus": "Pending",
      },
      {
        "orderNo": "1",
        "date": "24/12/2025",
        "time": "4:22 AM",
        "service": "Washing",
        "type": "Express",
        "item": "Military Suit",
        "itemStatus": "Ready for Delivery",
        "customer": "Walk-In Customer",
        "mobile": "123456787754",
        "address": "-",
        "paymentStatus": "Paid",
        "orderStatus": "Finished",
        "deliveryStatus": "Delivered",
      },
      // Add more items...
    ];

    if (!_isItemWise) {
      // NORMAL MODE: Card list per order
      return normalOrders.isEmpty
          ? const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  "No orders found",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : Column(
              children: normalOrders.map((order) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                              "Order #${order['orderNo']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                Icons.visibility_rounded,
                                color: Colors.blueGrey.shade700,
                              ),
                              tooltip: "View Details",
                              onPressed: () {},
                            ),
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
                              "${order['date']} • ${order['time']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.person_outline,
                          "Customer",
                          order['customer'],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          "Mobile",
                          order['mobile'],
                        ),
                        if (order['address'] != "-") ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.location_on_outlined,
                            "Address",
                            order['address'],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatusBadge(
                                order['paymentStatus'],
                                _getStatusColor(order['paymentStatus']),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusBadge(
                                order['orderStatus'],
                                _getStatusColor(order['orderStatus']),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildStatusBadge(
                                order['deliveryStatus'],
                                _getStatusColor(order['deliveryStatus']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
    } else {
      // ITEM-WISE MODE: Horizontal scrollable DataTable
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 56,
            dataRowHeight: 70,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            columns: const [
              DataColumn(
                label: Text(
                  "View",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Order No.",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Date",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Time",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Service",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Type",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Item",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Customer",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Mobile",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Address",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Payment",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Order Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Delivery Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: itemWiseData.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.visibility,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () {},
                    ),
                  ),
                  DataCell(Text(item['orderNo'] ?? '')),
                  DataCell(Text(item['date'] ?? '')),
                  DataCell(Text(item['time'] ?? '')),
                  DataCell(Text(item['service'] ?? '')),
                  DataCell(_buildTypeBadge(item['type'] ?? '')),
                  DataCell(
                    Text(
                      item['item'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(_buildItemStatusBadge(item['itemStatus'] ?? '')),
                  DataCell(Text(item['customer'] ?? '')),
                  DataCell(Text(item['mobile'] ?? '')),
                  DataCell(Text(item['address'] ?? '')),
                  DataCell(
                    _buildStatusBadge(
                      item['paymentStatus'] ?? '',
                      Colors.green.shade700,
                    ),
                  ),
                  DataCell(
                    _buildStatusBadge(
                      item['orderStatus'] ?? '',
                      Colors.deepPurple.shade700,
                    ),
                  ),
                  DataCell(
                    _buildStatusBadge(
                      item['deliveryStatus'] ?? '',
                      Colors.red.shade700,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  // Special badge for Type (Express = Red, Normal = Green)
  Widget _buildTypeBadge(String type) {
    Color color = type.toLowerCase() == "express" ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        type,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Special badge for Item Status (Processing, Ready for Delivery, etc.)
  Widget _buildItemStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case "processing":
        color = Colors.orange.shade700;
        break;
      case "ready for delivery":
        color = Colors.green.shade700;
        break;
      default:
        color = Colors.grey.shade700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper: Info row with icon
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Updated status badge with better styling
  Widget _buildStatusBadge(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: backgroundColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: backgroundColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Dynamic color based on status text
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "paid":
        return Colors.green.shade700;
      case "pending":
        return Colors.deepPurple.shade700;
      case "partial":
        return Colors.orange.shade700;
      case "finished":
        return Colors.blue.shade700;
      case "cancelled":
        return Colors.red.shade700;
      case "unpaid":
        return Colors.red.shade800;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildTextFilter(String label, {double width = 220}) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 40,
            child: TextField(
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                style: const TextStyle(fontSize: 13, color: Colors.black),
                onChanged: onChanged,
                items: _statusOptions.map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onChanged(picked);
            },
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
                    style: const TextStyle(fontSize: 13),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
