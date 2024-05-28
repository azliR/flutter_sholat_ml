import 'package:flutter_sholat_ml/features/preprocess/models/problem.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dataset_provider.g.dart';

@riverpod
Future<List<Problem>> analyseDataset(AnalyseDatasetRef ref) async {
  final preprocessRepository = PreprocessRepository();

  final dataItems =
      ref.watch(preprocessProvider.select((value) => value.dataItems));

  final (failure, problems) =
      await preprocessRepository.analyseDataset(dataItems);
  if (failure != null) {
    throw Exception(failure.message);
  }

  return problems!;
}

@riverpod
class EnablePredictedPreview extends _$EnablePredictedPreview {
  @override
  bool build() => false;

  void setEnable(bool enable) {
    if (enable) {
      ref.read(preprocessProvider.notifier).clearSelectedDataItems();
    }

    state = enable;
  }
}

// @riverpod
// class DatasetNotifier extends _$DatasetNotifier {
//   final _preprocessRepository = PreprocessRepository();

//   @override
//   Future<void> build() async {}

//   Future<void> save({
//     required String path,
//     required List<DataItem> dataItems,
//     required DatasetProp datasetProp,
//     bool diskOnly = false,
//     bool withVideo = true,
//     bool autoSaving = false,
//   }) async {
//     if (!autoSaving) {
//       state = const AsyncLoading();
//     }

//     final (failure, newPath, updatedDatasetProp) =
//         await _preprocessRepository.saveDataset(
//       path: path,
//       dataItems: dataItems,
//       datasetProp: datasetProp,
//       diskOnly: diskOnly,
//       withVideo: withVideo,
//     );

//     if (failure != null) {
//       throw Exception(failure.message);
//     }

//     ref.read(preprocessProvider.notifier).setDatasetProp(updatedDatasetProp!);

//     // state = copyWith(
//     //   path: newPath ?? path,
//     //   datasetProp: datasetProp,
//     //   isEdited: false,
//     //   presentationState: SaveDatasetSuccessState(isAutosave: autoSaving),
//     // );
//     state = const AsyncData(null);
//   }
// }
