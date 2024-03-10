import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/features/lab/blocs/lab/lab_notifier.dart';
import 'package:flutter_sholat_ml/features/labs/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/preprocess/blocs/preprocess/preprocess_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

class EndDrawer extends ConsumerStatefulWidget {
  const EndDrawer({
    required this.onModelSelected,
    super.key,
  });

  final void Function(MlModel model) onModelSelected;

  @override
  ConsumerState<EndDrawer> createState() => _EndDrawerState();
}

class _EndDrawerState extends ConsumerState<EndDrawer> {
  late final PreprocessNotifier _notifier;
  LabNotifier? _labNotifier;

  Future<void> _onSelectModel() async {
    final model = await context.router.push<MlModel>(const ModelPickerRoute());
    if (model == null) return;

    _notifier.setModel(model);
  }

  @override
  void initState() {
    _notifier = ref.read(preprocessProvider.notifier);
    final model = ref.read(preprocessProvider).selectedModel;
    if (model != null) {
      _labNotifier = ref.read(labProvider(LabArg(model: model)).notifier);
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    ref.listen(
      preprocessProvider.select((value) => value.selectedModel),
      (previous, model) {
        if (model != null) {
          _labNotifier = ref.read(labProvider(LabArg(model: model)).notifier);
        } else {
          _labNotifier = null;
        }
      },
    );

    final selectedModel =
        ref.watch(preprocessProvider.select((value) => value.selectedModel));

    return Drawer(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: ReverseAnimation(animation),
            child: child,
          );
        },
        child: selectedModel == null ? _buildEmptyPage() : _buildModelPage(),
      ),
    );
  }

  Widget _buildEmptyPage() {
    return IllustrationWidget(
      title: const Text('Model Testing'),
      description: const Text(
        'You can use a trained model to test the model or to fill in labels in this dataset automatically',
      ),
      icon: const Icon(Symbols.model_training_rounded),
      actions: [
        FilledButton.tonal(
          onPressed: _onSelectModel,
          child: const Text('Select Model'),
        ),
      ],
    );
  }

  Widget _buildModelPage() {
    final selectedModel =
        ref.watch(preprocessProvider.select((value) => value.selectedModel!));
    final predictedCategories = ref
        .watch(preprocessProvider.select((value) => value.predictedCategories));
    final recordState =
        ref.watch(preprocessProvider.select((value) => value.recordState));

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            'Model',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        RoundedListTile(
          title: Text(selectedModel.name),
          dense: true,
          trailing: IconButton(
            icon: const Icon(Symbols.close_rounded),
            onPressed: () {
              _notifier.setModel(null);
            },
          ),
          onTap: _onSelectModel,
        ),
        RoundedListTile(
          title: const Text('Change Configurations'),
          leading: const Icon(Symbols.tune_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          filled: false,
          dense: true,
          onTap: () {
            final currentBluetoothDevice =
                ref.read(authDeviceProvider).currentBluetoothDevice;
            final currentServices =
                ref.read(authDeviceProvider).currentServices;

            if (currentBluetoothDevice == null || currentServices == null) {
              showSnackbar(context, 'No connected device found');
              return;
            }

            context.router.push(
              LabRoute(
                device: currentBluetoothDevice,
                services: currentServices,
                onModelChanged: null,
                model: selectedModel,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: FilledButton.tonal(
                onPressed: switch (recordState) {
                  RecordState.ready => _notifier.startPrediction,
                  RecordState.preparing => null,
                  RecordState.recording => null,
                  RecordState.stopping => null,
                },
                child: Text(
                  switch (recordState) {
                    RecordState.ready => 'Start Predicting',
                    RecordState.preparing => 'Preparing...',
                    RecordState.recording => 'Predicting...',
                    RecordState.stopping => 'Stopping...',
                  },
                ),
              ),
            ),
            if (predictedCategories != null && predictedCategories.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _notifier.setPredictions(null),
                label: const Text('Clear Predictions'),
                icon: const Icon(Symbols.delete_rounded),
              ),
          ],
        ),
      ],
    );
  }
}
