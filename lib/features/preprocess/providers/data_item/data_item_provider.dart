import 'package:flutter_sholat_ml/features/preprocess/components/dataset_list_component.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_item_provider.g.dart';

final _preprocessRepository = PreprocessRepository();

@riverpod
Future<List<DataItemSection>> generateSection(GenerateSectionRef ref) async {
  final dataItems =
      ref.watch(preprocessProvider.select((value) => value.dataItems));

  final (failure, sections) =
      await _preprocessRepository.generateSections(dataItems);
  if (failure != null) {
    throw Exception(failure.message);
  }

  return sections!;
}

@riverpod
class SelectedSectionIndex extends _$SelectedSectionIndex {
  @override
  int? build() => null;

  void setSectionIndex(int? section) => state = section;
}
