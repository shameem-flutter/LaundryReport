import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:laundry/models/customer.dart';
import 'package:laundry/models/deliveryboy.dart';
import 'package:laundry/models/itemwise.dart';
import 'package:laundry/models/orderreport.dart';
import 'package:laundry/models/item.dart';
import 'package:laundry/models/services.dart';
import 'package:laundry/models/order_summary_report_model.dart';
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
  String _selectedPaymentMode = "All";
  final List<String> _paymentModeOptions = const [
    "All",
    "Cash",
    "Card",
    "Credit",
    "Cash,Card",
  ];
  DateTime _fromDate = DateTime.now().subtract(Duration(days: 14));
  DateTime _toDate = DateTime.now();
  bool _isItemWise = false;
  bool _isProductSummary = false;
  OrderSummaryReportResponse? _orderSummaryReport;
  bool _isLoading = false;
  bool _hasFetched = false;
  final ApiService _apiService = ApiService();
  List<OrderReportModel> _orders = [];
  List<ItemWiseorderreportModel> _itemWise = [];
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  int _pageSize = 20;

  List<OrderReportModel> get _filteredOrders {
    var items = _orders;

    if (_paymentStatus != "All") {
      final filter = _paymentStatus.trim().toLowerCase();
      items = items.where((order) {
        final status = order.paymentStatus.trim().toLowerCase();
        if (filter == "paid") {
          return status == "paid";
        } else if (filter == "not paid") {
          return status == "not paid" || status == "unpaid";
        }
        return status == filter;
      }).toList();
    }

    if (_orderStatus != "All") {
      final filter = _orderStatus.trim().toLowerCase();
      items = items
          .where((order) => order.orderStatus.trim().toLowerCase() == filter)
          .toList();
    }

    if (_deliveryStatus != "All") {
      final filter = _deliveryStatus.trim().toLowerCase();
      items = items
          .where((order) => order.deliveryStatus.trim().toLowerCase() == filter)
          .toList();
    }

    return items;
  }

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

    // Filter by Payment Status
    if (_paymentStatus != "All") {
      final filter = _paymentStatus.trim().toLowerCase();
      items = items.where((item) {
        final status = item.paymentStatus.trim().toLowerCase();
        if (filter == "paid") {
          return status == "paid";
        } else if (filter == "not paid") {
          return status == "not paid" || status == "unpaid";
        }
        return status == filter;
      }).toList();
    }

    // Filter by Order Status
    if (_orderStatus != "All") {
      final filter = _orderStatus.trim().toLowerCase();
      items = items
          .where((item) => item.orderStatus.trim().toLowerCase() == filter)
          .toList();
    }

    // Filter by Delivery Status
    if (_deliveryStatus != "All") {
      final filter = _deliveryStatus.trim().toLowerCase();
      items = items
          .where((item) => item.deliveryStatus.trim().toLowerCase() == filter)
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
    _fetchData();
  }

  String _getReportPdfName({String? orderNo}) {
    final fromStr = DateFormat('dd_MM_yyyy').format(_fromDate);
    final toStr = DateFormat('dd_MM_yyyy').format(_toDate);
    final dateRangeStr = '${fromStr}_to_$toStr';
    final targetOrderNo = orderNo ?? _orderNoController.text.trim();

    if (targetOrderNo.isNotEmpty) {
      return 'Order_${targetOrderNo}_$dateRangeStr';
    }
    if (_isProductSummary) {
      return 'Orders_Summary_$dateRangeStr';
    }
    return _isItemWise
        ? 'Item_Wise_Report_$dateRangeStr'
        : 'Laundry_Report_$dateRangeStr';
  }

  /// Generates the PDF document based on current table data
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    // Define fonts and styles with offline fallback
    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.poppinsRegular();
      fontBold = await PdfGoogleFonts.poppinsBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // 1. Determine which data to print
    final bool isProductReport = _isProductSummary;
    final bool isItemReport = _isItemWise;
    final String inputOrderNo = _orderNoController.text.trim();
    final String title = inputOrderNo.isNotEmpty
        ? "Order #$inputOrderNo Report"
        : (isProductReport
            ? "Orders Summary Report"
            : (isItemReport ? "Item-Wise Report" : "Order Report"));
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
    final List<String> headers = isProductReport
        ? [
            '#',
            'Order No',
            'Date',
            'Customer',
            'Mobile',
            'Order Qty',
            'Total Amt',
            'Discount (%)',
            'Discount Amt',
            'Grand Total',
            'Payment Mode',
          ]
        : isItemReport
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
                'Order Qty',
                'Address',
                'Entered By',
                'Payment Rec. By',
                'Payment',
                'Order Status',
                'Deliverystatus',
              ];

    tableData.add(headers);

    // Populate Rows
    if (isProductReport) {
      final items = _orderSummaryReport?.results ?? [];
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final modesStr = item.paymentMode
            .map((m) => "${m.paymentModeName}: ${m.amount}")
            .join(", ");
        tableData.add([
          "${i + 1}",
          _formatOrderNo(item.orderNo),
          item.orderDate.contains('T')
              ? item.orderDate.split('T')[0]
              : item.orderDate,
          item.customerName,
          item.customerMobile,
          _formatQty(item.orderQty),
          item.totalAmount.toStringAsFixed(2),
          item.discountPercentage != null
              ? "${item.discountPercentage}%"
              : "-",
          item.discountAmount.toStringAsFixed(2),
          item.grandTotal.toStringAsFixed(2),
          modesStr,
        ]);
      }
    } else if (isItemReport) {
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
      // _filteredOrders.sort((a, b) => a.orderNo.compareTo(b.orderNo));
      final sortedOrders = [..._filteredOrders]
        ..sort((a, b) => a.orderNo.compareTo(b.orderNo));
      for (var order in sortedOrders) {
        tableData.add([
          "${order.orderNo}",
          DateFormat('dd/MM/yy').format(order.orderDate),
          order.customerName,
          order.customerMobile,
          _formatQty(order.orderQty),
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
              border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 8.5,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: const pw.TextStyle(fontSize: 8.0),
              headerAlignments: isProductReport
                  ? {
                      0: pw.Alignment.center,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.centerLeft,
                      4: pw.Alignment.center,
                      5: pw.Alignment.centerRight,
                      6: pw.Alignment.centerRight,
                      7: pw.Alignment.center,
                      8: pw.Alignment.centerRight,
                      9: pw.Alignment.centerRight,
                      10: pw.Alignment.centerLeft,
                    }
                  : null,
              cellAlignments: isProductReport
                  ? {
                      0: pw.Alignment.center,
                      1: pw.Alignment.center,
                      2: pw.Alignment.center,
                      3: pw.Alignment.centerLeft,
                      4: pw.Alignment.center,
                      5: pw.Alignment.centerRight,
                      6: pw.Alignment.centerRight,
                      7: pw.Alignment.center,
                      8: pw.Alignment.centerRight,
                      9: pw.Alignment.centerRight,
                      10: pw.Alignment.centerLeft,
                    }
                  : null,
              columnWidths: isProductReport
                  ? {
                      0: const pw.FixedColumnWidth(24), // #
                      1: const pw.FixedColumnWidth(52), // Order No
                      2: const pw.FixedColumnWidth(58), // Date
                      3: const pw.FlexColumnWidth(2.2), // Customer
                      4: const pw.FixedColumnWidth(66), // Mobile
                      5: const pw.FixedColumnWidth(46), // Order Qty
                      6: const pw.FixedColumnWidth(54), // Total Amt
                      7: const pw.FixedColumnWidth(48), // Discount (%)
                      8: const pw.FixedColumnWidth(54), // Discount Amt
                      9: const pw.FixedColumnWidth(58), // Grand Total
                      10: const pw.FlexColumnWidth(2.0), // Payment Mode
                    }
                  : null,
            ),

            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total Records: ${isProductReport ? (_orderSummaryReport?.results.length ?? 0) : (isItemReport ? _filteredItems.length : _filteredOrders.length)}",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5),
              ),
            ),

            if (isProductReport && _orderSummaryReport != null) ...[
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Collection Summary",
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Total Orders: ${_orderSummaryReport!.totalOrders}",
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          "Total Qty: ${_formatQty(_orderSummaryReport!.totalOrderQty)}",
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          "Total Collection: ${_orderSummaryReport!.totalCollection.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          "Total Discount: ${_orderSummaryReport!.totalDiscountAmount.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          "Net (Cash & Card): ${_orderSummaryReport!.netTotalCashCard.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          "Net (Credit): ${_orderSummaryReport!.netTotalCredit.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _downloadPdf(PdfPageFormat format) async {
    try {
      final pdfBytes = await _generatePdf(format);
      final fileName = '${_getReportPdfName()}.pdf';

      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Downloading $fileName..."),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      Directory? directory;
      try {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          directory = await getDownloadsDirectory();
        } else if (Platform.isAndroid) {
          directory = await getDownloadsDirectory() ??
              await getExternalStorageDirectory();
        }
      } catch (e) {
        debugPrint("Error fetching downloads directory: $e");
      }

      directory ??= await getApplicationDocumentsDirectory();

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("PDF saved successfully:\n${file.path}"),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: "Share",
              textColor: Colors.amber,
              onPressed: () {
                Printing.sharePdf(bytes: pdfBytes, filename: fileName);
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Fallback to native sharing/saving if direct write is restricted
      try {
        final pdfBytes = await _generatePdf(format);
        final fileName = '${_getReportPdfName()}.pdf';
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error saving PDF: $err"),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1200),
            ),
          );
        }
      }
    }
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
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }

  /// Trigger Printing, Sharing, or Downloading
  Future<void> _printOrShare() async {
    // Check if there is data to print
    if ((_isProductSummary &&
            (_orderSummaryReport == null ||
                _orderSummaryReport!.results.isEmpty)) ||
        (!_isProductSummary && _isItemWise && _filteredItems.isEmpty) ||
        (!_isProductSummary && !_isItemWise && _filteredOrders.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No data to print/share!"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Wrap(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    "Export / Print Report",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.download_rounded, color: primaryColor),
                  ),
                  title: const Text('Download / Save PDF',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                      const Text('Save PDF file directly to device storage'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _downloadPdf(PdfPageFormat.a4.landscape);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.share_rounded,
                        color: Color(0xFF25D366)),
                  ),
                  title: const Text('Share via WhatsApp / Others',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle:
                      const Text('Share PDF to WhatsApp, email, or other apps'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _sharePdf(PdfPageFormat.a4.landscape);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.print_rounded,
                        color: Colors.purple.shade700),
                  ),
                  title: const Text('Print / Save as PDF',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                      'Open system print preview (supports Save as PDF)'),
                  onTap: () async {
                    Navigator.pop(context);
                    await Printing.layoutPdf(
                      onLayout: (PdfPageFormat format) async =>
                          _generatePdf(format),
                      name: _getReportPdfName(),
                    );
                  },
                ),
              ],
            ),
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

      if (_isProductSummary) {
        final response = await _apiService.fetchOrderSummaryReport(
          startDate: startDate,
          endDate: endDate,
          orderStatus: _orderStatus,
          paymentStatus: _paymentStatus,
          deliveryStatus: _deliveryStatus,
          customerId: _selectedCustomer == "All" ? null : _selectedCustomerId,
          orderNo: _orderNoController.text.trim(),
          paymentMode: _selectedPaymentMode,
        );
        setState(() {
          _orderSummaryReport = response;
          _hasFetched = true;
        });
      } else if (_isItemWise) {
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
      _fromDate = DateTime.now().subtract(const Duration(days: 14));
      _toDate = DateTime.now();
      _orderStatus = "All";
      _paymentStatus = "All";
      _deliveryStatus = "All";
      _selectedPaymentMode = "All";
      _isItemWise = false;
      _isProductSummary = false;
      _orderSummaryReport = null;
      _serviceType = "All";
      _selectedService = "All";
      _selectedItem = "All";
      _selectedCustomer = "All";
      _selectedCustomerId = null;
      _customerController.clear();
      _orderNoController.clear();
      _currentPage = 1;
      _totalPages = 1;
      _totalCount = 0;
      _pageSize = 20;
    });
    _fetchData();
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
                    (_isProductSummary
                        ? (_orderSummaryReport == null ||
                            _orderSummaryReport!.results.isEmpty)
                        : _isItemWise
                            ? _filteredItems.isEmpty
                            : _filteredOrders.isEmpty)) ...[
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
                else if (_isProductSummary)
                  if (_orderSummaryReport != null &&
                      _orderSummaryReport!.results.isNotEmpty)
                    _buildProductSummaryView(
                      currencyCode: currencyCode,
                      report: _orderSummaryReport!,
                    )
                  else
                    const SizedBox.shrink()
                else if (_isItemWise)
                  _buildItemsTable(
                    items: _filteredItems,
                    currencyCode: currencyCode,
                  )
                else
                  _buildOrderList(orders: _filteredOrders, currencyCode: currencyCode),
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
                          onChanged: (d) {
                            setState(() => _fromDate = d);
                            _fetchData();
                          },
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: _buildDatePickerField(
                          label: "To:",
                          date: _toDate,
                          onChanged: (d) {
                            setState(() => _toDate = d);
                            _fetchData();
                          },
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
                          onChanged: (v) {
                            setState(() => _orderStatus = v!);
                            _fetchData();
                          },
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: _isProductSummary
                            ? _buildDropdownFilter(
                                label: "Payment Mode:",
                                value: _paymentModeOptions
                                        .contains(_selectedPaymentMode)
                                    ? _selectedPaymentMode
                                    : "All",
                                options: _paymentModeOptions
                                        .contains(_selectedPaymentMode)
                                    ? _paymentModeOptions
                                    : [
                                        _selectedPaymentMode,
                                        ..._paymentModeOptions
                                      ],
                                onChanged: (v) {
                                  setState(() => _selectedPaymentMode = v!);
                                  _fetchData();
                                },
                              )
                            : _buildDropdownFilter(
                                label: "Payment Status:",
                                value: _paymentStatus,
                                options: const ["All", "Paid", "Not Paid"],
                                onChanged: (v) {
                                  setState(() => _paymentStatus = v!);
                                  _fetchData();
                                },
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
                          onChanged: (v) {
                            setState(() => _deliveryStatus = v!);
                            _fetchData();
                          },
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 24,
                    runSpacing: 10,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Item-Wise Report:",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                          Switch(
                            value: _isItemWise,
                            onChanged: (v) {
                              setState(() {
                                _isItemWise = v;
                                if (v) {
                                  _isProductSummary = false;
                                }
                                _hasFetched = false;
                              });
                              _fetchData();
                            },
                            activeThumbColor: const Color(0xFF0D47A1),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Product Summary:",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 10),
                          Switch(
                            value: _isProductSummary,
                            onChanged: (v) {
                              setState(() {
                                _isProductSummary = v;
                                if (v) {
                                  _isItemWise = false;
                                }
                                _hasFetched = false;
                              });
                              _fetchData();
                            },
                            activeThumbColor: const Color(0xFF0D47A1),
                          ),
                        ],
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
                labelText: "Customer name or phone ",
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
      optionsViewBuilder:
          (context, onSelected, Iterable<CustomerModel> options) {
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
        if (orders.isNotEmpty || _totalCount > 0) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    final startItem = _totalCount == 0
        ? 0
        : ((_currentPage - 1) * _pageSize) + 1;
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
              if (order.orderQty > 0) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: "Order Qty",
                  value: _formatQty(order.orderQty),
                ),
              ],
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

  // --- Product Summary View Methods ---
  String _formatOrderNo(dynamic val) {
    if (val == null) return '';
    final s = val.toString().trim();
    if (s.endsWith('.0')) {
      return s.substring(0, s.length - 2);
    }
    return s;
  }

  String _formatQty(double qty) {
    if (qty.truncateToDouble() == qty) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2);
  }
  Widget _buildProductSummaryView({
    required String currencyCode,
    required OrderSummaryReportResponse report,
  }) {
    final fromStr = DateFormat('dd MMM yyyy').format(_fromDate);
    final toStr = DateFormat('dd MMM yyyy').format(_toDate);
    final dateBadgeText = fromStr == toStr ? fromStr : "$fromStr - $toStr";
    final curr = currencyCode.isNotEmpty ? currencyCode : '₹';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row with Title and Date Badge
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 450;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Orders Summary",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F2B5C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateBadgeText,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Orders Summary",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F2B5C),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dateBadgeText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Collection Summary (at the top, above the table)
          _buildCollectionSummaryHorizontal(
            report: report,
            currencyCode: curr,
          ),

          // Active Payment Mode filter chip
          if (_selectedPaymentMode != "All" && _selectedPaymentMode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF93C5FD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt,
                            size: 14, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 6),
                        Text(
                          "Payment Mode: $_selectedPaymentMode",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() => _selectedPaymentMode = "All");
                            _fetchData();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: const Icon(
                            Icons.cancel,
                            size: 16,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Orders Table Card
          Card(
            elevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.06),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                dataRowMinHeight: 52,
                dataRowMaxHeight: 78,
                columnSpacing: 24,
                horizontalMargin: 20,
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade200),
                ),
                columns: [
                  const DataColumn(
                    label: Text(
                      "#",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Order No",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Order Date",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Customer Name",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Customer Mobile",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Order Qty",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Total Amount",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Discount (%)",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Discount Amount",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Grand Total",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                  DataColumn(
                    label: InkWell(
                      onTap: () => _showPaymentModeFilterDialog(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _selectedPaymentMode != "All" &&
                                  _selectedPaymentMode.isNotEmpty
                              ? const Color(0xFF0D47A1).withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: _selectedPaymentMode != "All" &&
                                  _selectedPaymentMode.isNotEmpty
                              ? Border.all(
                                  color: const Color(0xFF0D47A1)
                                      .withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Payment Mode",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _selectedPaymentMode != "All" &&
                                        _selectedPaymentMode.isNotEmpty
                                    ? const Color(0xFF0D47A1)
                                    : const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.filter_alt,
                              size: 16,
                              color: _selectedPaymentMode != "All" &&
                                      _selectedPaymentMode.isNotEmpty
                                  ? const Color(0xFF0D47A1)
                                  : const Color(0xFF64748B),
                            ),
                            if (_selectedPaymentMode != "All" &&
                                _selectedPaymentMode.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D47A1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _selectedPaymentMode,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                rows: report.results.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final item = entry.value;

                  // Parse Date and Time
                  final dt = DateTime.tryParse(item.orderDate);
                  final datePart = dt != null
                      ? DateFormat('dd MMM yyyy').format(dt)
                      : item.orderDate;
                  final timePart =
                      dt != null ? DateFormat('HH:mm:ss').format(dt) : '';

                  return DataRow(
                    cells: [
                      // # Index
                      DataCell(
                        Text(
                          "$index",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Order No
                      DataCell(
                        Text(
                          _formatOrderNo(item.orderNo),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      // Order Date
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              datePart,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            if (timePart.isNotEmpty)
                              Text(
                                timePart,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Customer Name
                      DataCell(
                        Text(
                          item.customerName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Customer Mobile
                      DataCell(
                        Text(
                          item.customerMobile,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Order Qty
                      DataCell(
                        Text(
                          _formatQty(item.orderQty),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Total Amount
                      DataCell(
                        Text(
                          item.totalAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Discount (%)
                      DataCell(
                        Text(
                          item.discountPercentage != null
                              ? item.discountPercentage!.toStringAsFixed(1)
                              : "0.0",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Discount Amount
                      DataCell(
                        Text(
                          item.discountAmount.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      // Grand Total
                      DataCell(
                        Text(
                          item.grandTotal.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      // Payment Mode Badges
                      DataCell(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: item.paymentMode.map((mode) {
                              return _buildPaymentModePill(mode, curr);
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentModePill(
      OrderSummaryPaymentMode mode, String currencyCode) {
    final name = mode.paymentModeName.trim();
    final lower = name.toLowerCase();
    Color bgColor;
    Color textColor;

    if (lower.contains('card')) {
      bgColor = const Color(0xFFEFF6FF); // light blue
      textColor = const Color(0xFF1D4ED8); // blue
    } else if (lower.contains('credit')) {
      bgColor = const Color(0xFFFFF7ED); // light orange
      textColor = const Color(0xFFC2410C); // orange/brown
    } else if (lower.contains('cash')) {
      bgColor = const Color(0xFFF0FDF4); // light green
      textColor = const Color(0xFF15803D); // green
    } else {
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF475569);
    }

    return InkWell(
      onTap: () => _showPaymentModeFilterDialog(initialSelection: name),
      borderRadius: BorderRadius.circular(6),
      child: Tooltip(
        message: "Filter by $name",
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: textColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "$currencyCode${mode.amount.toStringAsFixed(2)}",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentModeFilterDialog({String? initialSelection}) {
    final currentModes = _selectedPaymentMode == "All" ||
            _selectedPaymentMode.isEmpty
        ? <String>{}
        : _selectedPaymentMode.split(',').map((e) => e.trim()).toSet();

    if (initialSelection != null &&
        initialSelection.isNotEmpty &&
        initialSelection != "All") {
      currentModes.add(initialSelection);
    }

    showDialog(
      context: context,
      builder: (context) {
        final availableModes = ["Cash", "Card", "Credit"];
        final selectedSet = Set<String>.from(currentModes);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void applySelection(String modeString) {
              Navigator.of(context).pop();
              setState(() => _selectedPaymentMode = modeString);
              _fetchData();
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: Color(0xFF0D47A1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Filter by Payment Mode",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick Filters:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterOptionChip(
                          label: "All",
                          isSelected: _selectedPaymentMode == "All" ||
                              _selectedPaymentMode.isEmpty,
                          onTap: () => applySelection("All"),
                        ),
                        _buildFilterOptionChip(
                          label: "Cash",
                          isSelected: _selectedPaymentMode == "Cash",
                          onTap: () => applySelection("Cash"),
                        ),
                        _buildFilterOptionChip(
                          label: "Card",
                          isSelected: _selectedPaymentMode == "Card",
                          onTap: () => applySelection("Card"),
                        ),
                        _buildFilterOptionChip(
                          label: "Credit",
                          isSelected: _selectedPaymentMode == "Credit",
                          onTap: () => applySelection("Credit"),
                        ),
                        _buildFilterOptionChip(
                          label: "Cash,Card",
                          isSelected: _selectedPaymentMode == "Cash,Card",
                          onTap: () => applySelection("Cash,Card"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      "Custom Combination:",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...availableModes.map((mode) {
                      final isChecked = selectedSet.contains(mode);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          mode,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: isChecked,
                        activeColor: const Color(0xFF0D47A1),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val == true) {
                              selectedSet.add(mode);
                            } else {
                              selectedSet.remove(mode);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => applySelection("All"),
                  child: const Text("Reset (All)"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    final joined = selectedSet.isEmpty
                        ? "All"
                        : selectedSet.join(',');
                    applySelection(joined);
                  },
                  child: const Text("Apply Filter"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOptionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF0D47A1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0D47A1)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionSummaryHorizontal({
    required OrderSummaryReportResponse report,
    required String currencyCode,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF0D47A1),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "Collection Summary",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              _buildMetricCard(
                title: "Total Orders",
                value: "${report.totalOrders}",
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                icon: Icons.receipt_long_outlined,
              ),
              _buildMetricCard(
                title: "Total Order Qty",
                value: _formatQty(report.totalOrderQty),
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFF0F9FF),
                icon: Icons.inventory_2_outlined,
              ),
              _buildMetricCard(
                title: "Total Collection",
                value:
                    "$currencyCode ${report.totalCollection.toStringAsFixed(2)}",
                color: const Color(0xFF0D47A1),
                bgColor: const Color(0xFFEEF2FF),
                icon: Icons.payments_outlined,
              ),
              _buildMetricCard(
                title: "Total Discount Amount",
                value:
                    "$currencyCode ${report.totalDiscountAmount.toStringAsFixed(2)}",
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                icon: Icons.discount_outlined,
              ),
              _buildMetricCard(
                title: "Net Total (Cash & Card)",
                value:
                    "$currencyCode ${report.netTotalCashCard.toStringAsFixed(2)}",
                color: const Color(0xFF059669),
                bgColor: const Color(0xFFECFDF5),
                icon: Icons.point_of_sale_outlined,
              ),
              _buildMetricCard(
                title: "Net Total (Credit)",
                value:
                    "$currencyCode ${report.netTotalCredit.toStringAsFixed(2)}",
                color: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
                icon: Icons.credit_score_outlined,
              ),
              if (report.totalExpressCharges > 0)
                _buildMetricCard(
                  title: "Total Express Charges",
                  value:
                      "$currencyCode ${report.totalExpressCharges.toStringAsFixed(2)}",
                  color: const Color(0xFF7C3AED),
                  bgColor: const Color(0xFFF5F3FF),
                  icon: Icons.electric_bolt_outlined,
                ),
              if (report.totalVatAmount > 0)
                _buildMetricCard(
                  title: "Total VAT Amount",
                  value:
                      "$currencyCode ${report.totalVatAmount.toStringAsFixed(2)}",
                  color: const Color(0xFF0891B2),
                  bgColor: const Color(0xFFECFEFF),
                  icon: Icons.request_quote_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
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
      case "not paid":
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

    pw.Font font;
    pw.Font fontBold;
    try {
      font = await PdfGoogleFonts.poppinsRegular();
      fontBold = await PdfGoogleFonts.poppinsBold();
    } catch (_) {
      font = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final String dateStr =
        "${_formatDate(order.orderDate)} ${_formatTime(order.orderDate)}";

    // Calculate total quantity across items
    final double totalQty = items.fold(0.0, (sum, item) => sum + item.qty);
    final String totalQtyStr = totalQty.truncateToDouble() == totalQty
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
                    pw.Text("Invoice", style: const pw.TextStyle(fontSize: 8)),
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
                final qtyStr = item.qty.truncateToDouble() == item.qty
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

  Future<void> _downloadSingleOrderPdf(
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

      if (kIsWeb) {
        await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Downloading receipt $fileName..."),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      Directory? directory;
      try {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          directory = await getDownloadsDirectory();
        } else if (Platform.isAndroid) {
          directory = await getDownloadsDirectory() ??
              await getExternalStorageDirectory();
        }
      } catch (e) {
        debugPrint("Error getting downloads directory: $e");
      }

      directory ??= await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Receipt saved successfully:\n${file.path}"),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: "Share",
              textColor: Colors.amber,
              onPressed: () {
                Printing.sharePdf(bytes: pdfBytes, filename: fileName);
              },
            ),
          ),
        );
      }
    } catch (e) {
      try {
        await _shareSingleOrderPdf(order, currencyCode);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error saving receipt: $err"),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(milliseconds: 1200),
            ),
          );
        }
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
              final currencySuffix = currencyCode.isNotEmpty
                  ? ' $currencyCode'
                  : '';
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
                              if (order.orderQty > 0) ...[
                                const SizedBox(height: 6),
                                _buildInfoRow(
                                  icon: Icons.inventory_2_outlined,
                                  label: "Order Qty",
                                  value: _formatQty(order.orderQty),
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
                                              borderRadius:
                                                  BorderRadius.circular(6),
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
                              startDate: DateFormat(
                                'yyyy-MM-dd',
                              ).format(order.orderDate),
                              endDate: DateFormat(
                                'yyyy-MM-dd',
                              ).format(order.orderDate),
                              orderStatus: "All",
                              paymentStatus: "All",
                              deliveryStatus: "All",
                              orderNo: "${order.orderNo}",
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
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
                                    .map((item) => _buildItemWiseCard(item))
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
                        Tooltip(
                          message: "Download Receipt",
                          child: InkWell(
                            onTap: () =>
                                _downloadSingleOrderPdf(order, currencyCode),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.file_download_outlined,
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _printSingleOrderPdf(order, currencyCode),
                            icon: const Icon(Icons.print_outlined, size: 18),
                            label: const Text("Print"),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _shareSingleOrderPdf(order, currencyCode),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text("Share"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF25D366,
                              ), // WhatsApp Green / Modern Action Color
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getItemColor(
                        item.itemStatus,
                      ).withValues(alpha: 0.15),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
