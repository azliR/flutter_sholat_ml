import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/dataset_info/dataset_info.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';

class PreprocessRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<(Failure?, List<Dataset>?)> readDatasets(String path) async {
    try {
      const datasetCsvPath = Paths.datasetCsv;

      final datasetStrList = await File('$path/$datasetCsvPath').readAsLines();
      final datasets = datasetStrList.map(Dataset.fromCsv).toList();
      return (null, datasets);
    } catch (e, stackTrace) {
      const message = 'Failed getting dataset file paths';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, DatasetInfo?)> readDatasetInfo(String path) async {
    try {
      const datasetInfoPath = Paths.datasetInfo;

      final datasetInfoFile = File('$path/$datasetInfoPath');
      if (datasetInfoFile.existsSync()) {
        final datasetInfoJson = jsonDecode(await datasetInfoFile.readAsString())
            as Map<String, dynamic>;
        final datasetInfo = DatasetInfo.fromJson(datasetInfoJson);
        return (null, datasetInfo);
      }
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed getting dataset file paths';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, String?, DatasetInfo?)> saveDataset(
    String path,
    List<Dataset> datasets, {
    bool isUpdating = false,
  }) async {
    try {
      final datasetStr = datasets.fold('', (previousValue, dataset) {
        return previousValue + dataset.toCsv();
      });

      const datasetCsvPath = Paths.datasetCsv;
      const datasetVideoPath = Paths.datasetVideo;
      const datasetInfoPath = Paths.datasetInfo;

      final csvFile = File('$path/$datasetCsvPath');
      await csvFile.writeAsString(datasetStr);

      final (failure, datasetUploadInfo) = await uploadDataset(
        dirName: path.split('/').last,
        csvFile: csvFile,
        videoFile: isUpdating ? null : File('$path/$datasetVideoPath'),
      );
      if (failure != null) return (failure, null, null);

      final datasetUploadFile = File('$path/$datasetInfoPath');
      await datasetUploadFile
          .writeAsString(jsonEncode(datasetUploadInfo!.toJson()));

      const needReviewDir = Directories.needReviewDir;
      const reviewedDir = Directories.reviewedDir;

      final fullNewDir =
          Directory(path.replaceFirst(needReviewDir, reviewedDir));

      if (!fullNewDir.existsSync()) {
        await fullNewDir.create(recursive: true);
      }

      await Directory(path).rename(fullNewDir.path);

      return (null, fullNewDir.path, datasetUploadInfo);
    } catch (e, stackTrace) {
      const message = 'Failed saving dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null, null);
    }
  }

  Future<(Failure?, DatasetInfo?)> uploadDataset({
    required String dirName,
    required File csvFile,
    File? videoFile,
  }) async {
    try {
      const datasetCsvPath = Paths.datasetCsv;
      const datasetVideoPath = Paths.datasetVideo;

      final ref = _storage.ref().child('datasets').child(dirName);
      await ref.child(datasetCsvPath).putFile(csvFile);
      if (videoFile != null) {
        await ref.child(datasetVideoPath).putFile(videoFile);
      }

      final datasetUploadInfo = DatasetInfo(
        dirName: dirName,
        csvUrl: await ref.child(datasetCsvPath).getDownloadURL(),
        videoUrl: await ref.child(datasetVideoPath).getDownloadURL(),
      );

      final (failure, _) =
          await saveDatasetToDatabase(dirName, datasetUploadInfo);
      if (failure != null) throw Exception(failure.message);

      return (null, datasetUploadInfo);
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
    DatasetInfo datasetInfo,
  ) async {
    try {
      final ref = _firestore.collection('datasets').doc(dirName);
      await ref.set(datasetInfo.toFirestoreJson());

      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed saving dataset to firestore';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> deleteDatasetFromCloud(String dirName) async {
    DatasetInfo? datasetInfo;
    try {
      final dbRef = _firestore.collection('datasets').doc(dirName);
      final data = (await dbRef.get()).data();
      if (data != null) {
        datasetInfo = DatasetInfo.fromFirestoreJson(data, dirName);
      }

      await dbRef.delete();

      final storageRef = _storage.ref().child('datasets').child(dirName);
      await storageRef.listAll().then((value) async {
        await Future.wait(value.items.map((e) => e.delete()));
      });

      return (null, null);
    } catch (e, stackTrace) {
      if (datasetInfo != null) {
        final (failure, _) = await saveDatasetToDatabase(dirName, datasetInfo);
        if (failure != null) return (failure, null);
      }
      const message = 'Failed deleting dataset from cloud';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
