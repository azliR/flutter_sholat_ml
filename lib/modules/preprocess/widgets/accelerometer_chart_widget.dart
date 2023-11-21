import 'package:flutter/material.dart';
import 'package:flutter_sholat_ml/modules/home/models/dataset/data_item.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AccelerometerChart extends StatelessWidget {
  const AccelerometerChart({
    required this.dataItems,
    required this.primaryXAxis,
    required this.onTrackballChanged,
    required this.trackballBehavior,
    required this.zoomPanBehavior,
    super.key,
  });

  final List<DataItem> dataItems;
  final ChartAxis primaryXAxis;
  final TrackballBehavior trackballBehavior;
  final ZoomPanBehavior zoomPanBehavior;
  final void Function(TrackballArgs trackballArgs) onTrackballChanged;

  @override
  Widget build(BuildContext context) {
    final xDatasets = <num>[];
    final yDatasets = <num>[];
    final zDatasets = <num>[];

    for (final dataset in dataItems) {
      xDatasets.add(dataset.x);
      yDatasets.add(dataset.y);
      zDatasets.add(dataset.z);
    }

    return SfCartesianChart(
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.top,
        height: '10%',
      ),
      primaryXAxis: NumericAxis(
        visibleMaximum: 400,
        decimalPlaces: 0,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0.4),
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
      zoomPanBehavior: zoomPanBehavior,
      trackballBehavior: trackballBehavior,
      onTrackballPositionChanging: onTrackballChanged,
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
