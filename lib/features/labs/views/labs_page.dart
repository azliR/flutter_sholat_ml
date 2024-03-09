import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/features/labs/blocs/labs/labs_notifer.dart';
import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' hide context;

@RoutePage()
class LabsPage extends ConsumerStatefulWidget {
  const LabsPage({super.key});

  @override
  ConsumerState<LabsPage> createState() => _LabsPageState();
}

class _LabsPageState extends ConsumerState<LabsPage> {
  late final LabsNotifier _notifier;

  static const _pageSize = 20;

  final _mlModelsPagingController =
      PagingController<int, MlModel>(firstPageKey: 0);
  final _mlModelsRefreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _fetchLocalMlModelsPage(int pageKey) async {
    final (failure, mlModelMlModels) =
        await _notifier.getLocalMlModels(pageKey, _pageSize);

    if (failure != null) {
      _mlModelsPagingController.error = failure.error;
      return;
    }

    final isLastPage = mlModelMlModels!.length < _pageSize;
    if (isLastPage) {
      _mlModelsPagingController.appendLastPage(mlModelMlModels);
    } else {
      final nextPageKey = pageKey + mlModelMlModels.length;
      _mlModelsPagingController.appendPage(mlModelMlModels, nextPageKey);
    }
  }

  @override
  void initState() {
    _notifier = ref.read(labsProvider.notifier);

    _mlModelsPagingController.addPageRequestListener(_fetchLocalMlModelsPage);
    super.initState();
  }

  @override
  void dispose() {
    _mlModelsPagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      labsProvider.select((value) => value.presentationState),
      (previous, presentationState) async {
        switch (presentationState) {
          case LabsInitialState():
            break;
          case PickModelLoadingState():
            context.loaderOverlay.show();
          case PickModelSuccessState():
            context.loaderOverlay.hide();

            final currentBluetoothDevice =
                ref.read(authDeviceProvider).currentBluetoothDevice;
            final currentServices =
                ref.read(authDeviceProvider).currentServices;

            if (currentBluetoothDevice == null || currentServices == null) {
              showSnackbar(context, 'No connected device found');
              return;
            }

            await context.router.push(
              LabRoute(
                model: presentationState.model,
                device: currentBluetoothDevice,
                services: currentServices,
                onModelChanged: (model) {
                  final index = _mlModelsPagingController.itemList!
                      .indexWhere((e) => e.id == model.id);
                  _mlModelsPagingController.itemList![index] = model;
                  _mlModelsPagingController.notifyListeners();
                },
              ),
            );

            _mlModelsPagingController.refresh();
          case PickModelFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, presentationState.failure.message);
          case DeleteMlModelLoadingState():
            context.loaderOverlay.show();
          case DeleteMlModelSuccessState():
            context.loaderOverlay.hide();
            _mlModelsPagingController.itemList?.removeWhere(
              (mlModel) => presentationState.mlModels.contains(mlModel),
            );
            _mlModelsPagingController.notifyListeners();
          case DeleteMlModelFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, presentationState.failure.message);
        }
      },
    );

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar.large(
          title: const Text('Labs'),
          actions: [
            _buildAppBarMenu(),
            const SizedBox(width: 8),
          ],
        ),
      ],
      body: RefreshIndicator(
        key: _mlModelsRefreshKey,
        onRefresh: () async {
          _mlModelsPagingController.refresh();
          return Future.delayed(const Duration(seconds: 1), () => null);
        },
        child: PagedListView(
          pagingController: _mlModelsPagingController,
          padding: EdgeInsets.zero,
          builderDelegate: PagedChildBuilderDelegate<MlModel>(
            noItemsFoundIndicatorBuilder: (context) {
              return const IllustrationWidget(
                title: Text('No models, yet'),
                description: Text('Add a model to start experimenting! 🧪'),
                icon: Icon(
                  Symbols.model_training_rounded,
                ),
              );
            },
            itemBuilder: (context, model, index) {
              return RoundedListTile(
                leading: Text(extension(model.path).substring(1).toUpperCase()),
                title: Text(model.name ?? _formatDateTime(model.createdAt)),
                trailing: _buildMenu(model),
                onTap: () {
                  final currentBluetoothDevice =
                      ref.read(authDeviceProvider).currentBluetoothDevice;
                  final currentServices =
                      ref.read(authDeviceProvider).currentServices;

                  context.router.push(
                    LabRoute(
                      model: model,
                      device: currentBluetoothDevice,
                      services: currentServices,
                      onModelChanged: (model) {
                        _mlModelsPagingController.itemList![index] = model;
                        _mlModelsPagingController.notifyListeners();
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(MlModel mlModel) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          iconSize: 20,
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: child!,
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Symbols.delete_rounded),
          onPressed: () => _notifier.deleteMlModels([mlModel]),
          child: const Text('Delete'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat("EEEE 'at' HH:mm").format(dateTime);
  }

  Widget _buildAppBarMenu() {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: child!,
        );
      },
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Symbols.settings_rounded),
          onPressed: () => context.router.push(const SettingsRoute()),
          child: const Text('Settings'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}
