import 'package:dartx/dartx_io.dart';

enum SholatNoiseMovement {
  menggaruk,
  menggarukDenganTanganLain,
  menahanRambut,
  menggantiPosisiDuduk,
  menarikPakaianSaatIktidal,
  menyelangJari,
  berdiriTidakStabil,
  mengayunkanTanganSaatIktidal;

  static SholatNoiseMovement? fromValue(String value) {
    return SholatNoiseMovement.values.firstOrNullWhere((e) => e.value == value);
  }

  String get name => switch (this) {
        SholatNoiseMovement.menggaruk => 'Menggaruk',
        SholatNoiseMovement.menggarukDenganTanganLain =>
          'Menggaruk Dengan Tangan Lain',
        SholatNoiseMovement.menahanRambut => 'Menahan Rambut',
        SholatNoiseMovement.menggantiPosisiDuduk => 'Mengganti Posisi Duduk',
        SholatNoiseMovement.menarikPakaianSaatIktidal =>
          'Menahan Pakaian Saat Iktidal',
        SholatNoiseMovement.menyelangJari => 'Menyelang Jari',
        SholatNoiseMovement.berdiriTidakStabil => 'Berdiri Tidak Stabil',
        SholatNoiseMovement.mengayunkanTanganSaatIktidal =>
          'Mengayunkan Tangan Saat Iktidal',
      };

  String get value => switch (this) {
        SholatNoiseMovement.menggaruk => 'menggaruk',
        SholatNoiseMovement.menggarukDenganTanganLain =>
          'menggaruk_dengan_tangan_lain',
        SholatNoiseMovement.menahanRambut => 'menahan_rambut',
        SholatNoiseMovement.menggantiPosisiDuduk => 'mengganti_posisi_duduk',
        SholatNoiseMovement.menarikPakaianSaatIktidal =>
          'menahan_pakaian_saat_iktidal',
        SholatNoiseMovement.menyelangJari => 'menyelang_jari',
        SholatNoiseMovement.berdiriTidakStabil => 'berdiri_tidak_stabil',
        SholatNoiseMovement.mengayunkanTanganSaatIktidal =>
          'mengayunkan_tangan_saat_iktidal',
      };

  bool get isDeprecated => false;
}
