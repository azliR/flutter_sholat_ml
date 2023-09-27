import 'package:auto_route/auto_route.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/record/blocs/record/record_notifier.dart';
import 'package:flutter_sholat_ml/modules/record/widgets/accelerometer_chart_widget.dart';
import 'package:flutter_sholat_ml/modules/record/widgets/record_button_widget.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:wakelock/wakelock.dart';

@RoutePage()
class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({required this.device, required this.services, super.key});

  final BluetoothDevice device;
  final List<BluetoothService> services;

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage>
    with WidgetsBindingObserver {
  late final RecordNotifier _notifier;

  CameraController? _cameraController;

  @override
  void initState() {
    _notifier = ref.read(recordProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      await _notifier.initialise(
        widget.device,
        widget.services,
      );
    });
    Wakelock.enable();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _notifier
          .initialiseCamera(cameraController.description)
          .then((controller) {
        _cameraController = controller;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();

    Wakelock.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final notifier = ref.read(recordProvider.notifier);

    ref.listen(recordProvider, (previous, next) async {
      if (previous?.presentationState != next.presentationState) {
        final presentationState = next.presentationState;
        switch (presentationState) {
          case CameraInitialisationFailureState():
            showErrorSnackbar(context, 'Failed initialising camera');
          case RecordFailureState():
            showErrorSnackbar(context, 'Failed recording');
          case RecordSuccessState():
            showSnackbar(context, 'Success recording');
          case RecordInitialState():
            break;
        }
      } else if (previous?.isCameraPermissionGranted !=
          next.isCameraPermissionGranted) {
        if (next.isCameraPermissionGranted) {
          _cameraController = await notifier.initialiseCamera();
        }
      }
    });

    final isInitialised =
        ref.watch(recordProvider.select((value) => value.isInitialised));
    final isCameraPermissionGranted = ref.watch(
      recordProvider.select((value) => value.isCameraPermissionGranted),
    );
    final cameraState =
        ref.watch(recordProvider.select((value) => value.cameraState));

    return Scaffold(
      backgroundColor: !isCameraPermissionGranted ||
              cameraState == CameraState.notInitialised
          ? colorScheme.surface
          : Colors.black,
      body: SafeArea(
        child: () {
          if (!isInitialised) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!isCameraPermissionGranted) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.videocam_off_rounded,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We need camera permission',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera used to record together with accelerometer so it can be easy to determine what action that it did with accelerometer data.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () async {
                        _cameraController = await notifier.initialiseCamera();
                      },
                      child: const Text('Give permission'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (cameraState == CameraState.notInitialised) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return Stack(
            children: [
              // Positioned(
              //   top: 80,
              //   left: 0,
              //   right: 0,
              //   child: ClipRRect(
              //     borderRadius: const BorderRadius.all(Radius.circular(24)),
              //     child: CameraPreview(_cameraController!),
              //   ),
              // ),
              const Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 200,
                  child: AccelerometerChart(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: RecordButton(
                  cameraState: cameraState,
                  cameraController: _cameraController!,
                  onRecordPressed: () {
                    if (cameraState == CameraState.ready) {
                      notifier.startRecording(_cameraController!);
                    } else if (cameraState == CameraState.recording) {
                      notifier.stopRecording(_cameraController!);
                    }
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
