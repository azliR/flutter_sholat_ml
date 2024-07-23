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

  List<SholatMovementCategory?> get previousMovementCategories {
    return switch (this) {
      SholatMovementCategory.takbir => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.berdiri => [
          null,
          SholatMovementCategory.takbir,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.ruku => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.iktidal => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.qunut => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.sujud => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.duduk => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.transisi => [
          null,
          SholatMovementCategory.takbir,
          SholatMovementCategory.berdiri,
          SholatMovementCategory.ruku,
          SholatMovementCategory.iktidal,
          SholatMovementCategory.qunut,
          SholatMovementCategory.sujud,
          SholatMovementCategory.duduk,
          SholatMovementCategory.transisi,
        ],
    };
  }

  List<SholatMovementCategory?> get nextMovementCategories {
    return switch (this) {
      SholatMovementCategory.takbir => [
          null,
          SholatMovementCategory.berdiri,
        ],
      SholatMovementCategory.berdiri => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.ruku => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.iktidal => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.qunut => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.sujud => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.duduk => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.transisi => [
          null,
          SholatMovementCategory.takbir,
          SholatMovementCategory.berdiri,
          SholatMovementCategory.ruku,
          SholatMovementCategory.iktidal,
          SholatMovementCategory.qunut,
          SholatMovementCategory.sujud,
          SholatMovementCategory.duduk,
          SholatMovementCategory.transisi,
        ],
    };
  }

  List<SholatMovementCategory> get nextMovementCategoriesBySequence {
    return switch (this) {
      SholatMovementCategory.takbir => [
          SholatMovementCategory.berdiri,
          // SholatMovementCategory.iktidal,
          // SholatMovementCategory.ruku,
        ],
      SholatMovementCategory.berdiri => [
          SholatMovementCategory.ruku,
        ],
      SholatMovementCategory.ruku => [
          SholatMovementCategory.iktidal,
        ],
      SholatMovementCategory.iktidal => [
          SholatMovementCategory.sujud,
          SholatMovementCategory.qunut,
        ],
      SholatMovementCategory.qunut => [
          SholatMovementCategory.sujud,
        ],
      SholatMovementCategory.sujud => [
          SholatMovementCategory.duduk,
        ],
      SholatMovementCategory.duduk => [
          SholatMovementCategory.sujud,
          SholatMovementCategory.berdiri,
        ],
      SholatMovementCategory.transisi => [
          SholatMovementCategory.takbir,
          SholatMovementCategory.berdiri,
          SholatMovementCategory.ruku,
          SholatMovementCategory.iktidal,
          SholatMovementCategory.qunut,
          SholatMovementCategory.sujud,
          SholatMovementCategory.duduk,
          SholatMovementCategory.transisi,
        ],
    };
  }
}
