import 'package:flutter/material.dart';
import 'package:laundry/models/customer.dart';
import 'package:laundry/models/item.dart';
import 'package:laundry/models/services.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';
import 'package:laundry/screens/homescreen_widgets/common_widgets.dart';

class FilterSection extends StatefulWidget {
  // Actions
  final bool isLoading;
  final VoidCallback onApplyFilter;
  final VoidCallback onReset;

  // Dates
  final DateTime fromDate;
  final DateTime toDate;
  final Function(DateTime) onFromDateChanged;
  final Function(DateTime) onToDateChanged;

  // Customer
  final String selectedCustomer;
  final List<CustomerModel> customerNames;
  final Function(String?) onCustomerChanged;

  // Statuses
  final String orderStatus;
  final String paymentStatus;
  final String deliveryStatus;
  final List<String> statusOptions;
  final Function(String?) onOrderStatusChanged;
  final Function(String?) onPaymentStatusChanged;
  final Function(String?) onDeliveryStatusChanged;

  // Item Wise
  final bool isItemWise;
  final Function(bool) onIsItemWiseChanged;

  // Item Wise Filters
  final String serviceType;
  final VoidCallback onTapNormal;
  final VoidCallback onTapExpress;
  final String selectedItem;
  final List<ItemModel> apiItems;
  final Function(String?) onItemChanged;
  final String selectedService;
  final List<ServicesModel> apiServices;
  final Function(String?) onServiceChanged;

  const FilterSection({
    super.key,
    required this.isLoading,
    required this.onApplyFilter,
    required this.onReset,
    required this.fromDate,
    required this.toDate,
    required this.onFromDateChanged,
    required this.onToDateChanged,
    required this.selectedCustomer,
    required this.customerNames,
    required this.onCustomerChanged,
    required this.orderStatus,
    required this.paymentStatus,
    required this.deliveryStatus,
    required this.statusOptions,
    required this.onOrderStatusChanged,
    required this.onPaymentStatusChanged,
    required this.onDeliveryStatusChanged,
    required this.isItemWise,
    required this.onIsItemWiseChanged,
    required this.serviceType,
    required this.onTapNormal,
    required this.onTapExpress,
    required this.selectedItem,
    required this.apiItems,
    required this.onItemChanged,
    required this.selectedService,
    required this.apiServices,
    required this.onServiceChanged,
  });

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> {
  final _formKey = GlobalKey<FormState>();
  Key autoCompleteKey = UniqueKey();

  @override
  void didUpdateWidget(FilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedCustomer == 'All' &&
        oldWidget.selectedCustomer != 'All') {
      autoCompleteKey = UniqueKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        // 2. WRAP CONTENT IN A FORM
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      // 3. TRIGGER VALIDATION ON PRESS
                      onPressed: widget.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                widget.onApplyFilter();
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
                      onPressed: widget.onReset,
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

              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Autocomplete<String>(
                    key: autoCompleteKey,
                    initialValue: TextEditingValue(
                      text: widget.selectedCustomer == 'All'
                          ? ''
                          : widget.selectedCustomer,
                    ),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final query = textEditingValue.text.toLowerCase().trim();

                      if (query.isEmpty) {
                        return ["All"];
                      }

                      final matchingCustomers = widget.customerNames
                          .map((e) => e.customerName)
                          .where((name) => name.toLowerCase().contains(query))
                          .toList();

                      if (query == 'all') {
                        return ["All", ...matchingCustomers];
                      }

                      // FIX 3: If no matches (wrong key), return empty
                      if (matchingCustomers.isEmpty) {
                        return const Iterable<String>.empty();
                      }

                      return matchingCustomers;
                    },
                    onSelected: (String selection) {
                      widget.onCustomerChanged(selection);
                    },
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextFormField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            onChanged: (value) {
                              widget.onCustomerChanged(value);
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please select a customer';
                              }
                              return null;
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
                                        widget.onCustomerChanged("All");
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
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                  width: 1.2,
                                ),
                              ),
                              // Style for validation error
                              errorStyle: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                    optionsViewBuilder:
                        (context, onSelected, Iterable<String> options) {
                          if (options.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 6,
                              borderRadius: BorderRadius.circular(12),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.42,
                                  maxHeight: 250,
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (context, index) {
                                    final option = options.elementAt(index);
                                    final isAllOption = option == "All";

                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        isAllOption
                                            ? Icons.select_all
                                            : Icons.person_outline,
                                        size: 18,
                                        color: isAllOption
                                            ? Colors.blue
                                            : Colors.grey.shade600,
                                      ),
                                      title: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isAllOption
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isAllOption
                                              ? Colors.blue
                                              : Colors.black87,
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
                  ),
                  vertGap(10),
                  Row(
                    children: [
                      Expanded(
                        child: DatePickerField(
                          label: "From:",
                          date: widget.fromDate,
                          onChanged: widget.onFromDateChanged,
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: DatePickerField(
                          label: "To:",
                          date: widget.toDate,
                          onChanged: widget.onToDateChanged,
                        ),
                      ),
                    ],
                  ),
                  vertGap(12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownFilter(
                          label: "Order Status:",
                          value: widget.orderStatus,
                          options: widget.statusOptions,
                          onChanged: widget.onOrderStatusChanged,
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: DropdownFilter(
                          label: "Payment Status:",
                          value: widget.paymentStatus,
                          options: const ["All", "Paid", "Unpaid", "Partial"],
                          onChanged: widget.onPaymentStatusChanged,
                        ),
                      ),
                    ],
                  ),

                  vertGap(10),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownFilter(
                          label: "Delivery Status:",
                          value: widget.deliveryStatus,
                          options: const [
                            "All",
                            "Pending",
                            "Cancelled",
                            "Delivered",
                          ],
                          onChanged: widget.onDeliveryStatusChanged,
                        ),
                      ),
                      horiGap(10),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Item-Wise:",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Switch(
                              value: widget.isItemWise,
                              onChanged: widget.onIsItemWiseChanged,
                              activeThumbColor: const Color(0xFF0D47A1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  vertGap(05),
                ],
              ),

              if (widget.isItemWise) ...[
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
                          TypeButton(
                            label: "Normal",
                            color: Colors.green,
                            isActive: widget.serviceType == "Normal",
                            onTap: widget.onTapNormal,
                          ),
                          const SizedBox(height: 30),
                          TypeButton(
                            label: "Express",
                            color: Colors.red,
                            isActive: widget.serviceType == "Express",
                            onTap: widget.onTapExpress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownFilter(
                            label: "Item:",
                            value: widget.selectedItem,
                            options: widget.apiItems.isEmpty
                                ? ["All"]
                                : [
                                    "All",
                                    ...widget.apiItems.map(
                                      (e) => e.serviceItemName,
                                    ),
                                  ],
                            onChanged: widget.onItemChanged,
                          ),
                          const SizedBox(height: 12),
                          DropdownFilter(
                            label: "Category:",
                            value: widget.selectedService,
                            options: widget.apiServices.isEmpty
                                ? ["All"]
                                : [
                                    "All",
                                    ...widget.apiServices.map(
                                      (e) => e.serviceName,
                                    ),
                                  ],
                            onChanged: widget.onServiceChanged,
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
}
