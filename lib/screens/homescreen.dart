import 'package:flutter/material.dart';
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
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 14));
  DateTime _toDate = DateTime.now();
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
    "Ready for Delivery",
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

  /// Generates the PDF document based on current table data
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    // Define fonts and styles
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    // 1. Determine which data to print
    final bool isItemReport = _isItemWise;
    final String title = isItemReport ? "Item-Wise Report" : "Order Report";
    final String dateRange =
        "${DateFormat('dd/MM/yyyy').format(_fromDate)} - ${DateFormat('dd/MM/yyyy').format(_toDate)}";

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
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Date: $dateRange",
                    style: const pw.TextStyle(fontSize: 14),
                  ),
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
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/laundry_report_${DateFormat('dd_MM_yyyy').format(DateTime.now())}.pdf',
      );
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Here is the Laundry Report.');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sharing PDF: $e"),
            duration: Duration(milliseconds: 900),
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
                    name:
                        'Laundry_Report_${DateFormat('dd_MM_yyyy').format(DateTime.now())}',
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
          orderNo: _orderNoController.text,
        );
        setState(() => _orders = results);
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
    });
  }

  @override
  Widget build(BuildContext context) {
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
                const HomeHeader(),
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
                  _buildItemsTable(items: _filteredItems)
                else
                  _buildOrderList(orders: _orders),
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
                          options: const ["All", "Paid", "Unpaid", "Partial"],
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
    return Autocomplete<String>(
      initialValue: TextEditingValue(
        text: _selectedCustomer == 'All' ? '' : _selectedCustomer,
      ),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.toLowerCase().trim();
        if (query.isEmpty) return ["All"];
        final matchingCustomers = _customerName
            .map((e) => e.customerName)
            .where((name) => name.toLowerCase().contains(query))
            .toList();

        if (query == 'all') return ["All", ...matchingCustomers];
        if (matchingCustomers.isEmpty) return const Iterable<String>.empty();
        return matchingCustomers;
      },
      onSelected: (String selection) {
        setState(() {
          _selectedCustomer = selection;
          _updateCustomerId();
        });
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            // Keep controller in sync if needed, or primarily rely on state
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
              onChanged: (value) {
                // Optional: Update state on every keystroke if needed
              },
              decoration: InputDecoration(
                labelText: "Customer name",
                hintText: "Search customer or type 'All'",
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
      optionsViewBuilder: (context, onSelected, Iterable<String> options) {
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
                  final isAllOption = option == "All";
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isAllOption ? Icons.select_all : Icons.person_outline,
                      size: 18,
                      color: isAllOption ? Colors.blue : Colors.grey.shade600,
                    ),
                    title: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isAllOption
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isAllOption ? Colors.blue : Colors.black87,
                      ),
                    ),
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
  Widget _buildOrderList({required List<OrderReportModel> orders}) {
    return Column(
      children: orders.map((order) => _buildOrderCard(order)).toList(),
    );
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
                  "${_formatDate(order.orderDate)} / ${_formatTime(order.orderDate)}",
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
    );
  }

  // --- Items Table Methods ---
  Widget _buildItemsTable({required List<ItemWiseorderreportModel> items}) {
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
              c.customerName.toLowerCase() == _selectedCustomer.toLowerCase(),
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
}
