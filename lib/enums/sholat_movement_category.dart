enum SholatMovementCategory {
  takbir,
  berdiri,
  ruku,
  iktidal,
  qunut,
  sujud,
  duduk,
  transisi;

  factory SholatMovementCategory.fromValue(String value) {
    return SholatMovementCategory.values.firstWhere((e) => e.value == value);
  }

  String get name => switch (this) {
        SholatMovementCategory.takbir => 'Takbir',
        SholatMovementCategory.berdiri => 'Berdiri',
        SholatMovementCategory.ruku => 'Ruku',
        SholatMovementCategory.iktidal => 'Iktidal',
        SholatMovementCategory.qunut => 'Qunut',
        SholatMovementCategory.sujud => 'Sujud',
        SholatMovementCategory.duduk => 'Duduk',
        SholatMovementCategory.transisi => 'Transisi',
      };

  String get value => switch (this) {
        SholatMovementCategory.takbir => 'takbir',
        SholatMovementCategory.berdiri => 'berdiri',
        SholatMovementCategory.ruku => 'ruku',
        SholatMovementCategory.iktidal => 'iktidal',
        SholatMovementCategory.qunut => 'qunut',
        SholatMovementCategory.sujud => 'sujud',
        SholatMovementCategory.duduk => 'duduk',
        SholatMovementCategory.transisi => 'transisi',
      };

  bool get isDeprecated => false;
}
