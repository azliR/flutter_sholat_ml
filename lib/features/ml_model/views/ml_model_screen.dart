import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/constants/dimens.dart';
import 'package:flutter_sholat_ml/features/ml_model/blocs/ml_model/ml_model_notifier.dart';
import 'package:flutter_sholat_ml/features/ml_model/widgets/bottom_panel_widget.dart';
import 'package:flutter_sholat_ml/features/ml_model/widgets/filter_list_widget.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model_config.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/post_processing/temporal_consistency_enforcements.dart';
import 'package:flutter_sholat_ml/utils/services/local_storage_service.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_sholat_ml/widgets/banners/rounded_banner_widget.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:multi_split_view/multi_split_view.dart';

@RoutePage()
class MlModelScreen extends ConsumerStatefulWidget {
  const MlModelScreen({
    required this.model,
    required this.device,
    required this.services,
    required this.onModelChanged,
    super.key,
  });

  final MlModel model;
  final BluetoothDevice? device;
  final List<BluetoothService>? services;
  final void Function(MlModel model)? onModelChanged;

  @override
  ConsumerState<MlModelScreen> createState() => _MlModelScreenState();
}

class _MlModelScreenState extends ConsumerState<MlModelScreen> {
  late final MlModelNotifier _notifier;
  late final ProviderListenable<MlModelState> mlModelProviderFamily;

  late final MultiSplitViewController _mainSplitController;

  final _modelNameController = TextEditingController();

  var _editNameMode = false;

  void _onEditModelNameDone() {
    if (_modelNameController.text.isEmpty) return;

    final model = ref.read(mlModelProviderFamily).model;
    _notifier.setModel(
      model.copyWith(name: _modelNameController.text),
    );

    setState(() => _editNameMode = false);
  }

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
    _notifier =
        ref.read(mlModelProvider(MlModelArg(model: widget.model)).notifier);
    mlModelProviderFamily = mlModelProvider(MlModelArg(model: widget.model));

    final mainWeights = LocalStorageService.getMlModelSplitView1Weights();
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
      _notifier.initialise(widget.model, widget.device!, widget.services!);
    });
    super.initState();
  }

  @override
  void dispose() {
    _mainSplitController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(
        mlModelProviderFamily.select((value) => value.presentationState),
        (previous, presentationState) async {
          switch (presentationState) {
            case MlModelInitialState():
              break;
            case PredictFailureState():
              showErrorSnackbar(context, presentationState.failure.message);
            case PredictSuccessState():
              showSnackbar(context, 'Success predicting');
          }
        },
      )
      ..listen(
        mlModelProviderFamily.select((value) => value.model),
        (previous, model) {
          widget.onModelChanged?.call(model);
        },
      );

    final showBottomPanel = ref
        .watch(mlModelProviderFamily.select((value) => value.showBottomPanel));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        if (_editNameMode) {
          setState(() => _editNameMode = false);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: _editNameMode ? _buildEditModelNameField() : _buildAppBar(),
          actions: [
            if (!_editNameMode) ...[
              _buildMenu(),
              const SizedBox(width: 8),
            ],
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
            LocalStorageService.setMlModelSplitView1Weights(weights);
          },
          children: [
            _buildMain(),
            if (showBottomPanel)
              Consumer(
                builder: (context, ref, child) {
                  return BottomPanel(
                    logs: ref.watch(
                      mlModelProviderFamily.select((value) => value.logs),
                    ),
                    onClosePressed: () =>
                        _notifier.setShowBottomPanel(enable: false),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditModelNameField() {
    return Row(
      children: [
        Flexible(
          child: TextField(
            controller: _modelNameController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.text,
            onSubmitted: (value) => _onEditModelNameDone(),
            decoration: const InputDecoration(
              hintText: 'Input model name',
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _onEditModelNameDone,
          icon: const Icon(Symbols.check_rounded),
        ),
      ],
    );
  }

  InkWell _buildAppBar() {
    return InkWell(
      onTap: () {
        _modelNameController.text = ref.read(
              mlModelProviderFamily.select((value) => value.model.name),
            ) ??
            '';
        setState(() => _editNameMode = true);
      },
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Flexible(
              child: Consumer(
                builder: (context, ref, child) {
                  final modelName = ref.watch(
                    mlModelProviderFamily.select((value) => value.model.name),
                  );
                  return Text(modelName);
                },
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Symbols.edit_rounded,
              size: 16,
              weight: 600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMain() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isInitialised =
        ref.watch(mlModelProviderFamily.select((value) => value.isInitialised));
    final recordState =
        ref.watch(mlModelProviderFamily.select((value) => value.recordState));
    final predictedCategory = ref.watch(
      mlModelProviderFamily.select((value) => value.predictedCategory),
    );

    final modelConfig =
        ref.read(mlModelProviderFamily.select((value) => value.modelConfig));

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
              .setModelConfig(modelConfig.copyWith(inputDataType: value!)),
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
        // Consumer(
        //   builder: (context, ref, child) {
        //     final enableTeacherForcing = ref.watch(
        //       mlModelProviderFamily
        //           .select((value) => value.modelConfig.enableTeacherForcing),
        //     );

        //     return Card.filled(
        //       margin: EdgeInsets.zero,
        //       shape: const RoundedRectangleBorder(
        //         borderRadius: BorderRadius.all(Radius.circular(24)),
        //       ),
        //       clipBehavior: Clip.antiAlias,
        //       child: SwitchListTile(
        //         title: const Padding(
        //           padding: EdgeInsets.symmetric(vertical: 16),
        //           child: Text('Enable Teacher Forcing'),
        //         ),
        //         value: enableTeacherForcing,
        //         onChanged: (value) => _notifier.setModelConfig(
        //           modelConfig.copyWith(enableTeacherForcing: value),
        //         ),
        //       ),
        //     );
        //   },
        // ),
        const SizedBox(height: 16),
        ExpansionTile(
          title: Consumer(
            builder: (context, ref, child) {
              final selectedFilterLength = ref.watch(
                mlModelProviderFamily.select(
                  (value) =>
                      // value.modelConfig.smoothings.length +
                      // value.modelConfig.filterings.length +
                      value.modelConfig.temporalConsistencyEnforcements.length,
                  // value.modelConfig.weightings.length,
                ),
              );
              return Row(
                children: [
                  const Flexible(
                    child: Text('Post Processing'),
                  ),
                  if (selectedFilterLength > 0)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        selectedFilterLength.toString(),
                        style: textTheme.labelMedium
                            ?.copyWith(color: colorScheme.onSecondary),
                      ),
                    ),
                ],
              );
            },
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24)),
          ),
          backgroundColor: colorScheme.surfaceContainerHighest,
          collapsedShape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: colorScheme.outline),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            // Consumer(
            //   builder: (context, ref, child) {
            //     final selectedFilters = ref.watch(
            //       mlModelProviderFamily
            //           .select((value) => value.modelConfig.smoothings),
            //     );

            //     return FilterList<String>(
            //       title: const Text('Smoothing'),
            //       selectedFilters:
            //           selectedFilters.map((filter) => filter.name).toSet(),
            //       filters: Smoothing.values,
            //       filterNameBuilder: (filter) {
            //         final smoothing = selectedFilters.firstWhere(
            //           (e) => e.name == filter,
            //           orElse: () => Smoothing.fromName(filter),
            //         );

            //         switch (smoothing) {
            //           case MovingAverage():
            //             return smoothing.name;
            //           // case ExponentialSmoothing():
            //           //   if (smoothing.alpha == null) {
            //           //     return smoothing.name;
            //           //   }
            //           //   return '${smoothing.name} (${smoothing.alpha})';
            //         }
            //       },
            //       onSelected: recordState != RecordState.ready
            //           ? null
            //           : (filter, selected) async {
            //               final modelConfig = ref.read(
            //                 mlModelProviderFamily
            //                     .select((value) => value.modelConfig),
            //               );

            //               // if (filter == 'Exponential Smoothing' && selected) {
            //               //   final result = await showDialog<double?>(
            //               //     context: context,
            //               //     builder: (context) {
            //               //       return const _SliderDialog(
            //               //         title: 'Set alpha',
            //               //       );
            //               //     },
            //               //   );
            //               //   if (result == null) return;

            //               //   _notifier.setModelConfig(
            //               //     modelConfig.copyWith(
            //               //       smoothings: {
            //               //         ...selectedFilters,
            //               //         ExponentialSmoothing(alpha: result),
            //               //       },
            //               //     ),
            //               //   );
            //               //   return;
            //               // }

            //               _notifier.setModelConfig(
            //                 modelConfig.copyWith(
            //                   smoothings: selected
            //                       ? {
            //                           ...selectedFilters,
            //                           Smoothing.fromName(filter),
            //                         }
            //                       : selectedFilters
            //                           .where((e) => e.name != filter)
            //                           .toSet(),
            //                 ),
            //               );
            //             },
            //     );
            //   },
            // ),
            // const SizedBox(height: 8),
            // Consumer(
            //   builder: (context, ref, child) {
            //     final selectedFilters = ref.watch(
            //       mlModelProviderFamily
            //           .select((value) => value.modelConfig.filterings),
            //     );

            //     return FilterList<String>(
            //       title: const Text('Filtering'),
            //       selectedFilters: selectedFilters.map((e) => e.name).toSet(),
            //       filters: Filtering.values,
            //       filterNameBuilder: (filter) {
            //         final filtering = selectedFilters.firstWhere(
            //           (e) => e.name == filter,
            //           orElse: () => Filtering.fromName(filter),
            //         );

            //         switch (filtering) {
            //           case MedianFilter():
            //             return filtering.name;
            //           // case LowPassFilter():
            //           //   if (filtering.alpha == null) {
            //           //     return filtering.name;
            //           //   }
            //           //   return '${filtering.name} (${filtering.alpha})';
            //         }
            //       },
            //       onSelected: recordState != RecordState.ready
            //           ? null
            //           : (filter, selected) async {
            //               final modelConfig = ref.read(
            //                 mlModelProviderFamily
            //                     .select((value) => value.modelConfig),
            //               );

            //               // if (filter == 'Low Pass Filter' && selected) {
            //               //   final result = await showDialog<double?>(
            //               //     context: context,
            //               //     builder: (context) {
            //               //       return const _SliderDialog(
            //               //         title: 'Set alpha',
            //               //       );
            //               //     },
            //               //   );
            //               //   if (result == null) return;

            //               //   _notifier.setModelConfig(
            //               //     modelConfig.copyWith(
            //               //       filterings: {
            //               //         ...selectedFilters,
            //               //         LowPassFilter(alpha: result),
            //               //       },
            //               //     ),
            //               //   );
            //               //   return;
            //               // }

            //               _notifier.setModelConfig(
            //                 modelConfig.copyWith(
            //                   filterings: selected
            //                       ? {
            //                           ...selectedFilters,
            //                           Filtering.fromName(filter),
            //                         }
            //                       : selectedFilters
            //                           .where((e) => e.name != filter)
            //                           .toSet(),
            //                 ),
            //               );
            //             },
            //     );
            //   },
            // ),
            // const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final selectedFilters = ref.watch(
                  mlModelProviderFamily.select(
                    (value) =>
                        value.modelConfig.temporalConsistencyEnforcements,
                  ),
                );

                return FilterList<String>(
                  title: const Text('Temporal Consistency Enforcement'),
                  selectedFilters: selectedFilters.map((e) => e.name).toSet(),
                  filters: TemporalConsistencyEnforcement.values,
                  filterNameBuilder: (filter) {
                    final tce = selectedFilters.firstWhere(
                      (e) => e.name == filter,
                      orElse: () =>
                          TemporalConsistencyEnforcement.fromName(filter),
                    );

                    switch (tce) {
                      case MajorityVoting():
                        if (tce.minConsecutivePredictions == null) {
                          return tce.name;
                        }
                        return '${tce.name} (${tce.minConsecutivePredictions})';
                      // case TransitionConstraints():
                      //   if (tce.minDuration == null) {
                      //     return tce.name;
                      //   }
                      //   return '${tce.name} (${tce.minDuration})';
                    }
                  },
                  onSelected: recordState != RecordState.ready
                      ? null
                      : (filter, selected) async {
                          final modelConfig = ref.read(
                            mlModelProviderFamily
                                .select((value) => value.modelConfig),
                          );

                          if (filter == 'Majority Voting' && selected) {
                            final result = await showDialog<int?>(
                              context: context,
                              builder: (context) {
                                return const _NumberFieldDialog(
                                  title: 'Set min consecutive predictions',
                                  initialValue: 3,
                                );
                              },
                            );
                            if (result == null) return;

                            _notifier.setModelConfig(
                              modelConfig.copyWith(
                                temporalConsistencyEnforcements: {
                                  ...selectedFilters,
                                  MajorityVoting(
                                    minConsecutivePredictions: result,
                                  ),
                                },
                              ),
                            );
                            return;
                            // } else if (filter == 'Transition Constraints' &&
                            //     selected) {
                            //   final result = await showDialog<int?>(
                            //     context: context,
                            //     builder: (context) {
                            //       return const _NumberFieldDialog(
                            //         title: 'Set min duration',
                            //         initialValue: 3,
                            //       );
                            //     },
                            //   );
                            //   if (result == null) return;

                            //   _notifier.setModelConfig(
                            //     modelConfig.copyWith(
                            //       temporalConsistencyEnforcements: {
                            //         ...selectedFilters,
                            //         TransitionConstraints(minDuration: result),
                            //       },
                            //     ),
                            //   );
                            //   return;
                          }

                          _notifier.setModelConfig(
                            modelConfig.copyWith(
                              temporalConsistencyEnforcements: selected
                                  ? {
                                      ...selectedFilters,
                                      TemporalConsistencyEnforcement.fromName(
                                        filter,
                                      ),
                                    }
                                  : selectedFilters
                                      .where((e) => e.name != filter)
                                      .toSet(),
                            ),
                          );
                        },
                );
              },
            ),
            const SizedBox(height: 8),
            // Consumer(
            //   builder: (context, ref, child) {
            //     final selectedFilters = ref.watch(
            //       mlModelProviderFamily
            //           .select((value) => value.modelConfig.weightings),
            //     );

            //     return FilterList<String>(
            //       title: const Text('Weighting'),
            //       selectedFilters:
            //           selectedFilters.map((filter) => filter.name).toSet(),
            //       filters: Weighting.values,
            //       filterNameBuilder: (filter) {
            //         final weighting = selectedFilters.firstWhere(
            //           (e) => e.name == filter,
            //           orElse: () => Weighting.fromName(filter),
            //         );

            //         switch (weighting) {
            //           case TransitionWeighting():
            //             if (weighting.weight == null) {
            //               return weighting.name;
            //             }
            //             return '${weighting.name} (${weighting.weight})';
            //         }
            //       },
            //       onSelected: recordState != RecordState.ready
            //           ? null
            //           : (filter, selected) async {
            //               final modelConfig = ref.read(
            //                 mlModelProviderFamily
            //                     .select((value) => value.modelConfig),
            //               );

            //               if (filter == 'Transition Weighting' && selected) {
            //                 final result = await showDialog<double?>(
            //                   context: context,
            //                   builder: (context) {
            //                     return const _SliderDialog(
            //                       title: 'Set weight',
            //                       initialValue: 0.2,
            //                     );
            //                   },
            //                 );
            //                 if (result == null) return;

            //                 _notifier.setModelConfig(
            //                   modelConfig.copyWith(
            //                     weightings: selected
            //                         ? {
            //                             ...selectedFilters,
            //                             TransitionWeighting(weight: result),
            //                           }
            //                         : selectedFilters
            //                             .where((e) => e.name != filter)
            //                             .toSet(),
            //                   ),
            //                 );

            //                 return;
            //               }

            //               _notifier.setModelConfig(
            //                 modelConfig.copyWith(
            //                   weightings: selected
            //                       ? {
            //                           ...selectedFilters,
            //                           Weighting.fromName(filter),
            //                         }
            //                       : selectedFilters
            //                           .where((e) => e.name != filter)
            //                           .toSet(),
            //                 ),
            //               );
            //             },
            //     );
            //   },
            // ),
            const SizedBox(height: 8),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Prediction State: ${recordState.name}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Prediction:',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${predictedCategory?.name}',
              textAlign: TextAlign.center,
              style: textTheme.displaySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                RecordState.ready => 'Start Realtime Prediction',
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
    if (numberOfFeatures >
        ref.read(mlModelProviderFamily).modelConfig.windowSize) {
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
                  mlModelProviderFamily
                      .select((value) => value.showBottomPanel),
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

class _SliderDialog extends StatefulWidget {
  const _SliderDialog({
    required this.title,
    required this.initialValue,
  });

  final String title;
  final double initialValue;

  @override
  State<_SliderDialog> createState() => _SliderDialogState();
}

class _SliderDialogState extends State<_SliderDialog> {
  late double _value;

  @override
  void initState() {
    _value = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            value: _value,
            label: _value.toStringAsFixed(1),
            divisions: 10,
            onChanged: (value) {
              setState(() {
                _value = value;
              });
            },
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () {
            Navigator.of(context).pop(_value);
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}

class _NumberFieldDialog extends StatefulWidget {
  const _NumberFieldDialog({
    required this.title,
    required this.initialValue,
  });

  final String title;
  final int initialValue;

  @override
  State<_NumberFieldDialog> createState() => _NumberFieldDialogState();
}

class _NumberFieldDialogState extends State<_NumberFieldDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    _controller = TextEditingController(text: widget.initialValue.toString());
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                final number = int.tryParse(value);
                if (number == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            Navigator.of(context).pop(int.parse(_controller.text));
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}
