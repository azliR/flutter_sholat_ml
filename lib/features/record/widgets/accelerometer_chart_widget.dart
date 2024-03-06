import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/record/blocs/record/record_notifier.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AccelerometerChart extends ConsumerStatefulWidget {
  const AccelerometerChart({super.key});

  @override
  ConsumerState<AccelerometerChart> createState() => _AccelerometerChartState();
}

class _AccelerometerChartState extends ConsumerState<AccelerometerChart> {
  final List<int> indexes = [];
  final List<num> xDatasets = [];
  final List<num> yDatasets = [];
  final List<num> zDatasets = [];

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
          xDatasets.add(dataset.x);
          yDatasets.add(dataset.y);
          zDatasets.add(dataset.z);

          if (xDatasets.length == 100) {
            indexes.removeAt(0);
            xDatasets.removeAt(0);
            yDatasets.removeAt(0);
            zDatasets.removeAt(0);
          }
        }

        setState(() {});
      }
    });

    return ColoredBox(
      color: Colors.black26,
      child: SfCartesianChart(
        legend: const Legend(
          isVisible: true,
          textStyle: TextStyle(
            color: Colors.grey,
          ),
        ),
        primaryXAxis: const NumericAxis(
          axisLine: AxisLine(width: 0.4),
          majorGridLines: MajorGridLines(width: 0),
        ),
        plotAreaBorderWidth: 0,
        primaryYAxis: const NumericAxis(
          axisLine: AxisLine(width: 0),
          majorTickLines: MajorTickLines(width: 0),
          majorGridLines: MajorGridLines(
            width: 0.4,
            dashArray: [5, 5],
            color: Colors.grey,
          ),
        ),
        series: [
          SplineSeries<num, num>(
            width: 1.4,
            animationDuration: 0,
            dataSource: xDatasets,
            xValueMapper: (data, index) => indexes[index],
            yValueMapper: (data, index) => data,
            color: Colors.red,
            legendItemText: 'x',
          ),
          SplineSeries<num, num>(
            width: 1.4,
            animationDuration: 0,
            dataSource: yDatasets,
            xValueMapper: (data, index) => indexes[index],
            yValueMapper: (data, index) => data,
            color: Colors.green,
            legendItemText: 'y',
          ),
          SplineSeries<num, num>(
            width: 1.4,
            animationDuration: 0,
            dataSource: zDatasets,
            xValueMapper: (data, index) => indexes[index],
            yValueMapper: (data, index) => data,
            color: Colors.blue,
            legendItemText: 'z',
          ),
        ],
      ),
    );
  }
}
