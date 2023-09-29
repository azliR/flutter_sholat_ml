import 'dart:async';
import 'dart:io';

import 'package:flutter_sholat_ml/constants/directories.dart';
import 'package:flutter_sholat_ml/utils/failures/bluetooth_error.dart';
import 'package:path_provider/path_provider.dart';

class HomeRepository {
  Future<(Failure?, List<String>?)> loadDatasetsFromDisk(String folder) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      const savedDir = Directories.savedDatasetDir;
      final fullDir = Directory('${dir.path}/$savedDir/$folder');
      if (!fullDir.existsSync()) {
        await fullDir.create(recursive: true);
      }
      final entities = await fullDir.list().toList();

      final datasetPaths = entities.fold(<String>[], (previous, entity) {
        final type = FileSystemEntity.typeSync(entity.path);

        if (type == FileSystemEntityType.directory) {
          return [...previous, entity.path];
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
