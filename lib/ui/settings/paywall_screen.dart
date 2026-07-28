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
                  'Recording and looking after your things is free, unlimited, '
                  'and stays that way. Pro is for getting it back out.',
                  style: TextStyle(fontSize: 15, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                _buildBenefitItem(
                  Icons.description,
                  'Insurance Report',
                  'A page for every item — photos, serial number, receipt, '
                      'service history and estimated current value, grouped by '
                      'room and signed.',
                ),
                _buildBenefitItem(
                  Icons.save_alt,
                  'Backup & Restore',
                  'Every item, photo and year of service history in one file '
                      'you keep. No account, no cloud, nothing leaves your '
                      'device unless you send it.',
                ),
                _buildBenefitItem(
                  Icons.fingerprint,
                  'Biometric Lock',
                  'Keep the inventory behind FaceID or TouchID.',
                ),

                const SizedBox(height: 32),

                if (!proState.isStoreAvailable && !proState.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'The store is unavailable right now. Please try again later.',
                      style: TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),

                ElevatedButton(
                  onPressed:
                      proState.isLoading || !proState.isStoreAvailable
                          ? null
                          : () => proNotifier.purchasePro(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    // Priced by the store, so the figure is right in every
                    // currency and stays right if the price ever changes.
                    proState.priceString == null
                        ? 'Upgrade'
                        : 'Upgrade for ${proState.priceString}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed:
                      proState.isLoading || !proState.isStoreAvailable
                          ? null
                          : () => proNotifier.restorePurchases(),
                  child: const Text('Restore Purchases'),
                ),
                const SizedBox(height: 20),
                if (proState.proPackage != null)
                  Text(
                    proState.isSubscription
                        ? 'Renews automatically until cancelled. Manage or cancel any time in your account settings.'
                        : 'One-time purchase. No subscription.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
              color: Colors.purple.withValues(alpha: 0.1),
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
