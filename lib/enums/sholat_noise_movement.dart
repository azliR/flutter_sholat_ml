enum SholatNoiseMovement {
  menggaruk,
  menahanRambut,
  menahanPakaian,
  menyelangJari,
  berdiriTidakStabil;

  factory SholatNoiseMovement.fromValue(String value) {
    return SholatNoiseMovement.values.firstWhere((e) => e.value == value);
  }

  String get name {
    switch (this) {
      case SholatNoiseMovement.menggaruk:
        return 'Menggaruk';
      case SholatNoiseMovement.menahanRambut:
        return 'Menahan Rambut';
      case SholatNoiseMovement.menahanPakaian:
        return 'Menahan Pakaian';
      case SholatNoiseMovement.menyelangJari:
        return 'Menyelang Jari';
      case SholatNoiseMovement.berdiriTidakStabil:
        return 'Berdiri Tidak Stabil';
    }
  }

  String? get value {
    switch (this) {
      case SholatNoiseMovement.menggaruk:
        return 'menggaruk';
      case SholatNoiseMovement.menahanRambut:
        return 'menahan_rambut';
      case SholatNoiseMovement.menahanPakaian:
        return 'menahan_pakaian';
      case SholatNoiseMovement.menyelangJari:
        return 'menyelang_jari';
      case SholatNoiseMovement.berdiriTidakStabil:
        return 'berdiri_tidak_stabil';
    }
  }
}
