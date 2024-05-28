import 'dart:isolate';

import 'package:dartx/dartx_io.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/preprocess/components/dataset_list_component.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/dataset/dataset_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/ml_model/ml_model_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'data_item_provider.g.dart';

@riverpod
class GenerateDataItemSection extends _$GenerateDataItemSection {
  final _preprocessRepository = PreprocessRepository();

  @override
  Future<List<DataItemSection>> build() async {
    final enablePredictedPreview = ref.watch(enablePredictedPreviewProvider);
    var dataItems =
        ref.watch(preprocessProvider.select((value) => value.dataItems));

    if (enablePredictedPreview) {
      final predictedCategories =
          ref.watch(predictedCategoriesProvider).requireValue!;

      dataItems = await Isolate.run(
        () {
          var lastMovementSetId = const Uuid().v4();
          SholatMovementCategory? lastLabelCategory;
          return dataItems.mapIndexed(
            (index, dataItem) {
              final predictedCategory = predictedCategories[index];
              if (lastLabelCategory != predictedCategory) {
                lastMovementSetId = const Uuid().v4();
              }
              lastLabelCategory = predictedCategory;
              return dataItem.copyWith(
                labelCategory: () => predictedCategory,
                movementSetId: () => lastMovementSetId,
              );
            },
          ).toList();
        },
      );
    }

    final (failure, sections) =
        await _preprocessRepository.generateSections(dataItems);
    if (failure != null) {
      state = AsyncError(
        failure.error ?? failure.message,
        failure.stackTrace ?? StackTrace.current,
      );
    }

    return sections!;
  }

  void toggleSectionAt(int index) {
    final sections = state.valueOrNull;
    if (sections == null) return;

    final section = sections[index];
    sections[index] = section.copyWith(expanded: !section.expanded);

    state = AsyncData(sections);
  }
}

@riverpod
class SelectedSectionIndex extends _$SelectedSectionIndex {
  @override
  int? build() => null;

  void setSectionIndex(int? section) => state = section;
}
