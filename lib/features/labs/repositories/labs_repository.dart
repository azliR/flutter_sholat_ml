import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/utils/failures/failure.dart';
import 'package:flutter_sholat_ml/utils/services/local_ml_model_storage_service%20.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class LabsRepository {
  (Failure?, List<MlModel>?) getLocalMlModels(
    int start,
    int limit,
  ) {
    try {
      final mlModelProps =
          LocalMlModelStorageService.getMlModelRange(start, start + limit);

      return (null, mlModelProps);
    } catch (e, stackTrace) {
      const message = 'Failed getting local saved mlModels';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, String?)> pickModel() async {
    final filePicker = FilePicker.platform;
    try {
      await filePicker.clearTemporaryFiles();

      final pickedFile = await filePicker.pickFiles();
      if (pickedFile == null || pickedFile.files.isEmpty) {
        return (Failure('No file picked'), null);
      }

      final file = pickedFile.files.first;

      if (file.extension != 'onnx') {
        return (Failure('File must be onnx'), null);
      }

      final (failure, _) = await saveModel(tempPath: file.path!);
      if (failure != null) {
        return (failure, null);
      }

      return (null, file.path!);
    } catch (e, stackTrace) {
      const message = 'Failed picking model';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }

  Future<(Failure?, void)> saveModel({
    required String tempPath,
    String? name,
    String? description,
  }) async {
    final filePicker = FilePicker.platform;
    try {
      final now = DateTime.now();
      final modelId = const Uuid().v4();
      final modelExt = extension(tempPath);

      final dir = await getApplicationDocumentsDirectory();
      final baseOutputDir = dir.directory(Directories.savedMlModelDirPath);
      final outputDir = baseOutputDir.directory(modelId);
      final outputPath =
          setExtension(join(outputDir.path, Paths.mlModelName), modelExt);

      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      await File(tempPath).rename(outputPath).catchError((error, stackTrace) {
        return File(tempPath).copy(outputPath);
      });

      final mlModel = MlModel(
        id: modelId,
        name: name,
        path: outputPath,
        description: description,
        createdAt: now,
        updatedAt: now,
      );

      LocalMlModelStorageService.putMlModel(mlModel);

      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed picking model';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    } finally {
      await filePicker.clearTemporaryFiles();
    }
  }

  Future<(Failure?, void)> deleteMlModels(
    List<MlModel> mlModels, {
    bool skipWhenError = false,
  }) async {
    try {
      for (final mlModel in mlModels) {
        final dir = Directory(dirname(mlModel.path));
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
        LocalMlModelStorageService.deleteMlModel(mlModel.id);
      }
      return (null, null);
    } catch (e, stackTrace) {
      const message = 'Failed deleting mlModel';
      final failure = Failure(message, error: e, stackTrace: stackTrace);
      return (failure, null);
    }
  }
}
