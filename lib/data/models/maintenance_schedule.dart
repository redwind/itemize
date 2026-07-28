/// Common intervals, offered so nobody has to think in months.
///
/// Months rather than labels: the wording is translated at display time, and a
/// map keyed by an English phrase would have made the interval depend on the
/// language the app happened to be in.
const List<int> kMaintenanceIntervals = [1, 3, 6, 12, 24];

/// Jobs an item needs doing again and again, offered as a starting point.
///
/// Keyed by category, because what a fridge needs and what a boiler needs have
/// nothing in common and asking someone to invent the list from nothing is the
/// blank-page problem that stops people using this at all. The key stays the
/// English category held in the database; the title is a translation key, so
/// the suggestion reads in the owner's language without the filing changing.
const Map<String, List<({String titleKey, int months, bool warranty})>>
kSuggestedMaintenance = {
  'Appliances': [
    (titleKey: 'replaceWaterFilter', months: 6, warranty: false),
    (titleKey: 'cleanCoils', months: 12, warranty: false),
    (titleKey: 'annualService', months: 12, warranty: true),
  ],
  'Electronics': [
    (titleKey: 'cleanVents', months: 6, warranty: false),
    (titleKey: 'replaceBattery', months: 24, warranty: false),
  ],
  'Tools & Equipment': [
    (titleKey: 'serviceSharpen', months: 12, warranty: false),
    (titleKey: 'safetyInspection', months: 12, warranty: true),
  ],
  'Furniture': [(titleKey: 'treatOil', months: 12, warranty: false)],
  'Sports & Outdoors': [(titleKey: 'service', months: 12, warranty: false)],
};

/// A recurring job attached to one item.
///
/// The `requiredForWarranty` flag is the point of the whole feature. Plenty of
/// manufacturers void cover if their servicing schedule is not kept, and the
/// owner finds out at the moment they try to claim. This app already knows the
/// warranty date; knowing the schedule too lets it say so a year in advance.
class MaintenanceSchedule {
  final String id;
  final String assetId;
  final String title;

  /// How often it comes round, in months.
  final int intervalMonths;

  /// When it was last done, or null if it never has been.
  final DateTime? lastDoneAt;

  /// Whether skipping this voids the item's warranty.
  final bool requiredForWarranty;

  final String? notes;

  const MaintenanceSchedule({
    required this.id,
    required this.assetId,
    required this.title,
    required this.intervalMonths,
    this.lastDoneAt,
    this.requiredForWarranty = false,
    this.notes,
  });

  /// When this next falls due.
  ///
  /// Counted from the last time it was done, or from [fallbackStart] — the
  /// item's purchase date — when it never has been. A schedule added to a
  /// five-year-old boiler is therefore overdue immediately, which is the
  /// truth rather than a kindness.
  DateTime nextDueAfter(DateTime fallbackStart) =>
      addMonths(lastDoneAt ?? fallbackStart, intervalMonths);

  /// Adds whole months, clamping to the end of a shorter month.
  ///
  /// 31 January plus one month is 28 February, not 3 March: letting DateTime
  /// roll over would walk a monthly job forward through the calendar until it
  /// drifted into the wrong month entirely.
  static DateTime addMonths(DateTime from, int months) {
    final totalMonths = from.month - 1 + months;
    final year = from.year + (totalMonths ~/ 12);
    final month = (totalMonths % 12) + 1;
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = from.day <= lastDayOfMonth ? from.day : lastDayOfMonth;
    return DateTime(year, month, day);
  }

  MaintenanceSchedule copyWith({
    String? title,
    int? intervalMonths,
    DateTime? lastDoneAt,
    bool? requiredForWarranty,
    String? notes,
  }) {
    return MaintenanceSchedule(
      id: id,
      assetId: assetId,
      title: title ?? this.title,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      lastDoneAt: lastDoneAt ?? this.lastDoneAt,
      requiredForWarranty: requiredForWarranty ?? this.requiredForWarranty,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'assetId': assetId,
    'title': title,
    'intervalMonths': intervalMonths,
    'lastDoneAt': lastDoneAt?.toIso8601String(),
    'requiredForWarranty': requiredForWarranty ? 1 : 0,
    'notes': notes,
  };

  factory MaintenanceSchedule.fromMap(Map<String, dynamic> map) {
    return MaintenanceSchedule(
      id: map['id'] as String,
      assetId: map['assetId'] as String,
      title: map['title'] as String,
      intervalMonths: (map['intervalMonths'] as num).toInt(),
      lastDoneAt:
          map['lastDoneAt'] != null
              ? DateTime.parse(map['lastDoneAt'] as String)
              : null,
      requiredForWarranty: map['requiredForWarranty'] == 1,
      notes: map['notes'] as String?,
    );
  }

  @override
  String toString() =>
      'MaintenanceSchedule($title, every $intervalMonths mo, '
      'last: $lastDoneAt, warranty: $requiredForWarranty)';
}
