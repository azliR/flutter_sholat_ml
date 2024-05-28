import 'package:flutter_sholat_ml/enums/sholat_movements.dart';

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

  List<SholatMovementCategory?> get previousMovementCategory {
    return switch (this) {
      SholatMovementCategory.takbir => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.berdiri => [
          SholatMovementCategory.takbir,
        ],
      SholatMovementCategory.ruku => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.iktidal => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.qunut => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.sujud => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.duduk => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.transisi => [
          SholatMovementCategory.takbir,
          SholatMovementCategory.berdiri,
          SholatMovementCategory.ruku,
          SholatMovementCategory.iktidal,
          SholatMovementCategory.qunut,
          SholatMovementCategory.sujud,
          SholatMovementCategory.duduk,
        ],
    };
  }

  List<SholatMovementCategory?> get nextMovementCategory {
    return switch (this) {
      SholatMovementCategory.takbir => [
          SholatMovementCategory.berdiri,
        ],
      SholatMovementCategory.berdiri => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.ruku => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.iktidal => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.qunut => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.sujud => [
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.duduk => [
          null,
          SholatMovementCategory.transisi,
        ],
      SholatMovementCategory.transisi => [
          SholatMovementCategory.takbir,
          SholatMovementCategory.berdiri,
          SholatMovementCategory.ruku,
          SholatMovementCategory.iktidal,
          SholatMovementCategory.qunut,
          SholatMovementCategory.sujud,
          SholatMovementCategory.duduk,
        ],
    };
  }

  List<SholatMovement?> get previousMovement {
    return switch (this) {
      SholatMovementCategory.takbir => [
          null,
          SholatMovement.transisiDudukKeBersedekap,
          SholatMovement.transisiSujudKeBersedekap,
          SholatMovement.transisiRukuKeIktidal,
        ],
      SholatMovementCategory.berdiri => [
          SholatMovement.takbiratulihram,
          SholatMovement.transisiDudukKeBersedekap,
          SholatMovement.transisiSujudKeBersedekap,
        ],
      SholatMovementCategory.ruku => [
          SholatMovement.transisiBersedekapKeRuku,
        ],
      SholatMovementCategory.iktidal => [
          SholatMovement.transisiRukuKeIktidal,
        ],
      SholatMovementCategory.qunut => [
          SholatMovement.transisiBerdiriKeQunut,
        ],
      SholatMovementCategory.sujud => [
          SholatMovement.transisiIktidalKeSujud,
          SholatMovement.transisiDudukKeSujud,
        ],
      SholatMovementCategory.duduk => [
          SholatMovement.transisiSujudKeDuduk,
        ],
      SholatMovementCategory.transisi => [
          SholatMovement.takbiratulihram,
          SholatMovement.bersedekap,
          SholatMovement.ruku,
          SholatMovement.iktidalBersedekap,
          SholatMovement.iktidalTanpaBersedekap,
          SholatMovement.qunut,
          SholatMovement.sujud,
          SholatMovement.dudukAntaraDuaSujud,
          SholatMovement.dudukIstirohah,
          SholatMovement.dudukTasyahudAwal,
          SholatMovement.dudukTasyahudAkhir,
        ],
    };
  }

  List<SholatMovement?> get nextMovement {
    return switch (this) {
      SholatMovementCategory.takbir => [
          SholatMovement.bersedekap,
          SholatMovement.iktidalBersedekap,
          SholatMovement.iktidalTanpaBersedekap,
        ],
      SholatMovementCategory.berdiri => [
          SholatMovement.transisiBersedekapKeRuku,
        ],
      SholatMovementCategory.ruku => [
          SholatMovement.transisiRukuKeIktidal,
        ],
      SholatMovementCategory.iktidal => [
          SholatMovement.transisiIktidalKeSujud,
        ],
      SholatMovementCategory.qunut => [
          SholatMovement.transisiQunutKeBerdiri,
        ],
      SholatMovementCategory.sujud => [
          SholatMovement.transisiSujudKeDuduk,
          SholatMovement.transisiSujudKeBersedekap,
        ],
      SholatMovementCategory.duduk => [
          null,
          SholatMovement.transisiDudukKeSujud,
          SholatMovement.transisiDudukKeBersedekap,
        ],
      SholatMovementCategory.transisi => [
          SholatMovement.bersedekap,
          SholatMovement.ruku,
          SholatMovement.iktidalBersedekap,
          SholatMovement.iktidalTanpaBersedekap,
          SholatMovement.qunut,
          SholatMovement.sujud,
          SholatMovement.dudukAntaraDuaSujud,
          SholatMovement.dudukIstirohah,
          SholatMovement.dudukTasyahudAwal,
          SholatMovement.dudukTasyahudAkhir,
        ],
    };
  }
}
