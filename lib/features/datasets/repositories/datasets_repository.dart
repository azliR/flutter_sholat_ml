import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_dataset_storage_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tar/tar.dart';

enum ImportDatasetErrorCode { canceled, unsupported, missingRequiredFiles }

class DatasetsRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<(Failure?, List<Dataset>?)> getCloudDatasets(
    DateTime startAfter,
    int limit,
  ) async {
    try {
      final query = _firestore
          .collection('datasets')
          .orderBy('created_at', descending: true)
          .startAfter([startAfter])
          .limit(limit)
          .withConverter(
            fromFirestore: (snapshot, options) {
              final property =
                  DatasetProp.fromFirestoreJson(snapshot.data()!, snapshot.id);
              return Dataset(
                downloaded: null,
                property: property,
              );
            },
            toFirestore: (value, options) => value.property.toFirestoreJson(),
          );
      final snapshot = await query.get();
      final datasets = snapshot.docs.map((doc) => doc.data()).toList();
      final (failure, updatedDatasets) = await loadDatasetsFromDisk(
        datasets: datasets,
        isReviewedDataset: true,
        createIfNotExist: true,
      );
      if (failure != null) {
        return (failure, null);
      }

      return (null, updatedDatasets);
    } catch (e, stackTrace) {
      const message = 'Failed getting uploaded datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, List<Dataset>?)> getLocalDatasets(
    int start,
    int limit,
  ) async {
    try {
      final datasetProps =
          LocalDatasetStorageService.getDatasetRange(start, start + limit);
      final datasets = datasetProps
          .map(
            (datasetProp) => Dataset(
              downloaded: null,
              property: datasetProp,
            ),
          )
          .toList();
      final (failure, updatedDatasets) = await loadDatasetsFromDisk(
        datasets: datasets,
        isReviewedDataset: false,
        createIfNotExist: false,
      );
      if (failure != null) {
        return (null, datasets);
      }

      return (null, updatedDatasets);
    } catch (e, stackTrace) {
      const message = 'Failed getting local saved datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, List<Dataset>?)> loadDatasetsFromDisk({
    required List<Dataset> datasets,
    required bool isReviewedDataset,
    required bool createIfNotExist,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final datasetDirPath = isReviewedDataset
          ? Directories.reviewedDirPath
          : Directories.needReviewDirPath;

      final updatedDatasets = await Future.wait(
        datasets.map((dataset) async {
          final fullDir =
              dir.directory(datasetDirPath).directory(dataset.property.id);

          if (!fullDir.existsSync()) {
            fullDir.createSync(recursive: true);
          }

          final datasetCsvFile = fullDir.file(Paths.datasetCsv);
          final datasetVideoFile = fullDir.file(Paths.datasetVideo);
          final datasetPropFile = fullDir.file(Paths.datasetProp);

          if (createIfNotExist && !datasetPropFile.existsSync()) {
            await datasetPropFile
                .writeAsString(jsonEncode(dataset.property.toJson()));
          }

          final downloaded =
              datasetCsvFile.existsSync() && datasetVideoFile.existsSync();

          DatasetProp? datasetProp;
          if (datasetPropFile.existsSync()) {
            final datasetPropStr = datasetPropFile.readAsStringSync();
            final datasetPropMap =
                jsonDecode(datasetPropStr) as Map<String, dynamic>;
            datasetProp = DatasetProp.fromJson(datasetPropMap);
          }

          final updatedDataset = dataset.copyWith(
            path: fullDir.path,
            downloaded: downloaded,
            property: datasetProp,
          );
          return updatedDataset;
        }).toList(),
      );

      return (null, updatedDatasets);
    } catch (e, stackTrace) {
      const message = 'Failed getting saved datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  // Future<(Failure?, String?)> getDatasetThumbnail({
  //   required Dataset dataset,
  // }) async {
  //   try {
  //     final path = dataset.path;
  //     if (path == null) return (null, null);

  //     final thumbnailFile = Directory(path).file(Paths.datasetThumbnail);
  //     if (thumbnailFile.existsSync()) {
  //       return (null, thumbnailFile.path);
  //     }
  //     final videoFile = Directory(path).file(Paths.datasetVideo);
  //     if (videoFile.existsSync()) {
  //       await VideoThumbnail.thumbnailFile(
  //         video: videoFile.path,
  //         thumbnailPath: thumbnailFile.path,
  //         imageFormat: ImageFormat.WEBP,
  //       );
  //     } else {
  //       final thumbnailUrl = dataset.property.thumbnailUrl;
  //       if (thumbnailUrl != null) {
  //         final ref = _storage.refFromURL(thumbnailUrl);
  //         await ref.writeToFile(thumbnailFile);
  //       }
  //     }

  //     return (null, thumbnailFile.path);
  //   } catch (e, stackTrace) {
  //     const message = 'Failed getting dataset thumbnail';
  //     final failure = Failure(message, error: e, stackTrace: stackTrace);
  //     return (failure, null);
  //   }
  // }

  Future<(Failure?, Dataset?)> getDatasetStatus({
    required Dataset dataset,
  }) async {
    try {
      if (dataset.path == null) return (null, null);

      final fullDir = Directory(dataset.path!);
      final datasetCsvFile = fullDir.file(Paths.datasetCsv);
      final datasetVideoFile = fullDir.file(Paths.datasetVideo);

      if (!fullDir.existsSync()) return (null, null);

      final downloaded =
          datasetCsvFile.existsSync() && datasetVideoFile.existsSync();
      final updatedDataset = dataset.copyWith(downloaded: downloaded);

      return (null, updatedDataset);
    } catch (e, stackTrace) {
      const message = 'Failed getting saved datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> deleteDatasets(
    List<String> paths, {
    bool skipWhenError = false,
  }) async {
    try {
      for (final path in paths) {
        final dir = Directory(path);
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
        final fileName = basename(path);
        LocalDatasetStorageService.deleteDataset(fileName);
      }
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed deleting dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, Stream<double>?, String?)> exportDatasets(
    List<String> paths,
  ) async {
    try {
      final progressController = StreamController<double>();
      final tarEntriesController = StreamController<TarEntry>();

      final tempDir = await getTemporaryDirectory();

      const fileName = 'sholat-ml-dataset.shd';
      final archiveFile = tempDir.file(fileName);

      if (archiveFile.existsSync()) await archiveFile.delete();

      var totalSize = 0;

      for (final path in paths) {
        final dir = Directory(path);
        final dirName = dir.name;
        final files = await dir.list(recursive: true).toList();

        for (final entity in files) {
          if (entity is! File) continue;

          var fileName = relative(entity.path, from: dir.path);
          fileName = join(dirName, fileName);

          final fileStat = entity.statSync();

          tarEntriesController.add(
            TarEntry(
              TarHeader(
                name: fileName,
                mode: fileStat.mode,
                accessed: fileStat.accessed,
                modified: fileStat.modified,
                size: fileStat.size,
              ),
              entity.openRead(),
            ),
          );
          totalSize += fileStat.size;
        }
      }

      final tarEntries = tarEntriesController.stream;

      final output = archiveFile.openWrite();
      var processedSize = 0;
      unawaited(
        tarEntries
            .map((tarEntry) {
              processedSize += tarEntry.size;
              final progress = processedSize / totalSize;
              progressController.add(progress);
              return tarEntry;
            })
            // convert entries into a .tar stream
            .transform(tarWriter)
            // convert the .tar stream into a .tar.gz stream
            .transform(gzip.encoder)
            .handleError((Object error, StackTrace stackTrace) {
              const message = 'Failed compressing files';
              final failure =
                  Failure(message, error: error, stackTrace: stackTrace);
              progressController.addError(failure, stackTrace);
            })
            .pipe(output)
            .onError((error, stackTrace) {
              const message = 'Failed compressing files';
              final failure =
                  Failure(message, error: error, stackTrace: stackTrace);
              progressController.addError(failure, stackTrace);
            })
            .catchError((Object? error, Object? stackTrace) {
              final failure = Failure('Failed compressing files', error: error);
              progressController.addError(failure);
            })
            .whenComplete(() {
              progressController.close();
              output.close();
            }),
      );

      await tarEntriesController.close();

      return (
        null,
        progressController.stream,
        archiveFile.path,
      );
    } catch (e, stackTrace) {
      log('message');
      const message = 'Failed exporting dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null, null);
    }
  }

  Future<(Failure?, void)> shareDataset(List<String> paths) async {
    try {
      await Share.shareXFiles(paths.map(XFile.new).toList());
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed sharing dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> importDatasets() async {
    final filePicker = FilePicker.platform;
    try {
      await filePicker.clearTemporaryFiles();

      final result = await filePicker.pickFiles(allowCompression: false);

      if (result == null) {
        const message = 'Cancelled by user';
        const code = ImportDatasetErrorCode.canceled;
        final failure = Failure(message, code: code);
        return (failure, null);
      }
      final pickedFile = result.files.first;
      if (pickedFile.extension != 'shd') {
        const message = 'Unsupported file';
        const code = ImportDatasetErrorCode.unsupported;
        final failure = Failure(message, code: code);
        return (failure, null);
      }

      final dir = await getApplicationDocumentsDirectory();
      final baseOutputDir = dir.directory(Directories.needReviewDirPath);

      final inputStream = File(pickedFile.path!).openRead();

      final reader = TarReader(inputStream.transform(gzip.decoder));
      final fileMap = <String, List<File>>{};

      while (await reader.moveNext()) {
        final entry = reader.current;
        final header = entry.header;

        if (header.typeFlag != TypeFlag.reg) continue;

        final filePath = entry.header.name;
        if (![
          Paths.datasetCsv,
          Paths.datasetProp,
          Paths.datasetVideo,
          Paths.datasetThumbnail,
        ].contains(basename(filePath))) {
          continue;
        }

        final parts = split(normalize(filePath));

        if (parts.length != 2) continue;

        final dirName = parts[0];
        final fileName = parts[1];

        if (extension(fileName).isEmpty || fileName.split('/').length > 1) {
          log('Skipping folder $fileName');
          continue;
        }

        var outputDir = baseOutputDir.directory(dirName);
        var i = 1;
        while (!fileMap.containsKey(outputDir.name) && outputDir.existsSync()) {
          outputDir = baseOutputDir.directory('$dirName ($i)');
          i++;
        }
        final file = await outputDir.file(fileName).create(recursive: true);
        await entry.contents.pipe(file.openWrite());

        fileMap[basename(outputDir.name)] ??= [];
        fileMap[basename(outputDir.name)]!.add(file);
      }

      if (fileMap.isEmpty) {
        const message = 'Missing required files';
        const code = ImportDatasetErrorCode.missingRequiredFiles;
        final failure = Failure(message, code: code);
        return (failure, null);
      }

      for (final entry in fileMap.entries) {
        final isContainCsv = entry.value.any(
          (file) => basename(file.path) == Paths.datasetCsv,
        );
        final isContainVideo = entry.value.any(
          (file) => basename(file.path) == Paths.datasetVideo,
        );
        final isContainProp = entry.value.any(
          (file) => basename(file.path) == Paths.datasetProp,
        );

        if (!isContainCsv || !isContainVideo || !isContainProp) {
          await Directory(entry.key).delete(recursive: true);

          const message = 'Missing required files';
          const code = ImportDatasetErrorCode.missingRequiredFiles;
          final failure = Failure(message, code: code);
          return (failure, null);
        }

        final datasetOutputDirName = basename(entry.key);
        final datasetProp = await entry.value
            .firstWhere((file) => basename(file.path) == Paths.datasetProp)
            .readAsString()
            .then(
              (value) => DatasetProp.fromJson(
                jsonDecode(value) as Map<String, dynamic>,
              ).copyWith(id: datasetOutputDirName),
            );

        LocalDatasetStorageService.putDataset(datasetProp);
      }

      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed importing dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    } finally {
      await filePicker.clearTemporaryFiles();
    }
  }
}
