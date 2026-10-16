import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/customerbased/customer_details.dart';
import 'package:laundry/models/customerbased/customerledger_model.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry/providers/nav_provider.dart';
import 'package:laundry/providers/country_provider.dart';

class Customerledgerscreen extends ConsumerStatefulWidget {
  const Customerledgerscreen({super.key});

  @override
  ConsumerState<Customerledgerscreen> createState() =>
      _CustomerledgerscreenState();
}

class _CustomerledgerscreenState extends ConsumerState<Customerledgerscreen> {
  final ApiService _apiService = ApiService();
  TextEditingController? searchController;
  List<CustomerListModel> allCustomers = [];
  CustomerLedgerModel? custLedgerData;
  String? errorMessage;
  bool _isLoading = true;
  CustomerListModel? selectedCustomer;

  DateTime _fromDate = DateTime.now().subtract(Duration(days: 14));
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final customers = await _apiService.customerDetails();
      if (mounted) {
        setState(() {
          allCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Extract meaningful message or show generic error
          if (e.toString().contains("500")) {
            errorMessage = "Server Error (500). Please try again later.";
          } else if (e.toString().contains("Network is unreachable")) {
            errorMessage = "No Internet Connection.";
          } else {
            errorMessage =
                "Failed to load customers. Please check your connection.";
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _getCustomerledger({
    required String customerId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final data = await _apiService.getCustomerledger(
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );
      if (mounted) {
        setState(() {
          custLedgerData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      throw Exception("failed to get data: $e");
    }
  }

  String _getLedgerPdfName() {
    final fromStr = DateFormat('dd_MM_yyyy').format(_fromDate);
    final toStr = DateFormat('dd_MM_yyyy').format(_toDate);
    final dateRangeStr = '${fromStr}_to_$toStr';
    final custName =
        selectedCustomer?.customerName.replaceAll(RegExp(r'\s+'), '_') ?? '';
    if (custName.isNotEmpty) {
      return 'CustomerLedger_${custName}_$dateRangeStr';
    }
    return 'CustomerLedger_$dateRangeStr';
  }

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
    final custLedgerPrint = custLedgerData;
    final String title = selectedCustomer != null
        ? "Customer Ledger (${selectedCustomer!.customerName})"
        : "Customer Ledger Report";
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
    final List<String> headers = [
      'Date',
      'Trn.No',
      'Description',
      'Payment Mode',
      'Narration',
      'Credit',
      'Reciept',
      'Balance',
    ];

    tableData.add(headers);

    // Populate Rows

    // _filteredItems.sort((a, b) => a.orderNo.compareTo(b.orderNo));
    final sortedItems = [...custLedgerData!.ledger]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (var item in sortedItems) {
      tableData.add([
        item.trnDate != null
            ? DateFormat('dd/MM/yy').format(item.trnDate!)
            : "-",
        "${item.trnNo}",

        item.description,
        item.paymentMode.toString(),
        item.narration.toString(),
        item.creditAmount.toString(),
        item.receiptAmount.toString(),
        item.balance.toString(),
      ]);
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
                "Closing Balance: ${custLedgerPrint!.closingBalance} ${ref.read(countryCodeProvider).value?.currencyCode ?? ''}"
                    .trim(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _downloadPdf(PdfPageFormat format) async {
    try {
      final pdfBytes = await _generatePdf(format);
      final fileName = '${_getLedgerPdfName()}.pdf';

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
      try {
        final pdfBytes = await _generatePdf(format);
        final fileName = '${_getLedgerPdfName()}.pdf';
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
      final fileName = '${_getLedgerPdfName()}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error sharing PDF: $e"),
            duration: const Duration(milliseconds: 1200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Trigger Printing, Sharing, or Downloading
  Future<void> _printOrShare() async {
    // Check if there is data to print
    if (custLedgerData == null || custLedgerData!.ledger.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("No data to print/share!"),
          backgroundColor: redColor,
          behavior: SnackBarBehavior.floating,
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
                    "Export / Print Ledger",
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
                      name: _getLedgerPdfName(),
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

  @override
  Widget build(BuildContext context) {
    final countryCodeAsync = ref.watch(countryCodeProvider);
    final currencyCode = countryCodeAsync.value?.currencyCode ?? '';

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          heroTag: "fab_ledger",
          icon: Icon(Icons.print, color: whiteColor),
          onPressed: _printOrShare,
          label: Text("Print/Share", style: TextStyle(color: whiteColor)),
          backgroundColor: primaryColor,
        ),
        backgroundColor: Colors.grey.shade50,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: whiteColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      HomeHeader(
                        showBack: true,
                        onBack: () {
                          ref.read(navProvider.notifier).state =
                              NavIndex.dashboard;
                        },
                      ), // Assuming this has its own internal padding
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            // Search Row
                            Row(
                              children: [
                                Expanded(child: _buildSearchField()),
                                horiGap(10),
                                _buildSearchButton(),
                              ],
                            ),
                            vertGap(16),
                            // Date Filter Row
                            Row(
                              children: [
                                Expanded(
                                  child: _datePickerCard(
                                    label: "From Date",
                                    date: _fromDate,
                                    icon: Icons.calendar_today_outlined,
                                    onChanged: (d) =>
                                        setState(() => _fromDate = d),
                                  ),
                                ),
                                horiGap(12),
                                Expanded(
                                  child: _datePickerCard(
                                    label: "To Date",
                                    date: _toDate,
                                    icon: Icons.event_available_outlined,
                                    onChanged: (d) =>
                                        setState(() => _toDate = d),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- RESULT SECTION ---
              if (_isLoading)
                SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                )
              else if (errorMessage != null)
                SliverFillRemaining(child: _buildErrorState())
              else if (custLedgerData != null)
                ...getDataSlivers(custLedgerData!, currencyCode)
              else
                SliverFillRemaining(child: _buildEmptyState()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          vertGap(10),
          Text(
            "Select a customer to view ledger",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
            vertGap(10),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSearchField() {
    return Autocomplete<CustomerListModel>(
      optionsBuilder: (value) {
        if (value.text.isEmpty) {
          return const Iterable<CustomerListModel>.empty();
        }
        final query = value.text.toLowerCase();
        return allCustomers.where((customer) {
          return customer.customerName.toLowerCase().contains(query) ||
              customer.mobile.contains(query);
        });
      },
      onSelected: (CustomerListModel selection) {
        selectedCustomer = selection;
        FocusScope.of(context).unfocus(); // Close keyboard on selection
      },
      displayStringForOption: (option) => option.customerName,
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        searchController = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: "Search customer...",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: primaryColor),
            filled: true,
            fillColor: Colors.grey.shade100, // Modern flat fill
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            shadowColor: Colors.black12,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.of(context).size.width - 90, // Adjust width
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (c, i) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final option = options.elementAt(i);
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: primaryColor.withValues(alpha: 0.1),
                      child: Text(
                        option.customerName[0].toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      option.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      option.mobile,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
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

  Widget _buildSearchButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.3))],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withValues(alpha: 0.25),
          highlightColor: Colors.white.withValues(alpha: 0.15),
          onTap: () {
            if (selectedCustomer == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please select a customer first"),
                  backgroundColor: Colors.redAccent,
                  duration: Duration(milliseconds: 800),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            setState(() {
              _isLoading = true;
              errorMessage = null;
            });

            _getCustomerledger(
              customerId: selectedCustomer!.customerId.toString(),
              startDate: DateFormat('yyyy-MM-dd').format(_fromDate),
              endDate: DateFormat('yyyy-MM-dd').format(_toDate),
            );
          },
          child: const Center(
            child: Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _datePickerCard({
    required String label,
    required DateTime date,
    required IconData icon,
    required Function(DateTime) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          initialDate: date,
          builder: (context, child) {
            return Theme(
              data: Theme.of(
                context,
              ).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100, // Flat design
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            vertGap(4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yy').format(date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(icon, size: 16, color: primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- RESULT LIST UI ---

  List<Widget> getDataSlivers(CustomerLedgerModel ledger, String currencyCode) {
    final currencyFormat = NumberFormat.currency(
      symbol: currencyCode.isNotEmpty ? '$currencyCode ' : '',
      decimalDigits: 2,
    );

    return [
      // 1. Customer Summary Card
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: _buildHeaderCard(ledger, currencyFormat),
        ),
      ),

      // 2. Transaction List
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final item = ledger.ledger[index];
            final isCredit = (item.creditAmount) > 0;
            final amount = isCredit ? item.creditAmount : item.receiptAmount;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTransactionCard(
                item,
                isCredit,
                amount,
                currencyFormat,
              ),
            );
          }, childCount: ledger.ledger.length),
        ),
      ),
    ];
  }

  Widget _buildHeaderCard(CustomerLedgerModel ledger, NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ledger.customerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Closing Balance",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            formatter.format(ledger.closingBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    Ledger item,
    bool isCredit,
    double amount,
    NumberFormat formatter,
  ) {
    String day;
    String month;
    if (item.trnDate != null) {
      day = DateFormat('dd').format(item.trnDate!);
      month = DateFormat('MMM').format(item.trnDate!).toUpperCase();
    } else {
      day = "-";
      month = "-";
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildMiniTag(
                        Icons.numbers_rounded,
                        "Trn.No:-${item.trnNo ?? 'null'}",
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  _buildMiniTag(
                    Icons.payment,
                    "PaymentMode:-${item.paymentMode ?? 'N/A'}",
                  ),
                ],
              ),
            ),
            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${isCredit ? '-' : '+'} ${formatter.format(amount)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.redAccent : Colors.green[700],
                  ),
                ),
                const SizedBox(height: 4),
                // Narration as subtitle here if needed, or balance
                Text(
                  "Bal: ${formatter.format(item.balance)}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade400),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }
}
