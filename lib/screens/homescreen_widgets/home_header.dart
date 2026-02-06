import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry/screens/ip_config_dialog.dart';
import 'package:laundry/utilities/colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            "assets/wasla.png",
            height: 90,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              print("Error loading image: $error");
              return const Icon(Icons.broken_image, size: 90, color: Colors.grey);
            },
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const IpConfigDialog(),
              );
            },
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor,
              ),
              alignment: Alignment.center,
              child: Text(
                'IP',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: whiteColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            tooltip: 'Configure IP Address',
          ),
        ],
      ),
    );
  }
}
