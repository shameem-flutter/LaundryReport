import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:laundry/providers/country_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry/screens/licensekey.dart';
import 'package:laundry/screens/mainscreen.dart';
import 'package:laundry/services/api_endpoints.dart';
import 'package:laundry/services/api_service.dart';

class IpConfigDialog extends ConsumerStatefulWidget {
  const IpConfigDialog({super.key});

  @override
  ConsumerState<IpConfigDialog> createState() => _IpConfigDialogState();
}

class _IpConfigDialogState extends ConsumerState<IpConfigDialog> {
  final ApiService _apiService = ApiService();
  final _hostController = TextEditingController();
  String _selectedProtocol = 'http://';
  bool _isLoading = false;

  Future<bool> checkLicense() async {
    try {
      return await _apiService.checkLicenseStatus();
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final currentUrl = ApiEndpoints.baseUrl;
    if (currentUrl.startsWith('https://')) {
      _selectedProtocol = 'https://';
      _hostController.text = currentUrl
          .replaceFirst('https://', '')
          .replaceAll(RegExp(r'/$'), '');
    } else if (currentUrl.startsWith('http://')) {
      _selectedProtocol = 'http://';
      _hostController.text = currentUrl
          .replaceFirst('http://', '')
          .replaceAll(RegExp(r'/$'), '');
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IP Address',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildProtocolButton('http://'),
                    _buildProtocolButton('https://'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                hintText: '127.0.0.1:8081',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_hostController.text.isEmpty) return;
                          bool wasAlreadyVerified = LicenseState.isVerified;

                          setState(() => _isLoading = true);

                          await ApiEndpoints.updateBaseUrl(
                            _selectedProtocol,
                            _hostController.text.trim(),
                          );
                          
                          // Invalidate the provider to force a refresh with new IP
                          ref.invalidate(countryCodeProvider);

                          final bool isActivated = await _apiService
                              .checkLicenseStatus();

                          if (!context.mounted) return;
                          setState(() {
                            _isLoading = false;
                          });

                          final parentContext = context;

                          // 1. Close the dialog first
                          Navigator.of(context).pop();

                          if (isActivated) {
                            LicenseState.isVerified = true;
                            if (!wasAlreadyVerified) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => Mainscreen(),
                                ),
                              );
                            }
                          } else {
                            LicenseState.isVerified;
                            Navigator.of(
                              parentContext,
                              rootNavigator: true,
                            ).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ActivationRequiredScreen(),
                              ),
                            );
                            return;
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.teal,
                            ),
                          ),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.inter(
                            color: Colors.teal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolButton(String protocol) {
    bool isSelected = _selectedProtocol == protocol;
    return GestureDetector(
      onTap: () => setState(() => _selectedProtocol = protocol),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          protocol,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }
}

class LicenseState {
  static bool isVerified = false;
}
