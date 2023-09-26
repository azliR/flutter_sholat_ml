import 'package:auto_route/auto_route.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/record/blocs/record/record_notifier.dart';
import 'package:flutter_sholat_ml/utils/ui/snackbars.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mp_chart/mp/chart/line_chart.dart';
import 'package:mp_chart/mp/controller/line_chart_controller.dart';
import 'package:mp_chart/mp/core/data/line_data.dart';
import 'package:mp_chart/mp/core/data_set/line_data_set.dart';
import 'package:mp_chart/mp/core/description.dart';
import 'package:mp_chart/mp/core/entry/entry.dart';
import 'package:mp_chart/mp/core/enums/mode.dart';
import 'package:mp_chart/mp/core/enums/x_axis_position.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
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
                  child: _AccelerometerChart(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _RecordButton(
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

class _AccelerometerChart2 extends ConsumerStatefulWidget {
  const _AccelerometerChart2({super.key});

  @override
  ConsumerState<_AccelerometerChart2> createState() =>
      _AccelerometerChart2State();
}

class _AccelerometerChart2State extends ConsumerState<_AccelerometerChart2> {
  late final LineChartController _controller;

  @override
  void initState() {
    _initController();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.setVisibleXRange(0, 100);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(recordProvider, (previous, next) {
      if (previous?.lastDatasets != null && next.lastDatasets == null) {
        _controller.data?.clearValues();
        _controller.state?.setStateIfNotDispose();
        _createDataset();
      } else if (previous?.lastDatasets != next.lastDatasets &&
          next.lastDatasets != null) {
        final data = _controller.data!;
        for (final dataset in next.lastDatasets!) {
          final xSet = data.getDataSetByIndex(0)!;
          final count = xSet.getEntryCount().toDouble();

          final xEntry = Entry(x: count, y: dataset.x.toDouble());
          final yEntry = Entry(x: count, y: dataset.y.toDouble());
          final zEntry = Entry(x: count, y: dataset.z.toDouble());

          data
            ..addEntry(xEntry, 0)
            ..addEntry(yEntry, 1)
            ..addEntry(zEntry, 2)
            ..notifyDataChanged();
        }
        // final xSet = data.getDataSetByIndex(0)!;
        // final count = xSet.getEntryCount().toDouble();
        // _controller.setVisibleXRange(0, min(count, 100));
        _controller.state?.setStateIfNotDispose();

        // final index = set.getEntryCount() - 1;
        // final x = set.getEntryForIndex(index)?.x;

        // xEntry.x = x;
        // yEntry.x = x;
        // zEntry.x = x;

        // data
        //   ..updateEntryByIndex(index, xEntry, 0)
        //   ..updateEntryByIndex(index, yEntry, 1)
        //   ..updateEntryByIndex(index, zEntry, 2)
        //   ..notifyDataChanged();
      }
    });

    return LineChart(_controller);
  }

  void _initController() {
    final desc = Description()..enabled = false;
    _controller = LineChartController(
      resolveGestureHorizontalConflict: true,
      axisLeftSettingFunction: (axisLeft, controller) {
        axisLeft
          ?..zeroLineWidth = 1
          ..zeroLineColor = Colors.grey.shade500
          ..drawZeroLine = true
          ..drawGridLines = false
          ..textColor = Colors.white70
          ..axisLineColor = Colors.white70;
      },
      axisRightSettingFunction: (axisRight, controller) {
        axisRight?.enabled = false;
      },
      xAxisSettingFunction: (xAxis, controller) {
        xAxis
          ?..avoidFirstLastClipping = true
          ..position = XAxisPosition.BOTTOM
          ..drawGridLines = false
          ..drawAxisLine = true
          ..textColor = Colors.white70
          ..axisLineColor = Colors.white70;
      },
      legendSettingFunction: (legend, controller) {
        legend?.textColor = Colors.white70;
      },
      backgroundColor: Colors.black26,
      description: desc,
    );
    _createDataset();
  }

  void _createDataset() {
    final xSet = LineDataSet([], 'x')
      ..setColor1(Colors.red)
      ..setDrawValues(false)
      ..setDrawCircles(false)
      ..setMode(Mode.CUBIC_BEZIER)
      ..setLineWidth(1.2);

    final ySet = LineDataSet([], 'y')
      ..setColor1(Colors.green)
      ..setDrawValues(false)
      ..setDrawCircles(false)
      ..setMode(Mode.CUBIC_BEZIER)
      ..setLineWidth(1.2);

    final zSet = LineDataSet([], 'z')
      ..setColor1(Colors.blue)
      ..setDrawValues(false)
      ..setDrawCircles(false)
      ..setMode(Mode.CUBIC_BEZIER)
      ..setLineWidth(1.2);

    _controller.data = LineData.fromList([xSet, ySet, zSet]);
  }
}

class _AccelerometerChart extends ConsumerStatefulWidget {
  const _AccelerometerChart();

  @override
  ConsumerState<_AccelerometerChart> createState() =>
      _AccelerometerChartState();
}

class _AccelerometerChartState extends ConsumerState<_AccelerometerChart> {
  final List<num> indexes = [];
  final List<num> xDataset = [];
  final List<num> yDataset = [];
  final List<num> zDataset = [];

  @override
  Widget build(BuildContext context) {
    ref.listen(recordProvider, (previous, next) {
      if (previous?.lastDatasets != next.lastDatasets &&
          next.lastDatasets != null) {
        final datasets = next.lastDatasets!;
        for (var i = 0; i < datasets.length; i++) {
          final dataset = datasets[i];

          final index = indexes.lastOrNull ?? -1;
          indexes.add(index + 1);
          xDataset.add(dataset.x);
          yDataset.add(dataset.y);
          zDataset.add(dataset.z);

          if (xDataset.length == 100) {
            indexes.removeAt(0);
            xDataset.removeAt(0);
            yDataset.removeAt(0);
            zDataset.removeAt(0);
          }
        }

        setState(() {});
      }
    });

    return SfCartesianChart(
      series: [
        SplineSeries(
          animationDelay: 0,
          animationDuration: 0,
          dataSource: xDataset,
          xValueMapper: (data, index) => indexes[index],
          yValueMapper: (data, index) => data,
          color: Colors.red,
        ),
        SplineSeries(
          animationDelay: 0,
          animationDuration: 0,
          dataSource: yDataset,
          xValueMapper: (data, index) => indexes[index],
          yValueMapper: (data, index) => data,
          color: Colors.green,
        ),
        SplineSeries(
          animationDelay: 0,
          animationDuration: 0,
          dataSource: zDataset,
          xValueMapper: (data, index) => indexes[index],
          yValueMapper: (data, index) => data,
          color: Colors.blue,
        ),
      ],
    );
  }
}

class _RecordButton extends StatefulWidget {
  const _RecordButton({
    required this.cameraState,
    required this.cameraController,
    required this.onRecordPressed,
  });

  final CameraState cameraState;
  final CameraController cameraController;
  final void Function() onRecordPressed;

  @override
  State<_RecordButton> createState() => __RecordButtonState();
}

class __RecordButtonState extends State<_RecordButton> {
  var _isButtonPressed = false;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SizedBox(width: 48),
          GestureDetector(
            onTap: () {
              _isButtonPressed = false;
              widget.onRecordPressed();
            },
            onTapDown: (details) {
              if (widget.cameraState == CameraState.recording ||
                  widget.cameraState == CameraState.saving) return;
              setState(() {
                _isButtonPressed = true;
              });
            },
            onTapCancel: () {
              if (widget.cameraState == CameraState.recording ||
                  widget.cameraState == CameraState.saving) return;
              setState(() {
                _isButtonPressed = false;
              });
            },
            onTapUp: (details) {
              if (widget.cameraState == CameraState.recording ||
                  widget.cameraState == CameraState.saving) return;
              setState(() {
                _isButtonPressed = false;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.bounceInOut,
                    margin: EdgeInsets.all(
                      widget.cameraState == CameraState.recording
                          ? 24
                          : (_isButtonPressed ? 10 : 5),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                          widget.cameraState == CameraState.recording ? 6 : 36,
                        ),
                      ),
                      color: Colors.red,
                    ),
                  ),
                ),
                if (widget.cameraState == CameraState.preparing ||
                    widget.cameraState == CameraState.saving)
                  const SizedBox(
                    height: 72,
                    width: 72,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      strokeAlign: -1,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
              ],
            ),
          ),
          IconButton.outlined(
            iconSize: 36,
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
            onPressed: () {},
            icon: const Icon(Symbols.sync_rounded),
          ),
        ],
      ),
    );
  }
}
