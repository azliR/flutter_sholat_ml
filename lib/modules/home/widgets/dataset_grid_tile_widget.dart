import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/enums/dataset_version.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

class DatasetGridTile extends StatefulWidget {
  const DatasetGridTile({
    required this.dataset,
    required this.selected,
    required this.tagged,
    required this.action,
    required this.onInitialise,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final Dataset dataset;
  final bool selected;
  final bool tagged;
  final Widget? action;
  final void Function() onInitialise;
  final void Function() onTap;
  final void Function()? onLongPress;

  @override
  State<DatasetGridTile> createState() => _DatasetGridTileState();
}

class _DatasetGridTileState extends State<DatasetGridTile> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onInitialise();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = widget.dataset.property.dirName;
    final dateTime = DateTime.tryParse(name);
    final formattedDatasetName = dateTime == null
        ? name
        : DateFormat("EEEE 'at' HH:mm - d MMM yyy").format(dateTime);
    final datasetVersion = widget.dataset.property.datasetVersion;
    final datasetVersionName = '${datasetVersion.name}'
        '${DatasetVersion.values.last == datasetVersion ? ' (latest)' : ''}';
    final downloaded = widget.dataset.downloaded;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: widget.selected ? 0 : null,
      color: widget.selected ? colorScheme.primaryContainer : null,
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
                  alignment: Alignment.topRight,
                  children: [
                    if (widget.dataset.thumbnail == null)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else if (widget.dataset.thumbnail!.error != null)
                      const Center(
                        child: Icon(Symbols.broken_image_rounded),
                      )
                    else
                      Image.file(
                        File(widget.dataset.thumbnail!.thumbnailPath!),
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
                if (widget.action != null) widget.action!,
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    Symbols.csv_rounded,
                    size: 16,
                    weight: 600,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dataset $datasetVersionName',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            //   Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 8),
            //     child: Row(
            //       children: [
            //         Icon(
            //           Symbols.cloud_done_rounded,
            //           size: 16,
            //           opticalSize: 20,
            //           color: colorScheme.primary,
            //         ),
            //         const SizedBox(width: 6),
            //         Expanded(
            //           child: Text('Uploaded', style: textTheme.bodySmall),
            //         ),
            //       ],
            //     ),
            //   ),

            if (widget.tagged && (downloaded != null && !downloaded))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      downloaded
                          ? Symbols.offline_pin_rounded
                          : Symbols.download_rounded,
                      size: 16,
                      opticalSize: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        downloaded
                            ? 'Available offline'
                            : 'Available to download',
                        style: textTheme.bodySmall,
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
