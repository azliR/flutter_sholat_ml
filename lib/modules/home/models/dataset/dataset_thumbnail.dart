import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class DatasetThumbnail extends Equatable {
  const DatasetThumbnail({
    required this.dirName,
    required this.thumbnailPath,
    required this.error,
  });

  final String dirName;
  final String? thumbnailPath;
  final String? error;

  @override
  List<Object?> get props => [dirName, thumbnailPath, error];
}
