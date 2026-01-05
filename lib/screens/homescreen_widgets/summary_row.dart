import 'package:flutter/material.dart';
import 'package:laundry/screens/homescreen_widgets/common_widgets.dart';
import 'package:laundry/utilities/colors.dart';

class SummaryRow extends StatelessWidget {
  final int totalCount;
  final Map<String, int> deliveryCounts;

  const SummaryRow({
    super.key,
    required this.totalCount,
    required this.deliveryCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.brown,
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            StatusChip(
              label: "All",
              count: totalCount,
              color: whiteColor,
            ),
            StatusChip(
              label: "Processing",
              count: deliveryCounts['processing'] ?? 0,
              color: whiteColor,
            ),
            StatusChip(
              label: "Ready for Delivery",
              count: deliveryCounts['ready for delivery'] ?? 0,
              color: whiteColor,
            ),
            StatusChip(
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
}
