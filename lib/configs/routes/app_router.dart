import 'package:auto_route/auto_route.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: SplashRoute.page, initial: true),
        AutoRoute(page: DiscoverDeviceRoute.page),
        AutoRoute(page: AuthDeviceRoute.page),
        AutoRoute(
          page: HomeRoute.page,
          children: [
            AutoRoute(page: SavedDevicesRoute.page),
            AutoRoute(page: DatasetsRoute.page),
          ],
        ),
        AutoRoute(page: RecordRoute.page),
      ];
}
