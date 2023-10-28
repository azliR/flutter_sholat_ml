import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/enums/dataset_prop_version.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

class PreprocessRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<(Failure?, List<DataItem>?)> readDatasets(String path) async {
    try {
      const datasetCsvPath = Paths.datasetCsv;
      const datasetPropPath = Paths.datasetProp;

      // log((await Directory(path).list().toList()).toString());

      final datasetStrList = await File('$path/$datasetCsvPath').readAsLines();
      final datasetPropFile = File('$path/$datasetPropPath');

      final DatasetProp datasetProp;
      if (!datasetPropFile.existsSync()) {
        datasetProp = DatasetProp(
          dirName: path.split('/').last,
          datasetVersion: DatasetVersion.v1,
          datasetPropVersion: DatasetPropVersion.values.last,
        );
        datasetPropFile.writeAsStringSync(jsonEncode(datasetProp.toJson()));
      } else {
        final datasetPropStr = await datasetPropFile.readAsString();
        datasetProp = DatasetProp.fromJson(
          jsonDecode(datasetPropStr) as Map<String, dynamic>,
        );
      }

      final datasets = datasetStrList
          .map(
            (datasetStr) => DataItem.fromCsv(
              datasetStr,
              version: datasetProp.datasetVersion,
            ),
          )
          .toList();

      return (null, datasets);
    } catch (e, stackTrace) {
      const message = 'Failed getting dataset file paths';
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

  Future<(Failure?, String?, DatasetProp?)> saveDataset(
    String path,
    List<DataItem> datasets, {
    bool isUpdating = false,
  }) async {
    try {
      final datasetStr = datasets.fold('', (previousValue, dataset) {
        return previousValue + dataset.toCsv();
      });

      const datasetCsvPath = Paths.datasetCsv;
      const datasetVideoPath = Paths.datasetVideo;
      const datasetThumbnailPath = Paths.datasetThumbnail;
      const datasetPropPath = Paths.datasetProp;

      final csvFile = File('$path/$datasetCsvPath');
      await csvFile.writeAsString(datasetStr);

      final (failure, datasetPropInfo) = await uploadDataset(
        dirName: path.split('/').last,
        csvFile: csvFile,
        videoFile: isUpdating ? null : File('$path/$datasetVideoPath'),
        thumbnailFile: isUpdating ? null : File('$path/$datasetThumbnailPath'),
      );
      if (failure != null) return (failure, null, null);

      final datasetPropFile = File('$path/$datasetPropPath');
      await datasetPropFile
          .writeAsString(jsonEncode(datasetPropInfo!.toJson()));

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

      return (null, fullNewDir.path, datasetPropInfo);
    } catch (e, stackTrace) {
      const message = 'Failed saving dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null, null);
    }
  }

  Future<(Failure?, DatasetProp?)> uploadDataset({
    required String dirName,
    required File csvFile,
    File? videoFile,
    File? thumbnailFile,
  }) async {
    try {
      const datasetCsvPath = Paths.datasetCsv;
      const datasetVideoPath = Paths.datasetVideo;
      const datasetThumbnail = Paths.datasetThumbnail;

      final ref = _storage.ref().child('datasets').child(dirName);
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
      if (videoFile != null) {
        await datasetVideoRef.putFile(
          videoFile,
          SettableMetadata(contentType: 'video/mp4'),
        );
      }
      if (thumbnailFile != null) {
        await datasetThumbnailRef.putFile(
          thumbnailFile,
          SettableMetadata(contentType: 'image/webp'),
        );
      }

      final datasetPropInfo = DatasetProp(
        dirName: dirName,
        csvUrl: await datasetCsvRef.getDownloadURL(),
        videoUrl: await datasetVideoRef.getDownloadURL(),
        thumbnailUrl: await datasetThumbnailRef.getDownloadURL(),
        datasetVersion: DatasetVersion.values.last,
        datasetPropVersion: DatasetPropVersion.values.last,
      );

      final (failure, _) =
          await saveDatasetToDatabase(dirName, datasetPropInfo);
      if (failure != null) throw Exception(failure.message);

      return (null, datasetPropInfo);
    } catch (e, stackTrace) {
      final (deleteFailure, _) = await deleteDatasetFromCloud(dirName);
      if (deleteFailure != null) return (deleteFailure, null);

      const message = 'Failed saving dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> saveDatasetToDatabase(
    String dirName,
    DatasetProp datasetProp,
  ) async {
    try {
      final ref = _firestore.collection('datasets').doc(dirName);
      await ref.set(datasetProp.toFirestoreJson());

      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed saving dataset to firestore';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> deleteDatasetFromCloud(String dirName) async {
    DatasetProp? datasetProp;
    try {
      final dbRef = _firestore.collection('datasets').doc(dirName);
      final data = (await dbRef.get()).data();
      if (data != null) {
        datasetProp = DatasetProp.fromFirestoreJson(data, dirName);
      }

      await dbRef.delete();

      final storageRef = _storage.ref().child('datasets').child(dirName);
      await storageRef.listAll().then((value) async {
        await Future.wait(value.items.map((e) => e.delete()));
      });

      return (null, null);
    } catch (e, stackTrace) {
      if (datasetProp != null) {
        final (failure, _) = await saveDatasetToDatabase(dirName, datasetProp);
        if (failure != null) return (failure, null);
      }
      const message = 'Failed deleting dataset from cloud';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
