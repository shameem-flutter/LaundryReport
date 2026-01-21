import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/customerbased/customer_details.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});
  @override
  State<CustomerScreen> createState() => _CustomerscreenState();
}

class _CustomerscreenState extends State<CustomerScreen> {
  final ApiService _apiService = ApiService();

  TextEditingController? _searchController;

  // List<CustomerModel> _allCustomers = [];
  List<CustomerListModel> _allCustomers = [];
  List<CustomerListModel> _filteredCustomers = [];
  bool _isLoading = true;
  bool hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    // _searchController is managed by Autocomplete, do not dispose here if we pick it up from builder.
    // However, if we don't own it, we don't dispose it.
    super.dispose();
  }

  Future<void> _fetchCustomers() async {
    try {
      final customers = await _apiService.customerDetails();
      if (mounted) {
        setState(() {
          _allCustomers = customers;
          _filteredCustomers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch() {
    final query = _searchController?.text.trim() ?? "";
    final lowerQuery = query.toLowerCase();
    setState(() {
      hasSearched = true;

      if (query.isEmpty || lowerQuery == "all") {
        _filteredCustomers = List.from(_allCustomers);
      } else {
        _filteredCustomers = _allCustomers.where((customer) {
          return customer.customerName.toLowerCase().contains(lowerQuery);
          //   customer.customerId.toString().contains(lowerQuery)
          //   customer.mobile.contains(lowerQuery);
        }).toList();
      }
    });
  }

  String _formatDate(dynamic date) {
    if (date == null) return "-";
    if (date is String) {
      try {
        final parsed = DateTime.parse(date);
        return DateFormat('dd MMM yyyy').format(parsed);
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Autocomplete<CustomerListModel>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<CustomerListModel>.empty();
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return _allCustomers.where((customer) {
                          return customer.customerName.toLowerCase().contains(
                                query,
                              ) ||
                              customer.mobile.contains(query);
                        });
                      },
                      displayStringForOption: (CustomerListModel option) =>
                          option.customerName,
                      onSelected: (CustomerListModel selection) {
                        // Optional: Auto-search on selection
                        //  _performSearch();
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            _searchController = textEditingController;
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              onSubmitted: (String value) {
                                onFieldSubmitted();
                                FocusScope.of(context).unfocus();
                                // _performSearch();
                              },
                              decoration: InputDecoration(
                                hintText: "Search customer...",
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200,
                                maxWidth:
                                    MediaQuery.of(context).size.width -
                                    100, // Adjust width based on layout
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option.customerName),
                                    subtitle: Text(option.mobile),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _performSearch,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Search"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        "Error: $_errorMessage",
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _filteredCustomers.isEmpty
                  ? const Center(
                      child: Text(
                        "No customers found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        return _buildCustomerCard(_filteredCustomers[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerListModel customer) {
    // Define colors locally or grab from your theme
    final bool hasBalance = (customer.currentBalance) > 0;
    final Color balanceColor = hasBalance ? Colors.red.shade700 : Colors.teal;

    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 05,
      ), // Outer spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        // subtle shadow for depth
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------
          // TOP SECTION: Header & Balance
          // ---------------------------------------------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF2C3E50), // Modern dark slate
                  child: Text(
                    customer.customerName.isNotEmpty
                        ? customer.customerName[0].toUpperCase()
                        : "C",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Join Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "Since ${_formatDate(customer.entryDate)}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Balance (Hero Element)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Current Balance",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${customer.currentBalance}", // Add currency symbol if needed
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: balanceColor,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade100),
                bottom: BorderSide(color: Colors.grey.shade100),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildIconRow(Icons.phone_rounded, customer.mobile),
                      const SizedBox(height: 8),
                      _buildIconRow(
                        Icons.location_on_rounded,
                        customer.address,
                      ),
                      const SizedBox(height: 8),
                      _buildIconRow(
                        Icons.account_balance_wallet_rounded,
                        "Opening: ${customer.openingBalance ?? 0}",
                      ),
                    ],
                  ),
                ),

                //      const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          TextEditingController amountController =
                              TextEditingController();
                          TextEditingController narrationController =
                              TextEditingController();
                          String selectedPaymentMode = "Cash";
                          return StatefulBuilder(
                            builder: (context, updateDialogueState) {
                              return AlertDialog(
                                title: const Text("Settle Account"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Name: ${customer.customerName}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Phone: ${customer.mobile}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Opening Balance: ${customer.openingBalance ?? 0}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    TextField(
                                      controller: amountController,
                                      decoration: InputDecoration(
                                        hintText: "amount",
                                      ),
                                    ),
                                    TextField(
                                      controller: narrationController,
                                      decoration: InputDecoration(
                                        hintText: "narration",
                                      ),
                                    ),
                                    DropdownButtonFormField<String>(
                                      value: selectedPaymentMode,
                                      decoration: const InputDecoration(
                                        labelText: "Payment Mode",
                                        border: OutlineInputBorder(),
                                      ),
                                      items: ["Cash", "Online", "UPI", "Bank"]
                                          .map(
                                            (mode) => DropdownMenuItem(
                                              value: mode,
                                              child: Text(mode),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          updateDialogueState(
                                            () => selectedPaymentMode = val,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Close"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      if (amountController.text.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Please enter an amount",
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      // Call your API function
                                      try {
                                        await _updateCreditreciept(
                                          customerId: customer.customerId
                                              .toString(), // Ensure ID format matches your API
                                          paymentMode: selectedPaymentMode,
                                          amount: int.parse(
                                            amountController.text,
                                          ),
                                          narration: narrationController.text,
                                        );

                                        // Success: Close dialog and refresh list
                                        if (context.mounted) {
                                          Navigator.of(
                                            context,
                                          ).pop(); // Close dialog
                                          _fetchCustomers(); // Refresh the background list
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Settlement Successful",
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        // Error handling
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $e"),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text("Confirm"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text("Settle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------------------------------------------
          // BOTTOM SECTION: Note (If exists)
          // ---------------------------------------------
          if (customer.note.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.yellow.shade50, // Subtle warning/note color
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: Colors.orange.shade300,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // A much simpler helper widget for the details
  Widget _buildIconRow(IconData icon, String text) {
    final displayValue = (text.isEmpty || text == "-") ? "N/A" : text;

    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            displayValue,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _updateCreditreciept({
    required String customerId,
    required String paymentMode,
    required int amount,
    String? narration,
  }) async {
    try {
      await _apiService.updateCreditReciept(
        customerId: customerId,
        paymentMode: paymentMode,
        amount: amount,
        narration: narration,
      );
    } catch (e) {
      throw Exception("failed to update credit reciept:$e");
    }
  }
}
