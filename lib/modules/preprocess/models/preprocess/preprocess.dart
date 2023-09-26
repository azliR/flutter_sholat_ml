import 'package:flutter/foundation.dart';

@immutable
class Preprocess {
  const Preprocess({required this.csvPath, required this.videoPath});

  final String csvPath;
  final String videoPath;
}
