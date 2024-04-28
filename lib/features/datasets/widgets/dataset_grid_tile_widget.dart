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
    // required this.onInitialise,
    required this.onTap,
    this.onLongPress,
    super.key,
  });

  final Dataset dataset;
  final bool selected;
  final bool labeled;
  final Widget? action;
  // final void Function() onInitialise;
  final void Function() onTap;
  final void Function()? onLongPress;

  @override
  State<DatasetGridTile> createState() => _DatasetGridTileState();
}

class _DatasetGridTileState extends State<DatasetGridTile> {
  @override
  void initState() {
    // WidgetsBinding.instance.addObserver(this);
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   widget.onInitialise();
    // });
    super.initState();
  }

  @override
  void dispose() {
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.resumed) {
  //     widget.onInitialise();
  //   }
  //   super.didChangeAppLifecycleState(state);
  // }

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
    final includeVideo = datasetProp.includeVideo;

    return Card.filled(
      margin: EdgeInsets.zero,
      elevation: widget.selected ? 0 : null,
      color: widget.selected ? colorScheme.secondaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: widget.selected
            ? BorderSide(
                color: colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: ListTile(
        isThreeLine: true,
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                formattedDatasetName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              height: 42,
              width: 42,
              child: Center(
                child: switch (widget.selected) {
                  _ when widget.labeled && downloaded != null && !downloaded =>
                    const Icon(
                      Symbols.download_rounded,
                      size: 18,
                      weight: 600,
                    ),
                  false when widget.action != null => widget.action!,
                  true => Container(
                      padding: const EdgeInsets.all(2),
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
                  false => null,
                },
              ),
            ),
          ],
        ),
        subtitle: SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _InfoChip(
                icon: Icon(
                  hasEvaluated
                      ? Symbols.check_circle_rounded
                      : Symbols.pending_rounded,
                  weight: hasEvaluated ? 500 : null,
                  color: hasEvaluated ? colorScheme.primary : null,
                  fill: hasEvaluated ? 1 : null,
                ),
                title: Text(
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
              _InfoChip(
                icon: Icon(
                  isSyncedWithCloud
                      ? Symbols.cloud_done_rounded
                      : Symbols.sync_saved_locally_rounded,
                  weight: isSyncedWithCloud ? 500 : null,
                  color: isSyncedWithCloud ? colorScheme.primary : null,
                  fill: isSyncedWithCloud ? 1 : null,
                ),
                title: Text(
                  isSyncedWithCloud ? 'Synced with cloud' : 'Saved locally',
                  style: textTheme.bodySmall?.copyWith(
                    color: isSyncedWithCloud
                        ? colorScheme.primary
                        : colorScheme.onBackground,
                  ),
                ),
              ),
              if (includeVideo)
                _InfoChip(
                  icon: const Icon(Symbols.movie_rounded),
                  title: Text(
                    'Video',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.title,
    super.key,
  });

  final Widget? icon;
  final Widget title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            strokeAlign: BorderSide.strokeAlignOutside,
            color: colorScheme.outline,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.all(3),
                child: IconTheme(
                  data: IconThemeData(
                    size: 18,
                    weight: 400,
                    color: colorScheme.onBackground,
                    fill: 0,
                  ),
                  child: icon!,
                ),
              ),
              const SizedBox(width: 4),
            ],
            title,
          ],
        ),
      ),
    );
  }
}
