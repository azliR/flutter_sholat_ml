import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/features/ml_models/blocs/ml_models/ml_models_notifer.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart' hide context;

@RoutePage()
class MlModelsPage extends ConsumerStatefulWidget {
  const MlModelsPage({super.key});

  @override
  ConsumerState<MlModelsPage> createState() => _MlModelsPageState();
}

class _MlModelsPageState extends ConsumerState<MlModelsPage> {
  late final MlModelsNotifier _notifier;

  static const _pageSize = 20;

  final _modelsPagingController =
      PagingController<int, MlModel>(firstPageKey: 0);
  final _modelsRefreshKey = GlobalKey<RefreshIndicatorState>();

  Future<void> _fetchLocalMlModelsPage(int pageKey) async {
    final (failure, mlModelMlModels) =
        await _notifier.getLocalMlModels(pageKey, _pageSize);

    if (failure != null) {
      _modelsPagingController.error = failure.error;
      return;
    }

    final isLastPage = mlModelMlModels!.length < _pageSize;
    if (isLastPage) {
      _modelsPagingController.appendLastPage(mlModelMlModels);
    } else {
      final nextPageKey = pageKey + mlModelMlModels.length;
      _modelsPagingController.appendPage(mlModelMlModels, nextPageKey);
    }
  }

  @override
  void initState() {
    _notifier = ref.read(mlModelsProvider.notifier);

    _modelsPagingController.addPageRequestListener(_fetchLocalMlModelsPage);
    super.initState();
  }

  @override
  void dispose() {
    _modelsPagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      mlModelsProvider.select((value) => value.presentationState),
      (previous, presentationState) async {
        switch (presentationState) {
          case MlModelsInitialState():
            break;
          case PickModelLoadingState():
            context.loaderOverlay.show();
          case PickModelSuccessState():
            context.loaderOverlay.hide();

            final currentBluetoothDevice =
                ref.read(authDeviceProvider).currentBluetoothDevice;
            final currentServices =
                ref.read(authDeviceProvider).currentServices;

            await context.router.push(
              MlModelRoute(
                model: presentationState.model,
                device: currentBluetoothDevice,
                services: currentServices,
                onModelChanged: (model) {
                  final index = _modelsPagingController.itemList!
                      .indexWhere((e) => e.id == model.id);
                  _modelsPagingController.itemList![index] = model;
                  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                  _modelsPagingController.notifyListeners();
                },
              ),
            );

            _modelsPagingController.refresh();
          case PickModelFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, presentationState.failure.message);
          case DeleteMlModelLoadingState():
            context.loaderOverlay.show();
          case DeleteMlModelSuccessState():
            context.loaderOverlay.hide();
            _modelsPagingController.itemList?.removeWhere(
              (mlModel) => presentationState.mlModels.contains(mlModel),
            );
            // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
            _modelsPagingController.notifyListeners();
          case DeleteMlModelFailureState():
            context.loaderOverlay.hide();
            showErrorSnackbar(context, presentationState.failure.message);
        }
      },
    );

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar.large(
          title: const Text('Models'),
          actions: [
            _buildAppBarMenu(),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final sortType = ref.watch(
                        mlModelsProvider.select((value) => value.sortType),
                      );

                      return MenuAnchor(
                        builder: (context, controller, child) {
                          return ActionChip(
                            label: Text(sortType.name),
                            avatar: const Icon(Symbols.sort_rounded),
                            onPressed: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                          );
                        },
                        menuChildren: SortType.values.map((sortType) {
                          return MenuItemButton(
                            onPressed: () {
                              _notifier.setSortType(sortType);
                              _modelsPagingController.refresh();
                            },
                            leadingIcon: switch (sortType) {
                              SortType.modelName =>
                                const Icon(Symbols.sort_by_alpha_rounded),
                              SortType.lastUpdated =>
                                const Icon(Symbols.calendar_today_rounded),
                            },
                            child: Text(sortType.name),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final sortDirection = ref.watch(
                        mlModelsProvider.select((value) => value.sortDirection),
                      );

                      return MenuAnchor(
                        builder: (context, controller, child) {
                          return ActionChip(
                            label: Text(sortDirection.name),
                            avatar: const Icon(Symbols.swap_vert_rounded),
                            onPressed: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                          );
                        },
                        menuChildren: SortDirection.values.map((sortDirection) {
                          return MenuItemButton(
                            onPressed: () {
                              _notifier.setSortDirection(sortDirection);
                              _modelsPagingController.refresh();
                            },
                            leadingIcon: switch (sortDirection) {
                              SortDirection.ascending =>
                                const Icon(Symbols.arrow_upward_rounded),
                              SortDirection.descending =>
                                const Icon(Symbols.arrow_downward_rounded),
                            },
                            child: Text(sortDirection.name),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      body: RefreshIndicator(
        key: _modelsRefreshKey,
        onRefresh: () async {
          _modelsPagingController.refresh();
          return Future.delayed(const Duration(seconds: 1), () => null);
        },
        child: PagedListView(
          pagingController: _modelsPagingController,
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
                title: Text(model.name),
                trailing: _buildMenu(model),
                onTap: () {
                  final currentBluetoothDevice =
                      ref.read(authDeviceProvider).currentBluetoothDevice;
                  final currentServices =
                      ref.read(authDeviceProvider).currentServices;

                  context.router.push(
                    MlModelRoute(
                      model: model,
                      device: currentBluetoothDevice,
                      services: currentServices,
                      onModelChanged: (model) {
                        _modelsPagingController.itemList![index] = model;
                        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
                        _modelsPagingController.notifyListeners();
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
