import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum BannerType { info, warning, error, success }

class RoundedBanner extends StatelessWidget {
  const RoundedBanner({
    this.icon,
    this.title,
    this.description,
    this.type = BannerType.info,
    this.margin = const EdgeInsets.all(8),
    super.key,
  });

  final Widget? icon;
  final Widget? title;
  final Widget? description;
  final BannerType type;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final foregroundColor = switch (type) {
      BannerType.info => colorScheme.secondary,
      BannerType.warning => colorScheme.error,
      BannerType.error => colorScheme.onError,
      BannerType.success => colorScheme.primary,
    };

    final backgroundColor = switch (type) {
      BannerType.info => colorScheme.secondaryContainer,
      BannerType.warning => colorScheme.errorContainer,
      BannerType.error => colorScheme.error,
      BannerType.success => colorScheme.primaryContainer,
    };

    final icon = this.icon ??
        switch (type) {
          BannerType.info => const Icon(Symbols.info_rounded),
          BannerType.warning => const Icon(Symbols.warning_rounded),
          BannerType.error => const Icon(Symbols.error_rounded),
          BannerType.success => const Icon(Symbols.check_rounded),
        };

    return Card(
      color: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      margin: margin,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: IconTheme(
                data: IconThemeData(
                  color: foregroundColor,
                ),
                child: icon,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      DefaultTextStyle(
                        style: textTheme.titleMedium!,
                        child: title!,
                      ),
                    if (description != null)
                      DefaultTextStyle(
                        style: textTheme.bodyMedium!,
                        child: description!,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
