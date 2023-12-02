enum SholatNoiseMovement {
  menggaruk,
  menggarukDenganTanganLain,
  menahanRambut,
  menggantiPosisi,
  menahanPakaian,
  menyelangJari,
  berdiriTidakStabil;

  factory SholatNoiseMovement.fromValue(String value) {
    return SholatNoiseMovement.values.firstWhere((e) => e.value == value);
  }

  String get name => switch (this) {
        SholatNoiseMovement.menggaruk => 'Menggaruk',
        SholatNoiseMovement.menggarukDenganTanganLain =>
          'Menggaruk Dengan Tangan Lain',
        SholatNoiseMovement.menahanRambut => 'Menahan Rambut',
        SholatNoiseMovement.menggantiPosisi => 'Mengganti Posisi',
        SholatNoiseMovement.menahanPakaian => 'Menahan Pakaian',
        SholatNoiseMovement.menyelangJari => 'Menyelang Jari',
        SholatNoiseMovement.berdiriTidakStabil => 'Berdiri Tidak Stabil',
      };

  String? get value => switch (this) {
        SholatNoiseMovement.menggaruk => 'menggaruk',
        SholatNoiseMovement.menggarukDenganTanganLain =>
          'menggaruk_dengan_tangan_lain',
        SholatNoiseMovement.menahanRambut => 'menahan_rambut',
        SholatNoiseMovement.menggantiPosisi => 'mengganti_posisi',
        SholatNoiseMovement.menahanPakaian => 'menahan_pakaian',
        SholatNoiseMovement.menyelangJari => 'menyelang_jari',
        SholatNoiseMovement.berdiriTidakStabil => 'berdiri_tidak_stabil',
      };
}
