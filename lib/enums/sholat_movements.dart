import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';

enum SholatMovement {
  persiapan,
  takbiratulihram,
  berdiri,
  berdiriDariSujudTanpaDudukTanpaTakbir,
  berdiriDariSujudTanpaDudukDenganTakbir,
  berdiriDariSujudDenganDudukTanpaTakbir,
  berdiriDariSujudDenganDudukDenganTakbir,
  rukuTanpaTakbir,
  rukuDenganTakbir,
  iktidalTanpaBersedekap,
  iktidalBersedekap,
  qunut,
  qunutMembalikkanTangan,
  sujudDariBerdiri,
  sujudDariDuduk,
  dudukAntaraDuaSujud,
  dudukTasyahud,
  lainnya;

  factory SholatMovement.fromValue(String value) {
    return SholatMovement.values.firstWhere((e) => e.value == value);
  }

  static List<SholatMovement> getByCategory(SholatMovementCategory category) {
    switch (category) {
      case SholatMovementCategory.persiapan:
        return [
          SholatMovement.persiapan,
        ];
      case SholatMovementCategory.takbir:
        return [
          SholatMovement.takbiratulihram,
        ];
      case SholatMovementCategory.berdiri:
        return [
          SholatMovement.berdiri,
          SholatMovement.berdiriDariSujudTanpaDudukTanpaTakbir,
          SholatMovement.berdiriDariSujudTanpaDudukDenganTakbir,
          SholatMovement.berdiriDariSujudDenganDudukTanpaTakbir,
          SholatMovement.berdiriDariSujudDenganDudukDenganTakbir,
        ];
      case SholatMovementCategory.ruku:
        return [
          SholatMovement.rukuTanpaTakbir,
          SholatMovement.rukuDenganTakbir,
        ];
      case SholatMovementCategory.iktidal:
        return [
          SholatMovement.iktidalTanpaBersedekap,
          SholatMovement.iktidalBersedekap,
        ];
      case SholatMovementCategory.qunut:
        return [
          SholatMovement.qunut,
          SholatMovement.qunutMembalikkanTangan,
        ];
      case SholatMovementCategory.sujud:
        return [
          SholatMovement.sujudDariBerdiri,
          SholatMovement.sujudDariDuduk,
        ];
      case SholatMovementCategory.duduk:
        return [
          SholatMovement.dudukAntaraDuaSujud,
          SholatMovement.dudukTasyahud,
        ];
      case SholatMovementCategory.lainnya:
        return [
          SholatMovement.lainnya,
        ];
    }
  }

  String get name {
    switch (this) {
      case SholatMovement.persiapan:
        return 'Persiapan';
      case SholatMovement.takbiratulihram:
        return 'Takbiratul Ihram';
      case SholatMovement.berdiri:
        return 'Berdiri';
      case SholatMovement.berdiriDariSujudTanpaDudukTanpaTakbir:
        return 'Berdiri dari Sujud tanpa Duduk tanpa Takbir';
      case SholatMovement.berdiriDariSujudTanpaDudukDenganTakbir:
        return 'Berdiri dari Sujud tanpa Duduk dengan Takbir';
      case SholatMovement.berdiriDariSujudDenganDudukTanpaTakbir:
        return 'Berdiri dari Sujud dengan Duduk tanpa Takbir';
      case SholatMovement.berdiriDariSujudDenganDudukDenganTakbir:
        return 'Berdiri dari Sujud dengan Duduk dengan Takbir';
      case SholatMovement.rukuTanpaTakbir:
        return 'Ruku tanpa Takbir';
      case SholatMovement.rukuDenganTakbir:
        return 'Ruku dengan Takbir';
      case SholatMovement.iktidalTanpaBersedekap:
        return 'Iktidal tanpa Bersedekap';
      case SholatMovement.iktidalBersedekap:
        return 'Iktidal Bersedekap';
      case SholatMovement.qunut:
        return 'Qunut';
      case SholatMovement.qunutMembalikkanTangan:
        return 'Qunut Membalikkan Tangan';
      case SholatMovement.sujudDariBerdiri:
        return 'Sujud dari Berdiri';
      case SholatMovement.sujudDariDuduk:
        return 'Sujud dari Duduk';
      case SholatMovement.dudukAntaraDuaSujud:
        return 'Duduk antara dua Sujud';
      case SholatMovement.dudukTasyahud:
        return 'Duduk Tasyahud';
      case SholatMovement.lainnya:
        return 'Lainnya';
    }
  }

  String get value {
    switch (this) {
      case SholatMovement.persiapan:
        return 'persiapan';
      case SholatMovement.takbiratulihram:
        return 'takbiratulihram';
      case SholatMovement.berdiri:
        return 'berdiri';
      case SholatMovement.berdiriDariSujudTanpaDudukTanpaTakbir:
        return 'berdiri_dari_sujud_tanpa_duduk_tanpa_takbir';
      case SholatMovement.berdiriDariSujudTanpaDudukDenganTakbir:
        return 'berdiri_dari_sujud_tanpa_duduk_dengan_takbir';
      case SholatMovement.berdiriDariSujudDenganDudukTanpaTakbir:
        return 'berdiri_dari_sujud_dengan_duduk_tanpa_takbir';
      case SholatMovement.berdiriDariSujudDenganDudukDenganTakbir:
        return 'berdiri_dari_sujud_dengan_duduk_dengan_takbir';
      case SholatMovement.rukuTanpaTakbir:
        return 'ruku_tanpa_takbir';
      case SholatMovement.rukuDenganTakbir:
        return 'ruku_dengan_takbir';
      case SholatMovement.iktidalTanpaBersedekap:
        return 'iktidal_tanpa_bersedekap';
      case SholatMovement.iktidalBersedekap:
        return 'iktidal_bersedekap';
      case SholatMovement.qunut:
        return 'qunut';
      case SholatMovement.qunutMembalikkanTangan:
        return 'qunut_membalikkan_tangan';
      case SholatMovement.sujudDariBerdiri:
        return 'sujud_dari_berdiri';
      case SholatMovement.sujudDariDuduk:
        return 'sujud_dari_duduk';
      case SholatMovement.dudukAntaraDuaSujud:
        return 'duduk_antara_dua_sujud';
      case SholatMovement.dudukTasyahud:
        return 'dudu_tasyahud';
      case SholatMovement.lainnya:
        return 'lainnya';
    }
  }
}
