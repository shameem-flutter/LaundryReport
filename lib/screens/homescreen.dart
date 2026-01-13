import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/customer.dart';
import 'package:laundry/models/itemwise.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/models/item.dart';
import 'package:laundry/models/services.dart';
import 'package:laundry/screens/homescreen_widgets/filter_section.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/screens/homescreen_widgets/items_table.dart';
import 'package:laundry/screens/homescreen_widgets/orders_list.dart';
import 'package:laundry/screens/homescreen_widgets/summary_row.dart';
import 'package:laundry/screens/homescreen_widgets/title_banner.dart';
import 'package:laundry/screens/ip_config_dialog.dart';
import 'package:laundry/screens/licensekey.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';

class Homescreen extends StatefulWidget {
  static const routeName = '/home';
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

  // Controllers are not used in new design directly but keeping them if needed for further logic
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
    if (LicenseState.isVerified) {
      await _fetchData();
      return;
    }
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
      final bool isActivated = await _apiService.checkLicenseStatus();
      if (!mounted) return;
      if (!isActivated) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('License is not activated'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: redColor,
          ),
        );
        return;
      }
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

  void _resetFilters() {
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
  }

  @override
  Widget build(BuildContext context) {
    final deliveryCounts = buildDeliveryStatusCount();
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const HomeHeader(),
                const TitleBanner(),
                FilterSection(
                  isLoading: _isLoading,
                  onApplyFilter: _fetchData,
                  onReset: _resetFilters,
                  fromDate: _fromDate,
                  toDate: _toDate,
                  onFromDateChanged: (d) => setState(() => _fromDate = d),
                  onToDateChanged: (d) => setState(() => _toDate = d),
                  selectedCustomer: _selectedCustomer,
                  customerNames: _customerName,
                  onCustomerChanged: (v) {
                    setState(() {
                      _selectedCustomer = v ?? "";
                      if (_selectedCustomer == 'All' ||
                          _selectedCustomer.isEmpty) {
                        _selectedCustomerId = null;
                      } else {
                        try {
                          final customer = _customerName.firstWhere(
                            (c) =>
                                c.customerName.toLowerCase() ==
                                _selectedCustomer.toLowerCase(),
                          );
                          _selectedCustomerId = "${customer.customerId}";
                        } catch (e) {
                          _selectedCustomerId = "-1";
                        }
                      }
                    });
                  },
                  orderStatus: _orderStatus,
                  paymentStatus: _paymentStatus,
                  deliveryStatus: _deliveryStatus,
                  statusOptions: _statusOptions,
                  onOrderStatusChanged: (v) =>
                      setState(() => _orderStatus = v!),
                  onPaymentStatusChanged: (v) =>
                      setState(() => _paymentStatus = v!),
                  onDeliveryStatusChanged: (v) =>
                      setState(() => _deliveryStatus = v!),
                  isItemWise: _isItemWise,
                  onIsItemWiseChanged: (v) {
                    setState(() {
                      _isItemWise = v;
                      _hasFetched = false;
                    });
                  },
                  serviceType: _serviceType,
                  onTapNormal: () => setState(() {
                    _serviceType = _serviceType == "Normal" ? "All" : "Normal";
                  }),
                  onTapExpress: () => setState(() {
                    _serviceType = _serviceType == "Express"
                        ? "All"
                        : "Express";
                  }),
                  selectedItem: _selectedItem,
                  apiItems: _apiItems,
                  onItemChanged: (v) => setState(() => _selectedItem = v!),
                  selectedService: _selectedService,
                  apiServices: _apiServices,
                  onServiceChanged: (v) =>
                      setState(() => _selectedService = v!),
                ),
                if (!_isLoading &&
                    _hasFetched &&
                    (_isItemWise
                        ? _filteredItems.isEmpty
                        : _orders.isEmpty)) ...[
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
                    _filteredItems.isNotEmpty)
                  SummaryRow(
                    totalCount: getTotalCount(),
                    deliveryCounts: deliveryCounts,
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_isItemWise)
                  ItemsTable(items: _filteredItems)
                else
                  OrderList(orders: _orders),
                vertGap(10),
              ],
            ),
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
}
