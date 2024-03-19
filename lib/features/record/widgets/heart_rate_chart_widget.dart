import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sholat_ml/features/record/blocs/record/record_notifier.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HeartRateChart extends ConsumerStatefulWidget {
  const HeartRateChart({super.key});

  @override
  ConsumerState<HeartRateChart> createState() => _HeartRateChartState();
}

class _HeartRateChartState extends ConsumerState<HeartRateChart> {
  final List<int> indexes = [];
  final List<int> heartRateDatasets = [];

  late ChartSeriesController<num, num> _heartChartController;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 100;

    ref.listen(
      recordProvider.select((value) => value.lastDatasets),
      (previous, datasets) {
        if (datasets == null) return;

        final previousLength = heartRateDatasets.length;

        for (var i = 0; i < datasets.length; i++) {
          final dataset = datasets[i];

          final index = indexes.lastOrNull ?? -1;
          indexes.add(index + 1);

          if (dataset.heartRate != null) {
            heartRateDatasets.add(dataset.heartRate!);
          }

          if (heartRateDatasets.length == maxVisible + 1) {
            indexes.removeAt(0);
            heartRateDatasets.removeAt(0);
          }
        }

        final addedDataIndexes = List.generate(
          datasets.length,
          (index) => heartRateDatasets.length - index - 1,
        ).reversed.toList();
        final removedDataIndexes = List.generate(
          math.max(0, datasets.length + previousLength - maxVisible),
          (index) => index,
        );

        _heartChartController.updateDataSource(
          addedDataIndexes: addedDataIndexes,
          removedDataIndexes: removedDataIndexes,
        );
      },
    );

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
          LineSeries<num, num>(
            width: 1.4,
            animationDuration: 0,
            dataSource: heartRateDatasets,
            xValueMapper: (data, index) => indexes[index],
            yValueMapper: (data, index) => data,
            color: Colors.red,
            legendItemText: 'Heart Rate',
            onRendererCreated: (controller) {
              _heartChartController = controller;
            },
          ),
        ],
      ),
    );
  }
}
