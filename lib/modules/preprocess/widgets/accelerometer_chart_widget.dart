import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/dataset.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AccelerometerChart extends StatelessWidget {
  const AccelerometerChart(
      {required this.datasets, required this.onTrackballChanged, super.key});

  final List<Dataset> datasets;
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
      primaryXAxis: NumericAxis(
        visibleMaximum: 100,
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
      ),
      onTrackballPositionChanging: onTrackballChanged,
      series: [
        SplineSeries(
          dataSource: xDatasets,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          color: Colors.red,
        ),
        SplineSeries(
          dataSource: yDatasets,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          color: Colors.green,
        ),
        SplineSeries(
          dataSource: zDatasets,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          color: Colors.blue,
        ),
      ],
    );
  }
}
