// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Itemize';

  @override
  String get dashboardTitle => 'Instrumententafel';

  @override
  String get totalValue => 'Gesamtwert';

  @override
  String get assetsTab => 'Vermögenswerte';

  @override
  String get settingsTab => 'Einstellungen';

  @override
  String get searchPlaceholder => 'Assets suchen...';

  @override
  String get noAssetsFound => 'Keine Assets gefunden';

  @override
  String get addItemTitle => 'Neues Asset hinzufügen';

  @override
  String get smartScan => 'Intelligenter Scan (KI)';

  @override
  String get scanBarcode => 'Barcode scannen';

  @override
  String get scanReceipt => 'Beleg scannen (OCR)';

  @override
  String get exportPdf => 'PDF-Bericht exportieren';

  @override
  String get biometricLock => 'Biometrische Sperre';

  @override
  String get biometricLockSubtitle =>
      'Erfordert FaceID/TouchID für sensible Aktionen';

  @override
  String get language => 'Sprache';

  @override
  String get currency => 'Währung';

  @override
  String get dataManagement => 'Datenverwaltung';

  @override
  String get exportPdfSubtitle => 'Versicherungsbericht erstellen';

  @override
  String get backupData => 'Daten sichern';

  @override
  String get backupDataSubtitle => 'Lokales Backup (Demnächst)';

  @override
  String get preferences => 'Einstellungen';

  @override
  String get about => 'Über';

  @override
  String get version => 'Version';
}
