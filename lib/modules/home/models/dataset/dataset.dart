import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_thumbnail.dart';

@immutable
class Dataset extends Equatable {
  const Dataset({
    required this.property,
    this.path,
    this.thumbnail,
  });

  final String? path;
  final DatasetThumbnail? thumbnail;
  final DatasetProp property;

  Dataset copyWith({
    String? path,
    DatasetThumbnail? thumbnail,
    DatasetProp? property,
  }) {
    return Dataset(
      path: path ?? this.path,
      thumbnail: thumbnail ?? this.thumbnail,
      property: property ?? this.property,
    );
  }

  @override
  List<Object?> get props => [
        path,
        thumbnail,
        property,
      ];
}
