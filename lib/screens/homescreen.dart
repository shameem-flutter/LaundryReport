import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/customer.dart';
import 'package:laundry/models/deliveryboy.dart';
import 'package:laundry/models/itemwise.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/models/item.dart';
import 'package:laundry/models/services.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/screens/homescreen_widgets/title_banner.dart';
import 'package:laundry/screens/ip_config_dialog.dart';
import 'package:laundry/screens/licensekey.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:laundry/providers/nav_provider.dart';
import 'package:laundry/providers/country_provider.dart';

class Homescreen extends ConsumerStatefulWidget {
  static const routeName = '/home';
  const Homescreen({super.key});

  @override
  ConsumerState<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends ConsumerState<Homescreen> {
  String _orderStatus = "All";
  String _paymentStatus = "All";
  String _deliveryStatus = "All";
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 14));
  DateTime _toDate = DateTime.now();
  bool _isItemWise = false;
  bool _isLoading = false;
  bool _hasFetched = false;
  final ApiService _apiService = ApiService();
  List<OrderReportModel> _orders = [];
  List<ItemWiseorderreportModel> _itemWise = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  int _pageSize = 20;

  List<ItemWiseorderreportModel> get _filteredItems {
    var items = _itemWise;

    // Filter by Service Type
    if (_serviceType != "All") {
      items = items
          .where(
            (item) =>
                item.serviceType.toLowerCase() == _serviceType.toLowerCase(),
          )
          .toList();
    }

    // Filter by Order Number (Client-Side Fallback)
    if (_orderNoController.text.isNotEmpty) {
      final inputOrderNo = _orderNoController.text.trim();
      items = items.where((item) {
        // Compare as string to be safe, or try parsing if item.orderNo is int
        return item.orderNo.toString() == inputOrderNo;
      }).toList();
    }

    return items;
  }

  // Controllers are not used in new design directly but keeping them if needed for further logic
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _orderNoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _orderStatusOption = [
    "All",
    "Finished",
    "Pending",
    "Cancelled",
  ];
  final List<String> _deliveryStatusOption = [
    "All",
    "Pending",
    "Partial",
    "Delivered",
  ];
  String _serviceType = "All";
  String _selectedService = "All";
  String _selectedItem = "All";
  String _selectedCustomer = "All";

  String? _selectedCustomerId;

  List<ServicesModel> _apiServices = [];
  List<ItemModel> _apiItems = [];
  List<CustomerModel> _customerName = [];
  List<DeliveryboyModel> _deliveryBoys = [];

  @override
  void initState() {
    super.initState();
    _loadFilterData();
  }

  String _getReportPdfName({String? orderNo}) {
    final fromStr = DateFormat('dd_MM_yyyy').format(_fromDate);
    final toStr = DateFormat('dd_MM_yyyy').format(_toDate);
    final dateRangeStr = '${fromStr}_to_$toStr';
    final targetOrderNo = orderNo ?? _orderNoController.text.trim();

    if (targetOrderNo.isNotEmpty) {
      return 'Order_${targetOrderNo}_$dateRangeStr';
    }
    return 'Laundry_Report_$dateRangeStr';
  }

  /// Generates the PDF document based on current table data
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    // Define fonts and styles
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    // 1. Determine which data to print
    final bool isItemReport = _isItemWise;
    final String inputOrderNo = _orderNoController.text.trim();
    final String title = inputOrderNo.isNotEmpty
        ? "Order #$inputOrderNo Report"
        : (isItemReport ? "Item-Wise Report" : "Order Report");
    final String dateRange =
        "${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}";

    var countryModel = ref.read(countryCodeProvider).value;
    if (countryModel == null ||
        (countryModel.companyName.isEmpty && countryModel.address.isEmpty)) {
      try {
        countryModel = await _apiService.getCachedCountryCode();
        countryModel ??= await _apiService.getCountrycode();
      } catch (_) {}
    }
    final companyName = countryModel?.companyName ?? '';
    final companyAddress = countryModel?.address ?? '';

    // 2. Build Data Rows
    final List<List<String>> tableData = [];

    // Define Headers
    final List<String> headers = isItemReport
        ? [
            'Order No',
            'Date',
            'Service',
            'Item',
            'Item Status',
            'Customer',
            'Mobile',
            'Payment',
            'OrderStatus',
            'Deliverstatus',
          ]
        : [
            'Order No',
            'Date',
            'Customer',
            'Mobile',
            'Address',
            'Entered By',
            'Payment Rec. By',
            'Payment',
            'Order Status',
            'Deliverystatus',
          ];

    tableData.add(headers);

    // Populate Rows
    if (isItemReport) {
      // _filteredItems.sort((a, b) => a.orderNo.compareTo(b.orderNo));
      final sortedItems = [..._filteredItems]
        ..sort((a, b) => a.orderNo.compareTo(b.orderNo));
      for (var item in sortedItems) {
        tableData.add([
          "${item.orderNo}",
          DateFormat('dd/MM/yy').format(item.orderDate),
          item.serviceName,
          "${item.item} (${item.serviceType})",
          item.itemStatus,
          item.customerName,
          item.customerMobile,
          item.paymentStatus,
          item.orderStatus,
          item.deliveryStatus,
        ]);
      }
    } else {
      // _orders.sort((a, b) => a.orderNo.compareTo(b.orderNo));
      final sortedOrders = [..._orders]
        ..sort((a, b) => a.orderNo.compareTo(b.orderNo));
      for (var order in sortedOrders) {
        tableData.add([
          "${order.orderNo}",
          DateFormat('dd/MM/yy').format(order.orderDate),
          order.customerName,
          order.customerMobile,
          order.customerAddress == "-" ? "" : order.customerAddress,
          order.enteredBy,
          order.paymentReceivedBy,
          order.paymentStatus,
          order.orderStatus,
          order.deliveryStatus,
        ]);
      }
    }

    // 3. Create PDF Page
    pdf.addPage(
      pw.MultiPage(
        pageFormat: format.landscape, // Landscape for better table fit
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        margin: const pw.EdgeInsets.all(10),
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyName.isNotEmpty
                                ? companyName.trim()
                                : "Century Laundry & Dry Cleaning",
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          if (companyAddress.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              companyAddress
                                  .replaceAll('\r\n', ', ')
                                  .replaceAll('\n', ', '),
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      pw.Text(
                        "Date: $dateRange",
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              headers: tableData.first,
              data: tableData.sublist(1),
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.8),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 10),
              columnWidths: {0: const pw.FixedColumnWidth(40)},
            ),

            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total Records: ${isItemReport ? _filteredItems.length : _orders.length}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _sharePdf(PdfPageFormat format) async {
    try {
      final pdfBytes = await _generatePdf(format);
      final fileName = '${_getReportPdfName()}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sharing PDF: $e"),
            duration: const Duration(milliseconds: 900),
          ),
        );
      }
    }
  }

  /// Trigger Printing or Sharing
  Future<void> _printOrShare() async {
    // Check if there is data to print
    if ((_isItemWise && _filteredItems.isEmpty) ||
        (!_isItemWise && _orders.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No data to print/share!"),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Print'),
                onTap: () async {
                  Navigator.pop(context);
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async =>
                        _generatePdf(format),
                    name: _getReportPdfName(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share via WhatsApp/Others'),
                onTap: () async {
                  Navigator.pop(context);
                  await _sharePdf(PdfPageFormat.a4.landscape);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadFilterData() async {
    final services = await _apiService.fetchServices();
    final items = await _apiService.fetchItems();
    final custDetails = await _apiService.fetchCustName();
    final deliveryBoys = await _apiService.deliveryBoy();
    if (!mounted) return;
    setState(() {
      _apiServices = services;
      _apiItems = items;
      _customerName = custDetails;
      _deliveryBoys = deliveryBoys;
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

  Future<void> _fetchData({bool isPageChange = false}) async {
    setState(() {
      _isLoading = true;
      _hasFetched = true;
      if (!isPageChange) {
        _currentPage = 1;
      }
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
            duration: Duration(seconds: 1),
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
          orderNo: _orderNoController.text,
          orderId: _orderNoController.text,
        );
        setState(() => _itemWise = results);
      } else {
        final response = await _apiService.fetchOrderReport(
          startDate: startDate,
          endDate: endDate,
          orderStatus: _orderStatus,
          paymentStatus: _paymentStatus,
          deliveryStatus: _deliveryStatus,
          customerId: _selectedCustomer == "All" ? null : _selectedCustomerId,
          orderNo: _orderNoController.text,
          page: _currentPage,
          pageSize: _pageSize,
        );
        setState(() {
          _orders = response.results;
          _totalCount = response.count;
          _totalPages = response.totalPages;
          _currentPage = response.page;
          _pageSize = response.pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1400),
          ),
        );
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
      _currentPage = 1;
      _totalPages = 1;
      _totalCount = 0;
      _pageSize = 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    final countryCodeAsync = ref.watch(countryCodeProvider);
    final currencyCode = countryCodeAsync.value?.currencyCode ?? '';
    final deliveryCounts = buildDeliveryStatusCount();
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "fab_homescreen",
        onPressed: _printOrShare,
        backgroundColor: primaryColor,
        icon: Icon(Icons.print, color: whiteColor),
        label: Text("Print/Share", style: TextStyle(color: whiteColor)),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                HomeHeader(
                  showBack: true,
                  onBack: () {
                    ref.read(navProvider.notifier).state = NavIndex.dashboard;
                  },
                ),
                const TitleBanner(),
                _buildFilterSection(),
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
                  _buildSummaryRow(
                    totalCount: getTotalCount(),
                    deliveryCounts: deliveryCounts,
                  ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_isItemWise)
                  _buildItemsTable(items: _filteredItems, currencyCode: currencyCode)
                else
                  _buildOrderList(orders: _orders, currencyCode: currencyCode),
                vertGap(60),
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

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                _fetchData();
                              }
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
                  horiGap(18),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Reset"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: whiteColor,
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              vertGap(16),

              /// FILTERS
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerSearch(),
                  vertGap(10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDatePickerField(
                          label: "From:",
                          date: _fromDate,
                          onChanged: (d) => setState(() => _fromDate = d),
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: _buildDatePickerField(
                          label: "To:",
                          date: _toDate,
                          onChanged: (d) => setState(() => _toDate = d),
                        ),
                      ),
                    ],
                  ),
                  vertGap(12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFilter(
                          label: "Order Status:",
                          value: _orderStatus,
                          options: _orderStatusOption,
                          onChanged: (v) => setState(() => _orderStatus = v!),
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: _buildDropdownFilter(
                          label: "Payment Status:",
                          value: _paymentStatus,
                          options: const ["All", "Paid", "Not Paid"],
                          onChanged: (v) => setState(() => _paymentStatus = v!),
                        ),
                      ),
                    ],
                  ),
                  vertGap(10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownFilter(
                          label: "Delivery Status:",
                          value: _deliveryStatus,
                          options: _deliveryStatusOption,
                          onChanged: (v) =>
                              setState(() => _deliveryStatus = v!),
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Order No:",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            vertGap(6),
                            TextFormField(
                              controller: _orderNoController,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  vertGap(10),
                  Row(
                    children: [
                      Text(
                        "Item-Wise Report:",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      Switch(
                        value: _isItemWise,
                        onChanged: (v) {
                          setState(() {
                            _isItemWise = v;
                            _hasFetched = false;
                          });
                        },
                        activeThumbColor: const Color(0xFF0D47A1),
                      ),
                    ],
                  ),
                  vertGap(05),
                ],
              ),

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
                          const SizedBox(height: 25),
                          _buildTypeButton(
                            label: "Normal",
                            color: Colors.green,
                            isActive: _serviceType == "Normal",
                            onTap: () => setState(() {
                              _serviceType = _serviceType == "Normal"
                                  ? "All"
                                  : "Normal";
                            }),
                          ),
                          const SizedBox(height: 30),
                          _buildTypeButton(
                            label: "Express",
                            color: Colors.red,
                            isActive: _serviceType == "Express",
                            onTap: () => setState(() {
                              _serviceType = _serviceType == "Express"
                                  ? "All"
                                  : "Express";
                            }),
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
                            label: "Item:",
                            value: _selectedItem,
                            options: _apiItems.isEmpty
                                ? ["All"]
                                : [
                                    "All",
                                    ..._apiItems.map((e) => e.serviceItemName),
                                  ],
                            onChanged: (v) =>
                                setState(() => _selectedItem = v!),
                          ),
                          const SizedBox(height: 12),
                          _buildDropdownFilter(
                            label: "Category:",
                            value: _selectedService,
                            options: _apiServices.isEmpty
                                ? ["All"]
                                : [
                                    "All",
                                    ..._apiServices.map((e) => e.serviceName),
                                  ],
                            onChanged: (v) =>
                                setState(() => _selectedService = v!),
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
      ),
    );
  }

  Widget _buildCustomerSearch() {
    return Autocomplete<CustomerModel>(
      displayStringForOption: (CustomerModel option) => option.customerName,
      initialValue: TextEditingValue(
        text: _selectedCustomer == 'All' ? '' : _selectedCustomer,
      ),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.toLowerCase().trim();

        if (query.isEmpty) return const Iterable<CustomerModel>.empty();
        final matchingCustomers = _customerName
            .where(
              (c) =>
                  c.customerName.toLowerCase().contains(query) ||
                  c.mobile.toLowerCase().contains(query),
            )
            .toList();

        if (matchingCustomers.isEmpty) {
          return const Iterable<CustomerModel>.empty();
        }
        return matchingCustomers;
      },
      onSelected: (CustomerModel selection) {
        setState(() {
          _selectedCustomer = selection.customerName;
          _selectedCustomerId = selection.customerId.toString();
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  setState(() {
                    _selectedCustomer = "All";
                    _selectedCustomerId = null;
                  });
                } else {
                  setState(() {
                    _selectedCustomer = value;
                    _updateCustomerId();
                  });
                }
              },
              decoration: InputDecoration(
                labelText: "Customer name or phone",
                hintText: "Search customer by name or phone",
                labelStyle: const TextStyle(color: blackColor),
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                        onPressed: () {
                          textEditingController.clear();
                          setState(() {
                            _selectedCustomer = "All";
                            _selectedCustomerId = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.2,
                  ),
                ),
              ),
            );
          },
      optionsViewBuilder: (
        context,
        onSelected,
        Iterable<CustomerModel> options,
      ) {
        if (options.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.42,
                maxHeight: 250,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    title: Text(
                      option.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: option.mobile.isNotEmpty
                        ? Text(
                            option.mobile,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          )
                        : null,
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Order List Methods ---
  Widget _buildOrderList({
    required List<OrderReportModel> orders,
    required String currencyCode,
  }) {
    return Column(
      children: [
        ...orders.map((order) => _buildOrderCard(order, currencyCode)),
        if (orders.isNotEmpty || _totalCount > 0)
          _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    final startItem =
        _totalCount == 0 ? 0 : ((_currentPage - 1) * _pageSize) + 1;
    final endItem = (_currentPage * _pageSize) > _totalCount
        ? _totalCount
        : (_currentPage * _pageSize);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          return Flex(
            direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _totalCount > 0
                    ? "Showing $startItem-$endItem of $_totalCount orders"
                    : "No orders",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              if (isSmallScreen) const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentPage > 1 && !_isLoading
                        ? () {
                            setState(() => _currentPage--);
                            _fetchData(isPageChange: true);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text("Prev"),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade800,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Page $_currentPage of $_totalPages",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _currentPage < _totalPages && !_isLoading
                        ? () {
                            setState(() => _currentPage++);
                            _fetchData(isPageChange: true);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right, size: 18),
                    label: const Text("Next"),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade800,
                      disabledBackgroundColor: Colors.grey.shade100,
                      disabledForegroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderReportModel order, String currencyCode) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetailsSheet(context, order, currencyCode),
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
                  const SizedBox(width: 8),
                  Text(
                    "Order #${order.orderNo}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),

                const Spacer(),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  "${_formatDate(order.orderDate)} ${_formatTime(order.orderDate)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: "Customer",
              value: order.customerName,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: "Mobile",
              value: order.customerMobile,
            ),
            if (order.customerAddress.isNotEmpty &&
                order.customerAddress != "-") ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.location_on_outlined,
                label: "Address",
                value: order.customerAddress,
              ),
            ],
            if (order.enteredBy.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.badge_outlined,
                label: "Entered By",
                value: order.enteredBy,
              ),
            ],
            if (order.paymentReceivedBy.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                icon: Icons.receipt_long_outlined,
                label: "Payment Received By",
                value: order.paymentReceivedBy,
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
                        status: order.paymentStatus,
                        color: _getStatusColor(order.paymentStatus),
                        onStatusChanged: null,
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
                        status: order.orderStatus,
                        color: _getStatusColor(order.orderStatus),
                        onStatusChanged: (newStatus) {
                          _showConfirmationDialog(context, newStatus, () {
                            _updateOrderStatus("${order.orderId}", newStatus);
                          });
                        },
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
                        status: order.deliveryStatus,
                        color: _getStatusColor(order.deliveryStatus),
                        onStatusChanged: (newStatus) {
                          if (newStatus == "Delivered") {
                            _showDeliveryBoySelectionDialog(context, (
                              deliveryBoy,
                            ) {
                              _updateDeliveryStatus(
                                orderId: "${order.orderId}",
                                deliveryStage: newStatus,
                                deliveredBy: deliveryBoy.userName,
                              );
                            });
                          } else {
                            _showConfirmationDialog(context, newStatus, () {
                              _updateDeliveryStatus(
                                orderId: "${order.orderId}",
                                deliveryStage: newStatus,
                              );
                            });
                          }
                        },
                        menuItems: [
                          "Processing",
                          "Ready for Delivery",
                          "Delivered",
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  // --- Items Table Methods ---
  Widget _buildItemsTable({
    required List<ItemWiseorderreportModel> items,
    required String currencyCode,
  }) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
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
          rows: items.map((item) {
            return DataRow(
              onSelectChanged: (_) {
                final matchingOrder = _orders.firstWhere(
                  (o) => o.orderNo == item.orderNo,
                  orElse: () => OrderReportModel(
                    orderId: item.orderNo,
                    orderNo: item.orderNo,
                    orderDate: item.orderDate,
                    customerName: item.customerName,
                    customerMobile: item.customerMobile,
                    customerAddress: item.customerAddress,
                    paymentStatus: item.paymentStatus,
                    deliveryStatus: item.deliveryStatus,
                    orderStatus: item.orderStatus,
                    totalDiscount: 0,
                    grandTotal: 0,
                    enteredBy: '',
                    paymentReceivedBy: '',
                    orderItems: [],
                  ),
                );
                _showOrderDetailsSheet(context, matchingOrder, currencyCode);
              },
              cells: [
                _buildDataCell(Text("${item.orderNo}")),
                _buildDataCell(
                  Text(
                    "${_formatDate(item.orderDate)} ${_formatTime(item.orderDate)}",
                  ),
                ),
                _buildDataCell(Text(item.serviceName)),
                DataCell(
                  _buildFullCellStatus(
                    text: item.serviceType,
                    bgColor: _getServiceTypeColor(item.serviceType),
                  ),
                ),
                _buildDataCell(Text(item.item)),
                DataCell(
                  _buildFullCellStatus(
                    text: item.itemStatus,
                    bgColor: _getItemColor(item.itemStatus),
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
                    text: item.paymentStatus,
                    bgColor: _getStatusColor(item.paymentStatus),
                  ),
                ),
                DataCell(
                  _buildFullCellStatus(
                    text: item.orderStatus,
                    bgColor: _getStatusColor(item.orderStatus),
                  ),
                ),
                DataCell(
                  _buildFullCellStatus(
                    text: item.deliveryStatus,
                    bgColor: _getStatusColor(item.deliveryStatus),
                  ),
                ),
              ],
            );
          }).toList(),
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

  // --- Common Widget Builders ---

  // --- Summary Row Method ---
  Widget _buildSummaryRow({
    required int totalCount,
    required Map<String, int> deliveryCounts,
  }) {
    return Container(
      width: double.infinity,
      color: Colors.brown,
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusChip(
              label: "All",
              count: totalCount,
              color: whiteColor,
            ),
            _buildStatusChip(
              label: "Processing",
              count: deliveryCounts['processing'] ?? 0,
              color: whiteColor,
            ),
            _buildStatusChip(
              label: "Ready for Delivery",
              count: deliveryCounts['ready for delivery'] ?? 0,
              color: whiteColor,
            ),
            _buildStatusChip(
              label: "Delivered",
              count: deliveryCounts["delivered"] ?? 0,
              color: whiteColor,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _updateCustomerId() {
    if (_selectedCustomer == 'All' || _selectedCustomer.isEmpty) {
      _selectedCustomerId = null;
    } else {
      try {
        final customer = _customerName.firstWhere(
          (c) =>
              c.customerName.toLowerCase() == _selectedCustomer.toLowerCase() ||
              c.mobile.toLowerCase() == _selectedCustomer.toLowerCase() ||
              "${c.customerName} (${c.mobile})".toLowerCase() ==
                  _selectedCustomer.toLowerCase(),
        );
        _selectedCustomerId = "${customer.customerId}";
      } catch (e) {
        _selectedCustomerId = "-1";
      }
    }
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
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
              value: safeValue,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              style: const TextStyle(fontSize: 13, color: Colors.black),
              onChanged: onChanged,
              items: options
                  .toSet()
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

  Widget _buildDatePickerField({
    required String label,
    required DateTime date,
    required Function(DateTime) onChanged,
  }) {
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

  Widget _buildTypeButton({
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
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

  Widget _buildStatusBadge({
    required String status,
    required Color color,
    Function(String)? onStatusChanged,
    List<String> menuItems = const ["Finished", "Pending", "Cancelled"],
  }) {
    Widget badgeContainer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
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
    );

    return Align(
      alignment: Alignment.center,
      child: onStatusChanged != null
          ? PopupMenuButton<String>(
              offset: const Offset(0, 40),
              itemBuilder: (context) => menuItems.map((String value) {
                return PopupMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onSelected: (String selectedValue) {
                onStatusChanged(selectedValue);
              },
              child: badgeContainer,
            )
          : badgeContainer,
    );
  }

  Widget _buildFullCellStatus({
    required String text,
    required Color bgColor,
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

  Widget _buildStatusChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "paid":
        return Colors.green.shade800;
      case "unpaid":
        return Colors.red;
      case "finished":
        return Colors.blue;
      case "pending":
        return Colors.orange;
      case "delivered":
        return Colors.green.shade800;
      case "cancelled":
        return redColor;
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

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _formatTime(DateTime d) => DateFormat('h:mm a').format(d);

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await _apiService.updateOrderStatus(orderId: orderId, status: newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Order status updated successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 800),
          ),
        );
        await _fetchData(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: Colors.red,
            duration: Duration(milliseconds: 1400),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String newStatus,
    VoidCallback onConfirm,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Action'),
          content: Text(
            'Are you sure you want to change status to "$newStatus"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateDeliveryStatus({
    required String orderId,
    required String deliveryStage,
    String? deliveredBy,
  }) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _apiService.updateDeliveryStatus(
        orderId: orderId,
        deliveryStage: deliveryStage,
        deliveredBy: deliveredBy,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Updated DeliveryStatus"),
            backgroundColor: Colors.green,
            duration: Duration(milliseconds: 800),
          ),
        );
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to Updated DeliveryStatus"),
            duration: Duration(milliseconds: 900),
            backgroundColor: redColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeliveryBoySelectionDialog(
    BuildContext context,
    Function(DeliveryboyModel) onSelected,
  ) {
    if (_deliveryBoys.isEmpty) {
      _fetchDeliveryBoysAndShow(context, onSelected);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Delivery Boy"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _deliveryBoys.length,
              itemBuilder: (context, index) {
                final boy = _deliveryBoys[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(boy.userName),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(boy);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchDeliveryBoysAndShow(
    BuildContext context,
    Function(DeliveryboyModel) onSelected,
  ) async {
    final boys = await _apiService.deliveryBoy();
    if (!mounted) return;

    setState(() {
      _deliveryBoys = boys;
    });
    if (boys.isNotEmpty) {
      if (context.mounted) _showDeliveryBoySelectionDialog(context, onSelected);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No delivery boys found"),
            duration: Duration(milliseconds: 1000),
            backgroundColor: redColor,
          ),
        );
      }
    }
  }

  Future<List<OrderItem>> _ensureOrderItems(OrderReportModel order) async {
    if (order.orderItems.isNotEmpty) {
      return order.orderItems;
    }
    try {
      final itemWiseResults = await _apiService.fetchItemWiseReport(
        startDate: DateFormat('yyyy-MM-dd').format(order.orderDate),
        endDate: DateFormat('yyyy-MM-dd').format(order.orderDate),
        orderStatus: "All",
        paymentStatus: "All",
        deliveryStatus: "All",
        orderNo: "${order.orderNo}",
      );
      return itemWiseResults
          .map(
            (item) => OrderItem(
              serviceNameX: item.serviceName,
              serviceType: item.serviceType,
              serviceItemNameX: item.item,
              unitRate: 0.0,
              qty: 1.0,
              discount: 0.0,
              lineTotal: 0.0,
              itemStatus: item.itemStatus,
              extraNote: '',
              itemDeliveredBy: '',
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Uint8List> _generateSingleOrderReceiptPdf(
    PdfPageFormat format,
    OrderReportModel order,
    List<OrderItem> items,
    String currencyCode,
    String companyName,
    String companyAddress,
    String countryName,
  ) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    final String dateStr =
        "${_formatDate(order.orderDate)} ${_formatTime(order.orderDate)}";

    // Calculate total quantity across items
    final double totalQty = items.fold(0.0, (sum, item) => sum + item.qty);
    final String totalQtyStr =
        totalQty.truncateToDouble() == totalQty
            ? totalQty.toInt().toString()
            : totalQty.toStringAsFixed(2);

    // Roll 80mm thermal receipt format
    final pageFormat = PdfPageFormat.roll80.copyWith(
      marginTop: 10,
      marginBottom: 10,
      marginLeft: 8,
      marginRight: 8,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Info (Centered)
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      companyName.isNotEmpty
                          ? companyName.trim()
                          : "Century Laundry & Dry Cleaning",
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    if (companyAddress.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      ...companyAddress
                          .replaceAll('\r\n', '\n')
                          .split('\n')
                          .map(
                            (line) => pw.Text(
                              line.trim(),
                              style: const pw.TextStyle(fontSize: 7.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                    ] else if (countryName.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        countryName,
                        style: const pw.TextStyle(fontSize: 8),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Invoice",
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      "Outlet Copy",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 2),

              // Order Number Box
              pw.Center(
                child: pw.Text(
                  "Order #: ${order.orderNo}",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // Date & Customer Details
              pw.Text(
                "Order Date: $dateStr",
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                "Customer: ${order.customerName}",
                style: const pw.TextStyle(fontSize: 8),
              ),
              if (order.customerMobile.isNotEmpty) ...[
                pw.Text(
                  order.customerMobile,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // Table Headers
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      "Service",
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Container(
                    width: 25,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      "Qty",
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Container(
                    width: 35,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      "Price",
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Container(
                    width: 40,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(
                      "Amount",
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // Items Breakdown
              ...items.map((item) {
                final qtyStr =
                    item.qty.truncateToDouble() == item.qty
                        ? item.qty.toInt().toString()
                        : item.qty.toStringAsFixed(2);
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Line 1: Service Name + Service Type
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          item.serviceNameX,
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        if (item.serviceType.isNotEmpty)
                          pw.Text(
                            item.serviceType,
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    // Line 2: Item Name (uppercase) + Qty + Price + Amount
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            item.serviceItemNameX.toUpperCase(),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Container(
                          width: 25,
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            qtyStr,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Container(
                          width: 35,
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            item.unitRate.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Container(
                          width: 40,
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            item.lineTotal.toStringAsFixed(2),
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                  ],
                );
              }),

              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // Total Qty
              pw.Text(
                "Total Qty: $totalQtyStr",
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),

              // Total Amount
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Total\nAmount",
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    order.grandTotal.toStringAsFixed(2),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.black),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _shareSingleOrderPdf(
    OrderReportModel order,
    String currencyCode,
  ) async {
    try {
      final countryModel = ref.read(countryCodeProvider).value;
      final companyName = countryModel?.companyName ?? '';
      final companyAddress = countryModel?.address ?? '';
      final countryName = countryModel?.country ?? '';
      final items = await _ensureOrderItems(order);
      final pdfBytes = await _generateSingleOrderReceiptPdf(
        PdfPageFormat.a4,
        order,
        items,
        currencyCode,
        companyName,
        companyAddress,
        countryName,
      );
      final fileName =
          '${_getReportPdfName(orderNo: order.orderNo.toString())}.pdf';

      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sharing receipt: $e"),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }

  Future<void> _printSingleOrderPdf(
    OrderReportModel order,
    String currencyCode,
  ) async {
    try {
      final countryModel = ref.read(countryCodeProvider).value;
      final companyName = countryModel?.companyName ?? '';
      final companyAddress = countryModel?.address ?? '';
      final countryName = countryModel?.country ?? '';
      final items = await _ensureOrderItems(order);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async =>
            _generateSingleOrderReceiptPdf(
              format,
              order,
              items,
              currencyCode,
              companyName,
              companyAddress,
              countryName,
            ),
        name: _getReportPdfName(orderNo: order.orderNo.toString()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error printing receipt: $e"),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }

  void _showOrderDetailsSheet(
    BuildContext context,
    OrderReportModel order,
    String currencyCode,
  ) {
    final countryModel = ref.read(countryCodeProvider).value;
    final companyName = countryModel?.companyName ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              final currencySuffix =
                  currencyCode.isNotEmpty ? ' $currencyCode' : '';
              return Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header Bar with Company Name & Order No
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (companyName.isNotEmpty)
                                  Text(
                                    companyName.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                Text(
                                  "Order #${order.orderNo}",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${_formatDate(order.orderDate)} ${_formatTime(order.orderDate)}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Content List
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      children: [
                        // Customer Details Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CUSTOMER DETAILS",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildInfoRow(
                                icon: Icons.person_outline,
                                label: "Name",
                                value: order.customerName,
                              ),
                              const SizedBox(height: 6),
                              _buildInfoRow(
                                icon: Icons.phone_outlined,
                                label: "Mobile",
                                value: order.customerMobile,
                              ),
                              if (order.customerAddress.isNotEmpty &&
                                  order.customerAddress != "-") ...[
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: "Address",
                                  value: order.customerAddress,
                                ),
                              ],
                              if (order.enteredBy.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  icon: Icons.badge_outlined,
                                  label: "Entered By",
                                  value: order.enteredBy,
                                ),
                              ],
                              if (order.paymentReceivedBy.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  icon: Icons.receipt_long_outlined,
                                  label: "Payment Rec. By",
                                  value: order.paymentReceivedBy,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Order Statuses & Total
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildMiniStatusColumn(
                                    "Payment",
                                    order.paymentStatus,
                                    _getStatusColor(order.paymentStatus),
                                  ),
                                  _buildMiniStatusColumn(
                                    "Order Status",
                                    order.orderStatus,
                                    _getStatusColor(order.orderStatus),
                                  ),
                                  _buildMiniStatusColumn(
                                    "Delivery",
                                    order.deliveryStatus,
                                    _getStatusColor(order.deliveryStatus),
                                  ),
                                ],
                              ),
                              if (order.paymentMode.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Text(
                                      "Payment Mode: ",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    Expanded(
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: order.paymentMode.map((pm) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "${pm.paymentModeName}: ${pm.amount.toStringAsFixed(2)}$currencySuffix",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade900,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (order.grandTotal > 0 ||
                                  order.totalDiscount > 0) ...[
                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                if (order.totalDiscount > 0)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Total Discount:",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Text(
                                        "${order.totalDiscount.toStringAsFixed(2)}$currencySuffix",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (order.grandTotal > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Grand Total:",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${order.grandTotal.toStringAsFixed(2)}$currencySuffix",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Order Items Section
                        Row(
                          children: [
                            Icon(
                              Icons.cleaning_services_outlined,
                              size: 18,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "ORDER ITEMS",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (order.orderItems.isNotEmpty)
                          ...order.orderItems.map(
                            (item) => _buildOrderItemCard(item, currencySuffix),
                          )
                        else
                          FutureBuilder<List<ItemWiseorderreportModel>>(
                            future: _apiService.fetchItemWiseReport(
                              startDate: DateFormat('yyyy-MM-dd').format(order.orderDate),
                              endDate: DateFormat('yyyy-MM-dd').format(order.orderDate),
                              orderStatus: "All",
                              paymentStatus: "All",
                              deliveryStatus: "All",
                              orderNo: "${order.orderNo}",
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "No item details available",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: snapshot.data!
                                    .map(
                                      (item) => _buildItemWiseCard(item),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  // Bottom Action Bar (Print & Share PDF Buttons)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _printSingleOrderPdf(order, currencyCode),
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text("Print Receipt"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryColor,
                              side: BorderSide(color: primaryColor),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _shareSingleOrderPdf(order, currencyCode),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text("Share Receipt"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366), // WhatsApp Green / Modern Action Color
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMiniStatusColumn(String title, String status, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
        ),
      ],
    );
  }

  Widget _buildOrderItemCard(OrderItem item, String currencySuffix) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "${item.serviceItemNameX} (${item.serviceNameX})",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getServiceTypeColor(item.serviceType),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.serviceType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Qty: ${item.qty.toStringAsFixed(item.qty.truncateToDouble() == item.qty ? 0 : 2)}  ×  ${item.unitRate.toStringAsFixed(2)}$currencySuffix",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                "${item.lineTotal.toStringAsFixed(2)}$currencySuffix",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (item.extraNote.isNotEmpty || item.itemStatus.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (item.itemStatus.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getItemColor(item.itemStatus).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.itemStatus,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getItemColor(item.itemStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (item.extraNote.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Note: ${item.extraNote}",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemWiseCard(ItemWiseorderreportModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${item.item} (${item.serviceName})",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Status: ${item.itemStatus}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _getServiceTypeColor(item.serviceType),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.serviceType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
