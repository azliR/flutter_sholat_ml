import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AccelerometerChart extends StatelessWidget {
  const AccelerometerChart({
    required this.datasets,
    required this.onTrackballChanged,
    required this.trackballBehavior,
    super.key,
  });

  final List<Dataset> datasets;
  final TrackballBehavior trackballBehavior;
  final void Function(TrackballArgs trackballArgs) onTrackballChanged;

  @override
  Widget build(BuildContext context) {
    final xDatasets = <num>[];
    final yDatasets = <num>[];
    final zDatasets = <num>[];

    for (var i = 0; i < datasets.length; i++) {
      final dataset = datasets[i];
      xDatasets.add(dataset.x);
      yDatasets.add(dataset.y);
      zDatasets.add(dataset.z);
    }

    return SfCartesianChart(
      legend: const Legend(isVisible: true),
      primaryXAxis: NumericAxis(
        visibleMaximum: 400,
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
        zoomMode: ZoomMode.x,
        enableSelectionZooming: true,
      ),
      onSelectionChanged: (selectionArgs) {
        print(selectionArgs);
      },
      // trackballBehavior: trackballBehavior,
      // onTrackballPositionChanging: onTrackballChanged,
      series: [
        SplineSeries(
          width: 1.4,
          cardinalSplineTension: 1,
          dataSource: xDatasets,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          color: Colors.red,
          legendItemText: 'x',
        ),
        SplineSeries(
          width: 1.4,
          cardinalSplineTension: 1,
          dataSource: yDatasets,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          color: Colors.green,
          legendItemText: 'y',
        ),
        SplineSeries(
          width: 1.4,
          cardinalSplineTension: 1,
          dataSource: zDatasets,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          color: Colors.blue,
          legendItemText: 'z',
        ),
      ],
    );
  }
}
