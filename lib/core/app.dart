import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/l10n/l10n.dart';
import 'package:flutter_sholat_ml/modules/home/views/device_list_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DeviceListPage(),
    );
  }
}
