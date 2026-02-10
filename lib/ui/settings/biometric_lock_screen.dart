import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itemize/core/theme/app_theme.dart';
import 'package:itemize/core/utils/auth_service.dart';

class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const BiometricLockScreen({super.key, required this.onUnlock});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // Attempt authentication immediately after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    try {
      final authenticated = await AuthService().authenticate(
        reason: 'Authenticate to access Itemize',
      );

      if (authenticated && mounted) {
        widget.onUnlock();
      }
    } on PlatformException catch (e) {
      if (mounted) {
        String message = "Authentication failed.";
        if (e.code == 'NotAvailable') {
          message =
              "Security not set up. Please set a Screen Lock (PIN/Pattern).";
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Itemize Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please authenticate to continue',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 48),
              if (_isAuthenticating)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Unlock'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
