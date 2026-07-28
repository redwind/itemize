// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Itemize';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get totalValue => 'Total Value';

  @override
  String get assetsTab => 'Assets';

  @override
  String get settingsTab => 'Settings';

  @override
  String get searchPlaceholder => 'Search assets...';

  @override
  String get noAssetsFound => 'No assets found';

  @override
  String get addItemTitle => 'Add New Asset';

  @override
  String get smartScan => 'Smart Scan (AI)';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get scanReceipt => 'Scan Receipt (OCR)';

  @override
  String get exportPdf => 'Export Report to PDF';

  @override
  String get biometricLock => 'Biometric Lock';

  @override
  String get biometricLockSubtitle =>
      'Require FaceID/TouchID for sensitive actions';

  @override
  String get language => 'Language';

  @override
  String get currency => 'Currency';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get exportPdfSubtitle => 'Generate insurance report';

  @override
  String get backupData => 'Backup Data';

  @override
  String get backupDataSubtitle => 'Local backup (Coming Soon)';

  @override
  String get preferences => 'Preferences';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';
}
