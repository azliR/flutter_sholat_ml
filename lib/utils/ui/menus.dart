import 'package:flutter/widgets.dart';

RelativeRect determineMenuPosition(BuildContext context) {
  const offs = Offset.zero;
  final button = context.findRenderObject()! as RenderBox;
  final overlay =
      Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
  return RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(offs, ancestor: overlay),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero) + offs,
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );
}
