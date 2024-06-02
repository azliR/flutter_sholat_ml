import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';

enum SholatMovement {
  takbiratulihram,
  takbir,
  bersedekap,
  ruku,
  iktidalBersedekap,
  iktidalTanpaBersedekap,
  qunut,
  // qunutMembalikkanTangan,
  sujud,
  dudukAntaraDuaSujud,
  dudukIstirohah,
  dudukTasyahudAwal,
  dudukTasyahudAkhir,
  transisiBersedekapKeRuku,
  transisiRukuKeIktidal,
  transisiIktidalKeSujud,
  transisiSujudKeDuduk,
  transisiDudukKeSujud,
  transisiSujudKeBersedekap,
  transisiDudukKeBersedekap,
  transisiBerdiriKeQunut,
  transisiQunutKeBerdiri;

  factory SholatMovement.fromValue(String value) {
    return SholatMovement.values.firstWhere((e) => e.value == value);
  }

  static List<SholatMovement> getByCategory(SholatMovementCategory category) {
    switch (category) {
      case SholatMovementCategory.takbir:
        return [
          SholatMovement.takbiratulihram,
          SholatMovement.takbir,
        ];
      case SholatMovementCategory.berdiri:
        return [
          SholatMovement.bersedekap,
        ];
      case SholatMovementCategory.ruku:
        return [
          SholatMovement.ruku,
        ];
      case SholatMovementCategory.iktidal:
        return [
          SholatMovement.iktidalBersedekap,
          SholatMovement.iktidalTanpaBersedekap,
        ];
      case SholatMovementCategory.qunut:
        return [
          SholatMovement.qunut,
          // SholatMovement.qunutMembalikkanTangan,
        ];
      case SholatMovementCategory.sujud:
        return [
          SholatMovement.sujud,
        ];
      case SholatMovementCategory.duduk:
        return [
          SholatMovement.dudukAntaraDuaSujud,
          SholatMovement.dudukIstirohah,
          SholatMovement.dudukTasyahudAwal,
          SholatMovement.dudukTasyahudAkhir,
        ];
      case SholatMovementCategory.transisi:
        return [
          SholatMovement.transisiBersedekapKeRuku,
          SholatMovement.transisiRukuKeIktidal,
          SholatMovement.transisiIktidalKeSujud,
          SholatMovement.transisiSujudKeDuduk,
          SholatMovement.transisiDudukKeSujud,
          SholatMovement.transisiSujudKeBersedekap,
          SholatMovement.transisiDudukKeBersedekap,
          SholatMovement.transisiBerdiriKeQunut,
          SholatMovement.transisiQunutKeBerdiri,
        ];
    }
  }

  String get name => switch (this) {
        SholatMovement.takbiratulihram => 'Takbiratulihram',
        SholatMovement.takbir => 'Takbir',
        SholatMovement.bersedekap => 'Bersedekap',
        SholatMovement.ruku => 'Ruku',
        SholatMovement.iktidalBersedekap => 'Iktidal Bersedekap',
        SholatMovement.iktidalTanpaBersedekap => 'Iktidal Tanpa Bersedekap',
        SholatMovement.qunut => 'Qunut',
        // SholatMovement.qunutMembalikkanTangan => 'Qunut Membalikkan Tangan',
        SholatMovement.sujud => 'Sujud',
        SholatMovement.dudukAntaraDuaSujud => 'Duduk Antara Dua Sujud',
        SholatMovement.dudukIstirohah => 'Duduk Istirohah',
        SholatMovement.dudukTasyahudAwal => 'Duduk Tasyahud Awal',
        SholatMovement.dudukTasyahudAkhir => 'Duduk Tasyahud Akhir',
        SholatMovement.transisiBersedekapKeRuku =>
          'Transisi Bersedekap ke Ruku',
        SholatMovement.transisiRukuKeIktidal => 'Transisi Ruku ke Iktidal',
        SholatMovement.transisiIktidalKeSujud => 'Transisi Iktidal ke Sujud',
        SholatMovement.transisiSujudKeDuduk => 'Transisi Sujud ke Duduk',
        SholatMovement.transisiDudukKeSujud => 'Transisi Duduk ke Sujud',
        SholatMovement.transisiSujudKeBersedekap =>
          'Transisi Sujud ke Bersedekap',
        SholatMovement.transisiDudukKeBersedekap =>
          'Transisi Duduk ke Bersedekap',
        SholatMovement.transisiBerdiriKeQunut => 'Transisi Berdiri ke Qunut',
        SholatMovement.transisiQunutKeBerdiri => 'Transisi Qunut ke Berdiri',
      };

  String get value => switch (this) {
        SholatMovement.takbiratulihram => 'takbiratulihram',
        SholatMovement.takbir => 'takbir',
        SholatMovement.bersedekap => 'bersedekap',
        SholatMovement.ruku => 'ruku',
        SholatMovement.iktidalBersedekap => 'iktidal_bersedekap',
        SholatMovement.iktidalTanpaBersedekap => 'iktidal_tanpa_bersedekap',
        SholatMovement.qunut => 'qunut',
        // SholatMovement.qunutMembalikkanTangan => 'qunut_membalikkan_tangan',
        SholatMovement.sujud => 'sujud',
        SholatMovement.dudukAntaraDuaSujud => 'duduk_antara_dua_sujud',
        SholatMovement.dudukIstirohah => 'duduk_istirohah',
        SholatMovement.dudukTasyahudAwal => 'duduk_tasyahud_awal',
        SholatMovement.dudukTasyahudAkhir => 'duduk_tasyahud_akhir',
        SholatMovement.transisiBersedekapKeRuku =>
          'transisi_bersedekap_ke_ruku',
        SholatMovement.transisiRukuKeIktidal => 'transisi_ruku_ke_iktidal',
        SholatMovement.transisiIktidalKeSujud => 'transisi_iktidal_ke_sujud',
        SholatMovement.transisiSujudKeDuduk => 'transisi_sujud_ke_duduk',
        SholatMovement.transisiDudukKeSujud => 'transisi_duduk_ke_sujud',
        SholatMovement.transisiSujudKeBersedekap =>
          'transisi_sujud_ke_bersedekap',
        SholatMovement.transisiDudukKeBersedekap =>
          'transisi_duduk_ke_bersedekap',
        SholatMovement.transisiBerdiriKeQunut => 'transisi_berdiri_ke_qunut',
        SholatMovement.transisiQunutKeBerdiri => 'transisi_qunut_ke_berdiri',
      };

  bool get isDeprecated => [
        // SholatMovement.qunutMembalikkanTangan,
        SholatMovement.dudukIstirohah,
      ].contains(this);

  List<SholatMovement?> get previousMovement {
    return switch (this) {
      SholatMovement.takbiratulihram => [
          null,
        ],
      SholatMovement.takbir => [
          null,
          SholatMovement.bersedekap,
          SholatMovement.transisiRukuKeIktidal,
          SholatMovement.transisiDudukKeBersedekap,
          SholatMovement.transisiSujudKeBersedekap,
        ],
      SholatMovement.bersedekap => [
          null,
          SholatMovement.transisiDudukKeBersedekap,
          SholatMovement.transisiSujudKeBersedekap,
        ],
      SholatMovement.transisiBersedekapKeRuku => [
          null,
          SholatMovement.bersedekap,
        ],
      SholatMovement.ruku => [
          null,
          SholatMovement.transisiBersedekapKeRuku,
        ],
      SholatMovement.transisiRukuKeIktidal => [
          null,
          SholatMovement.ruku,
        ],
      SholatMovement.iktidalBersedekap ||
      SholatMovement.iktidalTanpaBersedekap =>
        [
          null,
          SholatMovement.takbir,
          SholatMovement.transisiRukuKeIktidal,
        ],
      SholatMovement.transisiBerdiriKeQunut => [
          null,
          SholatMovement.iktidalBersedekap,
          SholatMovement.iktidalTanpaBersedekap,
        ],
      SholatMovement.qunut => [
          null,
          SholatMovement.transisiBerdiriKeQunut,
        ],
      SholatMovement.transisiQunutKeBerdiri => [
          null,
          SholatMovement.qunut,
        ],
      SholatMovement.transisiIktidalKeSujud => [
          null,
          SholatMovement.iktidalBersedekap,
          SholatMovement.iktidalTanpaBersedekap,
        ],
      SholatMovement.sujud => [
          null,
          SholatMovement.transisiIktidalKeSujud,
          SholatMovement.transisiDudukKeSujud,
        ],
      SholatMovement.transisiSujudKeDuduk => [
          null,
          SholatMovement.sujud,
        ],
      SholatMovement.dudukAntaraDuaSujud ||
      SholatMovement.dudukIstirohah ||
      SholatMovement.dudukTasyahudAwal ||
      SholatMovement.dudukTasyahudAkhir =>
        [
          null,
          SholatMovement.transisiSujudKeDuduk,
        ],
      SholatMovement.transisiDudukKeSujud => [
          null,
          SholatMovement.dudukAntaraDuaSujud,
          SholatMovement.dudukTasyahudAwal,
        ],
      SholatMovement.transisiDudukKeBersedekap => [
          null,
          SholatMovement.dudukIstirohah,
          SholatMovement.dudukTasyahudAwal,
        ],
      SholatMovement.transisiSujudKeBersedekap => [
          null,
          SholatMovement.sujud,
        ],
    };
  }

  List<SholatMovement?> get nextMovement {
    return switch (this) {
      SholatMovement.takbiratulihram => [
          null,
          SholatMovement.bersedekap,
        ],
      SholatMovement.takbir => [
          null,
          SholatMovement.transisiBersedekapKeRuku,
          SholatMovement.iktidalBersedekap,
          SholatMovement.iktidalTanpaBersedekap,
        ],
      SholatMovement.bersedekap => [
          null,
          SholatMovement.takbir,
          SholatMovement.transisiBersedekapKeRuku,
        ],
      SholatMovement.transisiBersedekapKeRuku => [
          null,
          SholatMovement.ruku,
        ],
      SholatMovement.ruku => [
          null,
          SholatMovement.transisiRukuKeIktidal,
        ],
      SholatMovement.transisiRukuKeIktidal => [
          null,
          SholatMovement.takbir,
          SholatMovement.iktidalBersedekap,
          SholatMovement.iktidalTanpaBersedekap,
        ],
      SholatMovement.iktidalTanpaBersedekap ||
      SholatMovement.iktidalBersedekap =>
        [
          SholatMovement.transisiIktidalKeSujud,
          SholatMovement.transisiBerdiriKeQunut,
        ],
      SholatMovement.transisiBerdiriKeQunut => [
          null,
          SholatMovement.qunut,
        ],
      SholatMovement.qunut => [
          null,
          SholatMovement.transisiQunutKeBerdiri,
        ],
      SholatMovement.transisiQunutKeBerdiri => [
          null,
          SholatMovement.qunut,
        ],
      SholatMovement.transisiIktidalKeSujud => [
          null,
          SholatMovement.sujud,
        ],
      SholatMovement.sujud => [
          null,
          SholatMovement.transisiSujudKeDuduk,
          SholatMovement.transisiSujudKeBersedekap,
        ],
      SholatMovement.transisiSujudKeBersedekap => [
          null,
          SholatMovement.takbir,
          SholatMovement.bersedekap,
        ],
      SholatMovement.transisiSujudKeDuduk => [
          null,
          SholatMovement.dudukAntaraDuaSujud,
          SholatMovement.dudukIstirohah,
          SholatMovement.dudukTasyahudAwal,
          SholatMovement.dudukTasyahudAkhir,
        ],
      SholatMovement.dudukAntaraDuaSujud => [
          null,
          SholatMovement.transisiDudukKeSujud,
        ],
      SholatMovement.dudukIstirohah || SholatMovement.dudukTasyahudAwal => [
          null,
          SholatMovement.transisiDudukKeBersedekap,
        ],
      SholatMovement.dudukTasyahudAkhir => [
          null,
        ],
      // SholatMovement.qunutMembalikkanTangan => [
      //     null,
      //     SholatMovement.qunut,
      // ],
      SholatMovement.transisiDudukKeSujud => [
          null,
          SholatMovement.sujud,
        ],
      SholatMovement.transisiDudukKeBersedekap => [
          null,
          SholatMovement.takbir,
          SholatMovement.bersedekap,
        ],
    };
  }
}
