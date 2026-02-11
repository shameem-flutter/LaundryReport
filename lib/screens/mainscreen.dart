import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry/providers/country_provider.dart';
import 'package:laundry/providers/nav_provider.dart';
import 'package:laundry/screens/customer_outstanding.dart';
import 'package:laundry/screens/customer_screen.dart';
import 'package:laundry/screens/customerledgerscreen.dart';
import 'package:laundry/screens/homescreen.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/screens/sale_report_screen.dart';
import 'package:laundry/screens/income_expense.dart';

import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';

const Color kPrimaryColor = Color(0xFF4A90E2);
const Color kBackgroundColor = Color(0xFFF5F7FA);

/// =======================
/// MAIN SCREEN
/// =======================
class Mainscreen extends ConsumerWidget {
  const Mainscreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(navProvider);

    return PopScope(
      canPop: navIndex == NavIndex.dashboard,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          ref.read(navProvider.notifier).state = NavIndex.dashboard;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: kBackgroundColor,
        body: IndexedStack(
          index: navIndex,
          children: const [
            DashboardView(),
            Homescreen(),
            CustomerScreen(),
            Customerledgerscreen(),
            CustomerOutstanding(),
            IncomeExpense(),
            SalereportScreen(),
          ],
        ),
      ),
    );
  }
}

/// =======================
/// DASHBOARD VIEW
/// =======================
class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {

  @override
  Widget build(BuildContext context) {
    final countryCodeAsync = ref.watch(countryCodeProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25.0,
                vertical: 10,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    countryCodeAsync.when(
                      data: (countryCode) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            countryCode != null
                                ? "${countryCode.companyName} Dashboard"
                                : "Dashboard",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Select an option to proceed",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      loading: () => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dashboard",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Select an option to proceed",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      error: (_, __) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dashboard",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Select an option to proceed",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMenuCard(
                    title: "Order List",
                    subtitle: "Go to main dashboard",
                    icon: Icons.dashboard_rounded,
                    color: Colors.blueAccent,
                    onTap: () {
                      ref.read(navProvider.notifier).state = NavIndex.orderList;
                    },
                  ),
                  vertGap(15),
                  _buildMenuCard(
                    title: "Customer Report",
                    subtitle: "List, Ledger, Outstanding",
                    icon: Icons.folder_shared_rounded,
                    color: Colors.indigo,
                    onTap: () => _showCustomerReportOptions(context),
                  ),
                  vertGap(15),
                  _buildMenuCard(
                    title: "Report",
                    subtitle: "View sales analysis",
                    icon: Icons.bar_chart_rounded,
                    color: Colors.purpleAccent,
                    onTap: () => _showReportOptions(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =======================
  /// MENU CARD
  /// =======================
  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[300],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// =======================
  /// CUSTOMER OPTIONS
  /// =======================
  void _showCustomerReportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetOption(
                title: "Customer List",
                icon: Icons.person,
                color: kPrimaryColor,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(navProvider.notifier).state = NavIndex.customers;
                },
              ),
              const SizedBox(height: 10),
              _buildBottomSheetOption(
                title: "Customer Ledger",
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.teal,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(navProvider.notifier).state = NavIndex.ledger;
                },
              ),
              const SizedBox(height: 10),
              _buildBottomSheetOption(
                title: "Customer Outstanding",
                icon: Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(navProvider.notifier).state = NavIndex.outstanding;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// =======================
  /// REPORT OPTIONS
  /// =======================
  void _showReportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBottomSheetOption(
                title: "Income and Expense",
                icon: Icons.trending_up,
                color: greenColor,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(navProvider.notifier).state = NavIndex.incomeExpense;
                },
              ),
              vertGap(10),
              _buildBottomSheetOption(
                title: "Sales Report",
                icon: Icons.bar_chart,
                color: blueColor,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(navProvider.notifier).state = NavIndex.saleReport;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
}
