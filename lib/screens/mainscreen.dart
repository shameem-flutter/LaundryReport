import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

class Mainscreen extends StatefulWidget {
  const Mainscreen({super.key});

  @override
  State<Mainscreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Mainscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(),
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
                    title: "Order-List",
                    subtitle: "Go to main dashboard",
                    icon: Icons.dashboard_rounded,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Homescreen()),
                      );
                    },
                  ),
                  vertGap(15),
                  _buildMenuCard(
                    title: "Customer-List",
                    subtitle: "View customer details",
                    icon: Icons.person,
                    color: blueColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerScreen(),
                        ),
                      );
                    },
                  ),
                  vertGap(15),

                  _buildMenuCard(
                    title: "Customer Ledger",
                    subtitle: "View payment history",
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Customerledgerscreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildMenuCard(
                    title: "Customer Outstanding",
                    subtitle: "Track pending amounts",
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerOutstanding(),
                        ),
                      );
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
}
