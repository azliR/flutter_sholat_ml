import 'package:auto_route/auto_route.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:flutter_sholat_ml/modules/record/blocs/record/record_notifier.dart';
import 'package:flutter_sholat_ml/modules/record/widgets/accelerometer_chart_widget.dart';
import 'package:flutter_sholat_ml/modules/record/widgets/heart_rate_chart_widget.dart';
import 'package:flutter_sholat_ml/modules/record/widgets/record_button_widget.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:wakelock/wakelock.dart';

@RoutePage()
class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({
    required this.device,
    required this.services,
    required this.onRecordSuccess,
    super.key,
  });

  final BluetoothDevice device;
  final List<BluetoothService> services;
  final void Function() onRecordSuccess;

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen>
    with WidgetsBindingObserver {
  late final RecordNotifier _notifier;

  CameraController? _cameraController;

  Future<void> _showDeviceLocationDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          await context.router.pop();
          return true;
        },
        child: AlertDialog(
          title: const Text('Device location'),
          icon: const Icon(Symbols.watch_rounded),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Where do you wear your device?'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _notifier.onDeviceLocationChanged(DeviceLocation.leftWrist);
                  },
                  child: const Text('Left Wrist'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _notifier
                        .onDeviceLocationChanged(DeviceLocation.rightWrist);
                  },
                  child: const Text('Right Wrist'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLockPressed() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!context.mounted) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      return;
    }
    _notifier.onLockChanged(isLocked: true);
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async {
          return false;
        },
        child: Align(
          alignment: Alignment.topRight,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              onLongPress: () {
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Symbols.lock_open_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _notifier.onLockChanged(isLocked: false);
  }

  @override
  void initState() {
    _notifier = ref.read(recordProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _showDeviceLocationDialog();
      _notifier.initialise(widget.device, widget.services);
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
          .initialiseCameraController(cameraController.description)
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
            widget.onRecordSuccess();
          case GetCamerasFailureState():
            showErrorSnackbar(context, 'Failed getting available cameras');
          case RecordInitialState():
            break;
        }
      } else if (previous?.isCameraPermissionGranted !=
          next.isCameraPermissionGranted) {
        if (next.isCameraPermissionGranted) {
          _cameraController = await notifier.initialiseCameraController();
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
    final isLocked =
        ref.watch(recordProvider.select((value) => value.isLocked));

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
                        _cameraController =
                            await notifier.initialiseCameraController();
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
              if (!isLocked)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              const Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(child: AccelerometerChart()),
                      Expanded(child: HeartRateChart()),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Consumer(
                  builder: (context, ref, child) {
                    final availableCameras = ref.watch(
                      recordProvider.select((value) => value.availableCameras),
                    );

                    return RecordButton(
                      cameraState: cameraState,
                      cameraController: _cameraController!,
                      onRecordPressed: () {
                        if (cameraState == CameraState.ready) {
                          notifier.startRecording(_cameraController!);
                        } else if (cameraState == CameraState.recording) {
                          notifier.stopRecording(_cameraController!);
                        }
                      },
                      onLockPressed: _onLockPressed,
                      onSwitchPressed: availableCameras.every(
                        (camera) => [
                          CameraLensDirection.back,
                          CameraLensDirection.front,
                        ].contains(camera.lensDirection),
                      )
                          ? () async {
                              final currentCamera =
                                  ref.read(recordProvider).currentCamera!;
                              final switchCamera =
                                  availableCameras.firstWhere((camera) {
                                if (currentCamera.lensDirection ==
                                    CameraLensDirection.back) {
                                  return camera.lensDirection ==
                                      CameraLensDirection.front;
                                } else {
                                  return camera.lensDirection ==
                                      CameraLensDirection.back;
                                }
                              });
                              _cameraController = await _notifier
                                  .initialiseCameraController(switchCamera);
                              setState(() {});
                            }
                          : null,
                    );
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
