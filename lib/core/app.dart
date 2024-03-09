import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.dart';
import 'package:flutter_sholat_ml/l10n/l10n.dart';
import 'package:loader_overlay/loader_overlay.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
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
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.green);

    return GlobalLoaderOverlay(
      useDefaultLoading: false,
      useBackButtonInterceptor: true,
      duration: const Duration(milliseconds: 250),
      reverseDuration: const Duration(milliseconds: 250),
      overlayColor: colorScheme.surface.withOpacity(0.6),
      overlayWidgetBuilder: (_) {
        return const SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(),
          ),
        );
      },
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: colorScheme,
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
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _appRouter.config(),
      ),
    );
  }
}
