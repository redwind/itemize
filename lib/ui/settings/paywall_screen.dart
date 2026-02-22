import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itemize/providers/pro_provider.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proState = ref.watch(proProvider);
    final proNotifier = ref.read(proProvider.notifier);

    // Listen for state changes
    ref.listen(proProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.successMessage!)));
      }

      if (next.isPro && !(previous?.isPro ?? false)) {
        if (next.successMessage == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Welcome to Pro!")));
        }
        Navigator.pop(context);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.diamond, size: 80, color: Colors.purple),
                const SizedBox(height: 24),
                GestureDetector(
                  onLongPress: () {
                    proNotifier.toggleDetailedErrors();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Toggled detailed error logs"),
                      ),
                    );
                  },
                  child: const Text(
                    'Unlock Full Potential',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Get unlimited access to all features with a one-time purchase.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                _buildBenefitItem(
                  Icons.all_inclusive,
                  'Unlimited Items',
                  'Store as many items as you want.',
                ),
                _buildBenefitItem(
                  Icons.qr_code_scanner,
                  'Unlimited AI Scans',
                  'Scan barcodes and receipts without daily limits.',
                ),
                _buildBenefitItem(
                  Icons.picture_as_pdf,
                  'Pro PDF Reports',
                  'Export detailed insurance reports.',
                ),
                _buildBenefitItem(
                  Icons.fingerprint,
                  'Biometric Lock',
                  'Secure your inventory with FaceID/TouchID.',
                ),
                _buildBenefitItem(
                  Icons.cloud_upload,
                  'Image Backup',
                  'Sync images to persistent storage.',
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed:
                      proState.isLoading
                          ? null
                          : () => proNotifier.purchasePro(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Upgrade for \$4.99',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      proState.isLoading
                          ? null
                          : () => proNotifier.restorePurchases(),
                  child: const Text('Restore Purchases'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'One-time purchase. No subscription.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          if (proState.isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.purple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
