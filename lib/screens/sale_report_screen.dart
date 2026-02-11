import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:laundry/models/country_model.dart';
import 'package:laundry/models/salereportmodel.dart';
import 'package:laundry/providers/country_provider.dart';
import 'package:laundry/providers/nav_provider.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/services/api_service.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';

class SalereportScreen extends ConsumerStatefulWidget {
  const SalereportScreen({super.key});

  @override
  ConsumerState<SalereportScreen> createState() => _SalereportScreenState();
}

class _SalereportScreenState extends ConsumerState<SalereportScreen> {
  final ApiService _apiService = ApiService();
  SalereportModel? _data;
  bool _isLoading = false;
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final startDate = DateFormat('yyyy-MM-dd').format(fromDate);
      final endDate = DateFormat('yyyy-MM-dd').format(toDate);
      final result = await _apiService.getSalereport(
        fromDate: startDate,
        toDate: endDate,
      );
      setState(() {
        _data = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: redColor),
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

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryCodeAsync = ref.watch(countryCodeProvider);
    final countryCode = countryCodeAsync.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      HomeHeader(
                        showBack: true,
                        onBack: () {
                          ref.read(navProvider.notifier).state =
                              NavIndex.dashboard;
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildDateSelector(
                                "From",
                                fromDate,
                                () => _selectDate(context, true),
                              ),
                            ),
                            horiGap(12),
                            Expanded(
                              child: _buildDateSelector(
                                "To",
                                toDate,
                                () => _selectDate(context, false),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoading)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_data != null)
                        Expanded(
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -25),
                                child: _buildGrandTotalCard(countryCode),
                              ),
                              _buildPaymentList(countryCode), // List now flows in column
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.insert_chart_outlined_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                vertGap(16),
                                Text(
                                  "No data available",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
                vertGap(2),
                Text(
                  DateFormat('dd MMM yy').format(date),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalCard(CountryCodeModel? countryCode) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Grand Total Sales",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
          vertGap(8),
          Text(
            "${_data?.grandTotal.toStringAsFixed(2) ?? "0.00"} ${countryCode?.currencyCode ?? ''}",
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(CountryCodeModel? countryCode) {
    final payments = _data?.paymentSummary ?? [];
    if (payments.isEmpty) {
      return Center(
        child: Text(
          "No transaction history",
          style: GoogleFonts.poppins(color: Colors.grey),
        ),
      );
    }

    // Find max value to calculate percentage for progress bar
    double maxAmount = 0;
    for (var p in payments) {
      if (p.totalAmount > maxAmount) maxAmount = p.totalAmount;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: payments.map((item) {
          final percentage = maxAmount > 0
              ? (item.totalAmount / maxAmount)
              : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getColorForMode(
                            item.paymentModeName,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForMode(item.paymentModeName),
                          color: _getColorForMode(item.paymentModeName),
                          size: 20,
                        ),
                      ),
                      horiGap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.paymentModeName,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  "${item.totalAmount.toStringAsFixed(2)} ${countryCode?.currencyCode ?? ''}",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            vertGap(8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor: Colors.grey[100],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getColorForMode(item.paymentModeName),
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return Icons.attach_money_rounded;
      case 'card':
        return Icons.credit_card_rounded;
      case 'online':
      case 'upi':
        return Icons.qr_code_rounded;
      default:
        return Icons.payment_rounded;
    }
  }

  Color _getColorForMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'online':
      case 'upi':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}
