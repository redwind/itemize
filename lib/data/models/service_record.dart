/// What was done to an item on a given day.
enum ServiceKind {
  /// Scheduled upkeep — a filter, a service, an oil change.
  maintenance,

  /// Something broke and was mended.
  repair,

  /// Looked at and passed, with nothing replaced.
  inspection,
}

/// One entry in an item's history.
///
/// Two things come out of keeping these. Every repair has a cost, and the
/// running total against what the item is now worth is what answers "mend it
/// again or replace it" — the question a home inventory is otherwise no help
/// with. And a documented service history is what keeps a manufacturer from
/// declining a warranty claim on the grounds that the schedule was not kept.
class ServiceRecord {
  final String id;
  final String assetId;
  final DateTime date;
  final ServiceKind kind;
  final String? description;

  /// What it cost. Zero for work done under warranty or done at home, which is
  /// itself worth recording — a free repair is still a repair.
  final double cost;

  /// Who did it, so it can be found again.
  final String? provider;

  /// The schedule this satisfies, when it was logged against one.
  final String? scheduleId;

  const ServiceRecord({
    required this.id,
    required this.assetId,
    required this.date,
    required this.kind,
    this.description,
    this.cost = 0,
    this.provider,
    this.scheduleId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'assetId': assetId,
    'date': date.toIso8601String(),
    'kind': kind.name,
    'description': description,
    'cost': cost,
    'provider': provider,
    'scheduleId': scheduleId,
  };

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      id: map['id'] as String,
      assetId: map['assetId'] as String,
      date: DateTime.parse(map['date'] as String),
      // An unrecognised kind falls back to repair rather than throwing: a row
      // written by a newer build should not make the history unreadable.
      kind: ServiceKind.values.firstWhere(
        (k) => k.name == map['kind'],
        orElse: () => ServiceKind.repair,
      ),
      description: map['description'] as String?,
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
      provider: map['provider'] as String?,
      scheduleId: map['scheduleId'] as String?,
    );
  }

  @override
  String toString() => 'ServiceRecord(${kind.name}, $date, $cost)';
}
