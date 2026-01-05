import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/itemwise.dart';
import 'package:laundry/screens/homescreen_widgets/common_widgets.dart';

class ItemsTable extends StatelessWidget {
  final List<ItemWiseorderreportModel> items;

  const ItemsTable({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
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
                  FullCellStatus(
                    text: item.serviceType,
                    bgColor: getServiceTypeColor(item.serviceType),
                  ),
                ),
                _buildDataCell(Text(item.item)),
                DataCell(
                  FullCellStatus(
                    text: item.itemStatus,
                    bgColor: getItemColor(item.itemStatus),
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
                  FullCellStatus(
                    text: item.paymentStatus,
                    bgColor: getStatusColor(item.paymentStatus),
                  ),
                ),
                DataCell(
                  FullCellStatus(
                    text: item.orderStatus,
                    bgColor: getStatusColor(item.orderStatus),
                  ),
                ),
                DataCell(
                  FullCellStatus(
                    text: item.deliveryStatus,
                    bgColor: getStatusColor(item.deliveryStatus),
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

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  String _formatTime(DateTime d) => DateFormat('h:mm a').format(d);
}
