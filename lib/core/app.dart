import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.dart';
import 'package:flutter_sholat_ml/core/settings/blocs/settings/settings_notifier.dart';
import 'package:flutter_sholat_ml/l10n/l10n.dart';
import 'package:loader_overlay/loader_overlay.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _appRouter = AppRouter();

  @override
  void didChangeDependencies() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness,
        statusBarBrightness: Theme.of(context).brightness,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode =
        ref.watch(settingsProvider.select((value) => value.themeMode));

    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    );

    final lightTheme = _generateThemeData(
      colorScheme: colorScheme,
      brightness: Brightness.light,
    );

    final darkTheme = _generateThemeData(
      colorScheme: darkColorScheme,
      brightness: Brightness.dark,
    );

    final currentBrightness = Theme.of(context).brightness;

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: lightTheme,
      darkTheme: darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _appRouter.config(),
      builder: (context, child) {
        return LoaderOverlay(
          useDefaultLoading: false,
          useBackButtonInterceptor: true,
          duration: const Duration(milliseconds: 250),
          reverseDuration: const Duration(milliseconds: 250),
          overlayColor: switch (currentBrightness) {
            Brightness.dark => darkColorScheme.surface.withOpacity(0.5),
            Brightness.light => colorScheme.surface.withOpacity(0.5),
          },
          overlayWidgetBuilder: (_) {
            return const SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(),
              ),
            );
          },
          child: child!,
        );
      },
    );
  }

  ThemeData _generateThemeData({
    required ColorScheme colorScheme,
    required Brightness brightness,
  }) {
    final themeData = switch (brightness) {
      Brightness.dark => ThemeData.dark(),
      Brightness.light => ThemeData.light(),
    };

    return themeData.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: MenuItemButton.styleFrom(
          minimumSize: const Size(160, 56),
          padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
        ),
      ),
    );
  }
}
