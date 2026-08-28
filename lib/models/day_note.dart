class DayNote {
  final int? id;
  final DateTime date;
  final int? cycleId;
  final String content;
  final String? mood;
  final String? flowLevel;
  final int crampsSeverity;
  final List<String> symptoms;
  final DateTime createdAt;
  final DateTime updatedAt;

  DayNote({
    this.id,
    required this.date,
    this.cycleId,
    this.content = '',
    this.mood,
    this.flowLevel,
    this.crampsSeverity = 0,
    this.symptoms = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
        'cycleId': cycleId,
        'content': content,
        'mood': mood,
        'flowLevel': flowLevel,
        'crampsSeverity': crampsSeverity,
        'symptoms': symptoms.join(','),
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  factory DayNote.fromMap(Map<String, dynamic> m) => DayNote(
        id: m['id'] as int?,
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        cycleId: m['cycleId'] as int?,
        content: m['content'] as String? ?? '',
        mood: m['mood'] as String?,
        flowLevel: m['flowLevel'] as String?,
        crampsSeverity: m['crampsSeverity'] as int? ?? 0,
        symptoms: (m['symptoms'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(m['updatedAt'] as int),
      );

  DayNote copyWith({
    int? id,
    DateTime? date,
    int? cycleId,
    String? content,
    String? mood,
    String? flowLevel,
    int? crampsSeverity,
    List<String>? symptoms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DayNote(
        id: id ?? this.id,
        date: date ?? this.date,
        cycleId: cycleId ?? this.cycleId,
        content: content ?? this.content,
        mood: mood ?? this.mood,
        flowLevel: flowLevel ?? this.flowLevel,
        crampsSeverity: crampsSeverity ?? this.crampsSeverity,
        symptoms: symptoms ?? this.symptoms,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
