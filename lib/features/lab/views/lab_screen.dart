import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/lab/blocs/lab/lab_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';

@RoutePage()
class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({
    required this.path,
    required this.device,
    required this.services,
    super.key,
  });

  final String path;
  final BluetoothDevice device;
  final List<BluetoothService> services;

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends ConsumerState<LabScreen> {
  late final LabNotifier _notifier;

  @override
  void initState() {
    _notifier = ref.read(labProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _notifier.initialise(widget.path, widget.device, widget.services);
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

    final isInitialised =
        ref.watch(labProvider.select((value) => value.isInitialised));
    final predictState =
        ref.watch(labProvider.select((value) => value.predictState));
    final predictResult =
        ref.watch(labProvider.select((value) => value.predictResult));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab'),
      ),
      body: Center(
        child: () {
          if (!isInitialised) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Predict State: $predictState'),
              Text('Predict Result: $predictResult'),
              FilledButton.tonal(
                onPressed: () {
                  _notifier.predict(
                    <double>[
                      -780,
                      -791,
                      -851,
                      -865,
                      -828,
                      -885,
                      -764,
                      -834,
                      -882,
                      -875,
                      -814,
                      -894,
                      -920,
                      -900,
                      -892,
                      -902,
                      -866,
                      -917,
                      -901,
                      -922,
                      -919,
                      -934,
                      -948,
                      -961,
                      -911,
                      -885,
                      -921,
                      -938,
                      -916,
                      -884,
                      -919,
                      -905,
                      -883,
                      -880,
                      -907,
                      -895,
                      -907,
                      -876,
                      -874,
                      -899,
                      3670,
                      3770,
                      3698,
                      3471,
                      3759,
                      3639,
                      3805,
                      3661,
                      3709,
                      3700,
                      3663,
                      3658,
                      3692,
                      3694,
                      3683,
                      3716,
                      3670,
                      3671,
                      3645,
                      3647,
                      3670,
                      3642,
                      3646,
                      3689,
                      3613,
                      3646,
                      3642,
                      3644,
                      3653,
                      3607,
                      3612,
                      3630,
                      3616,
                      3639,
                      3590,
                      3647,
                      3619,
                      3629,
                      3622,
                      3629,
                      -1587,
                      -1634,
                      -1502,
                      -1471,
                      -1460,
                      -1508,
                      -1571,
                      -1525,
                      -1534,
                      -1574,
                      -1555,
                      -1540,
                      -1577,
                      -1565,
                      -1586,
                      -1591,
                      -1600,
                      -1593,
                      -1586,
                      -1582,
                      -1608,
                      -1597,
                      -1626,
                      -1558,
                      -1689,
                      -1637,
                      -1649,
                      -1657,
                      -1655,
                      -1663,
                      -1672,
                      -1662,
                      -1666,
                      -1672,
                      -1699,
                      -1692,
                      -1703,
                      -1676,
                      -1726,
                      -1691,
                    ],
                  );
                },
                child: const Text('Single Predict'),
              ),
              FilledButton.tonal(
                onPressed: switch (predictState) {
                  PredictState.ready => _notifier.startRecording,
                  PredictState.predicting => _notifier.stopRecording,
                  PredictState.preparing => null,
                  PredictState.stopping => null,
                },
                child: Text(
                  switch (predictState) {
                    PredictState.ready => 'Continuous Predict',
                    PredictState.predicting => 'Stop',
                    PredictState.preparing => 'Preparing...',
                    PredictState.stopping => 'Stopping...',
                  },
                ),
              ),
            ],
          );
        }(),
      ),
    );
  }
}
