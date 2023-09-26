import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:video_player/video_player.dart';

@RoutePage()
class PreprocessPage extends ConsumerStatefulWidget {
  const PreprocessPage({required this.path, super.key});

  final String path;

  @override
  ConsumerState<PreprocessPage> createState() => _PreprocessPageState();
}

class _PreprocessPageState extends ConsumerState<PreprocessPage> {
  late final PreprocessNotifier _notifier;

  late final VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier)..initialise(widget.path);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen(preprocessProvider, (previous, next) async {
      if (previous?.preprocess != next.preprocess) {
        _videoPlayerController = VideoPlayerController.file(
          File(next.preprocess!.videoPath),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );
        await _videoPlayerController.initialize();
        if (!mounted) return;
        setState(() {});
      }
    });

    final preprocess =
        ref.watch(preprocessProvider.select((state) => state.preprocess));
    final datasets =
        ref.watch(preprocessProvider.select((state) => state.datasets));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: () {
          if (preprocess == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return Column(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController),
                ),
              ),
              Divider(
                height: 0,
                color: colorScheme.outline,
              ),
              Expanded(
                child: Scrollbar(
                  child: ListView.separated(
                    cacheExtent: 24,
                    separatorBuilder: (_, __) => const Divider(),
                    itemCount: datasets.length,
                    itemBuilder: (context, index) {
                      final dataset = datasets[index];

                      return SizedBox(
                        height: 24,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Text(
                                  dataset.timestamp.toString(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Center(child: Text(dataset.x.toString())),
                            ),
                            Expanded(
                              child: Center(child: Text(dataset.y.toString())),
                            ),
                            Expanded(
                              child: Center(child: Text(dataset.z.toString())),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }(),
      ),
    );
  }
}
