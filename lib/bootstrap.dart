import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset_prop.dart';
import 'package:flutter_sholat_ml/firebase_options.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stack_trace/stack_trace.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace:
          details.stack != null ? Trace.from(details.stack!) : details.stack,
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

  runApp(
    ProviderScope(
      child: await builder(),
    ),
  );
}
