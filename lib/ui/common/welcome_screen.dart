import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventa/core/theme/app_theme.dart';
import 'package:inventa/providers/settings_provider.dart';
import 'package:inventa/ui/add_item/quick_capture_screen.dart';
import 'package:inventa/l10n/app_localizations.dart';

/// Walks a new owner into photographing one room.
///
/// Without it the app opens on an empty dashboard beside a `+`, and the feature
/// that solves the actual problem — photographing a whole room in one pass —
/// sits a level down inside a sheet nobody opens. The wall everyone hits is the
/// first ten items, so this points straight at it and asks for one room, not a
/// house.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  Future<void> _start() async {
    // Marked done on the way in, not on the way out. Someone who starts and
    // backs out of the camera has seen this screen; showing it again would be
    // nagging, and the Assets tab explains itself from there.
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuickCaptureScreen()),
    );
  }

  Future<void> _skip() async {
    await ref.read(settingsProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.inventory_2, size: 72, color: AppTheme.primaryBlue),
              const SizedBox(height: 28),
              Text(
                l10n.welcomeTitle,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                l10n.welcomeBody,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              _step(Icons.photo_camera, l10n.welcomeStep1, l10n.welcomeStep1Hint),
              _step(Icons.edit_note, l10n.welcomeStep2, l10n.welcomeStep2Hint),
              _step(
                Icons.shield_outlined,
                l10n.welcomeStep3,
                l10n.welcomeStep3Hint,
              ),

              const Spacer(),
              ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.welcomeStart,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _skip,
                child: Text(l10n.welcomeSkip),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(IconData icon, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [WelcomeScreen] until it has been seen, then the app proper.
///
/// Gated on the flag rather than on an empty inventory: somebody who has
/// deliberately deleted everything should not be greeted as a stranger.
class OnboardingGate extends ConsumerWidget {
  final Widget child;

  const OnboardingGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(
      settingsProvider.select((s) => s.hasOnboarded),
    );
    return onboarded ? child : const WelcomeScreen();
  }
}
