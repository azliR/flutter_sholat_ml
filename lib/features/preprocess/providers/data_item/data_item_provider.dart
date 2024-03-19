import 'package:flutter_sholat_ml/features/preprocess/components/dataset_list_component.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_item_provider.g.dart';

final _preprocessRepository = PreprocessRepository();

@riverpod
class GenerateDataItemSection extends _$GenerateDataItemSection {
  @override
  Future<List<DataItemSection>> build() async {
    final dataItems =
        ref.watch(preprocessProvider.select((value) => value.dataItems));

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
