import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/features/ml_models/blocs/ml_models/ml_models_notifer.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:path/path.dart';

@RoutePage<MlModel>()
class ModelPickerScreen extends ConsumerStatefulWidget {
  const ModelPickerScreen({super.key});

  @override
  ConsumerState<ModelPickerScreen> createState() => _ModelPickerScreenState();
}

class _ModelPickerScreenState extends ConsumerState<ModelPickerScreen> {
  late final MlModelsNotifier _notifier;

  static const _pageSize = 20;

  final _modelsPagingController =
      PagingController<int, MlModel>(firstPageKey: 0);

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Model'),
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
      body: PagedListView(
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
              onTap: () {
                context.router.pop(model);
              },
            );
          },
        ),
      ),
    );
  }
}
