import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/blocs/datasets/datasets_notifier.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset_thumbnail/dataset_thumbnail.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class DatasetGridTile extends ConsumerStatefulWidget {
  const DatasetGridTile({
    required this.datasetPath,
    required this.isTagged,
    required this.onTap,
    required this.onLongPress,
    required this.onDeleted,
    super.key,
  });

  final String datasetPath;
  final bool isTagged;
  final void Function() onTap;
  final void Function() onLongPress;
  final void Function() onDeleted;

  @override
  ConsumerState<DatasetGridTile> createState() => _DatasetGridTileState();
}

class _DatasetGridTileState extends ConsumerState<DatasetGridTile> {
  late final DatasetsNotifier notifier;

  @override
  void initState() {
    notifier = ref.read(datasetsProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final name = widget.datasetPath.split('/').last;
      final thumbnail = ref.read(
        datasetsProvider.select(
          (value) =>
              value.datasetThumbnails.cast<DatasetThumbnail?>().firstWhere(
                    (thumbnail) => thumbnail?.datasetDir == name,
                    orElse: () => null,
                  ),
        ),
      );
      if (thumbnail == null) {
        notifier.datasetThumbnail(widget.datasetPath);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = widget.datasetPath.split('/').last;
    final dateTime = DateTime.tryParse(name);
    final formattedDatasetName = dateTime == null
        ? name
        : DateFormat("EEEE 'at' HH:mm - MMM yyy").format(dateTime);

    final isSelected = ref.watch(
      datasetsProvider.select(
        (value) => value.selectedDatasetPaths.contains(widget.datasetPath),
      ),
    );
    final thumbnail = ref.watch(
      datasetsProvider.select(
        (value) => value.datasetThumbnails.cast<DatasetThumbnail?>().firstWhere(
              (thumbnail) => thumbnail?.datasetDir == name,
              orElse: () => null,
            ),
      ),
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 0 : null,
      color: isSelected ? colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isSelected
            ? BorderSide(
                color: colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  if (thumbnail == null)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else if (thumbnail.error != null)
                    Center(
                      child: Text(thumbnail.error!),
                    )
                  else
                    Image.file(
                      File(thumbnail.thumbnailPath!),
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(1),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Symbols.check_rounded,
                        color: colorScheme.onPrimary,
                        size: 20,
                        weight: 600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      formattedDatasetName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall,
                    ),
                  ),
                ),
                _buildMenu(widget.datasetPath),
              ],
            ),
            const SizedBox(height: 4),
            if (widget.isTagged)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      Symbols.cloud_done_rounded,
                      size: 16,
                      opticalSize: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text('Uploaded', style: textTheme.labelSmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  MenuAnchor _buildMenu(String datasetPath) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          iconSize: 20,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: child!,
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Symbols.delete_rounded),
          onPressed: () async {
            await notifier.deleteDataset(datasetPath);
            widget.onDeleted();
          },
          child: const Text('Delete just from device'),
        ),
        if (widget.isTagged)
          MenuItemButton(
            leadingIcon: const Icon(Symbols.delete_forever_rounded),
            onPressed: () async {
              await notifier.deleteDatasetFromCloud(datasetPath);
              widget.onDeleted();
            },
            child: const Text('Delete permanently'),
          ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
