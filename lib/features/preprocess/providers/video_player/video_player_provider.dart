import 'package:flutter_sholat_ml/constants/paths.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/features/preprocess/repositories/preprocess_repository.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_player_provider.g.dart';

@riverpod
class VideoPlaybackSpeed extends _$VideoPlaybackSpeed {
  @override
  double build() => 1;

  void setSpeed(double speed) => state = speed;
}

@riverpod
class CompressVideo extends _$CompressVideo {
  final _preprocessRepository = PreprocessRepository();

  @override
  bool build() => false;

  Future<void> compress({
    required String path,
    required bool diskOnly,
  }) async {
    state = true;

    const datasetVideoName = Paths.datasetVideo;
    final (compressFailure, _) = await _preprocessRepository.compressVideo(
      path: join(path, datasetVideoName),
    );
    if (compressFailure != null) {
      throw Exception(compressFailure.message);
    }

    final datasetProp =
        ref.read(preprocessProvider).datasetProp!.copyWith(isCompressed: true);

    final (writePropFailure, updatedDatasetProp) =
        await _preprocessRepository.writeDatasetProp(
      datasetPath: path,
      datasetProp: datasetProp,
    );

    if (writePropFailure != null) {
      throw Exception(writePropFailure.message);
    }

    ref.read(preprocessProvider.notifier).setDatasetProp(updatedDatasetProp!);

    state = false;
  }
}
