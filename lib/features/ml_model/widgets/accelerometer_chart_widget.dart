// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_sholat_ml/features/lab/blocs/lab/lab_notifier.dart';
// import 'package:syncfusion_flutter_charts/charts.dart';

// class AccelerometerChart extends ConsumerStatefulWidget {
//   const AccelerometerChart({super.key});

//   @override
//   ConsumerState<AccelerometerChart> createState() => _AccelerometerChartState();
// }

// class _AccelerometerChartState extends ConsumerState<AccelerometerChart> {
//   final List<int> _indexes = [];
//   final List<num> _xDatasets = [];
//   final List<num> _yDatasets = [];
//   final List<num> _zDatasets = [];

//   @override
//   Widget build(BuildContext context) {
//     ref
//       ..listen(
//         labProvider.select((value) => value.lastAccelData),
//         (previous, lastAccelData) {
//           if (lastAccelData == null) return;

//           final accelDataList = lastAccelData;
//           for (var i = 0; i < accelDataList.length; i += 3) {
//             final index = _indexes.lastOrNull ?? -1;
//             _indexes.add(index + 1);
//             _xDatasets.add(accelDataList[i]);
//             _yDatasets.add(accelDataList[i + 1]);
//             _zDatasets.add(accelDataList[i + 2]);

//             if (_xDatasets.length == 100) {
//               _indexes.removeAt(0);
//               _xDatasets.removeAt(0);
//               _yDatasets.removeAt(0);
//               _zDatasets.removeAt(0);
//             }
//           }

//           setState(() {});
//         },
//       )
//       ..listen(
//         labProvider.select((value) => value.recordState),
//         (previous, recordState) {
//           switch (recordState) {
//             case RecordState.ready:
//               break;
//             case RecordState.preparing:
//               _indexes.clear();
//               _xDatasets.clear();
//               _yDatasets.clear();
//               _zDatasets.clear();
//             case RecordState.recording:
//               break;
//             case RecordState.stopping:
//               break;
//           }
//         },
//       );

//     return SfCartesianChart(
//       legend: const Legend(
//         isVisible: true,
//       ),
//       primaryXAxis: const NumericAxis(
//         axisLine: AxisLine(width: 0.4),
//         majorGridLines: MajorGridLines(width: 0),
//       ),
//       plotAreaBorderWidth: 0,
//       primaryYAxis: const NumericAxis(
//         axisLine: AxisLine(width: 0),
//         majorTickLines: MajorTickLines(width: 0),
//         majorGridLines: MajorGridLines(
//           width: 0.4,
//           dashArray: [5, 5],
//           color: Colors.grey,
//         ),
//       ),
//       series: [
//         SplineSeries<num, num>(
//           width: 1.4,
//           animationDuration: 0,
//           dataSource: _xDatasets,
//           xValueMapper: (data, index) => _indexes[index],
//           yValueMapper: (data, index) => data,
//           color: Colors.red,
//           legendItemText: 'x',
//         ),
//         SplineSeries<num, num>(
//           width: 1.4,
//           animationDuration: 0,
//           dataSource: _yDatasets,
//           xValueMapper: (data, index) => _indexes[index],
//           yValueMapper: (data, index) => data,
//           color: Colors.green,
//           legendItemText: 'y',
//         ),
//         SplineSeries<num, num>(
//           width: 1.4,
//           animationDuration: 0,
//           dataSource: _zDatasets,
//           xValueMapper: (data, index) => _indexes[index],
//           yValueMapper: (data, index) => data,
//           color: Colors.blue,
//           legendItemText: 'z',
//         ),
//       ],
//     );
//   }
// } 
