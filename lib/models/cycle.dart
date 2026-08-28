class Cycle {
  final int? id;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleLength;
  final int? periodLength;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cycle({
    this.id,
    required this.startDate,
    this.endDate,
    this.cycleLength,
    this.periodLength,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate?.millisecondsSinceEpoch,
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'notes': notes,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory Cycle.fromMap(Map<String, dynamic> m) => Cycle(
        id: m['id'] as int?,
        startDate: DateTime.fromMillisecondsSinceEpoch(m['startDate'] as int),
        endDate: m['endDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(m['endDate'] as int)
            : null,
        cycleLength: m['cycleLength'] as int?,
        periodLength: m['periodLength'] as int?,
        notes: m['notes'] as String? ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int),
      );

  Cycle copyWith({
    int? id,
    DateTime? startDate,
    DateTime? endDate,
    int? cycleLength,
    int? periodLength,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Cycle(
        id: id ?? this.id,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        cycleLength: cycleLength ?? this.cycleLength,
        periodLength: periodLength ?? this.periodLength,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  bool get isOngoing => endDate == null;

  int get daysSinceStart =>
      DateTime.now().difference(startDate).inDays + 1;
}
