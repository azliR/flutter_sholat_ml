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
        ],
    };
  }

  List<SholatMovementCategory?> get nextMovementCategory {
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
        ],
    };
  }

  // List<SholatMovement?> get previousMovement {
  //   return switch (this) {
  //     SholatMovementCategory.takbir => [
  //         null,
  //         null,
  //         SholatMovement.transisiDudukKeBersedekap,
  //         SholatMovement.transisiSujudKeBersedekap,
  //         SholatMovement.transisiRukuKeIktidal,
  //       ],
  //     SholatMovementCategory.berdiri => [
  //         null,
  //         SholatMovement.takbiratulihram,
  //         SholatMovement.transisiDudukKeBersedekap,
  //         SholatMovement.transisiSujudKeBersedekap,
  //       ],
  //     SholatMovementCategory.ruku => [
  //         null,
  //         SholatMovement.transisiBersedekapKeRuku,
  //       ],
  //     SholatMovementCategory.iktidal => [
  //         null,
  //         SholatMovement.transisiRukuKeIktidal,
  //         SholatMovement.transisiQunutKeBerdiri,
  //       ],
  //     SholatMovementCategory.qunut => [
  //         null,
  //         SholatMovement.transisiBerdiriKeQunut,
  //       ],
  //     SholatMovementCategory.sujud => [
  //         null,
  //         SholatMovement.transisiIktidalKeSujud,
  //         SholatMovement.transisiDudukKeSujud,
  //       ],
  //     SholatMovementCategory.duduk => [
  //         null,
  //         SholatMovement.transisiSujudKeDuduk,
  //       ],
  //     SholatMovementCategory.transisi => [
  //         null,
  //         SholatMovement.takbiratulihram,
  //         SholatMovement.bersedekap,
  //         SholatMovement.ruku,
  //         SholatMovement.iktidalBersedekap,
  //         SholatMovement.iktidalTanpaBersedekap,
  //         SholatMovement.qunut,
  //         SholatMovement.sujud,
  //         SholatMovement.dudukAntaraDuaSujud,
  //         SholatMovement.dudukIstirohah,
  //         SholatMovement.dudukTasyahudAwal,
  //         SholatMovement.dudukTasyahudAkhir,
  //       ],
  //   };
  // }

  // List<SholatMovement?> get nextMovement {
  //   return switch (this) {
  //     SholatMovementCategory.takbir => [
  //         null,
  //         SholatMovement.bersedekap,
  //         SholatMovement.iktidalBersedekap,
  //         SholatMovement.iktidalTanpaBersedekap,
  //       ],
  //     SholatMovementCategory.berdiri => [
  //         null,
  //         SholatMovement.transisiBersedekapKeRuku,
  //       ],
  //     SholatMovementCategory.ruku => [
  //         null,
  //         SholatMovement.transisiRukuKeIktidal,
  //       ],
  //     SholatMovementCategory.iktidal => [
  //         null,
  //         SholatMovement.transisiIktidalKeSujud,
  //         SholatMovement.transisiBerdiriKeQunut,
  //       ],
  //     SholatMovementCategory.qunut => [
  //         null,
  //         SholatMovement.transisiQunutKeBerdiri,
  //       ],
  //     SholatMovementCategory.sujud => [
  //         null,
  //         SholatMovement.transisiSujudKeDuduk,
  //         SholatMovement.transisiSujudKeBersedekap,
  //       ],
  //     SholatMovementCategory.duduk => [
  //         null,
  //         null,
  //         SholatMovement.transisiDudukKeSujud,
  //         SholatMovement.transisiDudukKeBersedekap,
  //       ],
  //     SholatMovementCategory.transisi => [
  //         null,
  //         SholatMovement.bersedekap,
  //         SholatMovement.ruku,
  //         SholatMovement.iktidalBersedekap,
  //         SholatMovement.iktidalTanpaBersedekap,
  //         SholatMovement.qunut,
  //         SholatMovement.sujud,
  //         SholatMovement.dudukAntaraDuaSujud,
  //         SholatMovement.dudukIstirohah,
  //         SholatMovement.dudukTasyahudAwal,
  //         SholatMovement.dudukTasyahudAkhir,
  //       ],
  //   };
  // }
}
