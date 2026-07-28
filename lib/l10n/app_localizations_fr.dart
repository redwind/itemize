// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Itemize';

  @override
  String get dashboardTitle => 'Tableau de bord';

  @override
  String get totalValue => 'Valeur totale';

  @override
  String get assetsTab => 'Actifs';

  @override
  String get settingsTab => 'Paramètres';

  @override
  String get searchPlaceholder => 'Rechercher des actifs...';

  @override
  String get noAssetsFound => 'Aucun actif trouvé';

  @override
  String get addItemTitle => 'Ajouter un nouvel actif';

  @override
  String get smartScan => 'Scan intelligent (IA)';

  @override
  String get scanBarcode => 'Scanner le code-barres';

  @override
  String get scanReceipt => 'Scanner le reçu (OCR)';

  @override
  String get exportPdf => 'Exporter le rapport PDF';

  @override
  String get biometricLock => 'Verrouillage biométrique';

  @override
  String get biometricLockSubtitle =>
      'Nécessite FaceID/TouchID pour les actions sensibles';

  @override
  String get language => 'Langue';

  @override
  String get currency => 'Devise';

  @override
  String get dataManagement => 'Gestion des données';

  @override
  String get exportPdfSubtitle => 'Générer un rapport d\'assurance';

  @override
  String get backupData => 'Sauvegarder les données';

  @override
  String get backupDataSubtitle => 'Sauvegarde locale (Bientôt disponible)';

  @override
  String get preferences => 'Préférences';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';
}
