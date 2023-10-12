import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/dataset_prop/dataset_prop.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class HomeRepository {
  Future<(Failure?, List<String>?)> loadDatasetsFromDisk(String dirName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fullDir = Directory('${dir.path}/$dirName');
      if (!fullDir.existsSync()) {
        await fullDir.create(recursive: true);
      }
      final entities = await fullDir.list().toList();

      final datasetPaths = entities.fold(<String>[], (previous, entity) {
        final type = FileSystemEntity.typeSync(entity.path);

        if (type == FileSystemEntityType.directory) {
          return [...previous, entity.path];
        }
        return previous;
      }).toList();

      return (null, datasetPaths);
    } catch (e, stackTrace) {
      const message = 'Failed getting saved datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, DatasetProp?)> getDatasetProp(String path) async {
    try {
      final datasetPropFile = File('$path/${Paths.datasetProp}');
      if (!datasetPropFile.existsSync()) {
        return (null, null);
      }
      final datasetPropStr = await datasetPropFile.readAsString();
      final datasetPropJson = DatasetProp.fromJson(
        jsonDecode(datasetPropStr) as Map<String, dynamic>,
      );
      return (null, datasetPropJson);
    } catch (e, stackTrace) {
      const message = 'Failed getting saved datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, String?)> getDatasetThumbnail(String path) async {
    try {
      final thumbnailFile = File('$path/${Paths.datasetThumbnail}');
      if (thumbnailFile.existsSync()) {
        return (null, thumbnailFile.path);
      }
      await VideoThumbnail.thumbnailFile(
        video: '$path/${Paths.datasetVideo}',
        thumbnailPath: thumbnailFile.path,
        imageFormat: ImageFormat.WEBP,
      );
      return (null, thumbnailFile.path);
    } catch (e, stackTrace) {
      const message = 'Failed getting dataset thumbnail';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> deleteDataset(String path) async {
    try {
      final dir = Directory(path);
      await dir.delete(recursive: true);
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed deleting dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
