import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/asset_images.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/enums/sholat_movements.dart';
import 'package:flutter_sholat_ml/enums/sholat_noise_movement.dart';
import 'package:flutter_sholat_ml/modules/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

final categoryProvider =
    StateProvider.autoDispose<SholatMovementCategory?>((ref) => null);
final movementProvider =
    StateProvider.autoDispose<SholatMovement?>((ref) => null);
final noiseMovementProvider =
    StateProvider.autoDispose<SholatNoiseMovement?>((ref) => null);
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

  var _showWarning = true;

  Future<void> _showAddLabelDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final selectedCategory = ref.watch(categoryProvider);
            final movement = ref.watch(movementProvider);

            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select label',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    DropdownMenu<SholatMovementCategory>(
                      expandedInsets: EdgeInsets.zero,
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
                            leadingIcon: SvgPicture.asset(
                              switch (category) {
                                SholatMovementCategory.persiapan =>
                                  AssetImages.persiapan,
                                SholatMovementCategory.takbir =>
                                  AssetImages.takbir,
                                SholatMovementCategory.berdiri =>
                                  AssetImages.berdiri,
                                SholatMovementCategory.ruku => AssetImages.ruku,
                                SholatMovementCategory.iktidal =>
                                  AssetImages.iktidal,
                                SholatMovementCategory.qunut =>
                                  AssetImages.qunut,
                                SholatMovementCategory.sujud =>
                                  AssetImages.sujud,
                                SholatMovementCategory.duduk =>
                                  AssetImages.duduk,
                                SholatMovementCategory.lainnya =>
                                  AssetImages.persiapan,
                              },
                              width: 24,
                              height: 24,
                              colorFilter: ColorFilter.mode(
                                colorScheme.primary,
                                BlendMode.srcIn,
                              ),
                            ),
                          );
                        },
                      ).toList(),
                    ),
                    if (selectedCategory != null) ...[
                      const SizedBox(height: 16),
                      DropdownMenu<SholatMovement>(
                        expandedInsets: EdgeInsets.zero,
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
                    const SizedBox(height: 24),
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
                                        _notifier.setDataItemLabels(
                                      selectedCategory!,
                                      movement,
                                    );
                                    showSnackbar(
                                      context,
                                      'Data items tagged with movement ID: \n'
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

  Future<void> _showAddNoiseDialog() async {
    final textTheme = Theme.of(context).textTheme;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final selectedNoise = ref.watch(noiseMovementProvider);

            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select noise',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    DropdownMenu<SholatNoiseMovement>(
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('Noise'),
                      onSelected: (value) {
                        if (value != selectedNoise) {
                          ref.read(noiseMovementProvider.notifier).update(
                                (state) => value,
                              );
                        }
                      },
                      dropdownMenuEntries: SholatNoiseMovement.values.map(
                        (noise) {
                          return DropdownMenuEntry(
                            label: noise.name,
                            value: noise,
                          );
                        },
                      ).toList(),
                    ),
                    const SizedBox(height: 24),
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
                            onPressed: () {
                              Navigator.pop(context);
                              _notifier.setDataItemNoises(selectedNoise);
                              showSnackbar(
                                context,
                                'Data items marked as noised with $selectedNoise\n',
                              );
                            },
                            child: Text(
                              selectedNoise != null ? 'Save' : 'Remove noise',
                            ),
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
              title: const Text('Change data items label?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'One or more selected data items has been labeled. Are you sure you want to change the label?',
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
                    _showWarning = !dontShowAgain;
                  },
                  child: const Text('Cancel'),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                    _showWarning = !dontShowAgain;
                  },
                  child: const Text('Change label'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRemoveLabelsDialog() async {
    final data = MediaQuery.of(context);

    return showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Remove selected labels'),
              subtitle: const Text(
                'Remove only selected labels',
              ),
              leading: const Icon(Symbols.delete_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                _notifier.removeDataItemLabels();
              },
            ),
            ListTile(
              title: const Text('Remove same movement IDs'),
              subtitle:
                  const Text('Remove every labels with the same movement IDs'),
              leading: const Icon(Symbols.delete_sweep_rounded),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () {
                Navigator.pop(context);
                _notifier.removeDataItemLabels(includeSameMovementIds: true);
              },
            ),
            const SizedBox(height: 8),
            SizedBox(height: data.padding.bottom),
          ],
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

    final selectedDataItems = ref.watch(
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
    final startJumpIndex = ref.watch(
      preprocessProvider.select(
        (state) => state.selectedDataItems.isEmpty
            ? state.currentHighlightedIndex
            : state.lastSelectedIndex,
      ),
    );

    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!isJumpSelectMode && selectedDataItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${selectedDataItems.length} selected',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          if (isJumpSelectMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Select end index (start index: ${startJumpIndex!})',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          const Spacer(),
          if (selectedDataItems.isNotEmpty && !isJumpSelectMode) ...[
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
                _notifier.setJumpSelectMode(enable: true);
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
              onPressed: _showAddNoiseDialog,
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
                if (_showWarning) {
                  final anyLabeled =
                      selectedDataItems.any((dataItem) => dataItem.isLabeled);
                  if (anyLabeled) {
                    final shouldChangeTag = await _showWarningDialog();
                    if (shouldChangeTag != true) {
                      return;
                    }
                  }
                }
                await _showAddLabelDialog();
              },
            ),
            IconButton(
              tooltip: 'Remove label',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Symbols.backspace_rounded,
                weight: 300,
              ),
              onPressed: () async {
                final anyLabeled =
                    selectedDataItems.any((dataItem) => dataItem.isLabeled);
                if (anyLabeled) {
                  await _showRemoveLabelsDialog();
                } else {}
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
                _notifier.setFollowHighlightedMode(
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
