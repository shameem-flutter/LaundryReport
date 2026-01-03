import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry/models/customer.dart';
import 'package:laundry/models/itemwise.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/models/item.dart';
import 'package:laundry/models/services.dart';
import 'package:laundry/screens/ip_config_dialog.dart';
import 'package:laundry/screens/licensekey.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';
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
  bool _isLoading = false;
  bool _hasFetched = false;
  final ApiService _apiService = ApiService();
  List<OrderReportModel> _orders = [];
  List<ItemWiseorderreportModel> _itemWise = [];

  List<ItemWiseorderreportModel> get _filteredItems {
    if (_serviceType == "All") return _itemWise;
    return _itemWise
        .where(
          (item) =>
              item.serviceType.toLowerCase() == _serviceType.toLowerCase(),
        )
        .toList();
  }

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
  String _selectedCustomer = "All";

  String? _selectedCustomerId;

  List<ServicesModel> _apiServices = [];
  List<ItemModel> _apiItems = [];
  List<CustomerModel> _customerName = [];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    final services = await _apiService.fetchServices();
    final items = await _apiService.fetchItems();
    final custDetails = await _apiService.fetchCustName();
    if (!mounted) return;
    setState(() {
      _apiServices = services;
      _apiItems = items;
      _customerName = custDetails;
    });

    if (_selectedService != "All" &&
        !_apiServices.any((e) => e.serviceName == _selectedService)) {
      _selectedService = "All";
    }

    if (_selectedItem != "All" &&
        !_apiItems.any((e) => e.serviceItemName == _selectedItem)) {
      _selectedItem = "All";
    }
    if (_selectedCustomer != "All" &&
        !_customerName.any((e) => e.customerName == _selectedCustomer)) {
      _selectedCustomer = "All";
    }
  }

  Future<void> applyFilterWithlicense() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final bool isActivated = await _apiService.checkLicenseStatus();
      if (!mounted) return;
      if (isActivated) {
        await _fetchData();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => ActivationRequiredScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("License Expired!!!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: redColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasFetched = true;
    });
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(_fromDate);
      final endDate = DateFormat('yyyy-MM-dd').format(_toDate);

      if (_isItemWise) {
        String serviceId = "All";
        if (_selectedService != "All") {
          final service = _apiServices.firstWhere(
            (e) => e.serviceName == _selectedService,
            orElse: () => ServicesModel(serviceId: 0, serviceName: "All"),
          );
          serviceId = service.serviceId == 0
              ? "All"
              : service.serviceId.toString();
        }

        String itemId = "All";
        if (_selectedItem != "All") {
          final item = _apiItems.firstWhere(
            (e) => e.serviceItemName == _selectedItem,
            orElse: () => ItemModel(serviceItemId: 0, serviceItemName: "All"),
          );
          itemId = item.serviceItemId == 0
              ? "All"
              : item.serviceItemId.toString();
        }

        final results = await _apiService.fetchItemWiseReport(
          startDate: startDate,
          endDate: endDate,
          orderStatus: _orderStatus,
          paymentStatus: _paymentStatus,
          deliveryStatus: _deliveryStatus,
          customerId: _selectedCustomer == "All" ? null : _selectedCustomerId,
          serviceName: serviceId,
          itemName: itemId,
          serviceType: "All",
        );
        setState(() => _itemWise = results);
      } else {
        final results = await _apiService.fetchOrderReport(
          startDate: startDate,
          endDate: endDate,
          orderStatus: _orderStatus,
          paymentStatus: _paymentStatus,
          deliveryStatus: _deliveryStatus,
          customerId: _selectedCustomer == "All" ? null : _selectedCustomerId,
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
    final deliveryCounts = buildDeliveryStatusCount();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildTitleBanner(),
              _buildFilterSection(),
              if (!_isLoading &&
                  _hasFetched &&
                  (_isItemWise ? _filteredItems.isEmpty : _orders.isEmpty)) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: Text(
                      "No Data for that particular date!!!",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                        color: blueColor,
                      ),
                    ),
                  ),
                ),
              ],
              if (_isItemWise &&
                  !_isLoading &&
                  _hasFetched &&
                  _filteredItems.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  color: Colors.brown,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        statusChip(
                          label: "All",
                          count: getTotalCount(),
                          color: whiteColor,
                        ),
                        statusChip(
                          label: "Processing",
                          count: deliveryCounts['processing'] ?? 0,
                          color: whiteColor,
                        ),
                        statusChip(
                          label: "Ready for Delivery",
                          count: deliveryCounts['ready for delivery'] ?? 0,
                          color: whiteColor,
                        ),
                        statusChip(
                          label: "Delivered",
                          count: deliveryCounts["delivered"] ?? 0,
                          color: whiteColor,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ],

              // ),
              _buildOrdersTable(),
              vertGap(10),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> buildDeliveryStatusCount() {
    final Map<String, int> counts = {};

    for (final item in _filteredItems) {
      final status = item.itemStatus.trim().toLowerCase();
      if (status.isEmpty) continue;

      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  int getTotalCount() => _filteredItems.map((e) => e.itemStatus).length;
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset("assets/wasla.png", height: 90, fit: BoxFit.contain),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const IpConfigDialog(),
              );
            },
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
              ),
              alignment: Alignment.center,
              child: Text(
                'IP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: whiteColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            tooltip: 'Configure IP Address',
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
                        _selectedCustomer = "All";
                        _customerController.clear();
                        _orderNoController.clear();
                        _hasFetched = false;
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
                      //
                      _buildDropdownFilter(
                        "Customer",
                        _selectedCustomer,
                        _customerName.isEmpty
                            ? ["All"]
                            : [
                                "All",
                                ..._customerName.map((e) => e.customerName),
                              ],
                        (v) {
                          setState(() {
                            _selectedCustomer = v!;
                            if (v == 'All') {
                              _selectedCustomerId = null;
                            } else {
                              final customer = _customerName.firstWhere(
                                (c) => c.customerName == v,
                                orElse: () => _customerName.first,
                              );
                              _selectedCustomerId = "${customer.customerId}";
                            }
                          });
                        },
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
                            onChanged: (v) => setState(() {
                              _isItemWise = v;
                              _hasFetched = false;
                            }),
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
              vertGap(16),
              const Divider(),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 25), // Label + Gap offset
                        _buildTypeButton(
                          "Normal",
                          Colors.green,
                          _serviceType == "Normal",
                        ),
                        const SizedBox(
                          height: 30,
                        ), // Aligns with Category label + gap
                        _buildTypeButton(
                          "Express",
                          Colors.red,
                          _serviceType == "Express",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdownFilter(
                          "Item:",
                          _selectedItem,
                          _apiItems.isEmpty
                              ? ["All"]
                              : [
                                  "All",
                                  ..._apiItems.map((e) => e.serviceItemName),
                                ],
                          (v) => setState(() => _selectedItem = v!),
                        ),
                        const SizedBox(height: 12),
                        _buildDropdownFilter(
                          "Category:",
                          _selectedService,
                          _apiServices.isEmpty
                              ? ["All"]
                              : [
                                  "All",
                                  ..._apiServices.map((e) => e.serviceName),
                                ],
                          (v) => setState(() => _selectedService = v!),
                        ),
                        const SizedBox(height: 12),
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

  Widget _buildDropdownFilter(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    final safeValue = options.contains(value) ? value : options.first;

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
              value: safeValue, // ✅ IMPORTANT
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              style: const TextStyle(fontSize: 13, color: Colors.black),
              onChanged: onChanged,
              items: options
                  .toSet() // ✅ avoid duplicate names
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
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

  Widget _buildTypeButton(String label, Color color, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_serviceType == label) {
            _serviceType = "All";
          } else {
            _serviceType = label;
          }
        });
      },
      child: Container(
        height: 40,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                  "${formatDate(order.orderDate)} / ${formatTime(order.orderDate)}",
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
                      _buildStatusBadge(
                        order.paymentStatus,
                        _getStatusColor(order.paymentStatus),
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
                      _buildStatusBadge(
                        order.orderStatus,
                        _getStatusColor(order.orderStatus),
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
                      _buildStatusBadge(
                        order.deliveryStatus,
                        _getStatusColor(order.deliveryStatus),
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

  Widget _buildFullCellStatus(
    String text,
    Color bgColor, {
    Color textColor = Colors.white,
  }) {
    return Container(
      constraints: const BoxConstraints.expand(),
      alignment: Alignment.center,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Align(
      alignment: Alignment.center, // or center
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(05),
        ),
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildItemWiseTable() {
    if (_filteredItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          dataRowMinHeight: 48,
          dataRowMaxHeight: 48,
          horizontalMargin: 0,
          columnSpacing: 0,
          headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade400),
            verticalInside: BorderSide(color: Colors.grey.shade400),
            right: BorderSide(color: Colors.grey.shade400),
            left: BorderSide(color: Colors.grey.shade400),
            top: BorderSide(color: Colors.grey.shade400),
            bottom: BorderSide(color: Colors.grey.shade400),
          ),
          columns: [
            _buildColumn("Order No"),
            _buildColumn("Date"),
            _buildColumn("Service"),
            _buildColumn("Type"),
            _buildColumn("Item"),
            _buildColumn("status"),
            _buildColumn("Customer"),
            _buildColumn("Mobile"),
            _buildColumn("Address"),
            _buildColumn("Payment"),
            _buildColumn("Order Status"),
            _buildColumn("Delivery Status"),
          ],
          rows: _filteredItems.map((item) {
            return DataRow(
              cells: [
                _buildDataCell(Text("${item.orderNo}")),
                _buildDataCell(
                  Text(
                    "${formatDate(item.orderDate)} ${formatTime(item.orderDate)}",
                  ),
                ),
                _buildDataCell(Text(item.serviceName)),
                DataCell(
                  _buildFullCellStatus(
                    item.serviceType,
                    _getServiceTypeColor(item.serviceType),
                  ),
                ),
                _buildDataCell(Text(item.item)),
                DataCell(
                  _buildFullCellStatus(
                    item.itemStatus,
                    _getItemColor(item.itemStatus),
                  ),
                ),
                _buildDataCell(Text(item.customerName)),
                _buildDataCell(Text(item.customerMobile)),
                _buildDataCell(
                  Text(
                    item.customerAddress.isEmpty
                        ? "Null"
                        : item.customerAddress,
                  ),
                ),
                DataCell(
                  _buildFullCellStatus(
                    item.paymentStatus,
                    _getStatusColor(item.paymentStatus),
                  ),
                ),
                DataCell(
                  _buildFullCellStatus(
                    item.orderStatus,
                    _getStatusColor(item.orderStatus),
                  ),
                ),
                DataCell(
                  _buildFullCellStatus(
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

  Color _getServiceTypeColor(String status) {
    switch (status.toLowerCase()) {
      case "express":
        return Colors.red;
      case "normal":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getItemColor(String status) {
    switch (status.toLowerCase()) {
      case "processing":
        return Colors.red;
      case "ready for delivery":
        return Colors.green;
      case "delivered":
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String formatTime(DateTime d) => DateFormat('h:mm a').format(d);

  Widget statusChip({
    required String label,
    required int count,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          // border: Border.all(color: Colors.black87, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _buildColumn(String label) {
    return DataColumn(
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  DataCell _buildDataCell(Widget child) {
    return DataCell(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: child,
      ),
    );
  }
}
