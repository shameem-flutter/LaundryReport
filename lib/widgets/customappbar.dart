import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry/utilities/colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final String logoAsset;
  final VoidCallback? onIpTap;
  final bool showIpButton;

  const CustomAppBar({
    super.key,
    this.title = "Laundry Management",
    this.subtitle = "Automate, Track, Deliver Effortlessly",
    this.logoAsset = "assets/wasla.png",
    this.onIpTap,
    this.showIpButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(logoAsset, height: 120, width: 120, fit: BoxFit.contain),

          if (showIpButton)
            IconButton(
              onPressed: onIpTap,
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
            ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(140); // ✅ IMPORTANT
}
