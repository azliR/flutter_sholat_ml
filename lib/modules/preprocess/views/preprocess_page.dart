import 'package:flutter/material.dart';

class PreprocessPage extends StatelessWidget {
  const PreprocessPage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preprocess'),
      ),
      body: const Center(
        child: Text('Preprocess'),
      ),
    );
  }
}
