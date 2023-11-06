import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:flutter_sholat_ml/utils/services/local_dataset_storage_service.dart';
import 'package:get_thumbnail_video/index.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ImportDatasetStatus {
  canceled,
  unsupported,
  missingRequiredFiles,
  succeeded
}

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
            toFirestore: (value, options) => value.property.toFirestoreJson(),
          );

  (Failure?, List<Dataset>?) getLocalDatasets(
    int start,
    int end,
  ) {
    try {
      final datasetProps =
          LocalDatasetStorageService.getDatasetRange(start, end);
      final datasets = datasetProps.map((datasetProp) {
        return Dataset(
          downloaded: null,
          property: datasetProp,
        );
      }).toList();
      return (null, datasets);
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
          dir.directory(datasetDirPath).directory(dataset.property.id);

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

  Future<(Failure?, bool?)> getDatasetDownloadStatus({
    required String path,
  }) async {
    try {
      final fullDir = Directory(path);
      final datasetCsvFile = fullDir.file(Paths.datasetCsv);
      final datasetVideoFile = fullDir.file(Paths.datasetVideo);

      final downloaded =
          datasetCsvFile.existsSync() && datasetVideoFile.existsSync();

      return (null, downloaded);
    } catch (e, stackTrace) {
      const message = 'Failed getting saved datasets';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, StreamZip<TaskSnapshot>?)> downloadDataset(
    Dataset dataset, {
    bool forceDownload = false,
  }) async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final fullDir = baseDir
          .directory(Directories.reviewedDirPath)
          .directory(dataset.property.id);

      if (!fullDir.existsSync()) {
        await fullDir.create(recursive: true);
      }

      final datasetPropStr = jsonEncode(dataset.property.toJson());
      await fullDir.file(Paths.datasetProp).writeAsString(datasetPropStr);

      final streams = <Stream<TaskSnapshot>>[];

      final csvUrl = dataset.property.csvUrl;
      final csvFile = fullDir.file(Paths.datasetCsv);
      if (csvUrl != null && (!csvFile.existsSync() || forceDownload)) {
        final ref = _storage.refFromURL(csvUrl);
        final snapshotStream = ref.writeToFile(csvFile).snapshotEvents;
        streams.add(snapshotStream);
      }
      final videoUrl = dataset.property.videoUrl;
      final videoFile = fullDir.file(Paths.datasetVideo);
      if (videoUrl != null && (!videoFile.existsSync() || forceDownload)) {
        final ref = _storage.refFromURL(videoUrl);
        final snapshotStream = ref.writeToFile(videoFile).snapshotEvents;
        streams.add(snapshotStream);
      }
      final streamZip = StreamZip<TaskSnapshot>(streams);
      return (null, streamZip);
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
      LocalDatasetStorageService.deleteDataset(path);
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed deleting dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, Stream<double>?, String?)> exportDataset(
    String path,
  ) async {
    try {
      final streamController = StreamController<double>();

      final tempDir = await getTemporaryDirectory();
      final dir = Directory(path);

      final archivePath = tempDir.file('${dir.name}.shd').path;
      final archive = ZipFileEncoder()..create(archivePath);
      unawaited(
        archive.addDirectory(
          dir,
          onProgress: (value) {
            streamController.add(value);
            if (value >= 1) {
              archive.close();
              streamController.close();
            }
          },
        ),
      );
      return (
        null,
        streamController.stream,
        archivePath,
      );
    } catch (e, stackTrace) {
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
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result == null) {
        const message = 'Cancelled by user';
        final code = ImportDatasetStatus.canceled.name;
        final failure = Failure(message, code: code);
        return (failure, null);
      }
      final pickedFiles = result.files;
      if (pickedFiles.any((element) => element.extension != 'shd')) {
        const message = 'Unsupported file';
        final code = ImportDatasetStatus.unsupported.name;
        final failure = Failure(message, code: code);
        return (failure, null);
      }

      final dir = await getApplicationDocumentsDirectory();
      final outputDir = dir.directory(Directories.needReviewDirPath);

      for (final pickedFile in pickedFiles) {
        final futures = <Future<void>>[];
        final inputStream = InputFileStream(pickedFile.path!);
        final archive = ZipDecoder().decodeBuffer(inputStream);

        if (archive.files.isEmpty) {
          const message = 'Missing required files';
          final code = ImportDatasetStatus.missingRequiredFiles.name;
          final failure = Failure(message, code: code);
          return (failure, null);
        }
        final expandedFiles = archive.files.map((archiveFile) {
          if (archiveFile.isFile) {
            final file = File(archiveFile.name);
            print(file.dirName);
          }
        });
        print(expandedFiles);
        for (final archiveFile in archive.files) {
          if (archiveFile.isFile) {
            continue;
          }
          final archiveDir = outputDir.directory(archiveFile.name);
          final entities = await archiveDir.list().toList();
          final isContainsRequiredFiles = entities.all(
            (entity) => [
              Paths.datasetCsv,
              Paths.datasetProp,
              Paths.datasetVideo,
            ].contains(entity.name),
          );
          if (!isContainsRequiredFiles) {
            const message = 'Missing required files';
            final code = ImportDatasetStatus.missingRequiredFiles.name;
            final failure = Failure(message, code: code);
            return (failure, null);
          }

          for (final entity in entities) {
            if (![
              Paths.datasetCsv,
              Paths.datasetProp,
              Paths.datasetVideo,
              Paths.datasetThumbnail,
            ].contains(entity.name)) {
              continue;
            }
            final output = archiveDir.file(entity.name);
            final f = await output.create(recursive: true);
            final fp = await f.open(mode: FileMode.write);
            final bytes = archiveFile.content as List<int>;
            await fp.writeFrom(bytes);
            archiveFile.clear();
            futures.add(fp.close());
          }
        }
        futures.add(inputStream.close());

        if (futures.isNotEmpty) {
          await Future.wait(futures);
          futures.clear();
        }

        futures.add(archive.clear());

        if (futures.isNotEmpty) {
          await Future.wait(futures);
          futures.clear();
        }

        if (futures.isNotEmpty) {
          await Future.wait(futures);
          futures.clear();
        }
      }
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed importing dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
