part of 'settings_notifier.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.themeMode,
  });

  factory SettingsState.initial() => const SettingsState(
        themeMode: ThemeMode.system,
      );

  final ThemeMode themeMode;
  SettingsState copyWith({
    ThemeMode? themeMode,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  List<Object> get props => [themeMode];
}

sealed class SettingsPresentationState {
  const SettingsPresentationState();
}

final class SettingsInitial extends SettingsPresentationState {
  const SettingsInitial();
}
