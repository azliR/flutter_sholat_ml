import 'package:auto_route/auto_route.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(page: SplashRoute.page, initial: true),
      AutoRoute(page: DiscoverDeviceRoute.page),
      AutoRoute(page: ManualDeviceConnectRoute.page),
      AutoRoute(page: AuthDeviceRoute.page),
      AutoRoute(page: AuthWithXiaomiAccountRoute.page),
      AutoRoute(
        page: HomeRoute.page,
        children: [
          AutoRoute(page: SavedDevicesPage.page),
          AutoRoute(page: DatasetsPage.page),
          AutoRoute(page: LabsPage.page),
        ],
      ),
      AutoRoute(page: RecordRoute.page),
      AutoRoute(page: PreprocessRoute.page),
      AutoRoute(page: LabRoute.page),
      AutoRoute(page: SettingsRoute.page),
      AutoRoute(page: ModelPickerRoute.page, fullscreenDialog: true),
    ];
  }
}
