import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

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
import 'package:flutter_sholat_ml/features/datasets/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/features/preprocess/components/dataset_list_component.dart';
import 'package:flutter_sholat_ml/features/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_dataset_storage_service.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

class PreprocessRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  DownloadTask? _downloadTask;

  Future<(Failure?, List<DataItem>?)> readDataItems({
    required String path,
    required String? csvUrl,
  }) async {
    try {
      const datasetCsvPath = Paths.datasetCsv;
      const datasetPropPath = Paths.datasetProp;

      final datasetCsvFile = File('$path/$datasetCsvPath');
      if (!datasetCsvFile.existsSync()) {
        if (csvUrl == null) {
          return (Failure('Dataset not found'), null);
        }

        final ref = _storage.refFromURL(csvUrl);
        final snapshot = await ref.writeToFile(datasetCsvFile);

        if (snapshot.state != TaskState.success) {
          return (Failure('Failed to download dataset'), null);
        }
      }

      final datasetStrList = datasetCsvFile.readAsLinesSync();
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

  Future<(Failure?, Stream<TaskSnapshot>?)> downloadVideoDataset(
    DatasetProp datasetProp,
  ) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final fullDir = baseDir
          .directory(Directories.reviewedDirPath)
          .directory(datasetProp.id);

      if (!fullDir.existsSync()) {
        await fullDir.create(recursive: true);
      }

      final datasetPropStr = jsonEncode(datasetProp.toJson());
      await fullDir.file(Paths.datasetProp).writeAsString(datasetPropStr);

      final videoUrl = datasetProp.videoUrl;
      final videoFile = fullDir.file(Paths.datasetVideo);
      if (videoUrl != null && !videoFile.existsSync()) {
        final ref = _storage.refFromURL(videoUrl);

        _downloadTask = ref.writeToFile(videoFile);

        return (null, _downloadTask!.snapshotEvents);
      }
      return (null, const Stream<TaskSnapshot>.empty());
    } catch (e, stackTrace) {
      const message = 'Failed downloading video dataset!';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> cancelDownloadVideoDataset(String path) async {
    try {
      final success = await _downloadTask?.cancel() ?? false;
      if (!success) {
        return (Failure('Failed canceling download!'), null);
      }

      await Directory(path).file(Paths.datasetVideo).delete();

      return (null, success);
    } catch (e, stackTrace) {
      const message = 'Failed canceling download!';
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
              if (index == dataItems.length - 1) {
                return previous
                  ..last =
                      (prevStartIndex, index, prevLabel, prevLabelCategory);
              }
              return previous;
            }

            return previous
              ..last = (prevStartIndex, index - 1, prevLabel, prevLabelCategory)
              ..add(
                (
                  index,
                  index == dataItems.length - 1 ? index : null,
                  label,
                  labelCategory,
                ),
              );
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

            final prevLabelRecord = labelRecords.elementAtOrNull(index - 1);
            final nextLabelRecord = labelRecords.elementAtOrNull(index + 1);

            final prevLabel = prevLabelRecord?.$3;
            final prevLabelCategory = prevLabelRecord?.$4;
            final nextLabel = nextLabelRecord?.$3;
            final nextLabelCategory = nextLabelRecord?.$4;

            if (!label.previousMovements.contains(prevLabel)) {
              previous.add(
                WrongPreviousMovementSequenceProblem(
                  startIndex: startIndex,
                  endIndex: endIndex!,
                  label: label,
                  expectedLabels: label.previousMovements,
                ),
              );
            }
            if (!label.nextMovements.contains(nextLabel)) {
              previous.add(
                WrongNextMovementSequenceProblem(
                  startIndex: startIndex,
                  endIndex: endIndex!,
                  label: label,
                  expectedLabels: label.nextMovements,
                ),
              );
            }
            if (!labelCategory.previousMovementCategories
                .contains(prevLabelCategory)) {
              previous.add(
                WrongPreviousMovementCategorySequenceProblem(
                  startIndex: startIndex,
                  endIndex: endIndex!,
                  label: labelCategory,
                  expectedLabels: labelCategory.previousMovementCategories,
                ),
              );
            }
            if (!labelCategory.nextMovementCategories
                .contains(nextLabelCategory)) {
              previous.add(
                WrongNextMovementCategorySequenceProblem(
                  startIndex: startIndex,
                  endIndex: endIndex!,
                  label: labelCategory,
                  expectedLabels: labelCategory.nextMovementCategories,
                ),
              );
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
    required bool withVideo,
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
        withVideo: withVideo,
      );
      if (saveDatasetFailure != null) return (saveDatasetFailure, null, null);

      final (writeDatasetPropFailure, _) = await writeDatasetProp(
        datasetPath: path,
        datasetProp: updatedDatasetProp!,
      );
      if (writeDatasetPropFailure != null) {
        return (writeDatasetPropFailure, null, null);
      }

      if (path.contains(Directories.reviewedDirPath)) {
        return (null, path, updatedDatasetProp);
      }

      final dir = await getApplicationDocumentsDirectory();
      final fullNewDir =
          dir.directory(Directories.reviewedDirPath).directory(basename(path));
      final sourceDir = Directory(path);

      try {
        final files = sourceDir.listSync();
        if (files.isEmpty) {
          await sourceDir.rename(fullNewDir.path);
        } else {
          for (final file in files) {
            if (file is Directory) continue;

            await file.rename(join(fullNewDir.path, basename(file.path)));
          }
        }
      } on FileSystemException catch (_) {
        if (fullNewDir.existsSync()) {
          await fullNewDir.delete(recursive: true);
        }
        await sourceDir.copyRecursively(fullNewDir);
        await sourceDir.delete(recursive: true);
      }

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
    required bool withVideo,
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
        withVideo: withVideo,
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
    required bool forceReupload,
    required bool withVideo,
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
      if (forceReupload || (datasetProp.videoUrl == null && withVideo)) {
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
        videoUrl: await Future<String?>.value(
          datasetVideoRef.getDownloadURL(),
        ).catchError((Object? e) async {
          if (e is FirebaseException) {
            if (e.code == 'object-not-found') {
              return null;
            }
            throw e;
          }
          throw Exception(e);
        }),
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

  Future<(Failure?, List<List<List<num>>>?, List<String?>?)>
      createSegmentsAndLabels({
    required List<DataItem> dataItems,
    required int windowSize,
    required int windowStep,
  }) async {
    try {
      final (X, y) = await compute(
        (message) {
          final (dataItems, windowSize, windowStep) = message;
          final (data, labels) = dataItems.fold(
            (<List<num>>[], <String?>[]),
            (previousValue, dataItem) {
              final (data, labels) = previousValue;
              return (
                [
                  ...data,
                  [dataItem.x, dataItem.y, dataItem.z],
                ],
                [...labels, dataItem.labelCategory?.name],
              );
            },
          );

          final result = _segmentAndEncodeData(
            data,
            labels,
            windowSize,
            windowStep,
          );
          return result;
        },
        (dataItems, windowSize, windowStep),
      );
      return (null, X, y);
    } catch (e, stackTrace) {
      const message = 'Failed to extracting features';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null, null);
    }
  }

  List<List<List<num>>> _segmentData(
    List<List<num>> data,
    int windowSize,
    int windowStep,
  ) {
    final numSamples = (data.length - windowSize) ~/ windowStep + 1;
    final segments = List.generate(
      numSamples,
      (_) => List.filled(windowSize, <num>[0, 0, 0]),
      growable: false,
    );

    for (var i = 0; i < numSamples; i++) {
      final start = i * windowStep;
      final end = start + windowSize;
      segments[i] = data.sublist(start, end);
    }

    return segments;
  }

  String? _mode(List<String?> values) {
    final counts = <String?, int>{};
    for (final value in values) {
      counts[value] = (counts[value] ?? 0) + 1;
    }
    final maxCount = counts.values.reduce(math.max);
    return counts.keys.firstWhere((key) => counts[key] == maxCount);
  }

  List<num> _oneHotEncode(List<String?> labels, Map<String, int> encoder) {
    final encodedLabels = List<num>.filled(labels.length * encoder.length, 0);
    for (var i = 0; i < labels.length; i++) {
      final index = encoder[labels[i]];
      if (index != null) {
        encodedLabels[i * encoder.length + index] = 1.0;
      }
    }
    return encodedLabels;
  }

  (List<List<List<num>>>, List<String?>) _segmentAndEncodeData(
    List<List<num>> data,
    List<String?> labels,
    int windowSize,
    int windowStep,
  ) {
    final segments = _segmentData(data, windowSize, windowStep);
    final numSamples = segments.length;
    final labels = List<String?>.filled(numSamples, null);

    for (var i = 0; i < numSamples; i++) {
      final mode =
          _mode(segments[i].mapIndexed((index, _) => labels[index]).toList());
      labels[i] = mode;
    }

    // final oneHotLabels = _oneHotEncode(labels, oneHotEncoder);
    return (segments, labels);
  }

  Future<(Failure?, List<DataItemSection>?)> generateSections(
    List<DataItem> dataItems,
  ) async {
    try {
      final sections = await compute(
        (message) {
          final (dataItems,) = message;

          var currentIndex = 0;
          var lastIndex = 0;
          String? lastMovementSetId = '-1';

          return dataItems.fold(const <DataItemSection>[],
              (previousValue, dataItem) {
            if (lastMovementSetId != dataItem.movementSetId) {
              if (currentIndex != 0) {
                lastIndex += previousValue.last.dataItems.length;
              }

              currentIndex++;
              lastMovementSetId = dataItem.movementSetId;

              return [
                ...previousValue,
                DataItemSection(
                  startIndex: lastIndex,
                  movementSetId: dataItem.movementSetId,
                  labelCategory: dataItem.labelCategory,
                  dataItems: [dataItem],
                ),
              ];
            }
            currentIndex++;
            lastMovementSetId = dataItem.movementSetId;

            final lastSection = previousValue.last;
            return [
              ...previousValue
                ..[previousValue.lastIndex] = lastSection.copyWith(
                  dataItems: [...lastSection.dataItems, dataItem],
                ),
            ];
          });
        },
        (dataItems,),
      );
      return (null, sections);
    } catch (e, stackTrace) {
      const message = 'Failed to generating sections';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  double evaluateModel({
    required List<SholatMovementCategory?> categories,
    required List<SholatMovementCategory?> predictedCategories,
  }) {
    final accuracy = categories
            .zip<SholatMovementCategory?, bool>(
              predictedCategories,
              (a, b) => a == b,
            )
            .where((positive) => positive)
            .length /
        categories.length;
    return accuracy;
  }

  List<SholatMovementCategory?> removeDuplicates(
    List<SholatMovementCategory?> movements,
  ) {
    if (movements.isEmpty) return [];

    final result = <SholatMovementCategory?>[movements.first];
    for (var i = 1; i < movements.length; i++) {
      if (movements[i] != movements[i - 1]) {
        result.add(movements[i]);
      }
    }
    return result;
  }

  int levenshteinDistance(
    List<SholatMovementCategory?> a,
    List<SholatMovementCategory?> b,
  ) {
    final m = a.length;
    final n = b.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (var i = 1; i <= m; i++) {
      d[i][0] = i;
    }
    for (var j = 1; j <= n; j++) {
      d[0][j] = j;
    }

    for (var j = 1; j <= n; j++) {
      for (var i = 1; i <= m; i++) {
        if (a[i - 1] == b[j - 1]) {
          d[i][j] = d[i - 1][j - 1];
        } else {
          d[i][j] = math.min(
            d[i - 1][j] + 1, // Penghapusan
            math.min(
              d[i][j - 1] + 1, // Penyisipan
              d[i - 1][j - 1] + 1, // Substitusi
            ),
          );
        }
      }
    }

    return d[m][n];
  }

  double evaluateFluctuationRate({
    required List<SholatMovementCategory?> predictedCategories,
    required List<SholatMovementCategory?> labeledCategories,
  }) {
    final cleanedMovements = removeDuplicates(predictedCategories);
    final idealSequence = removeDuplicates(labeledCategories);

    final distance = levenshteinDistance(cleanedMovements, idealSequence);
    final fluctuationRate =
        distance / math.max(idealSequence.length, cleanedMovements.length);

    return fluctuationRate;
  }

  void setAutoSave({required bool enable}) {
    LocalStorageService.setPreprocessAutoSave(enable: enable);
  }

  bool? getAutoSave() {
    return LocalStorageService.getPreprocessAutoSave();
  }

  void setFollowHighlighted({required bool enable}) {
    LocalStorageService.setPreprocessFollowHighlighted(enable: enable);
  }

  bool? getFollowHighlighted() {
    return LocalStorageService.getPreprocessFollowHighlighted();
  }

  void setShowBottomPanel({required bool isShowBottomPanel}) {
    LocalStorageService.setPreprocessShowBottomPanel(
      enable: isShowBottomPanel,
    );
  }

  bool? getShowBottomPanel() {
    return LocalStorageService.getPreprocessShowBottomPanel();
  }
}
