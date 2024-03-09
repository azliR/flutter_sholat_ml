import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'settings_state.dart';

final settingsProvider =
    NotifierProvider.autoDispose<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AutoDisposeNotifier<SettingsState> {
  @override
  SettingsState build() {
    return SettingsState.initial();
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }
}
