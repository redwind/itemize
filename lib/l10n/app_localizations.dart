import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Itemize'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @assetsTab.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assetsTab;

  /// No description provided for @careTab.
  ///
  /// In en, this message translates to:
  /// **'Care'**
  String get careTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @totalValue.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValue;

  /// No description provided for @estimatedValueToday.
  ///
  /// In en, this message translates to:
  /// **'Estimated value today'**
  String get estimatedValueToday;

  /// No description provided for @underInsuredTitle.
  ///
  /// In en, this message translates to:
  /// **'You may be under-insured'**
  String get underInsuredTitle;

  /// No description provided for @underInsuredBody.
  ///
  /// In en, this message translates to:
  /// **'What you have recorded is worth about {amount} more than your {limit} contents cover. Worth a word with your insurer.'**
  String underInsuredBody(String amount, String limit);

  /// No description provided for @noAssetsData.
  ///
  /// In en, this message translates to:
  /// **'No assets data'**
  String get noAssetsData;

  /// No description provided for @errorLoadingChart.
  ///
  /// In en, this message translates to:
  /// **'Error loading chart'**
  String get errorLoadingChart;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search assets...'**
  String get searchPlaceholder;

  /// No description provided for @noAssetsFound.
  ///
  /// In en, this message translates to:
  /// **'No assets found'**
  String get noAssetsFound;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {details}'**
  String genericError(String details);

  /// No description provided for @addItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Asset'**
  String get addItemTitle;

  /// No description provided for @editItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Asset'**
  String get editItemTitle;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item Name'**
  String get itemName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @room.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get room;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Please choose a category.'**
  String get chooseCategory;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @identification.
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get identification;

  /// No description provided for @identificationHint.
  ///
  /// In en, this message translates to:
  /// **'What an insurer asks for to prove which unit you owned.'**
  String get identificationHint;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @serialNumber.
  ///
  /// In en, this message translates to:
  /// **'Serial Number'**
  String get serialNumber;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @purchase.
  ///
  /// In en, this message translates to:
  /// **'Purchase'**
  String get purchase;

  /// No description provided for @purchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase Date'**
  String get purchaseDate;

  /// No description provided for @warrantyExpiry.
  ///
  /// In en, this message translates to:
  /// **'Warranty Expiry'**
  String get warrantyExpiry;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @receiptAttached.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get receiptAttached;

  /// No description provided for @receiptHint.
  ///
  /// In en, this message translates to:
  /// **'Proof of purchase for a claim'**
  String get receiptHint;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Condition, where it was bought, extras...'**
  String get notesHint;

  /// No description provided for @markAsFavorite.
  ///
  /// In en, this message translates to:
  /// **'Mark as Favorite'**
  String get markAsFavorite;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromPhotos.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get chooseFromPhotos;

  /// No description provided for @pickStockImage.
  ///
  /// In en, this message translates to:
  /// **'Pick a Stock Image'**
  String get pickStockImage;

  /// No description provided for @pickStockImageHint.
  ///
  /// In en, this message translates to:
  /// **'Chairs, tables, appliances and more'**
  String get pickStockImageHint;

  /// No description provided for @makeCoverPhoto.
  ///
  /// In en, this message translates to:
  /// **'Make Cover Photo'**
  String get makeCoverPhoto;

  /// No description provided for @makeCoverPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Shown in lists and reports'**
  String get makeCoverPhotoHint;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @photosEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add photos — the first one becomes the cover.'**
  String get photosEmptyHint;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo.} other{{count} photos.}} Tap one to remove it or make it the cover.'**
  String photosCount(int count);

  /// No description provided for @coverBadge.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get coverBadge;

  /// No description provided for @photoLibrary.
  ///
  /// In en, this message translates to:
  /// **'Photo Library'**
  String get photoLibrary;

  /// No description provided for @noMatchingItems.
  ///
  /// In en, this message translates to:
  /// **'No matching items'**
  String get noMatchingItems;

  /// No description provided for @smartScan.
  ///
  /// In en, this message translates to:
  /// **'Smart Scan'**
  String get smartScan;

  /// No description provided for @scanNameplate.
  ///
  /// In en, this message translates to:
  /// **'Scan Label / Nameplate'**
  String get scanNameplate;

  /// No description provided for @scanNameplateHint.
  ///
  /// In en, this message translates to:
  /// **'Reads the brand, model and serial number'**
  String get scanNameplateHint;

  /// No description provided for @scanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get scanReceipt;

  /// No description provided for @scanReceiptHint.
  ///
  /// In en, this message translates to:
  /// **'Fills in the price and purchase date'**
  String get scanReceiptHint;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @scanBarcodeHint.
  ///
  /// In en, this message translates to:
  /// **'Records the product code'**
  String get scanBarcodeHint;

  /// No description provided for @barcodeSaved.
  ///
  /// In en, this message translates to:
  /// **'Barcode saved: {code}'**
  String barcodeSaved(String code);

  /// No description provided for @noBarcodeFound.
  ///
  /// In en, this message translates to:
  /// **'No barcode found'**
  String get noBarcodeFound;

  /// No description provided for @nameplateUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Nothing readable on that label. Try filling the frame with it.'**
  String get nameplateUnreadable;

  /// No description provided for @nameplateRead.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Read 1 field.} other{Read {count} fields.}} Please check them against the label.'**
  String nameplateRead(int count);

  /// No description provided for @receiptScanned.
  ///
  /// In en, this message translates to:
  /// **'Receipt scanned. Please check the details.'**
  String get receiptScanned;

  /// No description provided for @quickCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Capture'**
  String get quickCaptureTitle;

  /// No description provided for @quickCaptureEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Photograph everything first'**
  String get quickCaptureEmptyTitle;

  /// No description provided for @quickCaptureEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'The camera stays open between shots. Walk the room, then come back here and name what you photographed.'**
  String get quickCaptureEmptyBody;

  /// No description provided for @keepShooting.
  ///
  /// In en, this message translates to:
  /// **'Keep Shooting'**
  String get keepShooting;

  /// No description provided for @discardPhoto.
  ///
  /// In en, this message translates to:
  /// **'Discard this photo'**
  String get discardPhoto;

  /// No description provided for @saveCount.
  ///
  /// In en, this message translates to:
  /// **'Save {count}'**
  String saveCount(int count);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @savedNeedNames.
  ///
  /// In en, this message translates to:
  /// **'{saved} saved. {left} still needs a name.'**
  String savedNeedNames(int saved, int left);

  /// No description provided for @addOneItem.
  ///
  /// In en, this message translates to:
  /// **'Add One Item'**
  String get addOneItem;

  /// No description provided for @addOneItemHint.
  ///
  /// In en, this message translates to:
  /// **'With all its details'**
  String get addOneItemHint;

  /// No description provided for @quickCaptureRoom.
  ///
  /// In en, this message translates to:
  /// **'Quick Capture a Room'**
  String get quickCaptureRoom;

  /// No description provided for @quickCaptureRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Photograph everything, name it afterwards'**
  String get quickCaptureRoomHint;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Start with one room'**
  String get welcomeTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Most people give up on a home inventory somewhere around the tenth item, because every one of them wants a form filling in. So do it the other way round.'**
  String get welcomeBody;

  /// No description provided for @welcomeStep1.
  ///
  /// In en, this message translates to:
  /// **'Photograph everything'**
  String get welcomeStep1;

  /// No description provided for @welcomeStep1Hint.
  ///
  /// In en, this message translates to:
  /// **'The camera stays open between shots. Walk the room.'**
  String get welcomeStep1Hint;

  /// No description provided for @welcomeStep2.
  ///
  /// In en, this message translates to:
  /// **'Name it afterwards'**
  String get welcomeStep2;

  /// No description provided for @welcomeStep2Hint.
  ///
  /// In en, this message translates to:
  /// **'Sitting down, in one list, with a cup of tea.'**
  String get welcomeStep2Hint;

  /// No description provided for @welcomeStep3.
  ///
  /// In en, this message translates to:
  /// **'Then it looks after itself'**
  String get welcomeStep3;

  /// No description provided for @welcomeStep3Hint.
  ///
  /// In en, this message translates to:
  /// **'Warranties, servicing due, and a report if you ever claim.'**
  String get welcomeStep3Hint;

  /// No description provided for @welcomeStart.
  ///
  /// In en, this message translates to:
  /// **'Photograph a room'**
  String get welcomeStart;

  /// No description provided for @welcomeSkip.
  ///
  /// In en, this message translates to:
  /// **'I will add things one at a time'**
  String get welcomeSkip;

  /// No description provided for @purchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get purchased;

  /// No description provided for @warrantyExpires.
  ///
  /// In en, this message translates to:
  /// **'Warranty Expires'**
  String get warrantyExpires;

  /// No description provided for @careAndHistory.
  ///
  /// In en, this message translates to:
  /// **'Care & history'**
  String get careAndHistory;

  /// No description provided for @careNothingScheduled.
  ///
  /// In en, this message translates to:
  /// **'Add what this needs doing, and log repairs'**
  String get careNothingScheduled;

  /// No description provided for @careNoneOverdue.
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled, nothing overdue'**
  String careNoneOverdue(int count);

  /// No description provided for @careOverdue.
  ///
  /// In en, this message translates to:
  /// **'{late} overdue of {total} scheduled'**
  String careOverdue(int late, int total);

  /// No description provided for @valueEstimateDepreciates.
  ///
  /// In en, this message translates to:
  /// **'Straight-line estimate for {category}. Your insurer may use a different schedule.'**
  String valueEstimateDepreciates(String category);

  /// No description provided for @valueEstimateHeld.
  ///
  /// In en, this message translates to:
  /// **'{category} is not depreciated — insurers usually schedule it separately.'**
  String valueEstimateHeld(String category);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteItemTitle(String name);

  /// No description provided for @deleteItemSimple.
  ///
  /// In en, this message translates to:
  /// **'You can undo this straight afterwards.'**
  String get deleteItemSimple;

  /// No description provided for @deleteItemWithHistory.
  ///
  /// In en, this message translates to:
  /// **'This also removes {schedules} scheduled jobs and {records} history entries. You can undo it straight afterwards.'**
  String deleteItemWithHistory(int schedules, int records);

  /// No description provided for @deletedItem.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String deletedItem(String name);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @warranties.
  ///
  /// In en, this message translates to:
  /// **'Warranties'**
  String get warranties;

  /// No description provided for @standingEndingSoon.
  ///
  /// In en, this message translates to:
  /// **'Ending soon'**
  String get standingEndingSoon;

  /// No description provided for @standingCovered.
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get standingCovered;

  /// No description provided for @standingExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get standingExpired;

  /// No description provided for @standingUnknown.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get standingUnknown;

  /// No description provided for @standingCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String standingCountLabel(String label, int count);

  /// No description provided for @emptyEndingSoon.
  ///
  /// In en, this message translates to:
  /// **'Nothing is about to run out. This is where things appear in their last three months of cover.'**
  String get emptyEndingSoon;

  /// No description provided for @emptyCovered.
  ///
  /// In en, this message translates to:
  /// **'Nothing here is under warranty yet.'**
  String get emptyCovered;

  /// No description provided for @emptyExpired.
  ///
  /// In en, this message translates to:
  /// **'Nothing has run out of cover.'**
  String get emptyExpired;

  /// No description provided for @emptyUnknown.
  ///
  /// In en, this message translates to:
  /// **'Every item has a warranty date on it. Adding them is what makes this screen worth opening.'**
  String get emptyUnknown;

  /// No description provided for @notRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded'**
  String get notRecorded;

  /// No description provided for @endsToday.
  ///
  /// In en, this message translates to:
  /// **'Ends today'**
  String get endsToday;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} d left'**
  String daysLeft(int days);

  /// No description provided for @monthsLeft.
  ///
  /// In en, this message translates to:
  /// **'{months} mo left'**
  String monthsLeft(int months);

  /// No description provided for @yearsLeft.
  ///
  /// In en, this message translates to:
  /// **'{years} yr left'**
  String yearsLeft(int years);

  /// No description provided for @yearsMonthsLeft.
  ///
  /// In en, this message translates to:
  /// **'{years} yr {months} mo left'**
  String yearsMonthsLeft(int years, int months);

  /// No description provided for @endedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {days} d ago'**
  String endedDaysAgo(int days);

  /// No description provided for @endedMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {months} mo ago'**
  String endedMonthsAgo(int months);

  /// No description provided for @endedYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'Ended {years} yr ago'**
  String endedYearsAgo(int years);

  /// No description provided for @needsDoing.
  ///
  /// In en, this message translates to:
  /// **'Needs doing ({count})'**
  String needsDoing(int count);

  /// No description provided for @nothingScheduledAnywhere.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled anywhere yet. Open any item and add what it needs doing — a filter, a service — and it will show up here when due.'**
  String get nothingScheduledAnywhere;

  /// No description provided for @nothingDueFortnight.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in the next fortnight.'**
  String get nothingDueFortnight;

  /// No description provided for @warrantiesAtRisk.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 warranty is at risk} other{{count} warranties are at risk}}'**
  String warrantiesAtRisk(int count);

  /// No description provided for @warrantiesAtRiskBody.
  ///
  /// In en, this message translates to:
  /// **'Servicing these items is a condition of their cover, and it has lapsed. A missed service is grounds to decline a claim.'**
  String get warrantiesAtRiskBody;

  /// No description provided for @warrantyAtRiskItem.
  ///
  /// In en, this message translates to:
  /// **'This item is still under warranty, and this job is required to keep it valid. A missed service is grounds to decline a claim.'**
  String get warrantyAtRiskItem;

  /// No description provided for @daysLate.
  ///
  /// In en, this message translates to:
  /// **'{days} d late'**
  String daysLate(int days);

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} d'**
  String dueInDays(int days);

  /// No description provided for @entriesToCheck.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 entry to check} other{{count} entries to check}}'**
  String entriesToCheck(int count);

  /// No description provided for @entriesToCheckBody.
  ///
  /// In en, this message translates to:
  /// **'Still own these, and are the details still right? A list that has drifted is one an insurer can argue with.'**
  String get entriesToCheckBody;

  /// No description provided for @stillRight.
  ///
  /// In en, this message translates to:
  /// **'Still right'**
  String get stillRight;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @backupNudgeNever.
  ///
  /// In en, this message translates to:
  /// **'This is only on this phone'**
  String get backupNudgeNever;

  /// No description provided for @backupNudgeDays.
  ///
  /// In en, this message translates to:
  /// **'No backup for {days} days'**
  String backupNudgeDays(int days);

  /// No description provided for @backupNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'{count} items, their photographs and every repair you have logged. Lose the phone and it goes with it.'**
  String backupNudgeBody(int count);

  /// No description provided for @scheduledJobs.
  ///
  /// In en, this message translates to:
  /// **'Scheduled jobs'**
  String get scheduledJobs;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noSchedulesYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled. Add the jobs this needs — a filter, a service — and you will be told when they fall due.'**
  String get noSchedulesYet;

  /// No description provided for @noHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No work recorded yet. Logging repairs is what makes the running cost below mean anything — and what a manufacturer asks for when a warranty claim turns on whether it was serviced.'**
  String get noHistoryYet;

  /// No description provided for @overdueByEvery.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days} days · every {months} mo'**
  String overdueByEvery(int days, int months);

  /// No description provided for @dueOnEvery.
  ///
  /// In en, this message translates to:
  /// **'Due {date} · every {months} mo'**
  String dueOnEvery(String date, int months);

  /// No description provided for @newJob.
  ///
  /// In en, this message translates to:
  /// **'New job'**
  String get newJob;

  /// No description provided for @editJob.
  ///
  /// In en, this message translates to:
  /// **'Edit job'**
  String get editJob;

  /// No description provided for @commonForThis.
  ///
  /// In en, this message translates to:
  /// **'Common for this kind of thing'**
  String get commonForThis;

  /// No description provided for @whatNeedsDoing.
  ///
  /// In en, this message translates to:
  /// **'What needs doing'**
  String get whatNeedsDoing;

  /// No description provided for @whatNeedsDoingHint.
  ///
  /// In en, this message translates to:
  /// **'Replace water filter'**
  String get whatNeedsDoingHint;

  /// No description provided for @howOften.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get howOften;

  /// No description provided for @requiredForWarranty.
  ///
  /// In en, this message translates to:
  /// **'Required to keep the warranty valid'**
  String get requiredForWarranty;

  /// No description provided for @requiredForWarrantyHint.
  ///
  /// In en, this message translates to:
  /// **'You will be warned if this lapses while the item is still covered.'**
  String get requiredForWarrantyHint;

  /// No description provided for @addJob.
  ///
  /// In en, this message translates to:
  /// **'Add job'**
  String get addJob;

  /// No description provided for @intervalMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get intervalMonthly;

  /// No description provided for @intervalQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Every 3 months'**
  String get intervalQuarterly;

  /// No description provided for @intervalHalfYearly.
  ///
  /// In en, this message translates to:
  /// **'Every 6 months'**
  String get intervalHalfYearly;

  /// No description provided for @intervalYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get intervalYearly;

  /// No description provided for @intervalBiennial.
  ///
  /// In en, this message translates to:
  /// **'Every 2 years'**
  String get intervalBiennial;

  /// No description provided for @logWorkDone.
  ///
  /// In en, this message translates to:
  /// **'Log work done'**
  String get logWorkDone;

  /// No description provided for @kindMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get kindMaintenance;

  /// No description provided for @kindRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get kindRepair;

  /// No description provided for @kindInspection.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get kindInspection;

  /// No description provided for @whatWasDone.
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get whatWasDone;

  /// No description provided for @whatWasDoneHint.
  ///
  /// In en, this message translates to:
  /// **'Replaced the pump'**
  String get whatWasDoneHint;

  /// No description provided for @cost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get cost;

  /// No description provided for @whoDidIt.
  ///
  /// In en, this message translates to:
  /// **'Who did it'**
  String get whoDidIt;

  /// No description provided for @when.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get when;

  /// No description provided for @satisfiesWhichJob.
  ///
  /// In en, this message translates to:
  /// **'Satisfies which job'**
  String get satisfiesWhichJob;

  /// No description provided for @satisfiesWhichJobHint.
  ///
  /// In en, this message translates to:
  /// **'Marks that job as done and moves its next date'**
  String get satisfiesWhichJobHint;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @verdictKeep.
  ///
  /// In en, this message translates to:
  /// **'Worth keeping'**
  String get verdictKeep;

  /// No description provided for @verdictWatch.
  ///
  /// In en, this message translates to:
  /// **'Worth watching'**
  String get verdictWatch;

  /// No description provided for @verdictReplace.
  ///
  /// In en, this message translates to:
  /// **'Worth replacing'**
  String get verdictReplace;

  /// No description provided for @paidForIt.
  ///
  /// In en, this message translates to:
  /// **'Paid for it'**
  String get paidForIt;

  /// No description provided for @spentOnRepairs.
  ///
  /// In en, this message translates to:
  /// **'Spent on repairs'**
  String get spentOnRepairs;

  /// No description provided for @worthToday.
  ///
  /// In en, this message translates to:
  /// **'Worth today'**
  String get worthToday;

  /// No description provided for @totalOutlay.
  ///
  /// In en, this message translates to:
  /// **'Total outlay'**
  String get totalOutlay;

  /// No description provided for @verdictKeepBody.
  ///
  /// In en, this message translates to:
  /// **'Repairs are small against what it is still worth.'**
  String get verdictKeepBody;

  /// No description provided for @verdictWatchBody.
  ///
  /// In en, this message translates to:
  /// **'Repairs have passed half its remaining value. Worth thinking twice about the next one.'**
  String get verdictWatchBody;

  /// No description provided for @verdictReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'You have spent more mending this than it is now worth. A replacement may cost less than the next repair.'**
  String get verdictReplaceBody;

  /// No description provided for @verdictDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'A rule of thumb on estimated values, not a valuation.'**
  String get verdictDisclaimer;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export Report to PDF'**
  String get exportPdf;

  /// No description provided for @exportPdfSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate insurance report'**
  String get exportPdfSubtitle;

  /// No description provided for @exportPdfSubtitlePro.
  ///
  /// In en, this message translates to:
  /// **'Full report: photos, serials, receipts, signed'**
  String get exportPdfSubtitlePro;

  /// No description provided for @nothingToReport.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to report on yet.'**
  String get nothingToReport;

  /// No description provided for @reportPreview.
  ///
  /// In en, this message translates to:
  /// **'Report Preview'**
  String get reportPreview;

  /// No description provided for @summaryReportBanner.
  ///
  /// In en, this message translates to:
  /// **'This is the summary report'**
  String get summaryReportBanner;

  /// No description provided for @summaryReportBannerBody.
  ///
  /// In en, this message translates to:
  /// **'Pro turns it into the document an insurer asks for: a page for each of your {count} items with its photographs, serial number, receipt, service history and estimated value today — plus a signed declaration.'**
  String summaryReportBannerBody(int count);

  /// No description provided for @seeWhatProAdds.
  ///
  /// In en, this message translates to:
  /// **'See what Pro adds'**
  String get seeWhatProAdds;

  /// No description provided for @canStillShare.
  ///
  /// In en, this message translates to:
  /// **'You can still share or print this one.'**
  String get canStillShare;

  /// No description provided for @backupData.
  ///
  /// In en, this message translates to:
  /// **'Back Up to a File'**
  String get backupData;

  /// No description provided for @backupNeverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Never backed up — save everything to one file'**
  String get backupNeverSubtitle;

  /// No description provided for @backupTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last backed up today'**
  String get backupTodaySubtitle;

  /// No description provided for @backupYesterdaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last backed up yesterday'**
  String get backupYesterdaySubtitle;

  /// No description provided for @backupDaysAgoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Last backed up {days} days ago'**
  String backupDaysAgoSubtitle(int days);

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from a Backup'**
  String get restoreBackup;

  /// No description provided for @restoreBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds the items in a backup file to this app'**
  String get restoreBackupSubtitle;

  /// No description provided for @nothingToBackUp.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to back up yet.'**
  String get nothingToBackUp;

  /// No description provided for @preparingBackup.
  ///
  /// In en, this message translates to:
  /// **'Preparing backup…'**
  String get preparingBackup;

  /// No description provided for @restoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get restoring;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {details}'**
  String backupFailed(String details);

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {details}'**
  String restoreFailed(String details);

  /// No description provided for @backupShareText.
  ///
  /// In en, this message translates to:
  /// **'Itemize backup — {count} items. Keep this file somewhere you can find it again.'**
  String backupShareText(int count);

  /// No description provided for @restoreCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get restoreCompleteTitle;

  /// No description provided for @restoreCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'{added} items added, {updated} updated, {photos} photos restored.\n{schedules} scheduled jobs and {records} history entries restored.\n\nNothing already on this device was removed.'**
  String restoreCompleteBody(
    int added,
    int updated,
    int photos,
    int schedules,
    int records,
  );

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @coverLimit.
  ///
  /// In en, this message translates to:
  /// **'Contents Cover Limit'**
  String get coverLimit;

  /// No description provided for @coverLimitUnset.
  ///
  /// In en, this message translates to:
  /// **'Not set — tell us and we will warn you if you outgrow it'**
  String get coverLimitUnset;

  /// No description provided for @coverLimitDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The most your policy pays out for belongings. Find it on your schedule under contents.'**
  String get coverLimitDialogBody;

  /// No description provided for @coverLimitHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to remove'**
  String get coverLimitHint;

  /// No description provided for @warrantyReminders.
  ///
  /// In en, this message translates to:
  /// **'Warranty Reminders'**
  String get warrantyReminders;

  /// No description provided for @warrantyRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Told 30, 7 and 1 days before one runs out'**
  String get warrantyRemindersSubtitle;

  /// No description provided for @maintenanceReminders.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Reminders'**
  String get maintenanceReminders;

  /// No description provided for @maintenanceRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Told a week before a scheduled job is due'**
  String get maintenanceRemindersSubtitle;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off for Itemize. Enable them in your device settings.'**
  String get notificationsOff;

  /// No description provided for @biometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLock;

  /// No description provided for @biometricLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require FaceID/TouchID for sensitive actions'**
  String get biometricLockSubtitle;

  /// No description provided for @biometricProOnly.
  ///
  /// In en, this message translates to:
  /// **'Available in Pro Version'**
  String get biometricProOnly;

  /// No description provided for @biometricDeviceSecurityOff.
  ///
  /// In en, this message translates to:
  /// **'Device security disabled. Biometric lock turned off.'**
  String get biometricDeviceSecurityOff;

  /// No description provided for @authFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get authFailed;

  /// No description provided for @authNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometrics/Security not set up. Please enable a Lock Screen (PIN/Pattern).'**
  String get authNotAvailable;

  /// No description provided for @authLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get authLockedOut;

  /// No description provided for @authPermanentlyLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Biometrics disabled. Use PIN/Pattern or re-enroll.'**
  String get authPermanentlyLockedOut;

  /// No description provided for @authToExport.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to export your inventory'**
  String get authToExport;

  /// No description provided for @authToBackUp.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to back up your data'**
  String get authToBackUp;

  /// No description provided for @authToRestore.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to restore a backup'**
  String get authToRestore;

  /// No description provided for @authToDisableLock.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to disable Lock'**
  String get authToDisableLock;

  /// No description provided for @appLocked.
  ///
  /// In en, this message translates to:
  /// **'Itemize Locked'**
  String get appLocked;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get upgradeToPro;

  /// No description provided for @upgradeToProSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Insurance reports and backups. Everything else is free.'**
  String get upgradeToProSubtitle;

  /// No description provided for @proBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proBadge;

  /// No description provided for @unlockFullPotential.
  ///
  /// In en, this message translates to:
  /// **'Unlock Full Potential'**
  String get unlockFullPotential;

  /// No description provided for @paywallLead.
  ///
  /// In en, this message translates to:
  /// **'Recording and looking after your things is free, unlimited, and stays that way. Pro is for getting it back out.'**
  String get paywallLead;

  /// No description provided for @paywallReport.
  ///
  /// In en, this message translates to:
  /// **'Insurance Report'**
  String get paywallReport;

  /// No description provided for @paywallReportBody.
  ///
  /// In en, this message translates to:
  /// **'A page for every item — photos, serial number, receipt, service history and estimated current value, grouped by room and signed.'**
  String get paywallReportBody;

  /// No description provided for @paywallBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get paywallBackup;

  /// No description provided for @paywallBackupBody.
  ///
  /// In en, this message translates to:
  /// **'Every item, photo and year of service history in one file you keep. No account, no cloud, nothing leaves your device unless you send it.'**
  String get paywallBackupBody;

  /// No description provided for @paywallBiometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get paywallBiometric;

  /// No description provided for @paywallBiometricBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the inventory behind FaceID or TouchID.'**
  String get paywallBiometricBody;

  /// No description provided for @storeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store is unavailable right now. Please try again later.'**
  String get storeUnavailable;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @upgradeFor.
  ///
  /// In en, this message translates to:
  /// **'Upgrade for {price}'**
  String upgradeFor(String price);

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @subscriptionFinePrint.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically until cancelled. Manage or cancel any time in your account settings.'**
  String get subscriptionFinePrint;

  /// No description provided for @oneTimeFinePrint.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase. No subscription.'**
  String get oneTimeFinePrint;

  /// No description provided for @welcomeToPro.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Pro!'**
  String get welcomeToPro;

  /// No description provided for @reportTitlePro.
  ///
  /// In en, this message translates to:
  /// **'Home Inventory Report'**
  String get reportTitlePro;

  /// No description provided for @reportTitleFree.
  ///
  /// In en, this message translates to:
  /// **'Itemize Report'**
  String get reportTitleFree;

  /// No description provided for @reportItemsRecorded.
  ///
  /// In en, this message translates to:
  /// **'Items recorded'**
  String get reportItemsRecorded;

  /// No description provided for @reportRoomsCovered.
  ///
  /// In en, this message translates to:
  /// **'Rooms covered'**
  String get reportRoomsCovered;

  /// No description provided for @reportTotalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total purchase price'**
  String get reportTotalPaid;

  /// No description provided for @reportEstimatedToday.
  ///
  /// In en, this message translates to:
  /// **'Estimated value today'**
  String get reportEstimatedToday;

  /// No description provided for @reportDepreciation.
  ///
  /// In en, this message translates to:
  /// **'Estimated depreciation'**
  String get reportDepreciation;

  /// No description provided for @reportWithSerial.
  ///
  /// In en, this message translates to:
  /// **'Items with a serial number'**
  String get reportWithSerial;

  /// No description provided for @reportWithReceipt.
  ///
  /// In en, this message translates to:
  /// **'Items with a receipt attached'**
  String get reportWithReceipt;

  /// No description provided for @reportOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String reportOfTotal(int count, int total);

  /// No description provided for @reportEstimateDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Estimated values are straight-line figures based on conventional useful life by category. They are provided to help you check your cover and are not a valuation; your insurer may apply a different schedule.'**
  String get reportEstimateDisclaimer;

  /// No description provided for @reportNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items recorded.'**
  String get reportNoItems;

  /// No description provided for @reportColItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get reportColItem;

  /// No description provided for @reportColSerialModel.
  ///
  /// In en, this message translates to:
  /// **'Serial / Model'**
  String get reportColSerialModel;

  /// No description provided for @reportColPurchased.
  ///
  /// In en, this message translates to:
  /// **'Purchased'**
  String get reportColPurchased;

  /// No description provided for @reportColPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get reportColPaid;

  /// No description provided for @reportColToday.
  ///
  /// In en, this message translates to:
  /// **'Est. today'**
  String get reportColToday;

  /// No description provided for @reportSubtotal.
  ///
  /// In en, this message translates to:
  /// **'{room} subtotal: {amount}'**
  String reportSubtotal(String room, String amount);

  /// No description provided for @reportItemDetail.
  ///
  /// In en, this message translates to:
  /// **'Item detail'**
  String get reportItemDetail;

  /// No description provided for @reportPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get reportPurchasePrice;

  /// No description provided for @reportWarrantyUntil.
  ///
  /// In en, this message translates to:
  /// **'Warranty until'**
  String get reportWarrantyUntil;

  /// No description provided for @reportServiceHistory.
  ///
  /// In en, this message translates to:
  /// **'Service history'**
  String get reportServiceHistory;

  /// No description provided for @reportSpentToDate.
  ///
  /// In en, this message translates to:
  /// **'Spent on this item to date: {amount}'**
  String reportSpentToDate(String amount);

  /// No description provided for @reportDeclaration.
  ///
  /// In en, this message translates to:
  /// **'Declaration'**
  String get reportDeclaration;

  /// No description provided for @reportDeclarationBody.
  ///
  /// In en, this message translates to:
  /// **'I confirm that the items listed in this report were owned by me on {date}, and that the details and photographs given are accurate to the best of my knowledge.'**
  String reportDeclarationBody(String date);

  /// No description provided for @reportSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get reportSignature;

  /// No description provided for @reportDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get reportDate;

  /// No description provided for @reportSummaryNotice.
  ///
  /// In en, this message translates to:
  /// **'This is the summary report.'**
  String get reportSummaryNotice;

  /// No description provided for @reportSummaryNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Itemize Pro adds a page for every item with its photographs, serial number, receipt, service history and estimated current value, plus a signed declaration — the form an insurer asks for when you claim.'**
  String get reportSummaryNoticeBody;

  /// No description provided for @reportPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String reportPageOf(int page, int total);

  /// No description provided for @reportFooterFree.
  ///
  /// In en, this message translates to:
  /// **'Generated by Itemize Free'**
  String get reportFooterFree;

  /// No description provided for @roomLivingRoom.
  ///
  /// In en, this message translates to:
  /// **'Living Room'**
  String get roomLivingRoom;

  /// No description provided for @roomKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get roomKitchen;

  /// No description provided for @roomBedroom.
  ///
  /// In en, this message translates to:
  /// **'Bedroom'**
  String get roomBedroom;

  /// No description provided for @roomOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get roomOffice;

  /// No description provided for @roomGarage.
  ///
  /// In en, this message translates to:
  /// **'Garage'**
  String get roomGarage;

  /// No description provided for @roomOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get roomOther;

  /// No description provided for @catElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get catElectronics;

  /// No description provided for @catFurniture.
  ///
  /// In en, this message translates to:
  /// **'Furniture'**
  String get catFurniture;

  /// No description provided for @catAppliances.
  ///
  /// In en, this message translates to:
  /// **'Appliances'**
  String get catAppliances;

  /// No description provided for @catJewelry.
  ///
  /// In en, this message translates to:
  /// **'Jewelry & Watches'**
  String get catJewelry;

  /// No description provided for @catClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get catClothing;

  /// No description provided for @catTools.
  ///
  /// In en, this message translates to:
  /// **'Tools & Equipment'**
  String get catTools;

  /// No description provided for @catSports.
  ///
  /// In en, this message translates to:
  /// **'Sports & Outdoors'**
  String get catSports;

  /// No description provided for @catKitchenware.
  ///
  /// In en, this message translates to:
  /// **'Kitchenware'**
  String get catKitchenware;

  /// No description provided for @catArt.
  ///
  /// In en, this message translates to:
  /// **'Art & Collectibles'**
  String get catArt;

  /// No description provided for @catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// No description provided for @jobReplaceWaterFilter.
  ///
  /// In en, this message translates to:
  /// **'Replace water filter'**
  String get jobReplaceWaterFilter;

  /// No description provided for @jobCleanCoils.
  ///
  /// In en, this message translates to:
  /// **'Clean condenser coils'**
  String get jobCleanCoils;

  /// No description provided for @jobAnnualService.
  ///
  /// In en, this message translates to:
  /// **'Annual service'**
  String get jobAnnualService;

  /// No description provided for @jobCleanVents.
  ///
  /// In en, this message translates to:
  /// **'Clean dust from vents'**
  String get jobCleanVents;

  /// No description provided for @jobReplaceBattery.
  ///
  /// In en, this message translates to:
  /// **'Replace backup battery'**
  String get jobReplaceBattery;

  /// No description provided for @jobServiceSharpen.
  ///
  /// In en, this message translates to:
  /// **'Service and sharpen'**
  String get jobServiceSharpen;

  /// No description provided for @jobSafetyInspection.
  ///
  /// In en, this message translates to:
  /// **'Safety inspection'**
  String get jobSafetyInspection;

  /// No description provided for @jobTreatOil.
  ///
  /// In en, this message translates to:
  /// **'Treat or re-oil'**
  String get jobTreatOil;

  /// No description provided for @jobService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get jobService;

  /// No description provided for @itemSofa.
  ///
  /// In en, this message translates to:
  /// **'Sofa'**
  String get itemSofa;

  /// No description provided for @itemArmchair.
  ///
  /// In en, this message translates to:
  /// **'Armchair'**
  String get itemArmchair;

  /// No description provided for @itemCoffeeTable.
  ///
  /// In en, this message translates to:
  /// **'Coffee Table'**
  String get itemCoffeeTable;

  /// No description provided for @itemTelevision.
  ///
  /// In en, this message translates to:
  /// **'Television'**
  String get itemTelevision;

  /// No description provided for @itemFloorLamp.
  ///
  /// In en, this message translates to:
  /// **'Floor Lamp'**
  String get itemFloorLamp;

  /// No description provided for @itemBookshelf.
  ///
  /// In en, this message translates to:
  /// **'Bookshelf'**
  String get itemBookshelf;

  /// No description provided for @itemSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get itemSpeaker;

  /// No description provided for @itemRefrigerator.
  ///
  /// In en, this message translates to:
  /// **'Refrigerator'**
  String get itemRefrigerator;

  /// No description provided for @itemMicrowave.
  ///
  /// In en, this message translates to:
  /// **'Microwave'**
  String get itemMicrowave;

  /// No description provided for @itemCoffeeMaker.
  ///
  /// In en, this message translates to:
  /// **'Coffee Maker'**
  String get itemCoffeeMaker;

  /// No description provided for @itemBlender.
  ///
  /// In en, this message translates to:
  /// **'Blender'**
  String get itemBlender;

  /// No description provided for @itemDiningTable.
  ///
  /// In en, this message translates to:
  /// **'Dining Table'**
  String get itemDiningTable;

  /// No description provided for @itemDishwasher.
  ///
  /// In en, this message translates to:
  /// **'Dishwasher'**
  String get itemDishwasher;

  /// No description provided for @itemBed.
  ///
  /// In en, this message translates to:
  /// **'Bed'**
  String get itemBed;

  /// No description provided for @itemWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get itemWardrobe;

  /// No description provided for @itemWashingMachine.
  ///
  /// In en, this message translates to:
  /// **'Washing Machine'**
  String get itemWashingMachine;

  /// No description provided for @itemAirPurifier.
  ///
  /// In en, this message translates to:
  /// **'Air Purifier'**
  String get itemAirPurifier;

  /// No description provided for @itemIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get itemIron;

  /// No description provided for @itemLaptop.
  ///
  /// In en, this message translates to:
  /// **'Laptop'**
  String get itemLaptop;

  /// No description provided for @itemMonitor.
  ///
  /// In en, this message translates to:
  /// **'Monitor'**
  String get itemMonitor;

  /// No description provided for @itemDesk.
  ///
  /// In en, this message translates to:
  /// **'Desk'**
  String get itemDesk;

  /// No description provided for @itemOfficeChair.
  ///
  /// In en, this message translates to:
  /// **'Office Chair'**
  String get itemOfficeChair;

  /// No description provided for @itemPrinter.
  ///
  /// In en, this message translates to:
  /// **'Printer'**
  String get itemPrinter;

  /// No description provided for @itemRouter.
  ///
  /// In en, this message translates to:
  /// **'Router'**
  String get itemRouter;

  /// No description provided for @itemKeyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get itemKeyboard;

  /// No description provided for @itemHeadphones.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get itemHeadphones;

  /// No description provided for @itemBicycle.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get itemBicycle;

  /// No description provided for @itemCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get itemCar;

  /// No description provided for @itemPowerTools.
  ///
  /// In en, this message translates to:
  /// **'Power Tools'**
  String get itemPowerTools;

  /// No description provided for @itemToolbox.
  ///
  /// In en, this message translates to:
  /// **'Toolbox'**
  String get itemToolbox;

  /// No description provided for @itemLawnMower.
  ///
  /// In en, this message translates to:
  /// **'Lawn Mower'**
  String get itemLawnMower;

  /// No description provided for @itemCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get itemCamera;

  /// No description provided for @itemWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get itemWatch;

  /// No description provided for @itemPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get itemPhone;

  /// No description provided for @itemTablet.
  ///
  /// In en, this message translates to:
  /// **'Tablet'**
  String get itemTablet;

  /// No description provided for @itemBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get itemBooks;

  /// No description provided for @itemGymEquipment.
  ///
  /// In en, this message translates to:
  /// **'Gym Equipment'**
  String get itemGymEquipment;

  /// No description provided for @itemLuggage.
  ///
  /// In en, this message translates to:
  /// **'Luggage'**
  String get itemLuggage;

  /// No description provided for @itemMusicalInstrument.
  ///
  /// In en, this message translates to:
  /// **'Musical Instrument'**
  String get itemMusicalInstrument;

  /// No description provided for @authToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate to continue'**
  String get authToContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
