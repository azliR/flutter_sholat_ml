import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';

class DatasetTileWidget extends StatelessWidget {
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

  bool get tagged => dataset.labelCategory != null && dataset.label != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    var color = Colors.transparent;
    if (highlighted) {
      color = colorScheme.outline.withOpacity(0.3);
    }
    if (selected) {
      color = Color.alphaBlend(color, colorScheme.primaryContainer);
    }

    Icon? icon;
    if (tagged && selected) {
      icon = Icon(
        Symbols.warning_rounded,
        color: colorScheme.secondary,
        weight: 300,
      );
    } else if (tagged) {
      icon = Icon(
        Symbols.label_rounded,
        color: colorScheme.onSurface,
        weight: 300,
      );
    }

    return Material(
      color: color,
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
                    dataset.timestamp.toString().replaceFirst('000', ''),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(child: Text(dataset.x.toStringAsFixed(0))),
              ),
              Expanded(
                flex: 2,
                child: Center(child: Text(dataset.y.toStringAsFixed(0))),
              ),
              Expanded(
                flex: 2,
                child: Center(child: Text(dataset.z.toStringAsFixed(0))),
              ),
              Expanded(
                flex: 2,
                child: Center(child: Text('-')),
              ),
              Expanded(
                child: Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (tagged) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        showSnackbar(
                          context,
                          '${dataset.label}${dataset.label!}',
                        );
                      }
                    },
                    child: icon,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
