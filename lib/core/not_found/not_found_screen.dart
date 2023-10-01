import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: IllustrationWidget(type: IllustrationWidgetType.notFound),
    );
  }
}
