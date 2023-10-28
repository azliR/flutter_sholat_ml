import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartx/dartx_io.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class HomeRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Query<Dataset> get reviewedDatasetsQuery =>
      _firestore.collection('datasets').withConverter(
        fromFirestore: (snapshot, options) {
          final property =
              DatasetProp.fromFirestoreJson(snapshot.data()!, snapshot.id);
          return Dataset(
            downloaded: null,
            property: property,
          );
        },
        toFirestore: (value, options) {
          return value.property.toFirestoreJson();
        },
      );

  Future<(Failure?, List<Dataset>?)> loadDatasetsFromDisk(
    String dirName,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fullDir = dir.directory(dirName);

      if (!fullDir.existsSync()) {
        await fullDir.create(recursive: true);
      }

      final entities = await fullDir.list().toList();
      final datasetPaths = entities.fold(<Dataset>[], (previous, entity) {
        final type = FileSystemEntity.typeSync(entity.path);

        if (type == FileSystemEntityType.directory) {
          final fullDir = Directory(entity.path);
          final datasetPropFile = fullDir.file(Paths.datasetProp);

          if (!datasetPropFile.existsSync()) return previous;

          final datasetProp = DatasetProp.fromJson(
            jsonDecode(datasetPropFile.readAsStringSync())
                as Map<String, dynamic>,
          );
          final dataset = Dataset(
            downloaded: true,
            path: entity.path,
            property: datasetProp,
          );
          return [...previous, dataset];
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

  Future<(Failure?, Dataset?)> loadDatasetFromDisk({
    required Dataset dataset,
    required bool isReviewedDataset,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final datasetDirPath = isReviewedDataset
          ? Directories.reviewedDirPath
          : Directories.needReviewDirPath;
      final fullDir =
          dir.directory(datasetDirPath).directory(dataset.property.dirName);

      if (!fullDir.existsSync()) {
        await fullDir.create(recursive: true);
      }

      final datasetCsvFile = fullDir.file(Paths.datasetCsv);
      final datasetVideoFile = fullDir.file(Paths.datasetVideo);

      final updatedDataset = dataset.copyWith(
        path: fullDir.path,
        downloaded:
            datasetCsvFile.existsSync() && datasetVideoFile.existsSync(),
      );

      return (null, updatedDataset);
    } catch (e, stackTrace) {
      const message = 'Failed getting saved datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, Stream<TaskSnapshot>?)> downloadDataset(
    Dataset dataset, {
    bool forceDownload = false,
  }) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final fullDir = baseDir
          .directory(Directories.reviewedDirPath)
          .directory(dataset.property.dirName);

      if (!fullDir.existsSync()) {
        await fullDir.create(recursive: true);
      }

      final datasetPropStr = jsonEncode(dataset.property.toJson());
      await fullDir.file(Paths.datasetProp).writeAsString(datasetPropStr);

      final streamGroup = StreamGroup<TaskSnapshot>();

      final csvUrl = dataset.property.csvUrl;
      final csvFile = fullDir.file(Paths.datasetCsv);
      if (csvUrl != null && (!csvFile.existsSync() || forceDownload)) {
        final ref = _storage.refFromURL(csvUrl);
        final snapshotStream = ref.writeToFile(csvFile).snapshotEvents;
        await streamGroup.add(snapshotStream);
      }
      final videoUrl = dataset.property.videoUrl;
      final videoFile = fullDir.file(Paths.datasetVideo);
      if (videoUrl != null && (!videoFile.existsSync() || forceDownload)) {
        final ref = _storage.refFromURL(videoUrl);
        final snapshotStream = ref.writeToFile(videoFile).snapshotEvents;
        await streamGroup.add(snapshotStream);
      }
      return (null, streamGroup.isIdle ? null : streamGroup.stream);
    } catch (e, stackTrace) {
      const message = 'Failed getting saved datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, String?)> getDatasetThumbnail(
    String path, {
    required Dataset dataset,
  }) async {
    try {
      final thumbnailFile = Directory(path).file(Paths.datasetThumbnail);
      if (thumbnailFile.existsSync()) {
        return (null, thumbnailFile.path);
      }
      final videoFile = Directory(path).file(Paths.datasetVideo);
      if (videoFile.existsSync()) {
        await VideoThumbnail.thumbnailFile(
          video: videoFile.path,
          thumbnailPath: thumbnailFile.path,
          imageFormat: ImageFormat.WEBP,
        );
      } else {
        final thumbnailUrl = dataset.property.thumbnailUrl;
        if (thumbnailUrl != null) {
          final ref = _storage.refFromURL(thumbnailUrl);
          await ref.writeToFile(thumbnailFile);
        }
      }

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
