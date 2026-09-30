import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry/models/customeroutstandingmodel.dart';
import 'package:laundry/providers/country_provider.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/providers/nav_provider.dart';
import 'package:laundry/utilities/gapfunc.dart';

class CustomerOutstanding extends ConsumerStatefulWidget {
  const CustomerOutstanding({super.key});
  @override
  ConsumerState<CustomerOutstanding> createState() =>
      _CustomerOustandingState();
}

class _CustomerOustandingState extends ConsumerState<CustomerOutstanding> {
  ApiService apiService = ApiService();
  List<CustomerOutstandingModel> custOutstanding = [];
  List<CustomerOutstandingModel> filteredCustomer = [];
  TextEditingController? searchController;
  bool hasSearched = false;
  bool isLoading = true;
  String? errorMessage;
  @override
  void initState() {
    super.initState();
    getCustOutstanding();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getCustOutstanding() async {
    try {
      final result = await apiService.getCustomerOutstanding();
      if (mounted) {
        setState(() {
          custOutstanding = result;
          filteredCustomer = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryCodeAsync = ref.watch(countryCodeProvider);
    final countryCode = countryCodeAsync.value;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              showBack: true,
              onBack: () {
                ref.read(navProvider.notifier).state = NavIndex.dashboard;
              },
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Autocomplete<CustomerOutstandingModel>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<
                            CustomerOutstandingModel
                          >.empty();
                        }
                        final query = textEditingValue.text.toLowerCase();
                        return custOutstanding.where((customer) {
                          return customer.customerName.toLowerCase().contains(
                                query,
                              ) ||
                              customer.customerMobile.contains(query);
                        });
                      },
                      displayStringForOption:
                          (CustomerOutstandingModel option) =>
                              option.customerName,
                      onSelected: (CustomerOutstandingModel selection) {
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
                            searchController = textEditingController;
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              onSubmitted: (String value) {
                                onFieldSubmitted();
                                FocusScope.of(context).unfocus();
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
                                    MediaQuery.of(context).size.width - 100,
                              ),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text(option.customerName),
                                    subtitle: Text(option.customerMobile),
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
                  horiGap(10),
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
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(child: Text("Error: $errorMessage"))
                  : filteredCustomer.isEmpty
                  ? const Center(child: Text("No Customers found"))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCustomer.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filteredCustomer[index];

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

                                if (countryCode != null)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${item.totalOutstandingAmount} ${countryCode.currencyCode}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color:
                                              Colors.redAccent, // Red for debt
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

  void _performSearch() {
    final query = searchController?.text.trim() ?? "";
    final lowerQuery = query.toLowerCase();
    setState(() {
      hasSearched = true;

      if (query.isEmpty || lowerQuery == "all") {
        filteredCustomer = List.from(custOutstanding);
      } else {
        filteredCustomer = custOutstanding.where((customer) {
          return customer.customerName.toLowerCase().contains(lowerQuery) ||
              customer.customerMobile.contains(lowerQuery);
        }).toList();
      }
    });
  }
}
