import 'package:flutter/material.dart';

class RoundedListTile extends StatelessWidget {
  const RoundedListTile({
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.tileColor,
    this.titleTextStyle,
    this.dense,
    this.filled = true,
    this.margin,
    this.contentPadding,
    this.selected,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Color? tileColor;
  final bool? dense;
  final bool filled;
  final TextStyle? titleTextStyle;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? contentPadding;
  final bool? selected;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Card.filled(
        margin:
            margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        clipBehavior: Clip.antiAlias,
        child: _buildTile(context),
      );
    }
    return Card.outlined(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: _buildTile(context),
    );
  }

  ListTile _buildTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      contentPadding: contentPadding ??
          switch (trailing) {
            Icon() => const EdgeInsets.fromLTRB(16, 0, 12, 0),
            IconButton() => const EdgeInsets.fromLTRB(16, 0, 0, 0),
            MenuAnchor() => const EdgeInsets.fromLTRB(16, 0, 12, 0),
            _ => const EdgeInsets.fromLTRB(16, 0, 16, 0),
          },
      trailing: trailing,
      titleTextStyle: titleTextStyle,
      dense: dense,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: onTap != null,
      selected: selected ?? false,
      selectedTileColor: colorScheme.primaryContainer,
    );
  }
}
