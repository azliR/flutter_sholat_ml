import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset_thumbnail.dart';

@immutable
class Dataset extends Equatable {
  const Dataset({
    required this.downloaded,
    required this.property,
    this.path,
    this.thumbnail,
  });

  final String? path;
  final bool? downloaded;
  final DatasetThumbnail? thumbnail;
  final DatasetProp property;

  Dataset copyWith({
    String? path,
    bool? downloaded,
    DatasetThumbnail? thumbnail,
    DatasetProp? property,
  }) {
    return Dataset(
      path: path ?? this.path,
      downloaded: downloaded ?? this.downloaded,
      thumbnail: thumbnail ?? this.thumbnail,
      property: property ?? this.property,
    );
  }

  @override
  List<Object?> get props => [
        path,
        downloaded,
        thumbnail,
        property,
      ];
}
