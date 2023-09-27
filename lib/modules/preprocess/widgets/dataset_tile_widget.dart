import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';

class DatasetTileWidget extends ConsumerWidget {
  const DatasetTileWidget({
    required this.index,
    required this.dataset,
    required this.onTap,
    required this.onLongPress,
    required this.highlighted,
    required this.selected,
    super.key,
  });

  final int index;
  final Dataset dataset;
  final void Function() onTap;
  final void Function() onLongPress;
  final bool highlighted;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Color.alphaBlend(
        colorScheme.outline.withOpacity(highlighted ? 0.5 : 0),
        selected ? colorScheme.primary : colorScheme.surface,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: 32,
          child: Row(
            children: [
              Expanded(
                child: Center(child: Text(index.toString())),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: Text(
                    dataset.timestamp.toString(),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(child: Text(dataset.x.toString())),
              ),
              Expanded(
                flex: 2,
                child: Center(child: Text(dataset.y.toString())),
              ),
              Expanded(
                flex: 2,
                child: Center(child: Text(dataset.z.toString())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
