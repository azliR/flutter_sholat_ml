// import 'dart:async';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_sholat_ml/features/lab/blocs/lab/lab_notifier.dart';
// import 'package:flutter_sholat_ml/features/lab/models/ml_model_config/ml_model_config.dart';
// import 'package:flutter_sholat_ml/features/lab/views/lab_screen.dart';

// final labAsyncProvider =
//     AsyncNotifierProvider.autoDispose<LabAsyncNotifier, MlModelConfig>(
//   LabAsyncNotifier.new,
// );

// class LabAsyncNotifier extends AutoDisposeAsyncNotifier<LabState> {
//   @override
//   FutureOr<LabState> build() {
//     return LabScreen(path: path, device: device, services: services);
//   }
// }
