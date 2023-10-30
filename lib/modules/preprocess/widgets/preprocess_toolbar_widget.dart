import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

final categoryProvider =
    StateProvider.autoDispose<SholatMovementCategory?>((ref) => null);
final movementProvider =
    StateProvider.autoDispose<SholatMovement?>((ref) => null);
final dontShowWarningProvider = StateProvider.autoDispose<bool>((ref) => false);

class PreprocessToolbar extends ConsumerStatefulWidget {
  const PreprocessToolbar({
    required this.videoPlayerController,
    required this.onFollowHighlighted,
    super.key,
  });

  final VideoPlayerController videoPlayerController;
  final void Function() onFollowHighlighted;

  @override
  ConsumerState<PreprocessToolbar> createState() => _PreprocessToolbarState();
}

class _PreprocessToolbarState extends ConsumerState<PreprocessToolbar> {
  late final PreprocessNotifier _notifier;

  var _dontShowWarning = false;

  Future<void> _showTagDialog() async {
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
                    DropdownMenu<SholatMovementCategory>(
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
                        (category) {
                          return DropdownMenuEntry(
                            label: category.name,
                            value: category,
                          );
                        },
                      ).toList(),
                    ),
                    if (selectedCategory != null) ...[
                      const SizedBox(height: 12),
                      DropdownMenu<SholatMovement>(
                        width: size.width - 24,
                        label: const Text('Movement'),
                        errorText: movement == null
                            ? 'Please select a movement'
                            : null,
                        onSelected: (value) => ref
                            .read(movementProvider.notifier)
                            .update((state) => value),
                        dropdownMenuEntries:
                            SholatMovement.getByCategory(selectedCategory).map(
                          (movement) {
                            return DropdownMenuEntry(
                              value: movement,
                              label: movement.name,
                            );
                          },
                        ).toList(),
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
                                        _notifier.onTaggedDatasets(
                                      selectedCategory!,
                                      movement,
                                    );
                                    showSnackbar(
                                      context,
                                      'Datasets tagged with movement ID: \n'
                                      '$movementSetId',
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

  Future<bool?> _showWarningDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final dontShowAgain = ref.watch(dontShowWarningProvider);
            return AlertDialog(
              title: const Text('Tagged data items'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'One or more selected data items has been tagged. Are you sure you want to change the tag?',
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (value) {
                          ref
                              .read(dontShowWarningProvider.notifier)
                              .update((state) => value!);
                        },
                      ),
                      const Text("Don't show this again"),
                    ],
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                    _dontShowWarning = dontShowAgain;
                  },
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                    _dontShowWarning = dontShowAgain;
                  },
                  child: const Text('Change tag'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final selectedDatasets = ref.watch(
      preprocessProvider.select((state) => state.selectedDataItems),
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

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (selectedDatasets.isNotEmpty)
            IconButton(
              tooltip: 'Clear selected data items',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Symbols.arrow_back_rounded,
                weight: 300,
              ),
              onPressed: () {
                _notifier.clearSelectedDataItems();
              },
            ),
          if (!isJumpSelectMode && selectedDatasets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${selectedDatasets.length} selected',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          if (isJumpSelectMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Select end index (start index: ${lastSelectedIndex!})',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          const Spacer(),
          if (selectedDatasets.isNotEmpty && !isJumpSelectMode) ...[
            IconButton(
              tooltip: isJumpSelectMode
                  ? 'Disable jump select mode'
                  : 'Enable jump select mode',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Symbols.move_down_rounded,
                weight: 300,
              ),
              onPressed: () {
                _notifier.onJumpSelectModeChanged(enable: true);
              },
            ),
            const VerticalDivider(),
            IconButton(
              tooltip: 'Add noise',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Symbols.report_rounded,
                weight: 300,
              ),
              onPressed: () {},
            ),
            IconButton(
              tooltip: 'Add label',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Symbols.new_label_rounded,
                weight: 300,
              ),
              onPressed: () async {
                final selectedDataItems = ref.read(
                  preprocessProvider.select((state) => state.selectedDataItems),
                );
                if (!_dontShowWarning) {
                  final anyLabeled =
                      selectedDataItems.any((dataItem) => dataItem.isLabeled);
                  if (anyLabeled) {
                    final shouldChangeTag = await _showWarningDialog();
                    if (shouldChangeTag != true) {
                      return;
                    }
                  }
                }
                await _showTagDialog();
              },
            ),
            const VerticalDivider(),
          ],
          if (!isJumpSelectMode)
            IconButton(
              tooltip:
                  isFollowHighlightedMode ? 'Disable follow' : 'Enable follow',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: isFollowHighlightedMode
                    ? colorScheme.secondaryContainer
                    : null,
              ),
              icon: const Icon(
                Symbols.jump_to_element_rounded,
                weight: 300,
              ),
              onPressed: () {
                final enable = !isFollowHighlightedMode;
                _notifier.onFollowHighlightedModeChanged(
                  enable: enable,
                );
                if (enable) {
                  widget.onFollowHighlighted();
                }
              },
            ),
          IconButton(
            tooltip: isPlaying ? 'Pause' : 'Play',
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () {
              if (isPlaying) {
                widget.videoPlayerController.pause();
              } else {
                widget.videoPlayerController.play();
              }
            },
            icon: isPlaying
                ? const Icon(Symbols.pause, weight: 300)
                : const Icon(
                    Symbols.play_arrow,
                    weight: 300,
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
