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
  String get dashboardTitle => 'Übersicht';

  @override
  String get assetsTab => 'Gegenstände';

  @override
  String get careTab => 'Pflege';

  @override
  String get settingsTab => 'Einstellungen';

  @override
  String get totalValue => 'Gesamtwert';

  @override
  String get estimatedValueToday => 'Geschätzter Zeitwert';

  @override
  String get underInsuredTitle => 'Sie sind möglicherweise unterversichert';

  @override
  String underInsuredBody(String amount, String limit) {
    return 'Was Sie erfasst haben, ist rund $amount mehr wert als Ihre Hausratversicherung über $limit abdeckt. Sprechen Sie am besten mit Ihrem Versicherer.';
  }

  @override
  String get noAssetsData => 'Keine Daten';

  @override
  String get errorLoadingChart => 'Diagramm konnte nicht geladen werden';

  @override
  String get searchPlaceholder => 'Gegenstände suchen …';

  @override
  String get noAssetsFound => 'Keine Gegenstände gefunden';

  @override
  String genericError(String details) {
    return 'Fehler: $details';
  }

  @override
  String get addItemTitle => 'Neuer Gegenstand';

  @override
  String get editItemTitle => 'Gegenstand bearbeiten';

  @override
  String get itemName => 'Bezeichnung';

  @override
  String get nameRequired => 'Bezeichnung ist erforderlich';

  @override
  String get price => 'Preis';

  @override
  String get fieldRequired => 'Erforderlich';

  @override
  String get currency => 'Währung';

  @override
  String get room => 'Raum';

  @override
  String get category => 'Kategorie';

  @override
  String get chooseCategory => 'Bitte wählen Sie eine Kategorie.';

  @override
  String get uncategorized => 'Ohne Kategorie';

  @override
  String get identification => 'Identifikation';

  @override
  String get identificationHint =>
      'Was ein Versicherer verlangt, um nachzuweisen, welches Exemplar Ihnen gehörte.';

  @override
  String get brand => 'Marke';

  @override
  String get model => 'Modell';

  @override
  String get serialNumber => 'Seriennummer';

  @override
  String get barcode => 'Barcode';

  @override
  String get purchase => 'Kauf';

  @override
  String get purchaseDate => 'Kaufdatum';

  @override
  String get warrantyExpiry => 'Garantie bis';

  @override
  String get notSet => 'Nicht angegeben';

  @override
  String get receipt => 'Kaufbeleg';

  @override
  String get receiptAttached => 'Hinterlegt';

  @override
  String get receiptHint => 'Kaufnachweis für den Schadensfall';

  @override
  String get notes => 'Notizen';

  @override
  String get notesHint => 'Zustand, Kaufort, Zubehör …';

  @override
  String get markAsFavorite => 'Als Favorit markieren';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get chooseFromPhotos => 'Aus Fotos wählen';

  @override
  String get pickStockImage => 'Symbolbild wählen';

  @override
  String get pickStockImageHint => 'Stühle, Tische, Haushaltsgeräte und mehr';

  @override
  String get makeCoverPhoto => 'Als Titelbild festlegen';

  @override
  String get makeCoverPhotoHint => 'Erscheint in Listen und Berichten';

  @override
  String get removePhoto => 'Foto entfernen';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String get photosEmptyHint =>
      'Fotos hinzufügen — das erste wird zum Titelbild.';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fotos.',
      one: '1 Foto.',
    );
    return '$_temp0 Tippen Sie eines an, um es zu entfernen oder zum Titelbild zu machen.';
  }

  @override
  String get coverBadge => 'Titelbild';

  @override
  String get photoLibrary => 'Fotomediathek';

  @override
  String get noMatchingItems => 'Keine Treffer';

  @override
  String get smartScan => 'Scan';

  @override
  String get scanNameplate => 'Typenschild scannen';

  @override
  String get scanNameplateHint => 'Liest Marke, Modell und Seriennummer';

  @override
  String get scanReceipt => 'Kaufbeleg scannen';

  @override
  String get scanReceiptHint => 'Trägt Preis und Kaufdatum ein';

  @override
  String get scanBarcode => 'Barcode scannen';

  @override
  String get scanBarcodeHint => 'Erfasst den Produktcode';

  @override
  String barcodeSaved(String code) {
    return 'Barcode gespeichert: $code';
  }

  @override
  String get noBarcodeFound => 'Kein Barcode gefunden';

  @override
  String get nameplateUnreadable =>
      'Auf diesem Schild ist nichts lesbar. Füllen Sie den Bildausschnitt damit aus.';

  @override
  String nameplateRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Felder gelesen.',
      one: '1 Feld gelesen.',
    );
    return '$_temp0 Bitte gleichen Sie sie mit dem Schild ab.';
  }

  @override
  String get receiptScanned => 'Beleg gescannt. Bitte prüfen Sie die Angaben.';

  @override
  String get quickCaptureTitle => 'Schnellerfassung';

  @override
  String get quickCaptureEmptyTitle => 'Zuerst alles fotografieren';

  @override
  String get quickCaptureEmptyBody =>
      'Die Kamera bleibt zwischen den Aufnahmen offen. Gehen Sie durch den Raum und benennen Sie danach hier, was Sie fotografiert haben.';

  @override
  String get keepShooting => 'Weiter fotografieren';

  @override
  String get discardPhoto => 'Dieses Foto verwerfen';

  @override
  String saveCount(int count) {
    return '$count speichern';
  }

  @override
  String get save => 'Speichern';

  @override
  String savedNeedNames(int saved, int left) {
    return '$saved gespeichert. $left brauchen noch eine Bezeichnung.';
  }

  @override
  String get addOneItem => 'Einzelnen Gegenstand anlegen';

  @override
  String get addOneItemHint => 'Mit allen Angaben';

  @override
  String get quickCaptureRoom => 'Ganzen Raum erfassen';

  @override
  String get quickCaptureRoomHint => 'Alles fotografieren, danach benennen';

  @override
  String get welcomeTitle => 'Fangen Sie mit einem Raum an';

  @override
  String get welcomeBody =>
      'Die meisten geben ihr Hausratverzeichnis um den zehnten Gegenstand herum auf, weil jeder einzelne ein Formular verlangt. Machen wir es also andersherum.';

  @override
  String get welcomeStep1 => 'Alles fotografieren';

  @override
  String get welcomeStep1Hint =>
      'Die Kamera bleibt zwischen den Aufnahmen offen. Gehen Sie durch den Raum.';

  @override
  String get welcomeStep2 => 'Danach benennen';

  @override
  String get welcomeStep2Hint =>
      'Im Sitzen, in einer einzigen Liste, bei einer Tasse Kaffee.';

  @override
  String get welcomeStep3 => 'Dann läuft es von allein';

  @override
  String get welcomeStep3Hint =>
      'Garantien, fällige Wartungen und ein Bericht, falls Sie je einen Schaden melden.';

  @override
  String get welcomeStart => 'Einen Raum fotografieren';

  @override
  String get welcomeSkip => 'Ich lege alles einzeln an';

  @override
  String get purchased => 'Gekauft am';

  @override
  String get warrantyExpires => 'Garantie bis';

  @override
  String get careAndHistory => 'Pflege und Historie';

  @override
  String get careNothingScheduled =>
      'Tragen Sie ein, was ansteht, und protokollieren Sie Reparaturen';

  @override
  String careNoneOverdue(int count) {
    return '$count geplant, nichts überfällig';
  }

  @override
  String careOverdue(int late, int total) {
    return '$late von $total geplanten überfällig';
  }

  @override
  String valueEstimateDepreciates(String category) {
    return 'Lineare Schätzung für $category. Ihr Versicherer rechnet unter Umständen anders.';
  }

  @override
  String valueEstimateHeld(String category) {
    return '$category unterliegt keiner Wertminderung — Versicherer führen das meist gesondert.';
  }

  @override
  String get edit => 'Bearbeiten';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get ok => 'OK';

  @override
  String deleteItemTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get deleteItemSimple =>
      'Sie können das direkt danach rückgängig machen.';

  @override
  String deleteItemWithHistory(int schedules, int records) {
    return 'Damit verschwinden auch $schedules geplante Wartungen und $records Einträge der Historie. Sie können das direkt danach rückgängig machen.';
  }

  @override
  String deletedItem(String name) {
    return '$name gelöscht';
  }

  @override
  String get undo => 'Rückgängig';

  @override
  String get warranties => 'Garantien';

  @override
  String get standingEndingSoon => 'Läuft bald ab';

  @override
  String get standingCovered => 'Abgedeckt';

  @override
  String get standingExpired => 'Abgelaufen';

  @override
  String get standingUnknown => 'Ohne Datum';

  @override
  String standingCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get emptyEndingSoon =>
      'Nichts läuft demnächst ab. Hier erscheinen Gegenstände in ihren letzten drei Garantiemonaten.';

  @override
  String get emptyCovered => 'Noch nichts steht unter Garantie.';

  @override
  String get emptyExpired => 'Keine Garantie ist abgelaufen.';

  @override
  String get emptyUnknown =>
      'Zu jedem Gegenstand gehört ein Garantiedatum. Sie einzutragen macht diesen Bildschirm überhaupt erst nützlich.';

  @override
  String get notRecorded => 'Nicht erfasst';

  @override
  String get endsToday => 'Läuft heute ab';

  @override
  String daysLeft(int days) {
    return 'noch $days T.';
  }

  @override
  String monthsLeft(int months) {
    return 'noch $months Mon.';
  }

  @override
  String yearsLeft(int years) {
    return 'noch $years J.';
  }

  @override
  String yearsMonthsLeft(int years, int months) {
    return 'noch $years J. $months Mon.';
  }

  @override
  String endedDaysAgo(int days) {
    return 'Vor $days T. abgelaufen';
  }

  @override
  String endedMonthsAgo(int months) {
    return 'Vor $months Mon. abgelaufen';
  }

  @override
  String endedYearsAgo(int years) {
    return 'Vor $years J. abgelaufen';
  }

  @override
  String needsDoing(int count) {
    return 'Zu erledigen ($count)';
  }

  @override
  String get nothingScheduledAnywhere =>
      'Noch nichts geplant. Öffnen Sie einen Gegenstand und tragen Sie ein, was er braucht — ein Filter, eine Wartung — und es erscheint hier, sobald es fällig wird.';

  @override
  String get nothingDueFortnight =>
      'In den nächsten zwei Wochen steht nichts an.';

  @override
  String warrantiesAtRisk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Garantien sind gefährdet',
      one: '1 Garantie ist gefährdet',
    );
    return '$_temp0';
  }

  @override
  String get warrantiesAtRiskBody =>
      'Die Wartung dieser Gegenstände ist Bedingung für ihre Garantie, und sie ist ausgeblieben. Eine versäumte Wartung ist ein Grund, einen Schaden abzulehnen.';

  @override
  String get warrantyAtRiskItem =>
      'Dieser Gegenstand steht noch unter Garantie, und diese Wartung ist Bedingung dafür. Eine versäumte Wartung ist ein Grund, einen Schaden abzulehnen.';

  @override
  String daysLate(int days) {
    return '$days T. überfällig';
  }

  @override
  String dueInDays(int days) {
    return 'in $days T.';
  }

  @override
  String entriesToCheck(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge prüfen',
      one: '1 Eintrag prüfen',
    );
    return '$_temp0';
  }

  @override
  String get entriesToCheckBody =>
      'Besitzen Sie diese noch, und stimmen die Angaben weiterhin? Eine Liste, die nicht mehr stimmt, ist eine, der ein Versicherer widersprechen kann.';

  @override
  String get stillRight => 'Stimmt noch';

  @override
  String get check => 'Prüfen';

  @override
  String get backupNudgeNever => 'Das alles existiert nur auf diesem Telefon';

  @override
  String backupNudgeDays(int days) {
    return 'Seit $days Tagen keine Sicherung';
  }

  @override
  String backupNudgeBody(int count) {
    return '$count Gegenstände, ihre Fotos und jede protokollierte Reparatur. Geht das Telefon verloren, geht alles mit.';
  }

  @override
  String get scheduledJobs => 'Geplante Wartungen';

  @override
  String get history => 'Historie';

  @override
  String get add => 'Hinzufügen';

  @override
  String get noSchedulesYet =>
      'Nichts geplant. Tragen Sie ein, was dieser Gegenstand braucht — ein Filter, eine Wartung — und Sie werden zum Termin erinnert.';

  @override
  String get noHistoryYet =>
      'Noch nichts protokolliert. Reparaturen festzuhalten gibt den Kosten unten erst einen Sinn — und ist genau das, was ein Hersteller verlangt, wenn eine Garantie von der Wartung abhängt.';

  @override
  String overdueByEvery(int days, int months) {
    return '$days Tage überfällig · alle $months Mon.';
  }

  @override
  String dueOnEvery(String date, int months) {
    return 'Fällig am $date · alle $months Mon.';
  }

  @override
  String get newJob => 'Neue Wartung';

  @override
  String get editJob => 'Wartung bearbeiten';

  @override
  String get commonForThis => 'Üblich bei dieser Art von Gegenstand';

  @override
  String get whatNeedsDoing => 'Was ansteht';

  @override
  String get whatNeedsDoingHint => 'Wasserfilter wechseln';

  @override
  String get howOften => 'Wie oft';

  @override
  String get requiredForWarranty => 'Für den Garantieerhalt vorgeschrieben';

  @override
  String get requiredForWarrantyHint =>
      'Sie werden gewarnt, wenn dies versäumt wird, solange der Gegenstand noch abgedeckt ist.';

  @override
  String get addJob => 'Hinzufügen';

  @override
  String get intervalMonthly => 'Monatlich';

  @override
  String get intervalQuarterly => 'Alle 3 Monate';

  @override
  String get intervalHalfYearly => 'Alle 6 Monate';

  @override
  String get intervalYearly => 'Jährlich';

  @override
  String get intervalBiennial => 'Alle 2 Jahre';

  @override
  String get logWorkDone => 'Durchgeführte Arbeit erfassen';

  @override
  String get kindMaintenance => 'Wartung';

  @override
  String get kindRepair => 'Reparatur';

  @override
  String get kindInspection => 'Prüfung';

  @override
  String get whatWasDone => 'Was gemacht wurde';

  @override
  String get whatWasDoneHint => 'Pumpe ersetzt';

  @override
  String get cost => 'Kosten';

  @override
  String get whoDidIt => 'Ausgeführt von';

  @override
  String get when => 'Wann';

  @override
  String get satisfiesWhichJob => 'Erfüllt welche Wartung';

  @override
  String get satisfiesWhichJobHint =>
      'Markiert diese Wartung als erledigt und verschiebt den nächsten Termin';

  @override
  String get none => 'Keine';

  @override
  String get free => 'Kostenlos';

  @override
  String get verdictKeep => 'Behalten';

  @override
  String get verdictWatch => 'Im Auge behalten';

  @override
  String get verdictReplace => 'Ersetzen';

  @override
  String get paidForIt => 'Kaufpreis';

  @override
  String get spentOnRepairs => 'Für Reparaturen ausgegeben';

  @override
  String get worthToday => 'Zeitwert heute';

  @override
  String get totalOutlay => 'Gesamtaufwand';

  @override
  String get verdictKeepBody =>
      'Die Reparaturen fallen gegenüber dem heutigen Wert kaum ins Gewicht.';

  @override
  String get verdictWatchBody =>
      'Die Reparaturen übersteigen die Hälfte des Restwerts. Vor der nächsten lohnt es, zweimal nachzudenken.';

  @override
  String get verdictReplaceBody =>
      'Sie haben mehr für Reparaturen ausgegeben, als der Gegenstand heute wert ist. Ein Ersatz kostet womöglich weniger als die nächste Reparatur.';

  @override
  String get verdictDisclaimer =>
      'Eine Faustregel auf geschätzte Werte angewandt, kein Gutachten.';

  @override
  String get exportPdf => 'Bericht als PDF exportieren';

  @override
  String get exportPdfSubtitle => 'Versicherungsbericht erstellen';

  @override
  String get exportPdfSubtitlePro =>
      'Vollständig: Fotos, Seriennummern, Belege, unterschrieben';

  @override
  String get nothingToReport => 'Es gibt noch nichts zu berichten.';

  @override
  String get reportPreview => 'Berichtsvorschau';

  @override
  String get summaryReportBanner => 'Dies ist der Kurzbericht';

  @override
  String summaryReportBannerBody(int count) {
    return 'Pro macht daraus das Dokument, das ein Versicherer verlangt: eine Seite je Gegenstand für alle $count — mit Fotos, Seriennummer, Kaufbeleg, Wartungshistorie und geschätztem Zeitwert, dazu eine Erklärung zum Unterschreiben.';
  }

  @override
  String get seeWhatProAdds => 'Ansehen, was Pro ergänzt';

  @override
  String get canStillShare =>
      'Diesen hier können Sie trotzdem teilen oder drucken.';

  @override
  String get backupData => 'In eine Datei sichern';

  @override
  String get backupNeverSubtitle =>
      'Noch nie gesichert — alles in einer Datei speichern';

  @override
  String get backupTodaySubtitle => 'Zuletzt heute gesichert';

  @override
  String get backupYesterdaySubtitle => 'Zuletzt gestern gesichert';

  @override
  String backupDaysAgoSubtitle(int days) {
    return 'Zuletzt vor $days Tagen gesichert';
  }

  @override
  String get restoreBackup => 'Aus einer Sicherung wiederherstellen';

  @override
  String get restoreBackupSubtitle =>
      'Fügt dieser App die Gegenstände aus einer Sicherungsdatei hinzu';

  @override
  String get nothingToBackUp => 'Es gibt noch nichts zu sichern.';

  @override
  String get preparingBackup => 'Sicherung wird vorbereitet …';

  @override
  String get restoring => 'Wird wiederhergestellt …';

  @override
  String backupFailed(String details) {
    return 'Sicherung fehlgeschlagen: $details';
  }

  @override
  String restoreFailed(String details) {
    return 'Wiederherstellung fehlgeschlagen: $details';
  }

  @override
  String backupShareText(int count) {
    return 'Itemize-Sicherung — $count Gegenstände. Bewahren Sie diese Datei dort auf, wo Sie sie wiederfinden.';
  }

  @override
  String get restoreCompleteTitle => 'Wiederherstellung abgeschlossen';

  @override
  String restoreCompleteBody(
    int added,
    int updated,
    int photos,
    int schedules,
    int records,
  ) {
    return '$added Gegenstände hinzugefügt, $updated aktualisiert, $photos Fotos wiederhergestellt.\n$schedules geplante Wartungen und $records Einträge der Historie wiederhergestellt.\n\nNichts, was bereits auf diesem Gerät war, wurde entfernt.';
  }

  @override
  String get preferences => 'Einstellungen';

  @override
  String get about => 'Über';

  @override
  String get version => 'Version';

  @override
  String get language => 'Sprache';

  @override
  String get coverLimit => 'Versicherungssumme Hausrat';

  @override
  String get coverLimitUnset =>
      'Nicht angegeben — nennen Sie sie, und wir warnen Sie, wenn Sie darüber hinauswachsen';

  @override
  String get coverLimitDialogBody =>
      'Der Höchstbetrag, den Ihre Police für Ihren Hausrat zahlt. Sie finden ihn in Ihrem Versicherungsschein.';

  @override
  String get coverLimitHint => 'Leer lassen zum Entfernen';

  @override
  String get warrantyReminders => 'Garantie-Erinnerungen';

  @override
  String get warrantyRemindersSubtitle => 'Hinweis 30, 7 und 1 Tag vor Ablauf';

  @override
  String get maintenanceReminders => 'Wartungserinnerungen';

  @override
  String get maintenanceRemindersSubtitle =>
      'Hinweis eine Woche vor dem Termin';

  @override
  String get notificationsOff =>
      'Mitteilungen sind für Itemize deaktiviert. Aktivieren Sie sie in den Geräteeinstellungen.';

  @override
  String get biometricLock => 'Biometrische Sperre';

  @override
  String get biometricLockSubtitle =>
      'FaceID/TouchID für sensible Aktionen verlangen';

  @override
  String get biometricProOnly => 'In der Pro-Version verfügbar';

  @override
  String get biometricDeviceSecurityOff =>
      'Gerätesicherung deaktiviert. Biometrische Sperre ausgeschaltet.';

  @override
  String get authFailed => 'Authentifizierung fehlgeschlagen.';

  @override
  String get authNotAvailable =>
      'Biometrie oder Gerätesicherung ist nicht eingerichtet. Bitte richten Sie eine Bildschirmsperre ein (PIN oder Muster).';

  @override
  String get authLockedOut =>
      'Zu viele Versuche. Bitte später erneut versuchen.';

  @override
  String get authPermanentlyLockedOut =>
      'Biometrie deaktiviert. Verwenden Sie PIN oder Muster, oder richten Sie sie neu ein.';

  @override
  String get authToExport =>
      'Authentifizieren, um Ihr Verzeichnis zu exportieren';

  @override
  String get authToBackUp => 'Authentifizieren, um Ihre Daten zu sichern';

  @override
  String get authToRestore =>
      'Authentifizieren, um eine Sicherung wiederherzustellen';

  @override
  String get authToDisableLock => 'Authentifizieren, um die Sperre aufzuheben';

  @override
  String get appLocked => 'Itemize gesperrt';

  @override
  String get unlock => 'Entsperren';

  @override
  String get upgradeToPro => 'Auf Pro wechseln';

  @override
  String get upgradeToProSubtitle =>
      'Versicherungsberichte und Sicherungen. Alles andere ist kostenlos.';

  @override
  String get proBadge => 'PRO';

  @override
  String get unlockFullPotential => 'Alles freischalten';

  @override
  String get paywallLead =>
      'Ihren Besitz zu erfassen und zu pflegen ist kostenlos, unbegrenzt, und bleibt es. Pro ist dafür da, wieder etwas herauszuholen.';

  @override
  String get paywallReport => 'Versicherungsbericht';

  @override
  String get paywallReportBody =>
      'Eine Seite je Gegenstand — Fotos, Seriennummer, Kaufbeleg, Wartungshistorie und geschätzter Zeitwert, nach Räumen gegliedert und unterschrieben.';

  @override
  String get paywallBackup => 'Sichern und wiederherstellen';

  @override
  String get paywallBackupBody =>
      'Jeder Gegenstand, jedes Foto und jedes Jahr Historie in einer Datei, die Ihnen gehört. Kein Konto, keine Cloud; nichts verlässt Ihr Gerät, außer Sie verschicken es.';

  @override
  String get paywallBiometric => 'Biometrische Sperre';

  @override
  String get paywallBiometricBody =>
      'Halten Sie Ihr Verzeichnis hinter FaceID oder TouchID.';

  @override
  String get storeUnavailable =>
      'Der Store ist derzeit nicht erreichbar. Bitte später erneut versuchen.';

  @override
  String get upgrade => 'Auf Pro wechseln';

  @override
  String upgradeFor(String price) {
    return 'Auf Pro wechseln für $price';
  }

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get subscriptionFinePrint =>
      'Verlängert sich automatisch bis zur Kündigung. Jederzeit in Ihren Kontoeinstellungen verwaltbar oder kündbar.';

  @override
  String get oneTimeFinePrint => 'Einmalkauf. Kein Abonnement.';

  @override
  String get welcomeToPro => 'Willkommen bei Pro!';

  @override
  String get reportTitlePro => 'Hausratverzeichnis';

  @override
  String get reportTitleFree => 'Itemize-Bericht';

  @override
  String get reportItemsRecorded => 'Erfasste Gegenstände';

  @override
  String get reportRoomsCovered => 'Erfasste Räume';

  @override
  String get reportTotalPaid => 'Kaufpreis gesamt';

  @override
  String get reportEstimatedToday => 'Geschätzter Zeitwert';

  @override
  String get reportDepreciation => 'Geschätzte Wertminderung';

  @override
  String get reportWithSerial => 'Gegenstände mit Seriennummer';

  @override
  String get reportWithReceipt => 'Gegenstände mit Kaufbeleg';

  @override
  String reportOfTotal(int count, int total) {
    return '$count von $total';
  }

  @override
  String get reportEstimateDisclaimer =>
      'Die geschätzten Werte sind lineare Rechnungen auf Grundlage üblicher Nutzungsdauern je Kategorie. Sie helfen Ihnen, Ihre Deckung zu prüfen, und sind kein Gutachten; Ihr Versicherer rechnet unter Umständen anders.';

  @override
  String get reportNoItems => 'Keine Gegenstände erfasst.';

  @override
  String get reportColItem => 'Gegenstand';

  @override
  String get reportColSerialModel => 'Serie / Modell';

  @override
  String get reportColPurchased => 'Gekauft';

  @override
  String get reportColPaid => 'Bezahlt';

  @override
  String get reportColToday => 'Zeitwert';

  @override
  String reportSubtotal(String room, String amount) {
    return 'Zwischensumme $room: $amount';
  }

  @override
  String get reportItemDetail => 'Einzelaufstellung';

  @override
  String get reportPurchasePrice => 'Kaufpreis';

  @override
  String get reportWarrantyUntil => 'Garantie bis';

  @override
  String get reportServiceHistory => 'Wartungshistorie';

  @override
  String reportSpentToDate(String amount) {
    return 'Bisher für diesen Gegenstand ausgegeben: $amount';
  }

  @override
  String get reportDeclaration => 'Erklärung';

  @override
  String reportDeclarationBody(String date) {
    return 'Ich bestätige, dass die in diesem Bericht aufgeführten Gegenstände am $date in meinem Eigentum standen und dass die Angaben und Fotografien nach bestem Wissen zutreffen.';
  }

  @override
  String get reportSignature => 'Unterschrift';

  @override
  String get reportDate => 'Datum';

  @override
  String get reportSummaryNotice => 'Dies ist der Kurzbericht.';

  @override
  String get reportSummaryNoticeBody =>
      'Itemize Pro ergänzt eine Seite je Gegenstand mit Fotografien, Seriennummer, Kaufbeleg, Wartungshistorie und geschätztem Zeitwert sowie eine unterschriebene Erklärung — das Dokument, das ein Versicherer im Schadensfall verlangt.';

  @override
  String reportPageOf(int page, int total) {
    return 'Seite $page von $total';
  }

  @override
  String get reportFooterFree => 'Erstellt mit Itemize Free';

  @override
  String get roomLivingRoom => 'Wohnzimmer';

  @override
  String get roomKitchen => 'Küche';

  @override
  String get roomBedroom => 'Schlafzimmer';

  @override
  String get roomOffice => 'Arbeitszimmer';

  @override
  String get roomGarage => 'Garage';

  @override
  String get roomOther => 'Sonstiges';

  @override
  String get catElectronics => 'Elektronik';

  @override
  String get catFurniture => 'Möbel';

  @override
  String get catAppliances => 'Haushaltsgeräte';

  @override
  String get catJewelry => 'Schmuck und Uhren';

  @override
  String get catClothing => 'Kleidung';

  @override
  String get catTools => 'Werkzeug und Geräte';

  @override
  String get catSports => 'Sport und Freizeit';

  @override
  String get catKitchenware => 'Küchenausstattung';

  @override
  String get catArt => 'Kunst und Sammlerstücke';

  @override
  String get catOther => 'Sonstiges';

  @override
  String get jobReplaceWaterFilter => 'Wasserfilter wechseln';

  @override
  String get jobCleanCoils => 'Kondensator reinigen';

  @override
  String get jobAnnualService => 'Jahreswartung';

  @override
  String get jobCleanVents => 'Lüftungsschlitze entstauben';

  @override
  String get jobReplaceBattery => 'Pufferbatterie wechseln';

  @override
  String get jobServiceSharpen => 'Warten und schärfen';

  @override
  String get jobSafetyInspection => 'Sicherheitsprüfung';

  @override
  String get jobTreatOil => 'Pflegen oder ölen';

  @override
  String get jobService => 'Wartung';

  @override
  String get itemSofa => 'Sofa';

  @override
  String get itemArmchair => 'Sessel';

  @override
  String get itemCoffeeTable => 'Couchtisch';

  @override
  String get itemTelevision => 'Fernseher';

  @override
  String get itemFloorLamp => 'Stehlampe';

  @override
  String get itemBookshelf => 'Bücherregal';

  @override
  String get itemSpeaker => 'Lautsprecher';

  @override
  String get itemRefrigerator => 'Kühlschrank';

  @override
  String get itemMicrowave => 'Mikrowelle';

  @override
  String get itemCoffeeMaker => 'Kaffeemaschine';

  @override
  String get itemBlender => 'Mixer';

  @override
  String get itemDiningTable => 'Esstisch';

  @override
  String get itemDishwasher => 'Geschirrspüler';

  @override
  String get itemBed => 'Bett';

  @override
  String get itemWardrobe => 'Kleiderschrank';

  @override
  String get itemWashingMachine => 'Waschmaschine';

  @override
  String get itemAirPurifier => 'Luftreiniger';

  @override
  String get itemIron => 'Bügeleisen';

  @override
  String get itemLaptop => 'Laptop';

  @override
  String get itemMonitor => 'Monitor';

  @override
  String get itemDesk => 'Schreibtisch';

  @override
  String get itemOfficeChair => 'Bürostuhl';

  @override
  String get itemPrinter => 'Drucker';

  @override
  String get itemRouter => 'Router';

  @override
  String get itemKeyboard => 'Tastatur';

  @override
  String get itemHeadphones => 'Kopfhörer';

  @override
  String get itemBicycle => 'Fahrrad';

  @override
  String get itemCar => 'Auto';

  @override
  String get itemPowerTools => 'Elektrowerkzeuge';

  @override
  String get itemToolbox => 'Werkzeugkasten';

  @override
  String get itemLawnMower => 'Rasenmäher';

  @override
  String get itemCamera => 'Kamera';

  @override
  String get itemWatch => 'Armbanduhr';

  @override
  String get itemPhone => 'Telefon';

  @override
  String get itemTablet => 'Tablet';

  @override
  String get itemBooks => 'Bücher';

  @override
  String get itemGymEquipment => 'Sportgeräte';

  @override
  String get itemLuggage => 'Gepäck';

  @override
  String get itemMusicalInstrument => 'Musikinstrument';

  @override
  String get authToContinue =>
      'Bitte authentifizieren Sie sich, um fortzufahren';
}
