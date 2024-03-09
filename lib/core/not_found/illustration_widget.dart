import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/constants/asset_images.dart';
import 'package:flutter_svg/svg.dart';

enum IllustrationWidgetType {
  noData,
  error,
  notFound,
}

class IllustrationWidget extends StatelessWidget {
  const IllustrationWidget({
    this.type,
    this.icon,
    this.title,
    this.description,
    this.actions,
    super.key,
  }) : assert(
          type != null || icon != null,
          'Either type or icon must be provided',
        );

  final IllustrationWidgetType? type;
  final Widget? icon;
  final Widget? title;
  final Widget? description;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final String? illustrationPath;
    final String titleStr;
    final String descriptionStr;

    switch (type) {
      case IllustrationWidgetType.noData:
        illustrationPath = AssetImages.noData;
        titleStr = 'No Data';
        descriptionStr = 'There is no data to display';
      case IllustrationWidgetType.error:
        illustrationPath = AssetImages.error;
        titleStr = 'Error';
        descriptionStr = 'Something went wrong';
      case IllustrationWidgetType.notFound:
        illustrationPath = AssetImages.notFound;
        titleStr = 'Not Found';
        descriptionStr = 'The page you are looking for was not found';
      case null:
        illustrationPath = null;
        titleStr = '';
        descriptionStr = '';
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              IconTheme(
                data: IconThemeData(
                  size: 100,
                  weight: 200,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: icon!,
              )
            else
              SvgPicture.asset(
                illustrationPath!,
                width: 300,
              ),
            const SizedBox(height: 8),
            DefaultTextStyle(
              style: textTheme.titleMedium!,
              textAlign: TextAlign.center,
              child: title ?? Text(titleStr),
            ),
            const SizedBox(height: 4),
            DefaultTextStyle(
              style: textTheme.bodyMedium!,
              textAlign: TextAlign.center,
              child: description ?? Text(descriptionStr),
            ),
            const SizedBox(height: 24),
            if (actions != null)
              Wrap(
                alignment: WrapAlignment.center,
                runAlignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: actions!,
              ),
          ],
        ),
      ),
    );
  }
}
