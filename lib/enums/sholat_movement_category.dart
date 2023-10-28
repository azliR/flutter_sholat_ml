enum SholatMovementCategory {
  persiapan,
  takbir,
  berdiri,
  ruku,
  iktidal,
  qunut,
  sujud,
  duduk,
  lainnya;

  factory SholatMovementCategory.fromValue(String value) {
    return SholatMovementCategory.values.firstWhere((e) => e.value == value);
  }

  String get name {
    switch (this) {
      case SholatMovementCategory.persiapan:
        return 'Persiapan';
      case SholatMovementCategory.takbir:
        return 'Takbir';
      case SholatMovementCategory.berdiri:
        return 'Berdiri';
      case SholatMovementCategory.ruku:
        return 'Ruku';
      case SholatMovementCategory.iktidal:
        return 'Iktidal';
      case SholatMovementCategory.qunut:
        return 'Qunut';
      case SholatMovementCategory.sujud:
        return 'Sujud';
      case SholatMovementCategory.duduk:
        return 'Duduk';
      case SholatMovementCategory.lainnya:
        return 'Lainnya';
    }
  }

  String get value {
    switch (this) {
      case SholatMovementCategory.persiapan:
        return 'persiapan';
      case SholatMovementCategory.takbir:
        return 'takbir';
      case SholatMovementCategory.berdiri:
        return 'berdiri';
      case SholatMovementCategory.ruku:
        return 'ruku';
      case SholatMovementCategory.iktidal:
        return 'iktidal';
      case SholatMovementCategory.qunut:
        return 'qunut';
      case SholatMovementCategory.sujud:
        return 'sujud';
      case SholatMovementCategory.duduk:
        return 'duduk';
      case SholatMovementCategory.lainnya:
        return 'lainnya';
    }
  }
}
