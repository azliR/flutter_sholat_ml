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

  factory SholatMovementCategory.fromCode(String code) {
    switch (code) {
      case 'persiapan':
        return SholatMovementCategory.persiapan;
      case 'takbir':
        return SholatMovementCategory.takbir;
      case 'berdiri':
        return SholatMovementCategory.berdiri;
      case 'ruku':
        return SholatMovementCategory.ruku;
      case 'iktidal':
        return SholatMovementCategory.iktidal;
      case 'qunut':
        return SholatMovementCategory.qunut;
      case 'sujud':
        return SholatMovementCategory.sujud;
      case 'duduk':
        return SholatMovementCategory.duduk;
      case 'lainnya':
        return SholatMovementCategory.lainnya;
      default:
        throw Exception('Unknown SholatMovementCategory code: $code');
    }
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

  String get code {
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

enum Persiapan {
  persiapan;

  String get name {
    switch (this) {
      case Persiapan.persiapan:
        return 'Persiapan';
    }
  }

  String get code {
    switch (this) {
      case Persiapan.persiapan:
        return 'persiapan';
    }
  }
}

enum Takbir {
  takbiratulihram;

  String get name {
    switch (this) {
      case Takbir.takbiratulihram:
        return 'Takbiratul Ihram';
    }
  }

  String get code {
    switch (this) {
      case Takbir.takbiratulihram:
        return 'takbiratulihram';
    }
  }
}

enum Berdiri {
  berdiri,
  berdiriDariSujudTanpaDudukTanpaTakbir,
  berdiriDariSujudTanpaDudukDenganTakbir,
  berdiriDariSujudDenganDudukTanpaTakbir,
  berdiriDariSujudDenganDudukDenganTakbir;

  String get name {
    switch (this) {
      case Berdiri.berdiri:
        return 'Berdiri';
      case Berdiri.berdiriDariSujudTanpaDudukTanpaTakbir:
        return 'Berdiri dari Sujud tanpa Duduk tanpa Takbir';
      case Berdiri.berdiriDariSujudTanpaDudukDenganTakbir:
        return 'Berdiri dari Sujud tanpa Duduk dengan Takbir';
      case Berdiri.berdiriDariSujudDenganDudukTanpaTakbir:
        return 'Berdiri dari Sujud dengan Duduk tanpa Takbir';
      case Berdiri.berdiriDariSujudDenganDudukDenganTakbir:
        return 'Berdiri dari Sujud dengan Duduk dengan Takbir';
    }
  }

  String get code {
    switch (this) {
      case Berdiri.berdiri:
        return 'berdiri';
      case Berdiri.berdiriDariSujudTanpaDudukTanpaTakbir:
        return 'berdiri_dari_sujud_tanpa_duduk_tanpa_takbir';
      case Berdiri.berdiriDariSujudTanpaDudukDenganTakbir:
        return 'berdiri_dari_sujud_tanpa_duduk_dengan_takbir';
      case Berdiri.berdiriDariSujudDenganDudukTanpaTakbir:
        return 'berdiri_dari_sujud_dengan_duduk_tanpa_takbir';
      case Berdiri.berdiriDariSujudDenganDudukDenganTakbir:
        return 'berdiri_dari_sujud_dengan_duduk_dengan_takbir';
    }
  }
}

enum Ruku {
  rukuTanpaTakbir,
  rukuDenganTakbir;

  String get name {
    switch (this) {
      case Ruku.rukuTanpaTakbir:
        return 'Ruku tanpa Takbir';
      case Ruku.rukuDenganTakbir:
        return 'Ruku dengan Takbir';
    }
  }

  String get code {
    switch (this) {
      case Ruku.rukuTanpaTakbir:
        return 'ruku_tanpa_takbir';
      case Ruku.rukuDenganTakbir:
        return 'ruku_dengan_takbir';
    }
  }
}

enum Iktidal {
  iktidalTanpaBersedekap,
  iktidalBersedekap;

  String get name {
    switch (this) {
      case Iktidal.iktidalTanpaBersedekap:
        return 'Iktidal tanpa Bersedekap';
      case Iktidal.iktidalBersedekap:
        return 'Iktidal Bersedekap';
    }
  }

  String get code {
    switch (this) {
      case Iktidal.iktidalTanpaBersedekap:
        return 'iktidal_tanpa_bersedekap';
      case Iktidal.iktidalBersedekap:
        return 'iktidal_bersedekap';
    }
  }
}

enum Qunut {
  qunut,
  qunutMembalikkanTangan;

  String get name {
    switch (this) {
      case Qunut.qunut:
        return 'Qunut';
      case Qunut.qunutMembalikkanTangan:
        return 'Qunut Membalikkan Tangan';
    }
  }

  String get code {
    switch (this) {
      case Qunut.qunut:
        return 'qunut';
      case Qunut.qunutMembalikkanTangan:
        return 'qunut_membalikkan_tangan';
    }
  }
}

enum Sujud {
  sujudDariBerdiri,
  sujudDariDuduk;

  String get name {
    switch (this) {
      case Sujud.sujudDariBerdiri:
        return 'Sujud dari Berdiri';
      case Sujud.sujudDariDuduk:
        return 'Sujud dari Duduk';
    }
  }

  String get code {
    switch (this) {
      case Sujud.sujudDariBerdiri:
        return 'sujud_dari_berdiri';
      case Sujud.sujudDariDuduk:
        return 'sujud_dari_duduk';
    }
  }
}

enum Duduk {
  dudukAntaraDuaSujud,
  dudukTasyahudAwal,
  dudukTasyahudAkhir;

  String get name {
    switch (this) {
      case Duduk.dudukAntaraDuaSujud:
        return 'Duduk antara dua Sujud';
      case Duduk.dudukTasyahudAwal:
        return 'Duduk Tasyahud Awal';
      case Duduk.dudukTasyahudAkhir:
        return 'Duduk Tasyahud Akhir';
    }
  }

  String get code {
    switch (this) {
      case Duduk.dudukAntaraDuaSujud:
        return 'duduk_antara_dua_sujud';
      case Duduk.dudukTasyahudAwal:
        return 'dudu_tasyahud_awal';
      case Duduk.dudukTasyahudAkhir:
        return 'duduk_tasyahud_akhir';
    }
  }
}

enum Lainnya {
  lainnya;

  String get name {
    switch (this) {
      case Lainnya.lainnya:
        return 'Lainnya';
    }
  }

  String get code {
    switch (this) {
      case Lainnya.lainnya:
        return 'lainnya';
    }
  }
}
