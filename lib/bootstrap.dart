import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/firebase_options.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset_prop.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
  };
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug,
  // );

  final dir = await getApplicationDocumentsDirectory();
  Hive.defaultDirectory = dir.path;
  Hive.registerAdapter<DatasetProp>(
    'DatasetProp',
    (json) => DatasetProp.fromJson(json as Map<String, dynamic>),
  );

  // final fullDir = dir.directory(Directories.needReviewDirPath);

  // if (!fullDir.existsSync()) {
  //   await fullDir.create(recursive: true);
  // }

  // final entities = await fullDir.list().toList();
  // final datasetPaths =
  //     entities.fold(<String, DatasetProp>{}, (previous, entity) {
  //   final type = FileSystemEntity.typeSync(entity.path);

  //   if (type != FileSystemEntityType.directory) return previous;

  //   final fullDir = Directory(entity.path);
  //   final datasetPropFile = fullDir.file(Paths.datasetProp);

  //   if (!datasetPropFile.existsSync()) return previous;

  //   final json =
  //       jsonDecode(datasetPropFile.readAsStringSync()) as Map<String, dynamic>;
  //   final datasetProp = DatasetProp.fromJson(json);
  //   return {
  //     ...previous,
  //     entity.name: datasetProp,
  //   };
  // });
  // log(jsonEncode(datasetPaths));
  // LocalDatasetStorageService.putAll(datasetPaths);

  runApp(
    ProviderScope(
      child: await builder(),
    ),
  );
}
