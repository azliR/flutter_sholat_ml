import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/features/datasets/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';

class DataItemTile extends StatelessWidget {
  const DataItemTile({
    required this.index,
    required this.dataItem,
    required this.predictedCategory,
    required this.onTap,
    required this.onLongPress,
    required this.enablePredictedPreview,
    required this.isHighlighted,
    required this.isSelected,
    required this.hasProblem,
    super.key,
  });

  final int index;
  final DataItem dataItem;
  final SholatMovementCategory? predictedCategory;
  final void Function() onTap;
  final void Function() onLongPress;
  final bool enablePredictedPreview;
  final bool isHighlighted;
  final bool isSelected;
  final bool hasProblem;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    var backgroundColor = colorScheme.surface;
    if (isSelected) {
      backgroundColor = colorScheme.surfaceBright;
      // } else if (dataItem.isLabeled) {
      //   final splittedId = dataItem.movementSetId!.substring(0, 6);
      //   final hexColor = int.parse('ff$splittedId', radix: 16);
      //   final generatedColor = Color(hexColor);
      //   backgroundColor = Color.lerp(backgroundColor, generatedColor, 0.5)!;
    } else if (hasProblem) {
      backgroundColor = colorScheme.errorContainer;
    }

    Widget? icon;
    if (hasProblem) {
      icon = Icon(
        Symbols.cancel_rounded,
        color: colorScheme.error,
        weight: 300,
      );
    } else if (dataItem.isLabeled && isSelected) {
      icon = Icon(
        Symbols.warning_rounded,
        color: colorScheme.secondary,
        weight: 300,
      );
      // } else if (predictedCategory != null || dataItem.isLabeled) {
      //   final category = predictedCategory ?? dataItem.labelCategory!;
      //   final iconPath = switch (category) {
      //     SholatMovementCategory.takbir => AssetImages.takbir,
      //     SholatMovementCategory.berdiri => AssetImages.berdiri,
      //     SholatMovementCategory.ruku => AssetImages.ruku,
      //     SholatMovementCategory.iktidal => AssetImages.iktidal,
      //     SholatMovementCategory.qunut => AssetImages.qunut,
      //     SholatMovementCategory.sujud => AssetImages.sujud,
      //     SholatMovementCategory.duduk => AssetImages.duduk,
      //     SholatMovementCategory.transisi => AssetImages.transisi,
      //   };
      //   icon = SvgPicture.asset(
      //     iconPath,
      //     width: 24,
      //     height: 24,
      //     colorFilter: ColorFilter.mode(
      //       predictedCategory != null ? colorScheme.outline : colorScheme.primary,
      //       BlendMode.srcIn,
      //     ),
      //   );
    }

    return DefaultTextStyle(
      style: textTheme.bodyMedium!,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isHighlighted ? colorScheme.outline : Colors.transparent,
          ),
          borderRadius: isHighlighted
              ? const BorderRadius.all(Radius.circular(12))
              : BorderRadius.zero,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(index.toString()),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      dataItem.timestamp.toString().replaceFirst('000', ''),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text(dataItem.x.toStringAsFixed(0))),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text(dataItem.y.toStringAsFixed(0))),
                ),
                Expanded(
                  flex: 2,
                  child: Center(child: Text(dataItem.z.toStringAsFixed(0))),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Tooltip(
                      message: dataItem.noiseMovement?.name ?? '',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: dataItem.noiseMovement != null
                            ? () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                showSnackbar(
                                  context,
                                  dataItem.noiseMovement!.name,
                                );
                              }
                            : null,
                        child: dataItem.noiseMovement != null
                            ? Icon(
                                Symbols.report_rounded,
                                color: colorScheme.secondary,
                                weight: 300,
                              )
                            : const SizedBox(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Tooltip(
                      message: dataItem.label?.name ?? '',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: dataItem.isLabeled
                            ? () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                showSnackbar(
                                  context,
                                  '${dataItem.label!.name} with movement ID: '
                                  '${dataItem.movementSetId!}',
                                );
                              }
                            : null,
                        child: icon,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
