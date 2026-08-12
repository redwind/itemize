import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventa/providers/settings_provider.dart';
import 'package:inventa/ui/settings/biometric_lock_screen.dart';

class BiometricGuard extends ConsumerStatefulWidget {
  final Widget child;

  const BiometricGuard({super.key, required this.child});

  @override
  ConsumerState<BiometricGuard> createState() => _BiometricGuardState();
}

class _BiometricGuardState extends ConsumerState<BiometricGuard> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    if (!settings.isBiometricEnabled) {
      return widget.child;
    }

    if (_isAuthenticated) {
      return widget.child;
    }

    return BiometricLockScreen(
      onUnlock: () {
        setState(() {
          _isAuthenticated = true;
        });
      },
    );
  }
}
