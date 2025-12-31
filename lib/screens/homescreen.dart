import 'package:flutter/material.dart';
import 'package:laundry/utilities/gapfunc.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/models/itemwise.dart';
import 'package:intl/intl.dart';

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
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  List<OrderReportModel> _orders = [];
  List<ItemWiseorderreportModel> _itemWise = [];

  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _orderNoController = TextEditingController();

  final List<String> _statusOptions = [
    "All",
    "Finished",
    "Pending",
    "Cancelled",
  ];
  String _serviceType = "All";
  String _selectedService = "All";
  String _selectedItem = "All";

  List<Map<String, dynamic>> _apiServices = [];
  List<Map<String, dynamic>> _apiItems = [];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    final services = await _apiService.fetchServices();
    final items = await _apiService.fetchItems();
    if (mounted) {
      setState(() {
        _apiServices = services;
        _apiItems = items;
      });
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(_fromDate);
      final endDate = DateFormat('yyyy-MM-dd').format(_toDate);

      if (_isItemWise) {
        String serviceId = "All";
        if (_selectedService != "All") {
          final service = _apiServices.firstWhere(
            (e) => e['service_name'] == _selectedService,
            orElse: () => {"service_id": "All"},
          );
          serviceId = service['service_id'].toString();
        }

        String itemId = "All";
        if (_selectedItem != "All") {
          final item = _apiItems.firstWhere(
            (e) => e['service_item_name'] == _selectedItem,
            orElse: () => {"service_item_id": "All"},
          );
          itemId = item['service_item_id'].toString();
        }

        final results = await _apiService.fetchItemWiseReport(
          startDate: startDate,
          endDate: endDate,
          orderStatus: _orderStatus,
          paymentStatus: _paymentStatus,
          deliveryStatus: _deliveryStatus,
          customerId: _customerController.text,
          serviceName: serviceId,
          itemName: itemId,
          serviceType: _serviceType,
        );
        setState(() => _itemWise = results);
      } else {
        final results = await _apiService.fetchOrderReport(
          startDate: startDate,
          endDate: endDate,
          orderStatus: _orderStatus,
          paymentStatus: _paymentStatus,
          deliveryStatus: _deliveryStatus,
          customerId: _customerController.text,
        );
        setState(() => _orders = results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            /// TOP ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchData,
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
                        _serviceType = "All";
                        _selectedService = "All";
                        _selectedItem = "All";
                        _customerController.clear();
                        _orderNoController.clear();
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

            /// FILTER GRID (2 COLUMNS)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LEFT COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatePicker(
                        "From:",
                        _fromDate,
                        (d) => setState(() => _fromDate = d),
                      ),
                      const SizedBox(height: 12),
                      _buildTextFilter(
                        "Customer:",
                        controller: _customerController,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownFilter(
                        "Order Status:",
                        _orderStatus,
                        _statusOptions,
                        (v) => setState(() => _orderStatus = v!),
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownFilter(
                        "Payment Status:",
                        _paymentStatus,
                        ["All", "Paid", "Unpaid", "Partial"],
                        (v) => setState(() => _paymentStatus = v!),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 18),

                /// RIGHT COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDatePicker(
                        "To:",
                        _toDate,
                        (d) => setState(() => _toDate = d),
                      ),
                      const SizedBox(height: 12),
                      _buildTextFilter(
                        "Order No.:",
                        controller: _orderNoController,
                      ),
                      const SizedBox(height: 12),
                      _buildDropdownFilter(
                        "Delivery Status:",
                        _deliveryStatus,
                        [
                          "All",
                          "Pending",
                          "Finished",
                          "Cancelled",
                          "Delivered",
                        ],
                        (v) => setState(() => _deliveryStatus = v!),
                      ),
                      const SizedBox(height: 12),

                      /// ITEM-WISE SWITCH
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: _isItemWise,
                            onChanged: (v) => setState(() => _isItemWise = v),
                            activeColor: const Color(0xFF0D47A1),
                          ),
                          horiGap(6),
                          const Text(
                            "Item wise",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// ITEM-WISE EXTRA FILTERS
            if (_isItemWise) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Service Type",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildServiceTypeToggle(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdownFilter(
                          "Category:",
                          _selectedService,
                          [
                            "All",
                            ..._apiServices.map(
                              (e) => e['service_name'].toString(),
                            ),
                          ],
                          (v) => setState(() => _selectedService = v!),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter(
                          "Item:",
                          _selectedItem,
                          [
                            "All",
                            ..._apiItems.map(
                              (e) => e['service_item_name'].toString(),
                            ),
                          ],
                          (v) => setState(() => _selectedItem = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextFilter(String label, {TextEditingController? controller}) {
    return Column(
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
            controller: controller,
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
    );
  }

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
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
              value: options.contains(value) ? value : options.first,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              style: const TextStyle(fontSize: 13, color: Colors.black),
              onChanged: onChanged,
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
    String label,
    DateTime date,
    Function(DateTime) onChanged,
  ) {
    return Column(
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
                  DateFormat('dd/MM/yyyy').format(date),
                  style: const TextStyle(fontSize: 13),
                ),
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTypeToggle() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // _buildTypeButton("All", Colors.blueGrey, _serviceType == "All"),
        _buildTypeButton("Normal", Colors.green, _serviceType == "Normal"),
        _buildTypeButton("Express", Colors.red, _serviceType == "Express"),
      ],
    );
  }

  Widget _buildTypeButton(String label, Color color, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() => _serviceType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTable() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isItemWise) {
      return _buildItemWiseTable();
    } else {
      return Column(
        children: _orders.map((order) => _buildOrderCard(order)).toList(),
      );
    }
  }

  Widget _buildOrderCard(OrderReportModel order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  "${formatDate(order.orderDate)} • ${formatTime(order.orderDate)}",
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person_outline, "Customer", order.customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone_outlined, "Mobile", order.customerMobile),
            if (order.customerAddress.isNotEmpty &&
                order.customerAddress != "-") ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.location_on_outlined,
                "Address",
                order.customerAddress,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusBadge(
                    order.paymentStatus,
                    _getStatusColor(order.paymentStatus),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusBadge(
                    order.orderStatus,
                    _getStatusColor(order.orderStatus),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusBadge(
                    order.deliveryStatus,
                    _getStatusColor(order.deliveryStatus),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildItemWiseTable() {
    if (_itemWise.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text("No item-wise data found")),
      );
    }
    return Card(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade400),
            verticalInside: BorderSide(color: Colors.grey.shade400),
          ),
          columns: const [
            DataColumn(label: Text("Order No")),
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Service")),
            DataColumn(label: Text("Item")),
            DataColumn(label: Text("Customer")),
            DataColumn(label: Text("Mobile")),
            DataColumn(label: Text("Payment")),
            DataColumn(label: Text("Order Status")),
            DataColumn(label: Text("Delivery Status")),
          ],
          rows: _itemWise.map((item) {
            return DataRow(
              cells: [
                DataCell(Text("${item.orderNo}")),
                DataCell(
                  Text(
                    "${formatDate(item.orderDate)} ${formatTime(item.orderDate)}",
                  ),
                ),
                DataCell(Text(item.serviceName)),
                DataCell(Text(item.item)),
                DataCell(Text(item.customerName)),
                DataCell(Text(item.customerMobile)),
                DataCell(
                  _buildStatusBadge(
                    item.paymentStatus,
                    _getStatusColor(item.paymentStatus),
                  ),
                ),
                DataCell(
                  _buildStatusBadge(
                    item.orderStatus,
                    _getStatusColor(item.orderStatus),
                  ),
                ),
                DataCell(
                  _buildStatusBadge(
                    item.deliveryStatus,
                    _getStatusColor(item.deliveryStatus),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "paid":
        return Colors.green;
      case "unpaid":
        return Colors.red;
      case "finished":
        return Colors.blue;
      case "pending":
        return Colors.orange;
      case "delivered":
        return Colors.green.shade800;
      case "cancelled":
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String formatTime(DateTime d) => DateFormat('h:mm a').format(d);
}
