import 'package:inventa/data/models/asset.dart';
import 'package:inventa/data/models/service_record.dart';
import 'package:inventa/l10n/app_localizations.dart';

/// Translates the values the app stores, without translating what it stores.
///
/// Rooms and categories are persisted as English strings and used as lookup
/// keys in three places: the depreciation table, the catalog tints and the
/// suggested-maintenance list. Storing a translated value would break all three
/// the moment somebody changed language, and would leave a database whose
/// meaning depended on a setting. So the English string stays in storage and
/// only ever gets translated on its way to the screen.
///
/// Everything here falls back to the raw value. A room typed before the app
/// knew about it, or carried in from a backup made by a later version, should
/// appear as itself rather than vanish.
extension DomainLabels on AppLocalizations {
  String roomLabel(String room) => switch (room) {
    'Living Room' => roomLivingRoom,
    'Kitchen' => roomKitchen,
    'Dining Room' => roomDiningRoom,
    'Bathroom' => roomBathroom,
    'Bedroom' => roomBedroom,
    "Kids' Room" => roomKidsRoom,
    'Office' => roomOffice,
    'Hallway' => roomHallway,
    'Basement' => roomBasement,
    'Garage' => roomGarage,
    'Garden & Balcony' => roomGarden,
    'Other' => roomOther,
    _ => room,
  };

  String categoryLabel(String category) => switch (category) {
    'Electronics' => catElectronics,
    'Furniture' => catFurniture,
    'Appliances' => catAppliances,
    'Jewelry & Watches' => catJewelry,
    'Clothing' => catClothing,
    'Tools & Equipment' => catTools,
    'Sports & Outdoors' => catSports,
    'Kitchenware' => catKitchenware,
    'Art & Collectibles' => catArt,
    'Other' => catOther,
    kUncategorized => uncategorized,
    _ => category,
  };

  /// A suggested job's name. See [kSuggestedMaintenance] for the keys.
  ///
  /// Only the suggestion is translated. Once accepted it becomes the schedule's
  /// own title -- free text the owner may edit -- and is stored as typed, in
  /// whatever language they were using. That is correct: it is their note about
  /// their boiler, not a term the app needs to understand.
  String jobLabel(String key) => switch (key) {
    'replaceWaterFilter' => jobReplaceWaterFilter,
    'cleanCoils' => jobCleanCoils,
    'annualService' => jobAnnualService,
    'cleanVents' => jobCleanVents,
    'replaceBattery' => jobReplaceBattery,
    'serviceSharpen' => jobServiceSharpen,
    'safetyInspection' => jobSafetyInspection,
    'treatOil' => jobTreatOil,
    'service' => jobService,
    _ => key,
  };

  /// A stock item's name. See [CatalogItem.labelKey].
  String catalogLabel(String key) => _catalogLabels(this)[key] ?? key;

  String serviceKindLabel(ServiceKind kind) => switch (kind) {
    ServiceKind.maintenance => kindMaintenance,
    ServiceKind.repair => kindRepair,
    ServiceKind.inspection => kindInspection,
  };

  /// How often a job comes round, spelled out.
  String intervalLabel(int months) => switch (months) {
    1 => intervalMonthly,
    3 => intervalQuarterly,
    6 => intervalHalfYearly,
    12 => intervalYearly,
    24 => intervalBiennial,
    _ => '$months',
  };
}

/// Built once per call rather than as a constant, because every value is a
/// getter on the localizations object rather than a literal.
Map<String, String> _catalogLabels(AppLocalizations l) => {
      'sofa': l.itemSofa,
      'armchair': l.itemArmchair,
      'coffeeTable': l.itemCoffeeTable,
      'television': l.itemTelevision,
      'floorLamp': l.itemFloorLamp,
      'bookshelf': l.itemBookshelf,
      'speaker': l.itemSpeaker,
      'refrigerator': l.itemRefrigerator,
      'microwave': l.itemMicrowave,
      'coffeeMaker': l.itemCoffeeMaker,
      'blender': l.itemBlender,
      'diningTable': l.itemDiningTable,
      'dishwasher': l.itemDishwasher,
      'bed': l.itemBed,
      'wardrobe': l.itemWardrobe,
      'washingMachine': l.itemWashingMachine,
      'airPurifier': l.itemAirPurifier,
      'iron': l.itemIron,
      'laptop': l.itemLaptop,
      'monitor': l.itemMonitor,
      'desk': l.itemDesk,
      'officeChair': l.itemOfficeChair,
      'printer': l.itemPrinter,
      'router': l.itemRouter,
      'keyboard': l.itemKeyboard,
      'headphones': l.itemHeadphones,
      'bicycle': l.itemBicycle,
      'car': l.itemCar,
      'powerTools': l.itemPowerTools,
      'toolbox': l.itemToolbox,
      'lawnMower': l.itemLawnMower,
      'camera': l.itemCamera,
      'watch': l.itemWatch,
      'phone': l.itemPhone,
      'tablet': l.itemTablet,
      'books': l.itemBooks,
      'gymEquipment': l.itemGymEquipment,
      'luggage': l.itemLuggage,
      'musicalInstrument': l.itemMusicalInstrument,
    };
