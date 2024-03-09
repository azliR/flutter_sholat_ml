import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/dimens.dart';
import 'package:flutter_sholat_ml/features/lab/blocs/lab/lab_notifier.dart';
import 'package:flutter_sholat_ml/features/lab/models/ml_model_config/ml_model_config.dart';
import 'package:flutter_sholat_ml/features/lab/widgets/bottom_panel_widget.dart';
import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_sholat_ml/widgets/banners/rounded_banner_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:multi_split_view/multi_split_view.dart';

@RoutePage()
class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({
    required this.mlModel,
    required this.device,
    required this.services,
    super.key,
  });

  final MlModel mlModel;
  final BluetoothDevice? device;
  final List<BluetoothService>? services;

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends ConsumerState<LabScreen> {
  late final LabNotifier _notifier;

  late final MultiSplitViewController _mainSplitController;

  List<Area> _resetViews(List<Area> areas) {
    return areas
        .map(
          (area) => Area(
            minimalSize: area.minimalSize,
            minimalWeight: area.minimalWeight,
            weight: 0.2,
          ),
        )
        .toList();
  }

  @override
  void initState() {
    _notifier = ref.read(labProvider.notifier);

    final mainWeights = LocalStorageService.getLabSplitView1Weights();
    _mainSplitController = MultiSplitViewController(
      areas: [
        Area(minimalWeight: 0.6, weight: mainWeights.elementAtOrNull(0)),
        Area(minimalWeight: 0.1, weight: mainWeights.elementAtOrNull(1)),
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (widget.device == null || widget.services == null) {
        return;
      }
      _notifier.initialise(widget.mlModel, widget.device!, widget.services!);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      labProvider.select((value) => value.presentationState),
      (previous, presentationState) async {
        switch (presentationState) {
          case LabInitialState():
            break;
          case PredictFailureState():
            showErrorSnackbar(context, presentationState.failure.message);
          case PredictSuccessState():
            showSnackbar(context, 'Success predicting');
        }
      },
    );

    final showBottomPanel =
        ref.watch(labProvider.select((value) => value.showBottomPanel));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Lab'),
        actions: [
          _buildMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: MultiSplitView(
        controller: _mainSplitController,
        axis: Axis.vertical,
        dividerBuilder: _buildSplitDivider,
        onWeightChange: () {
          final weights = _mainSplitController.areas
              .map((area) => area.weight ?? 1)
              .toList();
          LocalStorageService.setLabSplitView1Weights(weights);
        },
        children: [
          _buildMain(),
          if (showBottomPanel)
            Consumer(
              builder: (context, ref, child) {
                return BottomPanel(
                  logs: ref.watch(labProvider.select((value) => value.logs)),
                  onClosePressed: () =>
                      _notifier.setShowBottomPanel(enable: false),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMain() {
    final isInitialised =
        ref.watch(labProvider.select((value) => value.isInitialised));
    final recordState =
        ref.watch(labProvider.select((value) => value.recordState));
    final predictedCategory =
        ref.watch(labProvider.select((value) => value.predictedCategory));

    final modelConfig =
        ref.read(labProvider.select((value) => value.modelConfig));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, Dimens.bottomListPadding),
      children: [
        if (!isInitialised)
          const RoundedBanner(
            type: BannerType.warning,
            title: Text('Your are disconnected'),
            description: Text('Connect to a device to start experimenting!'),
          ),
        // const SizedBox(
        //   height: 200,
        //   child: AccelerometerChart(),
        // ),
        const SizedBox(height: 24),
        DropdownMenu<InputDataType>(
          initialSelection: modelConfig.inputDataType,
          enabled: recordState == RecordState.ready,
          onSelected: (value) => _notifier
              .setModelConfig(modelConfig.copyWith(inputDataType: value)),
          enableSearch: false,
          label: const Text('Input Data Type'),
          expandedInsets: EdgeInsets.zero,
          dropdownMenuEntries: InputDataType.values.map((inputDataType) {
            return DropdownMenuEntry(
              value: inputDataType,
              label: inputDataType.name,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                initialValue: modelConfig.batchSize.toString(),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Batch Size',
                ),
                validator: _batchSizeValidator,
                enabled: recordState == RecordState.ready,
                onChanged: (value) {
                  if (_batchSizeValidator(value) != null) return;

                  _notifier.setModelConfig(
                    modelConfig.copyWith(batchSize: int.parse(value)),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                initialValue: modelConfig.windowSize.toString(),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Window Size',
                ),
                validator: _windowSizeValidator,
                enabled: recordState == RecordState.ready,
                onChanged: (value) {
                  if (_windowSizeValidator(value) != null) return;

                  _notifier.setModelConfig(
                    modelConfig.copyWith(windowSize: int.parse(value)),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                initialValue: modelConfig.numberOfFeatures.toString(),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Features',
                ),
                validator: _numberOfFeaturesValidator,
                enabled: recordState == RecordState.ready,
                onChanged: (value) {
                  if (_numberOfFeaturesValidator(value) != null) return;

                  _notifier.setModelConfig(
                    modelConfig.copyWith(numberOfFeatures: int.parse(value)),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final enableTeacherForcing = ref.watch(
              labProvider
                  .select((value) => value.modelConfig.enableTeacherForcing),
            );

            return Card.filled(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                title: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Enable Teacher Forcing'),
                ),
                value: enableTeacherForcing,
                onChanged: (value) => _notifier.setModelConfig(
                  modelConfig.copyWith(enableTeacherForcing: value),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: const Text('Advanced options'),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            collapsedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
            children: [
              const Divider(height: 1),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final selectedFilters = ref.watch(
                    labProvider.select((value) => value.modelConfig.smoothings),
                  );

                  return FilterList(
                    title: const Text('Smoothing'),
                    selectedFilters: selectedFilters,
                    filters: Smoothing.values,
                    filterNameBuilder: (filter) => filter.name,
                    onSelected: (filter, selected) {
                      final modelConfig = ref.read(
                          labProvider.select((value) => value.modelConfig));

                      _notifier.setModelConfig(
                        modelConfig.copyWith(
                          smoothings: selected
                              ? {...selectedFilters, filter}
                              : selectedFilters
                                  .where((e) => e != filter)
                                  .toSet(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final selectedFilters = ref.watch(
                    labProvider.select((value) => value.modelConfig.filterings),
                  );

                  return FilterList(
                    title: const Text('Filtering'),
                    selectedFilters: selectedFilters,
                    filters: Filtering.values,
                    filterNameBuilder: (filter) => filter.name,
                    onSelected: (filter, selected) {
                      final modelConfig = ref.read(
                          labProvider.select((value) => value.modelConfig));

                      _notifier.setModelConfig(
                        modelConfig.copyWith(
                          filterings: selected
                              ? {...selectedFilters, filter}
                              : selectedFilters
                                  .where((e) => e != filter)
                                  .toSet(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              Consumer(
                builder: (context, ref, child) {
                  final selectedFilters = ref.watch(
                    labProvider.select(
                      (value) =>
                          value.modelConfig.temporalConsistencyEnforcements,
                    ),
                  );

                  return FilterList(
                    title: const Text('Temporal Consistency Enforcement'),
                    selectedFilters: selectedFilters,
                    filters: TemporalConsistencyEnforcement.values,
                    filterNameBuilder: (filter) => filter.name,
                    onSelected: (filter, selected) {
                      final modelConfig = ref.read(
                          labProvider.select((value) => value.modelConfig));

                      _notifier.setModelConfig(
                        modelConfig.copyWith(
                          temporalConsistencyEnforcements: selected
                              ? {...selectedFilters, filter}
                              : selectedFilters
                                  .where((e) => e != filter)
                                  .toSet(),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Predict State: ${recordState.name}',
          textAlign: TextAlign.center,
        ),
        Text(
          'Predict Result: ${predictedCategory?.name}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: isInitialised
                ? () {
                    _notifier.singlePredict(
                      [
                        -530.0,
                        2711.0,
                        -2994.0,
                        -646.0,
                        2931.0,
                        -3022.0,
                        -591.0,
                        2810.0,
                        -2933.0,
                        -484.0,
                        2713.0,
                        -2895.0,
                        -466.0,
                        2673.0,
                        -2926.0,
                        -557.0,
                        2581.0,
                        -2970.0,
                        -583.0,
                        2651.0,
                        -3092.0,
                        -534.0,
                        2752.0,
                        -2918.0,
                        -739.0,
                        2966.0,
                        -3189.0,
                        -510.0,
                        2772.0,
                        -2898.0,
                        -464.0,
                        2767.0,
                        -2950.0,
                        -484.0,
                        2536.0,
                        -2863.0,
                        -634.0,
                        2722.0,
                        -3050.0,
                        -580.0,
                        2883.0,
                        -2883.0,
                        -565.0,
                        3108.0,
                        -2793.0,
                        -387.0,
                        3006.0,
                        -2689.0,
                        -363.0,
                        3416.0,
                        -2491.0,
                        -185.0,
                        3420.0,
                        -2322.0,
                        -104.0,
                        3319.0,
                        -2376.0,
                        -257.0,
                        3605.0,
                        -2310.0,
                        -223.0,
                        3552.0,
                        -2156.0,
                        -230.0,
                        3840.0,
                        -2184.0,
                        -218.0,
                        3889.0,
                        -1990.0,
                        -182.0,
                        4493.0,
                        -1607.0,
                        -162.0,
                        3802.0,
                        -1094.0,
                        -393.0,
                        4546.0,
                        -363.0,
                        -370.0,
                        3528.0,
                        -82.0,
                        -582.0,
                        3900.0,
                        530.0,
                        -811.0,
                        4101.0,
                        1007.0,
                        -923.0,
                        3508.0,
                        1103.0,
                        -1053.0,
                        3668.0,
                        1433.0,
                        -1076.0,
                        3268.0,
                        1303.0,
                        -1363.0,
                        3560.0,
                        1340.0,
                        -1437.0,
                        // 2964.0,
                        // 1925.0,
                        // -1418.0,
                        // 3012.0,
                        // 1814.0,
                        // -1348.0,
                        // 3249.0,
                        // 2123.0,
                        // -1450.0,
                        // 3215.0,
                        // 2619.0,
                        // -1055.0,
                        // 2687.0,
                        // 2566.0,
                        // -943.0,
                        // 2984.0,
                        // 2846.0,
                        // -940.0,
                        // 3101.0,
                        // 3074.0,
                        // -747.0,
                        // 2559.0,
                        // 3062.0
                      ],
                    );
                  }
                : null,
            child: const Text('Single Predict'),
          ),
        ),
        Center(
          child: FilledButton.tonal(
            onPressed: isInitialised
                ? switch (recordState) {
                    RecordState.ready => _notifier.startRecording,
                    RecordState.preparing => null,
                    RecordState.recording => _notifier.stopRecording,
                    RecordState.stopping => null,
                  }
                : null,
            child: Text(
              switch (recordState) {
                RecordState.ready => 'Continuous Predict',
                RecordState.preparing => 'Preparing...',
                RecordState.recording => 'Stop',
                RecordState.stopping => 'Stopping...',
              },
            ),
          ),
        ),
      ],
    );
  }

  String? _batchSizeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    final batchSize = int.tryParse(value);
    if (batchSize == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  String? _windowSizeValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    final windowSize = int.tryParse(value);
    if (windowSize == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  String? _numberOfFeaturesValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a value';
    }
    final numberOfFeatures = int.tryParse(value);
    if (numberOfFeatures == null) {
      return 'Please enter a valid number';
    }
    if (numberOfFeatures > ref.read(labProvider).modelConfig.windowSize) {
      return 'Window step must be less than window size';
    }
    return null;
  }

  Widget _buildSplitDivider(
    Axis axis,
    int index,
    bool resizable,
    bool dragging,
    bool highlighted,
    MultiSplitViewThemeData themeData,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(
          horizontal: axis == Axis.vertical ? 4 : 0,
          vertical: axis == Axis.horizontal ? 4 : 0,
        ),
        color: highlighted ? colorScheme.outline : Colors.transparent,
        child: axis == Axis.vertical
            ? VerticalDivider(color: colorScheme.outline)
            : Divider(color: colorScheme.outline),
      ),
    );
  }

  Widget _buildMenu() {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          iconSize: 20,
          tooltip: 'Menu',
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
        SubmenuButton(
          menuChildren: [
            Consumer(
              builder: (context, ref, child) {
                final isShowBottomPanel = ref.watch(
                  labProvider.select((value) => value.showBottomPanel),
                );
                return MenuItemButton(
                  leadingIcon: isShowBottomPanel
                      ? const Icon(Symbols.check_box_rounded, fill: 1)
                      : const Icon(Symbols.check_box_outline_blank_rounded),
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.backquote,
                    control: true,
                  ),
                  onPressed: () =>
                      _notifier.setShowBottomPanel(enable: !isShowBottomPanel),
                  child: const Text('Logs'),
                );
              },
            ),
            MenuItemButton(
              leadingIcon: const Icon(Symbols.reset_wrench_rounded),
              onPressed: () {
                _mainSplitController.areas =
                    _resetViews(_mainSplitController.areas);
              },
              child: const Text('Reset view'),
            ),
          ],
          child: const Text('View'),
        ),
      ],
      child: const Icon(Symbols.more_vert_rounded),
    );
  }
}

class FilterList<T extends Enum> extends StatelessWidget {
  const FilterList({
    required this.title,
    required this.selectedFilters,
    required this.filters,
    required this.filterNameBuilder,
    required this.onSelected,
    super.key,
  });

  final Widget title;
  final Set<T> selectedFilters;
  final List<T> filters;
  final String Function(T filter) filterNameBuilder;
  final void Function(T filter, bool selected) onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DefaultTextStyle(
            style: textTheme.bodyMedium!,
            child: title,
          ),
        ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];

              return FilterChip(
                label: Text(filterNameBuilder(filter)),
                labelStyle: textTheme.labelMedium,
                selected: selectedFilters.contains(filter),
                onSelected: (value) => onSelected(filter, value),
              );
            },
          ),
        ),
      ],
    );
  }
}
