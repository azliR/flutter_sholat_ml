import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'filter_form_providers.g.dart';

@riverpod
class ExponentialSmoothingAlpha extends _$ExponentialSmoothingAlpha {
  @override
  double build() => 0;

  void set(double value) => state = value;
}
