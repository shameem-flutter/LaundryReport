import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry/providers/nav_provider.dart';
import 'package:laundry/screens/customer_outstanding.dart';
import 'package:laundry/screens/customer_screen.dart';
import 'package:laundry/screens/customerledgerscreen.dart';
import 'package:laundry/screens/homescreen.dart';
import 'package:laundry/screens/homescreen_widgets/home_header.dart';
import 'package:laundry/utilities/colors.dart';
import 'package:laundry/utilities/gapfunc.dart';

// Make sure you have these standard colors defined or use these defaults
const Color kPrimaryColor = Color(0xFF4A90E2); // Soft Blue
const Color kBackgroundColor = Color(0xFFF5F7FA); // Very light grey/blue

class Mainscreen extends ConsumerWidget {
  const Mainscreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(navProvider);

    return PopScope(
      canPop: navIndex == NavIndex.dashboard,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return;
        }
        ref.read(navProvider.notifier).state = NavIndex.dashboard;
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
          ],
        ),
      ),
    );
  }
}

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    onTap: () => _showCustomerReportOptions(context, ref),
                  ),
                  vertGap(15),
                  _buildMenuCard(
                    title: "Report",
                    subtitle: "View sales analysis",
                    icon: Icons.bar_chart_rounded,
                    color: Colors.purpleAccent,
                    onTap: () {
                      _showReportoptions(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for consistent Modern Cards
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
            offset: const Offset(0, 4), // Shadow position
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
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
                // Arrow Icon
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

  void _showCustomerReportOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Customer Reports",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBottomSheetOption(
                title: "Customer List",
                icon: Icons.person,
                color: kPrimaryColor,
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(navProvider.notifier).state = NavIndex.customers;
                },
              ),
              const SizedBox(height: 10),
              _buildBottomSheetOption(
                title: "Customer Ledger",
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.teal,
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(navProvider.notifier).state = NavIndex.ledger;
                },
              ),
              const SizedBox(height: 10),
              _buildBottomSheetOption(
                title: "Customer Outstanding",
                icon: Icons.warning_amber_rounded,
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.of(context).pop();
                  ref.read(navProvider.notifier).state = NavIndex.outstanding;
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportoptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Reports",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
              vertGap(10),
              _buildBottomSheetOption(
                title: "Income and Expense",
                icon: Icons.trending_up,
                color: greenColor,
                onTap: Navigator.of(context).pop,
              ),
              vertGap(10),
              _buildBottomSheetOption(
                title: "Sales Report",
                icon: Icons.bar_chart,
                color: blueColor,
                onTap: () => Navigator.of(context).pop(),
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
