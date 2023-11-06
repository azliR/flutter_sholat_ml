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
    required this.type,
    this.actions,
    super.key,
  });

  final IllustrationWidgetType type;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final String illustrationPath;
    final String title;
    final String description;

    switch (type) {
      case IllustrationWidgetType.noData:
        illustrationPath = AssetImages.noData;
        title = 'No Data';
        description = 'There is no data to display';
      case IllustrationWidgetType.error:
        illustrationPath = AssetImages.error;
        title = 'Error';
        description = 'Something went wrong';
      case IllustrationWidgetType.notFound:
        illustrationPath = AssetImages.notFound;
        title = 'Not Found';
        description = 'The page you are looking for was not found';
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            illustrationPath,
            width: 300,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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
    );
  }
}
