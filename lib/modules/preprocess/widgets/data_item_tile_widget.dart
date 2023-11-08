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
    required this.highlighted,
    required this.selected,
    super.key,
  });

  final int index;
  final DataItem dataItem;
  final void Function() onTap;
  final void Function() onLongPress;
  final bool highlighted;
  final bool selected;

  bool _isColorDark(Color color) {
    return color.computeLuminance() < 0.5;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    var color = Colors.transparent;
    if (selected) {
      color = colorScheme.primaryContainer;
    } else if (dataItem.isLabeled) {
      final splittedId = dataItem.movementSetId!.substring(0, 6);
      final hexColor = int.parse('ff$splittedId', radix: 16);
      final generatedColor = Color(hexColor);
      color = Color.lerp(color, generatedColor, 0.5)!;
    }

    Widget? icon;
    if (dataItem.isLabeled && selected) {
      icon = Icon(
        Symbols.warning_rounded,
        color: colorScheme.secondary,
        weight: 300,
      );
    } else if (dataItem.isLabeled) {
      final category = dataItem.labelCategory!;
      final iconPath = switch (category) {
        SholatMovementCategory.persiapan => AssetImages.persiapan,
        SholatMovementCategory.takbir => AssetImages.takbir,
        SholatMovementCategory.berdiri => AssetImages.berdiri,
        SholatMovementCategory.ruku => AssetImages.ruku,
        SholatMovementCategory.iktidal => AssetImages.iktidal,
        SholatMovementCategory.qunut => AssetImages.qunut,
        SholatMovementCategory.sujud => AssetImages.sujud,
        SholatMovementCategory.duduk => AssetImages.duduk,
        SholatMovementCategory.lainnya => AssetImages.persiapan,
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

    return DefaultTextStyle(
      style: textTheme.bodyMedium!.copyWith(
        color: _isColorDark(color) ? Colors.white : Colors.black,
      ),
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: highlighted
              ? const BorderRadius.all(Radius.circular(12))
              : BorderRadius.zero,
          side: highlighted || selected
              ? BorderSide(
                  color: colorScheme.outline,
                )
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(child: Text(index.toString())),
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
                Expanded(
                  child: Center(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: dataItem.isLabeled
                          ? () {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              showSnackbar(
                                context,
                                '${dataItem.label!.name} with movement ID:\n'
                                '${dataItem.movementSetId!}',
                              );
                            }
                          : null,
                      child: icon,
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
