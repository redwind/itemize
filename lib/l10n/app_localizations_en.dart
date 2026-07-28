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
  String get assetsTab => 'Assets';

  @override
  String get careTab => 'Care';

  @override
  String get settingsTab => 'Settings';

  @override
  String get totalValue => 'Total Value';

  @override
  String get estimatedValueToday => 'Estimated value today';

  @override
  String get underInsuredTitle => 'You may be under-insured';

  @override
  String underInsuredBody(String amount, String limit) {
    return 'What you have recorded is worth about $amount more than your $limit contents cover. Worth a word with your insurer.';
  }

  @override
  String get noAssetsData => 'No assets data';

  @override
  String get errorLoadingChart => 'Error loading chart';

  @override
  String get searchPlaceholder => 'Search assets...';

  @override
  String get noAssetsFound => 'No assets found';

  @override
  String genericError(String details) {
    return 'Error: $details';
  }

  @override
  String get addItemTitle => 'Add New Asset';

  @override
  String get editItemTitle => 'Edit Asset';

  @override
  String get itemName => 'Item Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get price => 'Price';

  @override
  String get fieldRequired => 'Required';

  @override
  String get currency => 'Currency';

  @override
  String get room => 'Room';

  @override
  String get category => 'Category';

  @override
  String get chooseCategory => 'Please choose a category.';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get identification => 'Identification';

  @override
  String get identificationHint =>
      'What an insurer asks for to prove which unit you owned.';

  @override
  String get brand => 'Brand';

  @override
  String get model => 'Model';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get barcode => 'Barcode';

  @override
  String get purchase => 'Purchase';

  @override
  String get purchaseDate => 'Purchase Date';

  @override
  String get warrantyExpiry => 'Warranty Expiry';

  @override
  String get notSet => 'Not set';

  @override
  String get receipt => 'Receipt';

  @override
  String get receiptAttached => 'Attached';

  @override
  String get receiptHint => 'Proof of purchase for a claim';

  @override
  String get notes => 'Notes';

  @override
  String get notesHint => 'Condition, where it was bought, extras...';

  @override
  String get markAsFavorite => 'Mark as Favorite';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromPhotos => 'Choose from Photos';

  @override
  String get pickStockImage => 'Pick a Stock Image';

  @override
  String get pickStockImageHint => 'Chairs, tables, appliances and more';

  @override
  String get makeCoverPhoto => 'Make Cover Photo';

  @override
  String get makeCoverPhotoHint => 'Shown in lists and reports';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get photosEmptyHint => 'Add photos — the first one becomes the cover.';

  @override
  String photosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos.',
      one: '1 photo.',
    );
    return '$_temp0 Tap one to remove it or make it the cover.';
  }

  @override
  String get coverBadge => 'Cover';

  @override
  String get photoLibrary => 'Photo Library';

  @override
  String get noMatchingItems => 'No matching items';

  @override
  String get smartScan => 'Smart Scan';

  @override
  String get scanNameplate => 'Scan Label / Nameplate';

  @override
  String get scanNameplateHint => 'Reads the brand, model and serial number';

  @override
  String get scanReceipt => 'Scan Receipt';

  @override
  String get scanReceiptHint => 'Fills in the price and purchase date';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get scanBarcodeHint => 'Records the product code';

  @override
  String barcodeSaved(String code) {
    return 'Barcode saved: $code';
  }

  @override
  String get noBarcodeFound => 'No barcode found';

  @override
  String get nameplateUnreadable =>
      'Nothing readable on that label. Try filling the frame with it.';

  @override
  String nameplateRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Read $count fields.',
      one: 'Read 1 field.',
    );
    return '$_temp0 Please check them against the label.';
  }

  @override
  String get receiptScanned => 'Receipt scanned. Please check the details.';

  @override
  String get quickCaptureTitle => 'Quick Capture';

  @override
  String get quickCaptureEmptyTitle => 'Photograph everything first';

  @override
  String get quickCaptureEmptyBody =>
      'The camera stays open between shots. Walk the room, then come back here and name what you photographed.';

  @override
  String get keepShooting => 'Keep Shooting';

  @override
  String get discardPhoto => 'Discard this photo';

  @override
  String saveCount(int count) {
    return 'Save $count';
  }

  @override
  String get save => 'Save';

  @override
  String savedNeedNames(int saved, int left) {
    return '$saved saved. $left still needs a name.';
  }

  @override
  String get addOneItem => 'Add One Item';

  @override
  String get addOneItemHint => 'With all its details';

  @override
  String get quickCaptureRoom => 'Quick Capture a Room';

  @override
  String get quickCaptureRoomHint =>
      'Photograph everything, name it afterwards';

  @override
  String get welcomeTitle => 'Start with one room';

  @override
  String get welcomeBody =>
      'Most people give up on a home inventory somewhere around the tenth item, because every one of them wants a form filling in. So do it the other way round.';

  @override
  String get welcomeStep1 => 'Photograph everything';

  @override
  String get welcomeStep1Hint =>
      'The camera stays open between shots. Walk the room.';

  @override
  String get welcomeStep2 => 'Name it afterwards';

  @override
  String get welcomeStep2Hint =>
      'Sitting down, in one list, with a cup of tea.';

  @override
  String get welcomeStep3 => 'Then it looks after itself';

  @override
  String get welcomeStep3Hint =>
      'Warranties, servicing due, and a report if you ever claim.';

  @override
  String get welcomeStart => 'Photograph a room';

  @override
  String get welcomeSkip => 'I will add things one at a time';

  @override
  String get purchased => 'Purchased';

  @override
  String get warrantyExpires => 'Warranty Expires';

  @override
  String get careAndHistory => 'Care & history';

  @override
  String get careNothingScheduled =>
      'Add what this needs doing, and log repairs';

  @override
  String careNoneOverdue(int count) {
    return '$count scheduled, nothing overdue';
  }

  @override
  String careOverdue(int late, int total) {
    return '$late overdue of $total scheduled';
  }

  @override
  String valueEstimateDepreciates(String category) {
    return 'Straight-line estimate for $category. Your insurer may use a different schedule.';
  }

  @override
  String valueEstimateHeld(String category) {
    return '$category is not depreciated — insurers usually schedule it separately.';
  }

  @override
  String get edit => 'Edit';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String deleteItemTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get deleteItemSimple => 'You can undo this straight afterwards.';

  @override
  String deleteItemWithHistory(int schedules, int records) {
    return 'This also removes $schedules scheduled jobs and $records history entries. You can undo it straight afterwards.';
  }

  @override
  String deletedItem(String name) {
    return '$name deleted';
  }

  @override
  String get undo => 'Undo';

  @override
  String get warranties => 'Warranties';

  @override
  String get standingEndingSoon => 'Ending soon';

  @override
  String get standingCovered => 'Covered';

  @override
  String get standingExpired => 'Expired';

  @override
  String get standingUnknown => 'No date';

  @override
  String standingCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String get emptyEndingSoon =>
      'Nothing is about to run out. This is where things appear in their last three months of cover.';

  @override
  String get emptyCovered => 'Nothing here is under warranty yet.';

  @override
  String get emptyExpired => 'Nothing has run out of cover.';

  @override
  String get emptyUnknown =>
      'Every item has a warranty date on it. Adding them is what makes this screen worth opening.';

  @override
  String get notRecorded => 'Not recorded';

  @override
  String get endsToday => 'Ends today';

  @override
  String daysLeft(int days) {
    return '$days d left';
  }

  @override
  String monthsLeft(int months) {
    return '$months mo left';
  }

  @override
  String yearsLeft(int years) {
    return '$years yr left';
  }

  @override
  String yearsMonthsLeft(int years, int months) {
    return '$years yr $months mo left';
  }

  @override
  String endedDaysAgo(int days) {
    return 'Ended $days d ago';
  }

  @override
  String endedMonthsAgo(int months) {
    return 'Ended $months mo ago';
  }

  @override
  String endedYearsAgo(int years) {
    return 'Ended $years yr ago';
  }

  @override
  String needsDoing(int count) {
    return 'Needs doing ($count)';
  }

  @override
  String get nothingScheduledAnywhere =>
      'Nothing scheduled anywhere yet. Open any item and add what it needs doing — a filter, a service — and it will show up here when due.';

  @override
  String get nothingDueFortnight => 'Nothing due in the next fortnight.';

  @override
  String warrantiesAtRisk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warranties are at risk',
      one: '1 warranty is at risk',
    );
    return '$_temp0';
  }

  @override
  String get warrantiesAtRiskBody =>
      'Servicing these items is a condition of their cover, and it has lapsed. A missed service is grounds to decline a claim.';

  @override
  String get warrantyAtRiskItem =>
      'This item is still under warranty, and this job is required to keep it valid. A missed service is grounds to decline a claim.';

  @override
  String daysLate(int days) {
    return '$days d late';
  }

  @override
  String dueInDays(int days) {
    return 'in $days d';
  }

  @override
  String entriesToCheck(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries to check',
      one: '1 entry to check',
    );
    return '$_temp0';
  }

  @override
  String get entriesToCheckBody =>
      'Still own these, and are the details still right? A list that has drifted is one an insurer can argue with.';

  @override
  String get stillRight => 'Still right';

  @override
  String get check => 'Check';

  @override
  String get backupNudgeNever => 'This is only on this phone';

  @override
  String backupNudgeDays(int days) {
    return 'No backup for $days days';
  }

  @override
  String backupNudgeBody(int count) {
    return '$count items, their photographs and every repair you have logged. Lose the phone and it goes with it.';
  }

  @override
  String get scheduledJobs => 'Scheduled jobs';

  @override
  String get history => 'History';

  @override
  String get add => 'Add';

  @override
  String get noSchedulesYet =>
      'Nothing scheduled. Add the jobs this needs — a filter, a service — and you will be told when they fall due.';

  @override
  String get noHistoryYet =>
      'No work recorded yet. Logging repairs is what makes the running cost below mean anything — and what a manufacturer asks for when a warranty claim turns on whether it was serviced.';

  @override
  String overdueByEvery(int days, int months) {
    return 'Overdue by $days days · every $months mo';
  }

  @override
  String dueOnEvery(String date, int months) {
    return 'Due $date · every $months mo';
  }

  @override
  String get newJob => 'New job';

  @override
  String get editJob => 'Edit job';

  @override
  String get commonForThis => 'Common for this kind of thing';

  @override
  String get whatNeedsDoing => 'What needs doing';

  @override
  String get whatNeedsDoingHint => 'Replace water filter';

  @override
  String get howOften => 'How often';

  @override
  String get requiredForWarranty => 'Required to keep the warranty valid';

  @override
  String get requiredForWarrantyHint =>
      'You will be warned if this lapses while the item is still covered.';

  @override
  String get addJob => 'Add job';

  @override
  String get intervalMonthly => 'Monthly';

  @override
  String get intervalQuarterly => 'Every 3 months';

  @override
  String get intervalHalfYearly => 'Every 6 months';

  @override
  String get intervalYearly => 'Yearly';

  @override
  String get intervalBiennial => 'Every 2 years';

  @override
  String get logWorkDone => 'Log work done';

  @override
  String get kindMaintenance => 'Maintenance';

  @override
  String get kindRepair => 'Repair';

  @override
  String get kindInspection => 'Inspection';

  @override
  String get whatWasDone => 'What was done';

  @override
  String get whatWasDoneHint => 'Replaced the pump';

  @override
  String get cost => 'Cost';

  @override
  String get whoDidIt => 'Who did it';

  @override
  String get when => 'When';

  @override
  String get satisfiesWhichJob => 'Satisfies which job';

  @override
  String get satisfiesWhichJobHint =>
      'Marks that job as done and moves its next date';

  @override
  String get none => 'None';

  @override
  String get free => 'Free';

  @override
  String get verdictKeep => 'Worth keeping';

  @override
  String get verdictWatch => 'Worth watching';

  @override
  String get verdictReplace => 'Worth replacing';

  @override
  String get paidForIt => 'Paid for it';

  @override
  String get spentOnRepairs => 'Spent on repairs';

  @override
  String get worthToday => 'Worth today';

  @override
  String get totalOutlay => 'Total outlay';

  @override
  String get verdictKeepBody =>
      'Repairs are small against what it is still worth.';

  @override
  String get verdictWatchBody =>
      'Repairs have passed half its remaining value. Worth thinking twice about the next one.';

  @override
  String get verdictReplaceBody =>
      'You have spent more mending this than it is now worth. A replacement may cost less than the next repair.';

  @override
  String get verdictDisclaimer =>
      'A rule of thumb on estimated values, not a valuation.';

  @override
  String get exportPdf => 'Export Report to PDF';

  @override
  String get exportPdfSubtitle => 'Generate insurance report';

  @override
  String get exportPdfSubtitlePro =>
      'Full report: photos, serials, receipts, signed';

  @override
  String get nothingToReport => 'There is nothing to report on yet.';

  @override
  String get reportPreview => 'Report Preview';

  @override
  String get summaryReportBanner => 'This is the summary report';

  @override
  String summaryReportBannerBody(int count) {
    return 'Pro turns it into the document an insurer asks for: a page for each of your $count items with its photographs, serial number, receipt, service history and estimated value today — plus a signed declaration.';
  }

  @override
  String get seeWhatProAdds => 'See what Pro adds';

  @override
  String get canStillShare => 'You can still share or print this one.';

  @override
  String get backupData => 'Back Up to a File';

  @override
  String get backupNeverSubtitle =>
      'Never backed up — save everything to one file';

  @override
  String get backupTodaySubtitle => 'Last backed up today';

  @override
  String get backupYesterdaySubtitle => 'Last backed up yesterday';

  @override
  String backupDaysAgoSubtitle(int days) {
    return 'Last backed up $days days ago';
  }

  @override
  String get restoreBackup => 'Restore from a Backup';

  @override
  String get restoreBackupSubtitle =>
      'Adds the items in a backup file to this app';

  @override
  String get nothingToBackUp => 'There is nothing to back up yet.';

  @override
  String get preparingBackup => 'Preparing backup…';

  @override
  String get restoring => 'Restoring…';

  @override
  String backupFailed(String details) {
    return 'Backup failed: $details';
  }

  @override
  String restoreFailed(String details) {
    return 'Restore failed: $details';
  }

  @override
  String backupShareText(int count) {
    return 'Itemize backup — $count items. Keep this file somewhere you can find it again.';
  }

  @override
  String get restoreCompleteTitle => 'Restore complete';

  @override
  String restoreCompleteBody(
    int added,
    int updated,
    int photos,
    int schedules,
    int records,
  ) {
    return '$added items added, $updated updated, $photos photos restored.\n$schedules scheduled jobs and $records history entries restored.\n\nNothing already on this device was removed.';
  }

  @override
  String get preferences => 'Preferences';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get language => 'Language';

  @override
  String get coverLimit => 'Contents Cover Limit';

  @override
  String get coverLimitUnset =>
      'Not set — tell us and we will warn you if you outgrow it';

  @override
  String get coverLimitDialogBody =>
      'The most your policy pays out for belongings. Find it on your schedule under contents.';

  @override
  String get coverLimitHint => 'Leave empty to remove';

  @override
  String get warrantyReminders => 'Warranty Reminders';

  @override
  String get warrantyRemindersSubtitle =>
      'Told 30, 7 and 1 days before one runs out';

  @override
  String get maintenanceReminders => 'Maintenance Reminders';

  @override
  String get maintenanceRemindersSubtitle =>
      'Told a week before a scheduled job is due';

  @override
  String get notificationsOff =>
      'Notifications are turned off for Itemize. Enable them in your device settings.';

  @override
  String get biometricLock => 'Biometric Lock';

  @override
  String get biometricLockSubtitle =>
      'Require FaceID/TouchID for sensitive actions';

  @override
  String get biometricProOnly => 'Available in Pro Version';

  @override
  String get biometricDeviceSecurityOff =>
      'Device security disabled. Biometric lock turned off.';

  @override
  String get authFailed => 'Authentication failed.';

  @override
  String get authNotAvailable =>
      'Biometrics/Security not set up. Please enable a Lock Screen (PIN/Pattern).';

  @override
  String get authLockedOut => 'Too many attempts. Try again later.';

  @override
  String get authPermanentlyLockedOut =>
      'Biometrics disabled. Use PIN/Pattern or re-enroll.';

  @override
  String get authToExport => 'Authenticate to export your inventory';

  @override
  String get authToBackUp => 'Authenticate to back up your data';

  @override
  String get authToRestore => 'Authenticate to restore a backup';

  @override
  String get authToDisableLock => 'Authenticate to disable Lock';

  @override
  String get appLocked => 'Itemize Locked';

  @override
  String get unlock => 'Unlock';

  @override
  String get upgradeToPro => 'Upgrade to Pro';

  @override
  String get upgradeToProSubtitle =>
      'Insurance reports and backups. Everything else is free.';

  @override
  String get proBadge => 'PRO';

  @override
  String get unlockFullPotential => 'Unlock Full Potential';

  @override
  String get paywallLead =>
      'Recording and looking after your things is free, unlimited, and stays that way. Pro is for getting it back out.';

  @override
  String get paywallReport => 'Insurance Report';

  @override
  String get paywallReportBody =>
      'A page for every item — photos, serial number, receipt, service history and estimated current value, grouped by room and signed.';

  @override
  String get paywallBackup => 'Backup & Restore';

  @override
  String get paywallBackupBody =>
      'Every item, photo and year of service history in one file you keep. No account, no cloud, nothing leaves your device unless you send it.';

  @override
  String get paywallBiometric => 'Biometric Lock';

  @override
  String get paywallBiometricBody =>
      'Keep the inventory behind FaceID or TouchID.';

  @override
  String get storeUnavailable =>
      'The store is unavailable right now. Please try again later.';

  @override
  String get upgrade => 'Upgrade';

  @override
  String upgradeFor(String price) {
    return 'Upgrade for $price';
  }

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get subscriptionFinePrint =>
      'Renews automatically until cancelled. Manage or cancel any time in your account settings.';

  @override
  String get oneTimeFinePrint => 'One-time purchase. No subscription.';

  @override
  String get welcomeToPro => 'Welcome to Pro!';

  @override
  String get reportTitlePro => 'Home Inventory Report';

  @override
  String get reportTitleFree => 'Itemize Report';

  @override
  String get reportItemsRecorded => 'Items recorded';

  @override
  String get reportRoomsCovered => 'Rooms covered';

  @override
  String get reportTotalPaid => 'Total purchase price';

  @override
  String get reportEstimatedToday => 'Estimated value today';

  @override
  String get reportDepreciation => 'Estimated depreciation';

  @override
  String get reportWithSerial => 'Items with a serial number';

  @override
  String get reportWithReceipt => 'Items with a receipt attached';

  @override
  String reportOfTotal(int count, int total) {
    return '$count of $total';
  }

  @override
  String get reportEstimateDisclaimer =>
      'Estimated values are straight-line figures based on conventional useful life by category. They are provided to help you check your cover and are not a valuation; your insurer may apply a different schedule.';

  @override
  String get reportNoItems => 'No items recorded.';

  @override
  String get reportColItem => 'Item';

  @override
  String get reportColSerialModel => 'Serial / Model';

  @override
  String get reportColPurchased => 'Purchased';

  @override
  String get reportColPaid => 'Paid';

  @override
  String get reportColToday => 'Est. today';

  @override
  String reportSubtotal(String room, String amount) {
    return '$room subtotal: $amount';
  }

  @override
  String get reportItemDetail => 'Item detail';

  @override
  String get reportPurchasePrice => 'Purchase price';

  @override
  String get reportWarrantyUntil => 'Warranty until';

  @override
  String get reportServiceHistory => 'Service history';

  @override
  String reportSpentToDate(String amount) {
    return 'Spent on this item to date: $amount';
  }

  @override
  String get reportDeclaration => 'Declaration';

  @override
  String reportDeclarationBody(String date) {
    return 'I confirm that the items listed in this report were owned by me on $date, and that the details and photographs given are accurate to the best of my knowledge.';
  }

  @override
  String get reportSignature => 'Signature';

  @override
  String get reportDate => 'Date';

  @override
  String get reportSummaryNotice => 'This is the summary report.';

  @override
  String get reportSummaryNoticeBody =>
      'Itemize Pro adds a page for every item with its photographs, serial number, receipt, service history and estimated current value, plus a signed declaration — the form an insurer asks for when you claim.';

  @override
  String reportPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get reportFooterFree => 'Generated by Itemize Free';

  @override
  String get roomLivingRoom => 'Living Room';

  @override
  String get roomKitchen => 'Kitchen';

  @override
  String get roomBedroom => 'Bedroom';

  @override
  String get roomOffice => 'Office';

  @override
  String get roomGarage => 'Garage';

  @override
  String get roomOther => 'Other';

  @override
  String get catElectronics => 'Electronics';

  @override
  String get catFurniture => 'Furniture';

  @override
  String get catAppliances => 'Appliances';

  @override
  String get catJewelry => 'Jewelry & Watches';

  @override
  String get catClothing => 'Clothing';

  @override
  String get catTools => 'Tools & Equipment';

  @override
  String get catSports => 'Sports & Outdoors';

  @override
  String get catKitchenware => 'Kitchenware';

  @override
  String get catArt => 'Art & Collectibles';

  @override
  String get catOther => 'Other';

  @override
  String get jobReplaceWaterFilter => 'Replace water filter';

  @override
  String get jobCleanCoils => 'Clean condenser coils';

  @override
  String get jobAnnualService => 'Annual service';

  @override
  String get jobCleanVents => 'Clean dust from vents';

  @override
  String get jobReplaceBattery => 'Replace backup battery';

  @override
  String get jobServiceSharpen => 'Service and sharpen';

  @override
  String get jobSafetyInspection => 'Safety inspection';

  @override
  String get jobTreatOil => 'Treat or re-oil';

  @override
  String get jobService => 'Service';

  @override
  String get itemSofa => 'Sofa';

  @override
  String get itemArmchair => 'Armchair';

  @override
  String get itemCoffeeTable => 'Coffee Table';

  @override
  String get itemTelevision => 'Television';

  @override
  String get itemFloorLamp => 'Floor Lamp';

  @override
  String get itemBookshelf => 'Bookshelf';

  @override
  String get itemSpeaker => 'Speaker';

  @override
  String get itemRefrigerator => 'Refrigerator';

  @override
  String get itemMicrowave => 'Microwave';

  @override
  String get itemCoffeeMaker => 'Coffee Maker';

  @override
  String get itemBlender => 'Blender';

  @override
  String get itemDiningTable => 'Dining Table';

  @override
  String get itemDishwasher => 'Dishwasher';

  @override
  String get itemBed => 'Bed';

  @override
  String get itemWardrobe => 'Wardrobe';

  @override
  String get itemWashingMachine => 'Washing Machine';

  @override
  String get itemAirPurifier => 'Air Purifier';

  @override
  String get itemIron => 'Iron';

  @override
  String get itemLaptop => 'Laptop';

  @override
  String get itemMonitor => 'Monitor';

  @override
  String get itemDesk => 'Desk';

  @override
  String get itemOfficeChair => 'Office Chair';

  @override
  String get itemPrinter => 'Printer';

  @override
  String get itemRouter => 'Router';

  @override
  String get itemKeyboard => 'Keyboard';

  @override
  String get itemHeadphones => 'Headphones';

  @override
  String get itemBicycle => 'Bicycle';

  @override
  String get itemCar => 'Car';

  @override
  String get itemPowerTools => 'Power Tools';

  @override
  String get itemToolbox => 'Toolbox';

  @override
  String get itemLawnMower => 'Lawn Mower';

  @override
  String get itemCamera => 'Camera';

  @override
  String get itemWatch => 'Watch';

  @override
  String get itemPhone => 'Phone';

  @override
  String get itemTablet => 'Tablet';

  @override
  String get itemBooks => 'Books';

  @override
  String get itemGymEquipment => 'Gym Equipment';

  @override
  String get itemLuggage => 'Luggage';

  @override
  String get itemMusicalInstrument => 'Musical Instrument';

  @override
  String get authToContinue => 'Please authenticate to continue';
}
