import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';

enum SholatMovement {
  takbiratulihram,
  bersedekap,
  ruku,
  iktidalBersedekap,
  iktidalTanpaBersedekap,
  qunut,
  qunutMembalikkanTangan,
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
  transisiDudukKeBersedekap;

  factory SholatMovement.fromValue(String value) {
    return SholatMovement.values.firstWhere((e) => e.value == value);
  }

  static List<SholatMovement> getByCategory(SholatMovementCategory category) {
    switch (category) {
      case SholatMovementCategory.takbir:
        return [
          SholatMovement.takbiratulihram,
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
          SholatMovement.qunutMembalikkanTangan,
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
        ];
    }
  }

  String get name => switch (this) {
        SholatMovement.takbiratulihram => 'Takbiratulihram',
        SholatMovement.bersedekap => 'Bersedekap',
        SholatMovement.ruku => 'Ruku',
        SholatMovement.iktidalBersedekap => 'Iktidal Bersedekap',
        SholatMovement.iktidalTanpaBersedekap => 'Iktidal Tanpa Bersedekap',
        SholatMovement.qunut => 'Qunut',
        SholatMovement.qunutMembalikkanTangan => 'Qunut Membalikkan Tangan',
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
      };

  String get value => switch (this) {
        SholatMovement.takbiratulihram => 'takbiratulihram',
        SholatMovement.bersedekap => 'bersedekap',
        SholatMovement.ruku => 'ruku',
        SholatMovement.iktidalBersedekap => 'iktidal_bersedekap',
        SholatMovement.iktidalTanpaBersedekap => 'iktidal_tanpa_bersedekap',
        SholatMovement.qunut => 'qunut',
        SholatMovement.qunutMembalikkanTangan => 'qunut_membalikkan_tangan',
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
      };
}
