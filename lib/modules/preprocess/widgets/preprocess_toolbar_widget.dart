import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

final categoryProvider =
    StateProvider.autoDispose<SholatMovementCategory?>((ref) => null);
final movementProvider = StateProvider.autoDispose<String?>((ref) => null);

class PreprocessToolbar extends ConsumerWidget {
  const PreprocessToolbar({
    required this.videoPlayerController,
    required this.onFollowHighlighted,
    super.key,
  });

  final VideoPlayerController videoPlayerController;
  final void Function() onFollowHighlighted;

  Future<void> _showTagDialog(
    BuildContext context,
    PreprocessNotifier notifier,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final size = mediaQuery.size;

        return Consumer(
          builder: (context, ref, child) {
            final selectedCategory = ref.watch(categoryProvider);
            final movement = ref.watch(movementProvider);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownMenu(
                      width: size.width - 24,
                      label: const Text('Category'),
                      onSelected: (value) {
                        if (value != selectedCategory) {
                          ref.read(categoryProvider.notifier).update(
                                (state) => value,
                              );
                          ref.read(movementProvider.notifier).update(
                                (state) => null,
                              );
                        }
                      },
                      dropdownMenuEntries: SholatMovementCategory.values.map(
                        (e) {
                          return DropdownMenuEntry(
                            label: e.name,
                            value: e,
                          );
                        },
                      ).toList(),
                    ),
                    if (selectedCategory != null) ...[
                      const SizedBox(height: 12),
                      DropdownMenu(
                        width: size.width - 24,
                        label: const Text('Movement'),
                        errorText: movement == null
                            ? 'Please select a movement'
                            : null,
                        onSelected: (value) => ref
                            .read(movementProvider.notifier)
                            .update((state) => value),
                        dropdownMenuEntries: () {
                          switch (selectedCategory) {
                            case SholatMovementCategory.persiapan:
                              return Persiapan.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                            case SholatMovementCategory.takbir:
                              return Takbir.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                            case SholatMovementCategory.berdiri:
                              return Berdiri.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                            case SholatMovementCategory.ruku:
                              return Ruku.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                            case SholatMovementCategory.iktidal:
                              return Iktidal.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                            case SholatMovementCategory.qunut:
                              return Qunut.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                            case SholatMovementCategory.sujud:
                              return Sujud.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                            case SholatMovementCategory.duduk:
                              return Duduk.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                            case SholatMovementCategory.lainnya:
                              return Lainnya.values.map((e) {
                                return DropdownMenuEntry(
                                  label: e.name,
                                  value: e.code,
                                );
                              }).toList();
                          }
                        }(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.end,
                        runAlignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: movement != null
                                ? () {
                                    Navigator.pop(context);
                                    final movementSetId =
                                        notifier.onTaggedDatasets(
                                      selectedCategory!.code,
                                      movement,
                                    );
                                    showSnackbar(
                                      context,
                                      'Datasets tagged with movement id $movementSetId',
                                    );
                                  }
                                : null,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final notifier = ref.read(preprocessProvider.notifier);

    final selectedDatasets = ref.watch(
      preprocessProvider.select((state) => state.selectedDatasets),
    );
    final isPlaying = ref.watch(
      preprocessProvider.select((state) => state.isPlaying),
    );
    final isJumpSelectMode = ref.watch(
      preprocessProvider.select((state) => state.isJumpSelectMode),
    );
    final isFollowHighlightedMode = ref.watch(
      preprocessProvider.select((state) => state.isFollowHighlightedMode),
    );
    final lastSelectedIndex = ref.watch(
      preprocessProvider.select((state) => state.lastSelectedIndex),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isJumpSelectMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Select end index (start index: ${lastSelectedIndex!}))',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        const Spacer(),
        if (selectedDatasets.isNotEmpty && !isJumpSelectMode) ...[
          if (!isJumpSelectMode)
            IconButton(
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Symbols.move_down_rounded,
                weight: 300,
              ),
              onPressed: () {
                notifier.onJumpSelectModeChanged(enable: true);
              },
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(
              Symbols.new_label_rounded,
              weight: 300,
            ),
            onPressed: () => _showTagDialog(context, notifier),
          ),
        ],
        IconButton(
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor:
                isFollowHighlightedMode ? colorScheme.secondaryContainer : null,
          ),
          icon: const Icon(
            Symbols.jump_to_element_rounded,
            weight: 300,
          ),
          onPressed: () {
            final enable = !isFollowHighlightedMode;
            notifier.onFollowHighlightedModeChanged(
              enable: enable,
            );
            if (enable) {
              onFollowHighlighted();
            }
          },
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            if (isPlaying) {
              videoPlayerController.pause();
            } else {
              videoPlayerController.play();
            }
          },
          icon: isPlaying
              ? const Icon(Symbols.pause, weight: 300)
              : const Icon(
                  Symbols.play_arrow,
                  weight: 300,
                ),
        ),
      ],
    );
  }
}
