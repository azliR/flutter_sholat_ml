import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/modules/record/blocs/record/record_notifier.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HeartRateChart extends ConsumerStatefulWidget {
  const HeartRateChart({super.key});

  @override
  ConsumerState<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends ConsumerState<HeartRateChart> {
  final List<int> indexes = [];
  final List<int> heartRateDatasets = [];

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

          if (dataset.heartRate != null) {
            heartRateDatasets.add(dataset.heartRate!);
          }

          if (heartRateDatasets.length == 100) {
            indexes.removeAt(0);
            heartRateDatasets.removeAt(0);
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
          position: LegendPosition.bottom,
        ),
        primaryXAxis: NumericAxis(
          axisLine: const AxisLine(width: 0.4),
          majorGridLines: const MajorGridLines(width: 0),
          borderWidth: 0,
        ),
        plotAreaBorderWidth: 0,
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(width: 0),
          majorGridLines: const MajorGridLines(
            width: 0.4,
            dashArray: [5, 5],
            color: Colors.grey,
          ),
        ),
        series: [
          SplineSeries(
            width: 1.4,
            animationDelay: 0,
            animationDuration: 0,
            dataSource: heartRateDatasets,
            xValueMapper: (data, index) => indexes[index],
            yValueMapper: (data, index) => data,
            color: Colors.red,
            legendItemText: 'Heart Rate',
          ),
        ],
      ),
    );
  }
}
