import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/constants/asset_images.dart';
import 'package:flutter_sholat_ml/enums/sholat_movement_category.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

class DataItemTile extends StatelessWidget {
  const DataItemTile({
    required this.index,
    required this.dataItem,
    required this.onTap,
    required this.onLongPress,
    required this.isHighlighted,
    required this.isSelected,
    required this.hasProblem,
    super.key,
  });

  final int index;
  final DataItem dataItem;
  final void Function() onTap;
  final void Function() onLongPress;
  final bool isHighlighted;
  final bool isSelected;
  final bool hasProblem;

  bool _isColorDark(Color color) {
    return color.computeLuminance() < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    var backgroundColor = colorScheme.background;
    if (isSelected) {
      backgroundColor = colorScheme.primaryContainer;
    } else if (dataItem.isLabeled) {
      final splittedId = dataItem.movementSetId!.substring(0, 6);
      final hexColor = int.parse('ff$splittedId', radix: 16);
      final generatedColor = Color(hexColor);
      backgroundColor = Color.lerp(backgroundColor, generatedColor, 0.5)!;
    }

    Widget? icon;
    if (dataItem.isLabeled && isSelected) {
      icon = Icon(
        Symbols.warning_rounded,
        color: colorScheme.secondary,
        weight: 300,
      );
    } else if (dataItem.isLabeled) {
      final category = dataItem.labelCategory!;
      final iconPath = switch (category) {
        SholatMovementCategory.takbir => AssetImages.takbir,
        SholatMovementCategory.berdiri => AssetImages.berdiri,
        SholatMovementCategory.ruku => AssetImages.ruku,
        SholatMovementCategory.iktidal => AssetImages.iktidal,
        SholatMovementCategory.qunut => AssetImages.qunut,
        SholatMovementCategory.sujud => AssetImages.sujud,
        SholatMovementCategory.duduk => AssetImages.duduk,
        SholatMovementCategory.transisi => AssetImages.transisi,
      };
      icon = SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          colorScheme.primary,
          BlendMode.srcIn,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: DefaultTextStyle(
        style: textTheme.bodyMedium!.copyWith(
          color: _isColorDark(backgroundColor) ? Colors.white : Colors.black,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: isHighlighted ? colorScheme.outline : Colors.transparent,
            ),
            borderRadius: isHighlighted
                ? const BorderRadius.all(Radius.circular(12))
                : BorderRadius.zero,
          ),
          child: SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: hasProblem
                        ? Icon(
                            Symbols.error_circle_rounded_error_rounded,
                            color: colorScheme.error,
                          )
                        : Text(index.toString()),
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
