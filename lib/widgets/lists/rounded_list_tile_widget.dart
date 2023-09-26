import 'package:flutter/material.dart';

class RoundedListTile extends StatelessWidget {
  const RoundedListTile({
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.tileColor,
    this.padding,
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
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final bool? selected;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        tileColor: tileColor ?? colorScheme.surfaceVariant,
        title: title,
        subtitle: subtitle,
        leading: leading,
        contentPadding: contentPadding ??
            ((trailing is Icon || trailing is IconButton)
                ? const EdgeInsets.fromLTRB(16, 0, 8, 0)
                : const EdgeInsets.fromLTRB(16, 0, 16, 0)),
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
        enabled: onTap != null,
        selected: selected ?? false,
        selectedTileColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
