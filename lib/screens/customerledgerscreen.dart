import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/customerbased/customer_details.dart';
import 'package:laundry/models/customerbased/customerledger_model.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';

class Customerledgerscreen extends StatefulWidget {
  const Customerledgerscreen({super.key});

  @override
  State<Customerledgerscreen> createState() => _CustomerledgerscreenState();
}

class _CustomerledgerscreenState extends State<Customerledgerscreen> {
  final ApiService _apiService = ApiService();
  TextEditingController? searchController;
  List<CustomerListModel> allCustomers = [];
  CustomerLedgerModel? ledgerData;
  String? errorMessage;
  bool _isLoading = true;
  CustomerListModel? selectedCustomer;

  DateTime _fromDate = DateTime.now();
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
          errorMessage = e.toString();
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
          ledgerData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      throw Exception("failed to get data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Modern off-white background for the scaffold to make white cards pop
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // --- TOP CONTROL PANEL SECTION ---
            Container(
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
                  const HomeHeader(), // Assuming this has its own internal padding
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
                                onChanged: (d) => setState(() => _fromDate = d),
                              ),
                            ),
                            horiGap(12),
                            Expanded(
                              child: _datePickerCard(
                                label: "To Date",
                                date: _toDate,
                                icon: Icons.event_available_outlined,
                                onChanged: (d) => setState(() => _toDate = d),
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

            // --- RESULT SECTION ---
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : errorMessage != null
                  ? _buildErrorState()
                  : ledgerData != null
                  ? getData(ledgerData!)
                  : _buildEmptyState(),
            ),
          ],
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
    return InkWell(
      onTap: () {
        if (selectedCustomer == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please select a customer first"),
              backgroundColor: Colors.redAccent,
              duration: Duration(milliseconds: 800),
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
      child: Container(
        height: 55,
        width: 55,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
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

  Widget getData(CustomerLedgerModel ledger) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);

    return Column(
      children: [
        // 1. Customer Summary Card
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: _buildHeaderCard(ledger, currencyFormat),
        ),

        // 2. Transaction List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: ledger.ledger.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = ledger.ledger[index];
              final isCredit = (item.creditAmount ?? 0) > 0;
              final amount = isCredit ? item.creditAmount : item.receiptAmount;

              return _buildTransactionCard(
                item,
                isCredit,
                amount ?? 0,
                currencyFormat,
              );
            },
          ),
        ),
      ],
    );
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
    var item,
    bool isCredit,
    double amount,
    NumberFormat formatter,
  ) {
    // Attempt to parse Date safely
    String day = "00";
    String month = "NOV";
    try {
      // Assuming item.trnDate is String "2023-11-24" or similar
      final dt = DateTime.parse(item..toString());
      day = DateFormat('dd').format(dt);
      month = DateFormat('MMM').format(dt).toUpperCase();
    } catch (e) {
      // Fallback if date string is weird
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
