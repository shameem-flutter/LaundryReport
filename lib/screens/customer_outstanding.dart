import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl to pubspec.yaml for currency formatting
import 'package:laundry/models/customeroutstandingmodel.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';

class CustomerOutstanding extends StatefulWidget {
  const CustomerOutstanding({super.key});
  @override
  State<CustomerOutstanding> createState() => _CustomerOustandingState();
}

class _CustomerOustandingState extends State<CustomerOutstanding> {
  // --- YOUR LOGIC STARTS HERE (UNCHANGED) ---
  ApiService apiService = ApiService();
  List<CustomerOutstandingModel> custOutstanding = [];

  @override
  void initState() {
    super.initState();
    getCustOutstanding();
  }

  Future<void> getCustOutstanding() async {
    final result = await apiService.getCustomerOutstanding();
    if (!mounted) return;
    custOutstanding = result;
    setState(() {});
  }
  // --- YOUR LOGIC ENDS HERE ---

  @override
  Widget build(BuildContext context) {
    // Helper for currency formatting (UI only)
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 2);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Modern off-white background
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),

            // Expanded List
            Expanded(
              child: custOutstanding.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // Optional: Simple loader while waiting
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: custOutstanding.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = custOutstanding[index];

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 1. Avatar (Generated from Name)
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: primaryColor,
                                  child: Text(
                                    item.customerName.isNotEmpty
                                        ? item.customerName[0].toUpperCase()
                                        : "?",
                                    style: TextStyle(
                                      color: whiteColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // 2. Customer Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.customerName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Mobile Row
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_outlined,
                                            size: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.customerMobile,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      // Address Row
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.customerAddress,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // 3. Outstanding Amount
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      currencyFormat.format(
                                        item.totalOutstandingAmount,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.redAccent, // Red for debt
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Due",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade400,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
