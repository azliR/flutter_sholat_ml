import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/dataset.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class DatasetGridTile extends StatefulWidget {
  const DatasetGridTile({
    required this.dataset,
    required this.selected,
    required this.labeled,
    required this.action,
    required this.onInitialise,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final Dataset dataset;
  final bool selected;
  final bool labeled;
  final Widget? action;
  final void Function() onInitialise;
  final void Function() onTap;
  final void Function()? onLongPress;

  @override
  State<DatasetGridTile> createState() => _DatasetGridTileState();
}

class _DatasetGridTileState extends State<DatasetGridTile>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onInitialise();
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.onInitialise();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dataset = widget.dataset;
    final datasetProp = widget.dataset.property;
    final createdAt = datasetProp.createdAt;
    final formattedDatasetName =
        DateFormat("EEEE 'at' HH:mm - d MMM yyy").format(createdAt);
    final downloaded = dataset.downloaded;
    final hasEvaluated = datasetProp.hasEvaluated;
    final isSyncedWithCloud = datasetProp.isSyncedWithCloud;
    final csvOnly = datasetProp.csvOnly;

    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: widget.selected ? 0 : null,
      color: widget.selected ? colorScheme.secondaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: widget.selected
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
              height: 100,
              child: ColoredBox(
                color: colorScheme.outlineVariant,
                child: Stack(
                  children: [
                    if (dataset.thumbnail == null)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (dataset.thumbnail!.error != null)
                      const Center(
                        child: Icon(Symbols.broken_image_rounded),
                      )
                    else
                      Image.file(
                        File(dataset.thumbnail!.thumbnailPath!),
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Symbols.broken_image_rounded),
                          );
                        },
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    if (widget.selected)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Symbols.check_rounded,
                            color: colorScheme.onPrimary,
                            size: 18,
                            weight: 600,
                          ),
                        ),
                      )
                    else if (widget.labeled &&
                        downloaded != null &&
                        !downloaded)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Symbols.download_rounded,
                            color: colorScheme.onSecondary,
                            size: 18,
                            weight: 600,
                          ),
                        ),
                      ),
                    if (csvOnly)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(4)),
                          ),
                          child: Text(
                            'CSV ONLY',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
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
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ),
                if (widget.action != null) widget.action!,
              ],
            ),
            const SizedBox(height: 8),
            if (widget.labeled) ...[
              if (downloaded != null && downloaded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        isSyncedWithCloud
                            ? Symbols.cloud_done_rounded
                            : Symbols.sync_saved_locally_rounded,
                        size: 16,
                        opticalSize: 20,
                        color: isSyncedWithCloud
                            ? colorScheme.primary
                            : colorScheme.onBackground,
                        weight: isSyncedWithCloud ? 500 : 400,
                        fill: isSyncedWithCloud ? 1 : 0,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isSyncedWithCloud
                              ? 'Synced with cloud'
                              : 'Saved locally',
                          style: textTheme.bodySmall?.copyWith(
                            color: isSyncedWithCloud
                                ? colorScheme.primary
                                : colorScheme.onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    hasEvaluated
                        ? Symbols.check_circle_rounded
                        : Symbols.pending_rounded,
                    size: 16,
                    opticalSize: 20,
                    weight: hasEvaluated ? 500 : 400,
                    color: hasEvaluated
                        ? colorScheme.primary
                        : colorScheme.outline,
                    fill: hasEvaluated ? 1 : 0,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasEvaluated ? 'Evaluated' : 'Not evaluated',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight:
                            hasEvaluated ? FontWeight.bold : FontWeight.normal,
                        color: hasEvaluated
                            ? colorScheme.primary
                            : colorScheme.onBackground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
