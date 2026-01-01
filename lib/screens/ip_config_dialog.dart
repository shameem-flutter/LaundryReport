import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:laundry/services/api_endpoints.dart';

class IpConfigDialog extends StatefulWidget {
  const IpConfigDialog({super.key});

  @override
  State<IpConfigDialog> createState() => _IpConfigDialogState();
}

class _IpConfigDialogState extends State<IpConfigDialog> {
  final _hostController = TextEditingController();
  String _selectedProtocol = 'http://';

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() {
    final currentUrl = ApiEndpoints.baseUrl;
    if (currentUrl.startsWith('https://')) {
      _selectedProtocol = 'https://';
      _hostController.text = currentUrl.replaceFirst('https://', '').replaceAll(RegExp(r'/$'), '');
    } else if (currentUrl.startsWith('http://')) {
      _selectedProtocol = 'http://';
      _hostController.text = currentUrl.replaceFirst('http://', '').replaceAll(RegExp(r'/$'), '');
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
              color: Colors.black.withOpacity(0.1),
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
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
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
            const SizedBox(height: 20),
            TextField(
              controller: _hostController,
              decoration: InputDecoration(
                hintText: '127.0.0.1:8081',
                hintStyle: GoogleFonts.inter(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.05),
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
                  onPressed: () async {
                    if (_hostController.text.isNotEmpty) {
                      await ApiEndpoints.updateBaseUrl(
                        _selectedProtocol,
                        _hostController.text.trim(),
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(
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
                    color: Colors.black.withOpacity(0.05),
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
