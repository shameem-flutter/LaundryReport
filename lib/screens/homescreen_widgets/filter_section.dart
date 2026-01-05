import 'package:flutter/material.dart';
import 'package:laundry/models/customer.dart';
import 'package:laundry/models/item.dart';
import 'package:laundry/models/services.dart';
import 'package:laundry/utilities/gapfunc.dart';
import 'package:laundry/screens/homescreen_widgets/common_widgets.dart';

class FilterSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : onApplyFilter,
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
                const SizedBox(width: 18),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Reset"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3E2723),
                      side: const BorderSide(color: Color(0xFF3E2723)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// FILTER GRID (2 COLUMNS)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// LEFT COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DatePickerField(
                        label: "From:",
                        date: fromDate,
                        onChanged: onFromDateChanged,
                      ),
                      const SizedBox(height: 12),
                      DropdownFilter(
                        label: "Customer",
                        value: selectedCustomer,
                        options: customerNames.isEmpty
                            ? ["All"]
                            : [
                                "All",
                                ...customerNames.map((e) => e.customerName),
                              ],
                        onChanged: onCustomerChanged,
                      ),
                      const SizedBox(height: 12),
                      DropdownFilter(
                        label: "Order Status:",
                        value: orderStatus,
                        options: statusOptions,
                        onChanged: onOrderStatusChanged,
                      ),
                      const SizedBox(height: 12),
                      DropdownFilter(
                        label: "Payment Status:",
                        value: paymentStatus,
                        options: const ["All", "Paid", "Unpaid", "Partial"],
                        onChanged: onPaymentStatusChanged,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 18),

                /// RIGHT COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DatePickerField(
                        label: "To:",
                        date: toDate,
                        onChanged: onToDateChanged,
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(height: 12),
                      DropdownFilter(
                        label: "Delivery Status:",
                        value: deliveryStatus,
                        options: const [
                          "All",
                          "Pending",
                          "Finished",
                          "Cancelled",
                          "Delivered",
                        ],
                        onChanged: onDeliveryStatusChanged,
                      ),
                      const SizedBox(height: 12),

                      /// ITEM-WISE SWITCH
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: isItemWise,
                            onChanged: onIsItemWiseChanged,
                            activeColor: const Color(0xFF0D47A1),
                          ),
                          horiGap(6),
                          const Text(
                            "Item wise",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            /// ITEM-WISE EXTRA FILTERS
            if (isItemWise) ...[
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
                        const SizedBox(height: 25), // Label + Gap offset
                        TypeButton(
                          label: "Normal",
                          color: Colors.green,
                          isActive: serviceType == "Normal",
                          onTap: onTapNormal,
                        ),
                        const SizedBox(
                          height: 30,
                        ), // Aligns with Category label + gap
                        TypeButton(
                          label: "Express",
                          color: Colors.red,
                          isActive: serviceType == "Express",
                          onTap: onTapExpress,
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
                          value: selectedItem,
                          options: apiItems.isEmpty
                              ? ["All"]
                              : [
                                  "All",
                                  ...apiItems.map((e) => e.serviceItemName),
                                ],
                          onChanged: onItemChanged,
                        ),
                        const SizedBox(height: 12),
                        DropdownFilter(
                          label: "Category:",
                          value: selectedService,
                          options: apiServices.isEmpty
                              ? ["All"]
                              : ["All", ...apiServices.map((e) => e.serviceName)],
                          onChanged: onServiceChanged,
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
    );
  }
}
