import 'dart:async';
import 'dart:convert';
import 'dart:developer';
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
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ImportDatasetErrorCode { canceled, unsupported, missingRequiredFiles }

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
    required bool createDirIfNotExist,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final datasetDirPath = isReviewedDataset
          ? Directories.reviewedDirPath
          : Directories.needReviewDirPath;
      final fullDir =
          dir.directory(datasetDirPath).directory(dataset.property.id);

      if (createDirIfNotExist || !fullDir.existsSync()) {
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

  Future<(Failure?, Stream<TaskSnapshot>?)> downloadDataset(
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
      final streamGroup = StreamGroup.merge(streams);
      return (null, streamGroup);
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

  Future<(Failure?, void)> deleteDatasets(List<String> paths) async {
    try {
      for (final path in paths) {
        final dir = Directory(path);
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
        final result = LocalDatasetStorageService.deleteDataset(basename(path));
        if (!result) {
          return (Failure('Failed deleting dataset'), null);
        }
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
      final streams = <Stream<double>>[];
      final tempDir = await getTemporaryDirectory();

      final archivePath = tempDir.file('sholat-ml-dataset.shd').path;
      final output = OutputFileStream(archivePath);
      final encoder = ZipEncoder()..startEncode(output);

      for (final path in paths) {
        final streamController = StreamController<double>();
        streams.add(streamController.stream);

        final dir = Directory(path);
        final dirName = dir.name;
        final files = await dir.list(recursive: true).toList();
        var current = 0;
        final amount = files.length;

        for (final file in files) {
          final fileStat = file.statSync();
          var filename = relative(file.path, from: dir.path);
          filename = '$dirName/$filename';

          if (file is Directory) {
            final archiveFile = ArchiveFile('$filename/', 0, null)
              ..mode = fileStat.mode
              ..lastModTime = fileStat.modified.millisecondsSinceEpoch ~/ 1000
              ..isFile = false;
            encoder.addFile(archiveFile);
          } else if (file is File) {
            final fileStream = InputFileStream(file.path);
            final archiveFile =
                ArchiveFile.stream(filename, file.lengthSync(), fileStream)
                  ..lastModTime =
                      fileStat.modified.millisecondsSinceEpoch ~/ 1000
                  ..mode = fileStat.mode;

            encoder.addFile(archiveFile);
            await fileStream.close();
            streamController.add(++current / amount);
          }
        }
        unawaited(streamController.close());
      }
      encoder.endEncode();

      return (
        null,
        StreamGroup.merge(streams),
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
      final result = await FilePicker.platform.pickFiles();
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

      final inputStream = InputFileStream(pickedFile.path!);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      if (archive.files.isEmpty) {
        const message = 'Missing required files';
        const code = ImportDatasetErrorCode.missingRequiredFiles;
        final failure = Failure(message, code: code);
        return (failure, null);
      }

      final fileMap = <String, List<ArchiveFile>>{};

      for (final file in archive.files) {
        final parts = file.name.split('/');

        if (parts.length != 2) continue;

        final folderName = parts[0];
        final fileName = parts[1];

        if (extension(fileName).isEmpty || fileName.split('/').length > 1) {
          log('Skipping folder $fileName');
          continue;
        }

        fileMap[folderName] ??= [];
        fileMap[folderName]!.add(file);
      }

      bool containsFile(List<ArchiveFile> files, String fileName) {
        return files.any((file) => basename(file.name) == fileName);
      }

      for (final entry in fileMap.entries) {
        final isContainCsv = containsFile(entry.value, Paths.datasetCsv);
        final isContainVideo = containsFile(entry.value, Paths.datasetVideo);
        final isContainProp = containsFile(entry.value, Paths.datasetProp);

        if (!isContainCsv || !isContainVideo || !isContainProp) {
          const message = 'Missing required files';
          const code = ImportDatasetErrorCode.missingRequiredFiles;
          final failure = Failure(message, code: code);
          return (failure, null);
        }

        var datasetOutputDir = baseOutputDir.directory(entry.key);

        var i = 1;
        while (true) {
          if (!datasetOutputDir.existsSync()) break;

          datasetOutputDir = baseOutputDir.directory('${entry.key} ($i)');
          i++;
        }
        final datasetOutputDirName = basename(datasetOutputDir.path);
        late final DatasetProp datasetProp;
        for (final archiveFile in entry.value) {
          final filename = basename(archiveFile.name);
          if (![
            Paths.datasetCsv,
            Paths.datasetProp,
            Paths.datasetVideo,
            Paths.datasetThumbnail,
          ].contains(filename)) {
            continue;
          }
          final bytes = archiveFile.content as List<int>;
          final outputFile = datasetOutputDir.file(filename);
          final file = await outputFile.create(recursive: true);
          await file.writeAsBytes(bytes);
          archiveFile.clear();

          if (filename == Paths.datasetProp) {
            final datasetPropStr = utf8.decode(bytes);
            datasetProp = DatasetProp.fromJson(
              jsonDecode(datasetPropStr) as Map<String, dynamic>,
            ).copyWith(
              id: datasetOutputDirName,
            );
          }
        }
        LocalDatasetStorageService.putDataset(
          datasetOutputDirName,
          datasetProp,
        );
      }

      await archive.clear();

      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed importing dataset';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
