import 'package:animations/animations.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/configs/routes/app_router.gr.dart';
import 'package:flutter_sholat_ml/core/auth_device/blocs/auth_device/auth_device_notifier.dart';
import 'package:flutter_sholat_ml/core/not_found/illustration_widget.dart';
import 'package:flutter_sholat_ml/features/ml_models/models/ml_model/ml_model.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/dataset/dataset_provider.dart';
import 'package:flutter_sholat_ml/features/preprocess/providers/ml_model/ml_model_provider.dart';
import 'package:flutter_sholat_ml/widgets/lists/rounded_list_tile_widget.dart';
import 'package:material_symbols_icons/symbols.dart';

class EndDrawer extends ConsumerStatefulWidget {
  const EndDrawer({
    super.key,
  });

  @override
  ConsumerState<EndDrawer> createState() => _EndDrawerState();
}

class _EndDrawerState extends ConsumerState<EndDrawer> {
  // late final PreprocessNotifier _notifier;

  Future<void> _onSelectModel() async {
    final model = await context.router.push<MlModel>(const ModelPickerRoute());
    if (model == null) return;

    ref.read(selectedMlModelProvider.notifier).setModel(model);
  }

  @override
  void initState() {
    // _notifier = ref.read(preprocessProvider.notifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedModel = ref.watch(selectedMlModelProvider);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: ReverseAnimation(animation),
            fillColor: Colors.transparent,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final selectedModel = ref.watch(selectedMlModelProvider)!;
    final predictedCategories = ref.watch(predictedCategoriesProvider);
    final evaluationAsync = ref.watch(modelEvaluationProvider);
    final enablePredictedPreview = ref.watch(enablePredictedPreviewProvider);
    final selectedFilterLength = selectedModel.config.smoothings.length +
        selectedModel.config.filterings.length +
        selectedModel.config.temporalConsistencyEnforcements.length;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8 + MediaQuery.paddingOf(context).top,
        16,
        24,
      ),
      children: [
        Text(
          'Model',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        RoundedListTile(
          title: Text(selectedModel.name),
          dense: true,
          margin: const EdgeInsets.symmetric(vertical: 4),
          trailing: IconButton(
            icon: const Icon(Symbols.close_rounded),
            onPressed: () =>
                ref.read(selectedMlModelProvider.notifier).setModel(null),
          ),
          onTap: _onSelectModel,
        ),
        RoundedListTile(
          title: Row(
            children: [
              const Text('Configurations'),
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
          ),
          leading: const Icon(Symbols.tune_rounded),
          trailing: const Icon(Symbols.chevron_right_rounded),
          filled: false,
          dense: true,
          margin: const EdgeInsets.symmetric(vertical: 4),
          onTap: () {
            final currentBluetoothDevice =
                ref.read(authDeviceProvider).currentBluetoothDevice;
            final currentServices =
                ref.read(authDeviceProvider).currentServices;

            context.router.push(
              MlModelRoute(
                device: currentBluetoothDevice,
                services: currentServices,
                onModelChanged: null,
                model: selectedModel,
              ),
            );
          },
        ),
        evaluationAsync.when(
          data: (data) {
            if (data == null) return const SizedBox();

            final accuracy = data * 100;
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${accuracy.toStringAsFixed(2)}%',
                    textAlign: TextAlign.center,
                    style: textTheme.displaySmall,
                  ),
                  Text(
                    'Accuracy',
                    style: textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          },
          error: (error, stackTrace) => Text(error.toString()),
          loading: () => const SizedBox(),
        ),
        const SizedBox(height: 24),
        FilledButton.tonal(
          onPressed: predictedCategories.maybeWhen(
            loading: () => null,
            orElse: () => () => ref
                .read(predictedCategoriesProvider.notifier)
                .startPrediction(),
          ),
          child: Text(
            predictedCategories.maybeWhen(
              loading: () => 'Predicting...',
              orElse: () => 'Start Prediction',
            ),
          ),
        ),
        if (predictedCategories.valueOrNull != null) ...[
          OutlinedButton.icon(
            onPressed: () {
              ref
                  .read(enablePredictedPreviewProvider.notifier)
                  .setEnable(!enablePredictedPreview);
              Navigator.pop(context);
            },
            label: Text(enablePredictedPreview ? 'Remove preview' : 'Preview'),
            icon: enablePredictedPreview
                ? const Icon(Symbols.visibility_off_rounded)
                : const Icon(Symbols.visibility_rounded),
          ),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(predictedCategoriesProvider.notifier).clearPrediction();
              Navigator.pop(context);
            },
            label: const Text('Clear Predictions'),
            icon: const Icon(Symbols.delete_rounded),
          ),
        ],
      ],
    );
  }
}
