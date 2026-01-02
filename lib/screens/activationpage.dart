import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivationInstructionsScreen extends StatefulWidget {
  // final String? machineCode;

  const ActivationInstructionsScreen({super.key});

  @override
  State<ActivationInstructionsScreen> createState() =>
      _ActivationInstructionsScreenState();
}

class _ActivationInstructionsScreenState
    extends State<ActivationInstructionsScreen> {
  final TextEditingController _activationKeyController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _activationKeyController.dispose();
    super.dispose();
  }

  Future<void> _copyMachineCode() async {
    await Clipboard.setData(ClipboardData(text: ""));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Machine code copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _activateProduct() async {
    final activationKey = _activationKeyController.text.trim();

    if (activationKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the activation key'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual activation API call
    // final success = await activateWithKey(activationKey);

    setState(() => _isLoading = false);

    if (mounted) {
      // On success, navigate back or to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activation successful!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to home screen after successful activation
      // Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Activation Instructions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructionText(
              '1. Copy the machine code below and send it to the administrator.',
            ),
            const SizedBox(height: 12),
            _buildInstructionText(
              '2. They will generate and send you an activation key.',
            ),
            const SizedBox(height: 12),
            _buildInstructionText(
              '3. Paste the activation key into the field below and press ACTIVATE.',
            ),

            const SizedBox(height: 32),

            // Machine Code Section
            const Text(
              'Machine Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      "",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _copyMachineCode,
                    icon: Icon(Icons.copy, color: Colors.grey.shade700),
                    tooltip: 'Copy machine code',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Activation Key Input
            const Text(
              'Activation Key *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _activationKeyController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Enter your activation key here',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF3949AB),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),

            const SizedBox(height: 40),

            // Activate Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _activateProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3949AB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'ACTIVATE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 15, color: Colors.grey.shade700, height: 1.5),
    );
  }
}

// Example usage
class ExampleUsage extends StatelessWidget {
  const ExampleUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivationInstructionsScreen(),
              ),
            );
          },
          child: const Text('Open Activation Screen'),
        ),
      ),
    );
  }
}
