import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartx/dartx_io.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/enums/dataset_prop_version.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';
import 'package:flutter_sholat_ml/enums/device_location.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/modules/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_dataset_storage_service.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

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
          isSyncedWithCloud: false,
          isCompressed: false,
          hasEvaluated: false,
          deviceLocation: DeviceLocation.leftWrist,
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
      final message = (datasetStrList, datasetProp);
      final datasets = await compute(
        (message) {
          final datasetStrList = message.$1;
          final datasetProp = message.$2;

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

  Future<(Failure?, List<Problem>?)> analyseDataset(
    List<DataItem> dataItems,
  ) async {
    try {
      final problems = await compute(
        (dataItems) {
          int? lastLabeledIndex;

          final labelRecords = dataItems.indexed
              .fold(<(int, int?, SholatMovement?, SholatMovementCategory?)>[],
                  (previous, record) {
            final (index, dataItem) = record;

            final label = dataItem.label;
            final labelCategory = dataItem.labelCategory;

            if (dataItem.isLabeled) lastLabeledIndex = index;

            if (previous.lastOrNull == null) {
              return previous..add((index, null, label, labelCategory));
            }

            final (prevStartIndex, _, prevLabel, prevLabelCategory) =
                previous.last;

            if (prevLabel == label) {
              return previous;
            }

            return previous
              ..last = (prevStartIndex, index - 1, prevLabel, prevLabelCategory)
              ..add((index, null, label, labelCategory));
          });

          final problems =
              labelRecords.indexed.fold(<Problem>[], (previous, record) {
            final index = record.$1;
            final (startIndex, endIndex, label, labelCategory) = record.$2;

            if (label == null || labelCategory == null) {
              if (lastLabeledIndex == null ||
                  startIndex > lastLabeledIndex! ||
                  startIndex == 0) {
                return previous;
              }
              previous.add(
                MissingLabelProblem(
                  startIndex: startIndex,
                  endIndex: endIndex!,
                ),
              );
              return previous;
            }

            if (label.isDeprecated) {
              previous.add(
                DeprecatedLabelProblem(
                  startIndex: startIndex,
                  endIndex: endIndex!,
                  label: label,
                ),
              );
            }

            if (labelCategory.isDeprecated) {
              previous.add(
                DeprecatedLabelCategoryProblem(
                  startIndex: startIndex,
                  endIndex: endIndex!,
                  labelCategory: labelCategory,
                ),
              );
            }

            if (labelCategory == SholatMovementCategory.qunut) {
              final prevLabelRecord = labelRecords.elementAtOrNull(index - 1);
              final nextLabelRecord = labelRecords.elementAtOrNull(index + 1);

              final prevLabel = prevLabelRecord?.$3;
              final nextLabel = nextLabelRecord?.$3;

              if (prevLabel != SholatMovement.transisiBerdiriKeQunut ||
                  nextLabel != SholatMovement.transisiQunutKeBerdiri) {
                previous.add(
                  WrongMovementSequenceProblem(
                    startIndex: startIndex,
                    endIndex: endIndex!,
                    label: label,
                    expectedPreviousLabels: [
                      SholatMovement.transisiBerdiriKeQunut,
                    ],
                    expectedNextLabels: [
                      SholatMovement.transisiQunutKeBerdiri,
                    ],
                  ),
                );
              }
            }
            return previous;
          });

          return problems;
        },
        dataItems,
      );
      return (null, problems);
    } catch (e, stackTrace) {
      const message = 'Failed validating dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> compressVideo({
    required String path,
  }) async {
    try {
      final tempDir = await getApplicationCacheDirectory();

      final videoFile = File(path);
      final tempVideo =
          await videoFile.copy(tempDir.file(Paths.datasetVideo).path);

      final result = await VideoCompress.compressVideo(
        tempVideo.path,
        deleteOrigin: true,
        includeAudio: true,
        quality: VideoQuality.MediumQuality,
      );
      if (result == null) {
        return (Failure('Failed compressing video'), null);
      }
      await result.file?.rename(path);
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed compressing video';
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

      final csvFile = File('$path/$datasetCsvPath');
      await csvFile.writeAsString(datasetStr);

      if (diskOnly) {
        final updatedDatasetProp = datasetProp.copyWith(
          isSyncedWithCloud: false,
          datasetPropVersion: DatasetPropVersion.values.last,
          datasetVersion: DatasetVersion.values.last,
        );
        final (writeDatasetPropFailure, _) = await writeDatasetProp(
          datasetPath: path,
          datasetProp: updatedDatasetProp,
        );
        if (writeDatasetPropFailure != null) {
          return (writeDatasetPropFailure, null, null);
        }

        return (null, path, updatedDatasetProp);
      }

      final (saveDatasetFailure, updatedDatasetProp) =
          await _saveDatasetToDatabase(
        csvFile: csvFile,
        videoFile: File('$path/$datasetVideoPath'),
        thumbnailFile: File('$path/$datasetThumbnailPath'),
        datasetProp: datasetProp,
      );
      if (saveDatasetFailure != null) return (saveDatasetFailure, null, null);

      final (writeDatasetPropFailure, _) = await writeDatasetProp(
        datasetPath: path,
        datasetProp: updatedDatasetProp!,
      );
      if (writeDatasetPropFailure != null) {
        return (writeDatasetPropFailure, null, null);
      }

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

      LocalDatasetStorageService.deleteDataset(basename(path));

      return (null, fullNewDir.path, updatedDatasetProp);
    } catch (e, stackTrace) {
      const message = 'Failed saving dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null, null);
    }
  }

  Future<(Failure?, DatasetProp?)> writeDatasetProp({
    required String datasetPath,
    required DatasetProp datasetProp,
  }) async {
    try {
      final updatedDatasetProp = datasetProp.copyWith(
        datasetPropVersion: DatasetPropVersion.values.last,
      );

      const datasetPropPath = Paths.datasetProp;

      final datasetPropFile = File('$datasetPath/$datasetPropPath');
      await datasetPropFile
          .writeAsString(jsonEncode(updatedDatasetProp.toJson()));

      if (!datasetProp.isUploaded) {
        LocalDatasetStorageService.putDataset(updatedDatasetProp);
      }

      return (null, updatedDatasetProp);
    } catch (e, stackTrace) {
      const message = 'Failed writing dataset prop to disk';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, DatasetProp?)> _saveDatasetToDatabase({
    required File csvFile,
    required File videoFile,
    required File thumbnailFile,
    required DatasetProp datasetProp,
  }) async {
    final ref = _firestore.collection('datasets');
    final docRef = ref.doc(datasetProp.isUploaded ? datasetProp.id : null);
    try {
      final bool forceReupload;
      if (datasetProp.isUploaded) {
        final doc = await docRef.get();
        final oldDatasetProp =
            DatasetProp.fromFirestoreJson(doc.data()!, datasetProp.id);
        if (oldDatasetProp.isCompressed != datasetProp.isCompressed) {
          forceReupload = true;
        } else {
          forceReupload = false;
        }
      } else {
        forceReupload = false;
      }

      final (failure, updatedDatasetProp) = await _uploadDataset(
        datasetProp: datasetProp.copyWith(id: docRef.id),
        csvFile: csvFile,
        videoFile: videoFile,
        thumbnailFile: thumbnailFile,
        forceReupload: forceReupload,
      );
      if (failure != null) throw Exception(failure.message);

      await docRef.set(
        updatedDatasetProp!.toFirestoreJson(),
        SetOptions(merge: false),
      );

      return (null, updatedDatasetProp);
    } catch (e, stackTrace) {
      if (!datasetProp.isUploaded) {
        log('Deleting uploaded dataset...');
        final (deleteFailure, _) = await deleteDatasetFromCloud(docRef.id);
        if (deleteFailure != null) return (deleteFailure, null);
      }
      const message = 'Failed saving dataset to firestore';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, DatasetProp?)> _uploadDataset({
    required DatasetProp datasetProp,
    required File csvFile,
    required File videoFile,
    required File thumbnailFile,
    bool forceReupload = false,
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
      if (forceReupload || datasetProp.videoUrl == null) {
        await datasetVideoRef.putFile(
          videoFile,
          SettableMetadata(contentType: 'video/mp4'),
        );
      }
      if (forceReupload || datasetProp.thumbnailUrl == null) {
        await datasetThumbnailRef.putFile(
          thumbnailFile,
          SettableMetadata(contentType: 'image/webp'),
        );
      }

      final updatedDatasetProp = datasetProp.copyWith(
        csvUrl: await datasetCsvRef.getDownloadURL(),
        videoUrl: await datasetVideoRef.getDownloadURL(),
        thumbnailUrl: await datasetThumbnailRef.getDownloadURL(),
        isSyncedWithCloud: true,
        datasetVersion: DatasetVersion.values.last,
        datasetPropVersion: DatasetPropVersion.values.last,
      );

      return (null, updatedDatasetProp);
    } catch (e, stackTrace) {
      if (!datasetProp.isUploaded) {
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

  void setAutoSave({required bool enable}) {
    LocalStorageService.setAutoSave(enable: enable);
  }

  bool? getAutoSave() {
    return LocalStorageService.getAutoSave();
  }

  void setFollowHighlighted({required bool enable}) {
    LocalStorageService.setFollowHighlighted(enable: enable);
  }

  bool? getFollowHighlighted() {
    return LocalStorageService.getFollowHighlighted();
  }

  void setShowBottomPanel({required bool isShowBottomPanel}) {
    LocalStorageService.setShowBottomPanel(
      enable: isShowBottomPanel,
    );
  }

  bool? getShowBottomPanel() {
    return LocalStorageService.getShowBottomPanel();
  }
}
