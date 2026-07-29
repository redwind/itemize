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
  String get assetsTab => 'Biens';

  @override
  String get careTab => 'Entretien';

  @override
  String get settingsTab => 'Réglages';

  @override
  String get totalValue => 'Valeur totale';

  @override
  String get estimatedValueToday => 'Valeur estimée aujourd\'hui';

  @override
  String get underInsuredTitle => 'Vous êtes peut-être sous-assuré';

  @override
  String underInsuredBody(String amount, String limit) {
    return 'Ce que vous avez enregistré vaut environ $amount de plus que votre garantie mobilier de $limit. Cela vaut la peine d\'en parler à votre assureur.';
  }

  @override
  String get noAssetsData => 'Aucune donnée';

  @override
  String get errorLoadingChart => 'Erreur de chargement du graphique';

  @override
  String get searchPlaceholder => 'Rechercher un bien...';

  @override
  String get noAssetsFound => 'Aucun bien trouvé';

  @override
  String genericError(String details) {
    return 'Erreur : $details';
  }

  @override
  String get addItemTitle => 'Nouveau bien';

  @override
  String get editItemTitle => 'Modifier le bien';

  @override
  String get itemName => 'Nom du bien';

  @override
  String get nameRequired => 'Le nom est obligatoire';

  @override
  String get price => 'Prix';

  @override
  String get fieldRequired => 'Obligatoire';

  @override
  String get invalidAmount => 'Saisissez un montant valide';

  @override
  String get currency => 'Devise';

  @override
  String get room => 'Pièce';

  @override
  String get category => 'Catégorie';

  @override
  String get chooseCategory => 'Veuillez choisir une catégorie.';

  @override
  String get uncategorized => 'Sans catégorie';

  @override
  String get identification => 'Identification';

  @override
  String get identificationHint =>
      'Ce qu\'un assureur demande pour prouver quel exemplaire vous possédiez.';

  @override
  String get brand => 'Marque';

  @override
  String get model => 'Modèle';

  @override
  String get serialNumber => 'Numéro de série';

  @override
  String get barcode => 'Code-barres';

  @override
  String get purchase => 'Achat';

  @override
  String get purchaseDate => 'Date d\'achat';

  @override
  String get warrantyExpiry => 'Fin de garantie';

  @override
  String get notSet => 'Non renseigné';

  @override
  String get receipt => 'Facture';

  @override
  String get receiptAttached => 'Jointe';

  @override
  String get receiptHint => 'Justificatif d\'achat en cas de sinistre';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'État, lieu d\'achat, accessoires...';

  @override
  String get markAsFavorite => 'Marquer comme favori';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromPhotos => 'Choisir dans les photos';

  @override
  String get pickStockImage => 'Choisir une illustration';

  @override
  String get pickStockImageHint => 'Chaises, tables, électroménager et plus';

  @override
  String get makeCoverPhoto => 'Définir comme photo principale';

  @override
  String get makeCoverPhotoHint => 'Affichée dans les listes et les rapports';

  @override
  String get removePhoto => 'Supprimer la photo';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String get photosEmptyHint =>
      'Ajoutez des photos — la première devient la photo principale.';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos.',
      one: '1 photo.',
    );
    return '$_temp0 Touchez-en une pour la supprimer ou la définir comme principale.';
  }

  @override
  String get coverBadge => 'Principale';

  @override
  String get photoLibrary => 'Photothèque';

  @override
  String get noMatchingItems => 'Aucun résultat';

  @override
  String get smartScan => 'Scan';

  @override
  String get scanNameplate => 'Scanner l\'étiquette signalétique';

  @override
  String get scanNameplateHint =>
      'Lit la marque, le modèle et le numéro de série';

  @override
  String get scanReceipt => 'Scanner la facture';

  @override
  String get scanReceiptHint => 'Renseigne le prix et la date d\'achat';

  @override
  String get scanBarcode => 'Scanner le code-barres';

  @override
  String get scanBarcodeHint => 'Enregistre le code produit';

  @override
  String barcodeSaved(String code) {
    return 'Code-barres enregistré : $code';
  }

  @override
  String get noBarcodeFound => 'Aucun code-barres trouvé';

  @override
  String get nameplateUnreadable =>
      'Rien de lisible sur cette étiquette. Essayez de la cadrer en plein écran.';

  @override
  String nameplateRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count champs lus.',
      one: '1 champ lu.',
    );
    return '$_temp0 Vérifiez-les sur l\'étiquette.';
  }

  @override
  String get receiptScanned => 'Facture scannée. Vérifiez les détails.';

  @override
  String get quickCaptureTitle => 'Prise rapide';

  @override
  String get quickCaptureEmptyTitle => 'Photographiez tout d\'abord';

  @override
  String get quickCaptureEmptyBody =>
      'L\'appareil photo reste ouvert entre les prises. Faites le tour de la pièce, puis revenez ici nommer ce que vous avez photographié.';

  @override
  String get keepShooting => 'Continuer à photographier';

  @override
  String get discardPhoto => 'Supprimer cette photo';

  @override
  String saveCount(int count) {
    return 'Enregistrer $count';
  }

  @override
  String get save => 'Enregistrer';

  @override
  String savedNeedNames(int saved, int left) {
    return '$saved enregistrés. Il en reste $left à nommer.';
  }

  @override
  String get addOneItem => 'Ajouter un bien';

  @override
  String get addOneItemHint => 'Avec tous ses détails';

  @override
  String get quickCaptureRoom => 'Prise rapide d\'une pièce';

  @override
  String get quickCaptureRoomHint => 'Photographiez tout, nommez ensuite';

  @override
  String get welcomeTitle => 'Commencez par une pièce';

  @override
  String get welcomeBody =>
      'La plupart des gens abandonnent leur inventaire vers le dixième objet, parce que chacun réclame un formulaire à remplir. Alors prenons le problème à l\'envers.';

  @override
  String get welcomeStep1 => 'Photographiez tout';

  @override
  String get welcomeStep1Hint =>
      'L\'appareil photo reste ouvert entre les prises. Faites le tour de la pièce.';

  @override
  String get welcomeStep2 => 'Nommez ensuite';

  @override
  String get welcomeStep2Hint =>
      'Assis, dans une seule liste, une tasse de café à la main.';

  @override
  String get welcomeStep3 => 'Puis l\'app s\'en occupe';

  @override
  String get welcomeStep3Hint =>
      'Garanties, entretiens à venir, et un rapport le jour où vous déclarez un sinistre.';

  @override
  String get welcomeStart => 'Photographier une pièce';

  @override
  String get welcomeSkip => 'J\'ajouterai mes biens un par un';

  @override
  String get purchased => 'Acheté le';

  @override
  String get warrantyExpires => 'Garantie jusqu\'au';

  @override
  String get careAndHistory => 'Entretien et historique';

  @override
  String get careNothingScheduled =>
      'Ajoutez ce qu\'il faut faire, et consignez les réparations';

  @override
  String careNoneOverdue(int count) {
    return '$count planifiés, aucun en retard';
  }

  @override
  String careOverdue(int late, int total) {
    return '$late en retard sur $total planifiés';
  }

  @override
  String valueEstimateDepreciates(String category) {
    return 'Estimation linéaire pour la catégorie $category. Votre assureur peut appliquer un autre barème de vétusté.';
  }

  @override
  String valueEstimateHeld(String category) {
    return '$category ne subit pas de vétusté — les assureurs les traitent généralement à part.';
  }

  @override
  String get edit => 'Modifier';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get ok => 'OK';

  @override
  String deleteItemTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get deleteItemSimple => 'Vous pourrez annuler juste après.';

  @override
  String deleteItemWithHistory(int schedules, int records) {
    return 'Cela supprime aussi $schedules entretiens planifiés et $records entrées d\'historique. Vous pourrez annuler juste après.';
  }

  @override
  String deletedItem(String name) {
    return '$name supprimé';
  }

  @override
  String get undo => 'Annuler';

  @override
  String get warranties => 'Garanties';

  @override
  String get standingEndingSoon => 'Bientôt échues';

  @override
  String get standingCovered => 'Couvert';

  @override
  String get standingExpired => 'Échue';

  @override
  String get standingUnknown => 'Sans date';

  @override
  String standingCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get emptyEndingSoon =>
      'Rien n\'arrive à échéance. Les biens apparaissent ici dans leurs trois derniers mois de garantie.';

  @override
  String get emptyCovered => 'Aucun bien n\'est encore sous garantie.';

  @override
  String get emptyExpired => 'Aucune garantie n\'est échue.';

  @override
  String get emptyUnknown =>
      'Chaque bien porte une date de fin de garantie. Les renseigner est ce qui rend cet écran utile.';

  @override
  String get notRecorded => 'Non renseignée';

  @override
  String get endsToday => 'Échoit aujourd\'hui';

  @override
  String daysLeft(int days) {
    return '$days j restants';
  }

  @override
  String monthsLeft(int months) {
    return '$months mois restants';
  }

  @override
  String yearsLeft(int years) {
    return '$years ans restants';
  }

  @override
  String yearsMonthsLeft(int years, int months) {
    return '$years ans $months mois restants';
  }

  @override
  String endedDaysAgo(int days) {
    return 'Échue il y a $days j';
  }

  @override
  String endedMonthsAgo(int months) {
    return 'Échue il y a $months mois';
  }

  @override
  String endedYearsAgo(int years) {
    return 'Échue il y a $years ans';
  }

  @override
  String needsDoing(int count) {
    return 'À faire ($count)';
  }

  @override
  String get nothingScheduledAnywhere =>
      'Rien n\'est encore planifié. Ouvrez un bien et ajoutez ce qu\'il demande — un filtre, un entretien — et cela apparaîtra ici à l\'échéance.';

  @override
  String get nothingDueFortnight => 'Rien à faire dans les quinze jours.';

  @override
  String warrantiesAtRisk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count garanties sont menacées',
      one: '1 garantie est menacée',
    );
    return '$_temp0';
  }

  @override
  String get warrantiesAtRiskBody =>
      'L\'entretien de ces biens conditionne leur garantie, et il n\'a pas été fait. Un entretien manqué justifie un refus d\'indemnisation.';

  @override
  String get warrantyAtRiskItem =>
      'Ce bien est encore sous garantie, et cet entretien conditionne sa validité. Un entretien manqué justifie un refus d\'indemnisation.';

  @override
  String daysLate(int days) {
    return '$days j de retard';
  }

  @override
  String dueInDays(int days) {
    return 'dans $days j';
  }

  @override
  String entriesToCheck(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fiches à vérifier',
      one: '1 fiche à vérifier',
    );
    return '$_temp0';
  }

  @override
  String get entriesToCheckBody =>
      'Possédez-vous toujours ces biens, et les détails sont-ils encore exacts ? Une liste qui a dérivé est une liste qu\'un assureur peut contester.';

  @override
  String get stillRight => 'Toujours exact';

  @override
  String get check => 'Vérifier';

  @override
  String get backupNudgeNever => 'Tout ceci n\'existe que sur ce téléphone';

  @override
  String backupNudgeDays(int days) {
    return 'Aucune sauvegarde depuis $days jours';
  }

  @override
  String backupNudgeBody(int count) {
    return '$count biens, leurs photos et chaque réparation consignée. Perdez le téléphone et tout disparaît avec.';
  }

  @override
  String get scheduledJobs => 'Entretiens planifiés';

  @override
  String get history => 'Historique';

  @override
  String get add => 'Ajouter';

  @override
  String get noSchedulesYet =>
      'Rien de planifié. Ajoutez ce que ce bien demande — un filtre, un entretien — et vous serez prévenu à l\'échéance.';

  @override
  String get noHistoryYet =>
      'Aucune intervention consignée. Consigner les réparations est ce qui donne un sens au coût ci-dessous — et ce qu\'un fabricant réclame lorsqu\'une garantie dépend de l\'entretien réalisé.';

  @override
  String overdueByEvery(int days, int months) {
    return 'En retard de $days jours · tous les $months mois';
  }

  @override
  String dueOnEvery(String date, int months) {
    return 'Échéance le $date · tous les $months mois';
  }

  @override
  String get newJob => 'Nouvel entretien';

  @override
  String get editJob => 'Modifier l\'entretien';

  @override
  String get commonForThis => 'Courant pour ce type de bien';

  @override
  String get whatNeedsDoing => 'Ce qu\'il faut faire';

  @override
  String get whatNeedsDoingHint => 'Remplacer le filtre à eau';

  @override
  String get howOften => 'Fréquence';

  @override
  String get requiredForWarranty => 'Obligatoire pour conserver la garantie';

  @override
  String get requiredForWarrantyHint =>
      'Vous serez alerté si cet entretien est manqué alors que le bien est encore couvert.';

  @override
  String get addJob => 'Ajouter';

  @override
  String get intervalMonthly => 'Tous les mois';

  @override
  String get intervalQuarterly => 'Tous les 3 mois';

  @override
  String get intervalHalfYearly => 'Tous les 6 mois';

  @override
  String get intervalYearly => 'Tous les ans';

  @override
  String get intervalBiennial => 'Tous les 2 ans';

  @override
  String get logWorkDone => 'Consigner une intervention';

  @override
  String get kindMaintenance => 'Entretien';

  @override
  String get kindRepair => 'Réparation';

  @override
  String get kindInspection => 'Contrôle';

  @override
  String get whatWasDone => 'Ce qui a été fait';

  @override
  String get whatWasDoneHint => 'Remplacement de la pompe';

  @override
  String get cost => 'Coût';

  @override
  String get whoDidIt => 'Par qui';

  @override
  String get when => 'Quand';

  @override
  String get satisfiesWhichJob => 'Correspond à quel entretien';

  @override
  String get satisfiesWhichJobHint =>
      'Marque cet entretien comme fait et décale sa prochaine échéance';

  @override
  String get none => 'Aucun';

  @override
  String get free => 'Gratuit';

  @override
  String get verdictKeep => 'À conserver';

  @override
  String get verdictWatch => 'À surveiller';

  @override
  String get verdictReplace => 'À remplacer';

  @override
  String get paidForIt => 'Prix payé';

  @override
  String get spentOnRepairs => 'Dépensé en réparations';

  @override
  String get worthToday => 'Valeur aujourd\'hui';

  @override
  String get totalOutlay => 'Dépense totale';

  @override
  String get verdictKeepBody =>
      'Les réparations restent faibles au regard de sa valeur actuelle.';

  @override
  String get verdictWatchBody =>
      'Les réparations dépassent la moitié de sa valeur restante. Réfléchissez à deux fois avant la prochaine.';

  @override
  String get verdictReplaceBody =>
      'Vous avez dépensé plus en réparations que ce bien ne vaut aujourd\'hui. Un remplacement coûtera peut-être moins que la prochaine réparation.';

  @override
  String get verdictDisclaimer =>
      'Une règle empirique appliquée à des valeurs estimées, pas une expertise.';

  @override
  String get exportPdf => 'Exporter le rapport en PDF';

  @override
  String get exportPdfSubtitle => 'Générer un rapport d\'assurance';

  @override
  String get exportPdfSubtitlePro =>
      'Rapport complet : photos, numéros de série, factures, signé';

  @override
  String get nothingToReport => 'Il n\'y a encore rien à déclarer.';

  @override
  String get reportPreview => 'Aperçu du rapport';

  @override
  String get summaryReportBanner => 'Ceci est le rapport résumé';

  @override
  String summaryReportBannerBody(int count) {
    return 'Pro en fait le document qu\'un assureur réclame : une page pour chacun de vos $count biens, avec ses photos, son numéro de série, sa facture, son historique d\'entretien et sa valeur estimée du jour — plus une attestation à signer.';
  }

  @override
  String get seeWhatProAdds => 'Voir ce qu\'apporte Pro';

  @override
  String get canStillShare =>
      'Vous pouvez tout de même partager ou imprimer celui-ci.';

  @override
  String get backupData => 'Sauvegarder dans un fichier';

  @override
  String get backupNeverSubtitle =>
      'Jamais sauvegardé — tout enregistrer dans un fichier';

  @override
  String get backupTodaySubtitle => 'Dernière sauvegarde aujourd\'hui';

  @override
  String get backupYesterdaySubtitle => 'Dernière sauvegarde hier';

  @override
  String backupDaysAgoSubtitle(int days) {
    return 'Dernière sauvegarde il y a $days jours';
  }

  @override
  String get restoreBackup => 'Restaurer une sauvegarde';

  @override
  String get restoreBackupSubtitle =>
      'Ajoute à cette app les biens contenus dans un fichier de sauvegarde';

  @override
  String get nothingToBackUp => 'Il n\'y a encore rien à sauvegarder.';

  @override
  String get preparingBackup => 'Préparation de la sauvegarde…';

  @override
  String get restoring => 'Restauration…';

  @override
  String backupFailed(String details) {
    return 'Échec de la sauvegarde : $details';
  }

  @override
  String restoreFailed(String details) {
    return 'Échec de la restauration : $details';
  }

  @override
  String backupShareText(int count) {
    return 'Sauvegarde Itemize — $count biens. Conservez ce fichier là où vous le retrouverez.';
  }

  @override
  String get restoreCompleteTitle => 'Restauration terminée';

  @override
  String restoreCompleteBody(
    int added,
    int updated,
    int photos,
    int schedules,
    int records,
  ) {
    return '$added biens ajoutés, $updated mis à jour, $photos photos restaurées.\n$schedules entretiens planifiés et $records entrées d\'historique restaurés.\n\nRien de ce qui existait déjà sur cet appareil n\'a été supprimé.';
  }

  @override
  String get preferences => 'Préférences';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get language => 'Langue';

  @override
  String get coverLimit => 'Plafond de garantie mobilier';

  @override
  String get coverLimitUnset =>
      'Non renseigné — indiquez-le et nous vous préviendrons si vous le dépassez';

  @override
  String get coverLimitDialogBody =>
      'Le montant maximal que votre contrat verse pour vos biens mobiliers. Il figure sur vos conditions particulières.';

  @override
  String get coverLimitHint => 'Laissez vide pour retirer';

  @override
  String get warrantyReminders => 'Rappels de garantie';

  @override
  String get warrantyRemindersSubtitle =>
      'Prévenu 30, 7 et 1 jours avant l\'échéance';

  @override
  String get maintenanceReminders => 'Rappels d\'entretien';

  @override
  String get maintenanceRemindersSubtitle =>
      'Prévenu une semaine avant l\'échéance';

  @override
  String get notificationsOff =>
      'Les notifications sont désactivées pour Itemize. Activez-les dans les réglages de votre appareil.';

  @override
  String get biometricLock => 'Verrouillage biométrique';

  @override
  String get biometricLockSubtitle =>
      'Exiger FaceID/TouchID pour les actions sensibles';

  @override
  String get biometricProOnly => 'Disponible dans la version Pro';

  @override
  String get biometricDeviceSecurityOff =>
      'Sécurité de l\'appareil désactivée. Verrouillage biométrique désactivé.';

  @override
  String get authFailed => 'Échec de l\'authentification.';

  @override
  String get authNotAvailable =>
      'Biométrie ou sécurité non configurée. Activez un verrouillage d\'écran (code ou schéma).';

  @override
  String get authLockedOut => 'Trop de tentatives. Réessayez plus tard.';

  @override
  String get authPermanentlyLockedOut =>
      'Biométrie désactivée. Utilisez votre code ou réenregistrez-vous.';

  @override
  String get authToExport => 'Authentifiez-vous pour exporter votre inventaire';

  @override
  String get authToBackUp => 'Authentifiez-vous pour sauvegarder vos données';

  @override
  String get authToRestore => 'Authentifiez-vous pour restaurer une sauvegarde';

  @override
  String get authToDisableLock =>
      'Authentifiez-vous pour désactiver le verrouillage';

  @override
  String get appLocked => 'Itemize verrouillé';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get upgradeToPro => 'Passer à Pro';

  @override
  String get upgradeToProSubtitle =>
      'Rapports d\'assurance et sauvegardes. Tout le reste est gratuit.';

  @override
  String get proBadge => 'PRO';

  @override
  String get unlockFullPotential => 'Débloquez tout le potentiel';

  @override
  String get paywallLead =>
      'Enregistrer et entretenir vos biens est gratuit, sans limite, et le restera. Pro sert à en ressortir quelque chose.';

  @override
  String get paywallReport => 'Rapport d\'assurance';

  @override
  String get paywallReportBody =>
      'Une page par bien — photos, numéro de série, facture, historique d\'entretien et valeur estimée du jour, regroupés par pièce et signés.';

  @override
  String get paywallBackup => 'Sauvegarde et restauration';

  @override
  String get paywallBackupBody =>
      'Chaque bien, chaque photo et chaque année d\'historique dans un fichier que vous conservez. Sans compte, sans cloud ; rien ne quitte votre appareil sauf si vous l\'envoyez.';

  @override
  String get paywallBiometric => 'Verrouillage biométrique';

  @override
  String get paywallBiometricBody =>
      'Gardez votre inventaire derrière FaceID ou TouchID.';

  @override
  String get storeUnavailable =>
      'La boutique est indisponible pour le moment. Vérifiez votre connexion et réessayez.';

  @override
  String get retryStore => 'Réessayer';

  @override
  String get upgrade => 'Passer à Pro';

  @override
  String upgradeFor(String price) {
    return 'Passer à Pro pour $price';
  }

  @override
  String get restorePurchases => 'Restaurer mes achats';

  @override
  String get subscriptionFinePrint =>
      'Renouvellement automatique jusqu\'à résiliation. Gérez ou résiliez à tout moment dans les réglages de votre compte.';

  @override
  String get oneTimeFinePrint => 'Achat unique. Aucun abonnement.';

  @override
  String get welcomeToPro => 'Bienvenue dans Pro !';

  @override
  String get reportTitlePro => 'Inventaire du mobilier';

  @override
  String get reportTitleFree => 'Rapport Itemize';

  @override
  String get reportItemsRecorded => 'Biens enregistrés';

  @override
  String get reportRoomsCovered => 'Pièces couvertes';

  @override
  String get reportTotalPaid => 'Prix d\'achat total';

  @override
  String get reportEstimatedToday => 'Valeur estimée aujourd\'hui';

  @override
  String get reportDepreciation => 'Vétusté estimée';

  @override
  String get reportWithSerial => 'Biens avec numéro de série';

  @override
  String get reportWithReceipt => 'Biens avec facture jointe';

  @override
  String reportOfTotal(int count, int total) {
    return '$count sur $total';
  }

  @override
  String get reportEstimateDisclaimer =>
      'Les valeurs estimées sont calculées de façon linéaire selon une durée d\'usage conventionnelle par catégorie. Elles vous aident à vérifier votre couverture et ne constituent pas une expertise ; votre assureur peut appliquer un autre barème de vétusté.';

  @override
  String get reportNoItems => 'Aucun bien enregistré.';

  @override
  String get reportColItem => 'Bien';

  @override
  String get reportColSerialModel => 'Série / Modèle';

  @override
  String get reportColPurchased => 'Acheté le';

  @override
  String get reportColPaid => 'Payé';

  @override
  String get reportColToday => 'Val. estimée';

  @override
  String reportSubtotal(String room, String amount) {
    return 'Sous-total $room : $amount';
  }

  @override
  String get reportItemDetail => 'Détail par bien';

  @override
  String get reportPurchasePrice => 'Prix d\'achat';

  @override
  String get reportWarrantyUntil => 'Garantie jusqu\'au';

  @override
  String get reportServiceHistory => 'Historique d\'entretien';

  @override
  String reportSpentToDate(String amount) {
    return 'Dépensé sur ce bien à ce jour : $amount';
  }

  @override
  String get reportDeclaration => 'Attestation';

  @override
  String reportDeclarationBody(String date) {
    return 'J\'atteste que les biens figurant dans ce rapport m\'appartenaient au $date, et que les informations et photographies fournies sont exactes à ma connaissance.';
  }

  @override
  String get reportSignature => 'Signature';

  @override
  String get reportDate => 'Date';

  @override
  String get reportSummaryNotice => 'Ceci est le rapport résumé.';

  @override
  String get reportSummaryNoticeBody =>
      'Itemize Pro ajoute une page par bien, avec ses photographies, son numéro de série, sa facture, son historique d\'entretien et sa valeur estimée du jour, ainsi qu\'une attestation signée — le document qu\'un assureur réclame lors d\'un sinistre.';

  @override
  String reportPageOf(int page, int total) {
    return 'Page $page sur $total';
  }

  @override
  String get reportFooterFree => 'Généré par Itemize Free';

  @override
  String get roomLivingRoom => 'Salon';

  @override
  String get roomKitchen => 'Cuisine';

  @override
  String get roomBedroom => 'Chambre';

  @override
  String get roomOffice => 'Bureau';

  @override
  String get roomGarage => 'Garage';

  @override
  String get roomOther => 'Autre';

  @override
  String get catElectronics => 'Électronique';

  @override
  String get catFurniture => 'Mobilier';

  @override
  String get catAppliances => 'Électroménager';

  @override
  String get catJewelry => 'Bijoux et montres';

  @override
  String get catClothing => 'Vêtements';

  @override
  String get catTools => 'Outillage';

  @override
  String get catSports => 'Sport et plein air';

  @override
  String get catKitchenware => 'Arts de la table';

  @override
  String get catArt => 'Art et collections';

  @override
  String get catOther => 'Autre';

  @override
  String get jobReplaceWaterFilter => 'Remplacer le filtre à eau';

  @override
  String get jobCleanCoils => 'Nettoyer le condenseur';

  @override
  String get jobAnnualService => 'Entretien annuel';

  @override
  String get jobCleanVents => 'Dépoussiérer les aérations';

  @override
  String get jobReplaceBattery => 'Remplacer la pile de secours';

  @override
  String get jobServiceSharpen => 'Entretenir et affûter';

  @override
  String get jobSafetyInspection => 'Contrôle de sécurité';

  @override
  String get jobTreatOil => 'Traiter ou huiler';

  @override
  String get jobService => 'Entretien';

  @override
  String get itemSofa => 'Canapé';

  @override
  String get itemArmchair => 'Fauteuil';

  @override
  String get itemCoffeeTable => 'Table basse';

  @override
  String get itemTelevision => 'Téléviseur';

  @override
  String get itemFloorLamp => 'Lampadaire';

  @override
  String get itemBookshelf => 'Bibliothèque';

  @override
  String get itemSpeaker => 'Enceinte';

  @override
  String get itemRefrigerator => 'Réfrigérateur';

  @override
  String get itemMicrowave => 'Micro-ondes';

  @override
  String get itemCoffeeMaker => 'Cafetière';

  @override
  String get itemBlender => 'Blender';

  @override
  String get itemDiningTable => 'Table à manger';

  @override
  String get itemDishwasher => 'Lave-vaisselle';

  @override
  String get itemBed => 'Lit';

  @override
  String get itemWardrobe => 'Armoire';

  @override
  String get itemWashingMachine => 'Lave-linge';

  @override
  String get itemAirPurifier => 'Purificateur d\'air';

  @override
  String get itemIron => 'Fer à repasser';

  @override
  String get itemLaptop => 'Ordinateur portable';

  @override
  String get itemMonitor => 'Écran';

  @override
  String get itemDesk => 'Bureau';

  @override
  String get itemOfficeChair => 'Chaise de bureau';

  @override
  String get itemPrinter => 'Imprimante';

  @override
  String get itemRouter => 'Routeur';

  @override
  String get itemKeyboard => 'Clavier';

  @override
  String get itemHeadphones => 'Casque audio';

  @override
  String get itemBicycle => 'Vélo';

  @override
  String get itemCar => 'Voiture';

  @override
  String get itemPowerTools => 'Outils électriques';

  @override
  String get itemToolbox => 'Boîte à outils';

  @override
  String get itemLawnMower => 'Tondeuse';

  @override
  String get itemCamera => 'Appareil photo';

  @override
  String get itemWatch => 'Montre';

  @override
  String get itemPhone => 'Téléphone';

  @override
  String get itemTablet => 'Tablette';

  @override
  String get itemBooks => 'Livres';

  @override
  String get itemGymEquipment => 'Équipement de sport';

  @override
  String get itemLuggage => 'Bagages';

  @override
  String get itemMusicalInstrument => 'Instrument de musique';

  @override
  String get authToContinue => 'Veuillez vous authentifier pour continuer';

  @override
  String get currencyChangeTitle => 'Changer de devise ?';

  @override
  String get currencyChangeBody =>
      'Les montants déjà saisis ne sont pas convertis. Ils conservent les chiffres que vous avez entrés et seront simplement affichés avec le nouveau symbole.';

  @override
  String get changeAnyway => 'Changer quand même';

  @override
  String restoreKeptNewer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count objets sur cet appareil étaient plus récents et ont été conservés tels quels.',
      one:
          '1 objet sur cet appareil était plus récent et a été conservé tel quel.',
    );
    return '$_temp0';
  }

  @override
  String get batchSaveFailed =>
      'Enregistrement impossible. Rien n\'a été stocké — vos photos sont toujours là, réessayez.';
}
