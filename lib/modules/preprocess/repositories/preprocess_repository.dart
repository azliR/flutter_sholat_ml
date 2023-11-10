import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/enums/dataset_prop_version.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:flutter_sholat_ml/utils/services/local_dataset_storage_service.dart';

class PreprocessRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<(Failure?, List<DataItem>?)> readDataItems(String path) async {
    try {
      const datasetCsvPath = Paths.datasetCsv;
      const datasetPropPath = Paths.datasetProp;

      // log((await Directory(path).list().toList()).toString());

      final datasetStrList = await File('$path/$datasetCsvPath').readAsLines();
      final datasetPropFile = File('$path/$datasetPropPath');
      final dirName = path.split('/').last;

      final DatasetProp datasetProp;
      if (!datasetPropFile.existsSync()) {
        datasetProp = DatasetProp(
          id: dirName,
          hasEvaluated: false,
          datasetVersion: DatasetVersion.v1,
          createdAt: DateTime.tryParse(dirName) ?? DateTime.now(),
        );
        datasetPropFile.writeAsStringSync(jsonEncode(datasetProp.toJson()));
      } else {
        final datasetPropStr = await datasetPropFile.readAsString();
        datasetProp = DatasetProp.fromJson(
          jsonDecode(datasetPropStr) as Map<String, dynamic>,
        );
      }

      final (failure, datasets) = await _readDataItemsInIsolate(
        datasetStrList: datasetStrList,
        datasetProp: datasetProp,
      );
      if (failure != null) return (failure, null);

      return (null, datasets);
    } catch (e, stackTrace) {
      const message = 'Failed reading data items';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, List<DataItem>?)> _readDataItemsInIsolate({
    required List<String> datasetStrList,
    required DatasetProp datasetProp,
  }) async {
    try {
      final message = [datasetStrList, datasetProp];
      final datasets = await compute(
        (message) {
          final datasetStrList = message[0] as List<String>;
          final datasetProp = message[1] as DatasetProp;

          final datasets = datasetStrList
              .map(
                (datasetStr) => DataItem.fromCsv(
                  datasetStr,
                  version: datasetProp.datasetVersion,
                ),
              )
              .toList();
          return datasets;
        },
        message,
      );
      return (null, datasets);
    } catch (e, stackTrace) {
      const message = 'Failed reading data items in isolate';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, DatasetProp?)> readDatasetProp(String path) async {
    try {
      const datasetPropPath = Paths.datasetProp;

      final datasetPropFile = File('$path/$datasetPropPath');
      if (datasetPropFile.existsSync()) {
        final datasetPropJson = jsonDecode(await datasetPropFile.readAsString())
            as Map<String, dynamic>;
        final datasetProp = DatasetProp.fromJson(datasetPropJson);
        return (null, datasetProp);
      }
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed getting dataset file paths';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, String?, DatasetProp?)> saveDataset({
    required String path,
    required List<DataItem> dataItems,
    required DatasetProp datasetProp,
    required bool diskOnly,
  }) async {
    try {
      final datasetStr = await compute(
        (dataItems) {
          return dataItems.fold('', (previousValue, dataset) {
            return previousValue + dataset.toCsv();
          });
        },
        dataItems,
      );

      const datasetCsvPath = Paths.datasetCsv;
      const datasetVideoPath = Paths.datasetVideo;
      const datasetThumbnailPath = Paths.datasetThumbnail;
      const datasetPropPath = Paths.datasetProp;

      final csvFile = File('$path/$datasetCsvPath');
      await csvFile.writeAsString(datasetStr);

      if (diskOnly) return (null, path, datasetProp);

      final (failure, updatedDatasetProp) = await saveDatasetToDatabase(
        csvFile: csvFile,
        videoFile: File('$path/$datasetVideoPath'),
        thumbnailFile: File('$path/$datasetThumbnailPath'),
        datasetProp: datasetProp,
      );
      if (failure != null) return (failure, null, null);

      final datasetPropFile = File('$path/$datasetPropPath');
      await datasetPropFile
          .writeAsString(jsonEncode(updatedDatasetProp!.toJson()));

      final fullNewDir = Directory(
        path.replaceFirst(
          Directories.needReviewDirPath,
          Directories.reviewedDirPath,
        ),
      );

      if (!fullNewDir.existsSync()) {
        await fullNewDir.create(recursive: true);
      }

      await Directory(path).rename(fullNewDir.path);

      LocalDatasetStorageService.deleteDataset(path.split('/').last);

      return (null, fullNewDir.path, updatedDatasetProp);
    } catch (e, stackTrace) {
      const message = 'Failed saving dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null, null);
    }
  }

  Future<(Failure?, DatasetProp?)> saveDatasetToDatabase({
    required File csvFile,
    required File videoFile,
    required File thumbnailFile,
    required DatasetProp datasetProp,
  }) async {
    final ref = _firestore.collection('datasets');
    final docRef = ref.doc(datasetProp.isSubmitted ? datasetProp.id : null);
    try {
      final (failure, updatedDatasetProp) = await uploadDataset(
        datasetProp: datasetProp.copyWith(id: docRef.id),
        csvFile: csvFile,
        videoFile: videoFile,
        thumbnailFile: thumbnailFile,
      );
      if (failure != null) throw Exception(failure.message);

      await docRef.set(
        updatedDatasetProp!.toFirestoreJson(),
        SetOptions(merge: false),
      );

      return (null, updatedDatasetProp);
    } catch (e, stackTrace) {
      if (!datasetProp.isSubmitted) {
        log('Deleting uploaded dataset...');
        final (deleteFailure, _) = await deleteDatasetFromCloud(docRef.id);
        if (deleteFailure != null) return (deleteFailure, null);
      }
      const message = 'Failed saving dataset to firestore';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, DatasetProp?)> uploadDataset({
    required DatasetProp datasetProp,
    required File csvFile,
    required File videoFile,
    required File thumbnailFile,
  }) async {
    try {
      const datasetCsvPath = Paths.datasetCsv;
      const datasetVideoPath = Paths.datasetVideo;
      const datasetThumbnail = Paths.datasetThumbnail;

      final ref = _storage.ref().child('datasets').child(datasetProp.id);
      final datasetCsvRef = ref.child(datasetCsvPath);
      final datasetVideoRef = ref.child(datasetVideoPath);
      final datasetThumbnailRef = ref.child(datasetThumbnail);

      await datasetCsvRef.putFile(
        csvFile,
        SettableMetadata(
          contentType: 'text/csv',
          customMetadata: <String, String>{
            'version': DatasetVersion.values.last.value.toString(),
          },
        ),
      );
      if (datasetProp.isSubmitted || datasetProp.videoUrl == null) {
        await datasetVideoRef.putFile(
          videoFile,
          SettableMetadata(contentType: 'video/mp4'),
        );
      }
      if (datasetProp.isSubmitted || datasetProp.thumbnailUrl == null) {
        await datasetThumbnailRef.putFile(
          thumbnailFile,
          SettableMetadata(contentType: 'image/webp'),
        );
      }

      final updatedDatasetProp = datasetProp.copyWith(
        csvUrl: await datasetCsvRef.getDownloadURL(),
        videoUrl: await datasetVideoRef.getDownloadURL(),
        thumbnailUrl: await datasetThumbnailRef.getDownloadURL(),
        datasetVersion: DatasetVersion.values.last,
        datasetPropVersion: DatasetPropVersion.values.last,
      );

      return (null, updatedDatasetProp);
    } catch (e, stackTrace) {
      if (!datasetProp.isSubmitted) {
        log('Deleting uploaded dataset...');
        final (deleteFailure, _) = await deleteDatasetFromCloud(datasetProp.id);
        if (deleteFailure != null) return (deleteFailure, null);
      }

      const message = 'Failed saving dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> deleteDatasetFromCloud(String id) async {
    DatasetProp? datasetProp;
    final docRef = _firestore.collection('datasets').doc(id);
    try {
      final data = (await docRef.get()).data();
      if (data != null) {
        datasetProp = DatasetProp.fromFirestoreJson(data, id);
      }

      await docRef.delete();

      final storageRef = _storage.ref().child('datasets').child(id);
      await storageRef.listAll().then((value) async {
        await Future.wait(value.items.map((e) => e.delete()));
      });

      return (null, null);
    } catch (e, stackTrace) {
      if (datasetProp != null) {
        await docRef
            .set(datasetProp.toFirestoreJson())
            .catchError((error, stackTrace) {})
            .onError((error, stackTrace) {});
      }
      const message = 'Failed deleting dataset from cloud';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
