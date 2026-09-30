import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry/screens/ip_config_dialog.dart';
import 'package:laundry/utilities/colors.dart';

class HomeHeader extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;
  const HomeHeader({super.key, this.showBack = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showBack)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    onPressed: onBack ?? () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: Colors.black87, // Or primaryColor depending on design
                  ),
                ),
              Image.asset(
                "assets/wasla.png",
                height: 90,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading image: $error");
                  return const Icon(
                    Icons.broken_image,
                    size: 90,
                    color: Colors.grey,
                  );
                },
              ),
            ],
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
