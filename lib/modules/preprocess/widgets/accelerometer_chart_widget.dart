import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AccelerometerChart extends StatelessWidget {
  const AccelerometerChart({
    required this.x,
    required this.y,
    required this.z,
    required this.onTrackballChanged,
    required this.trackballBehavior,
    required this.zoomPanBehavior,
    required this.primaryXAxis,
    required this.onActualRangeChanged,
    super.key,
  });

  final List<num> x;
  final List<num> y;
  final List<num> z;
  final NumericAxis primaryXAxis;
  final TrackballBehavior trackballBehavior;
  final ZoomPanBehavior zoomPanBehavior;
  final void Function(TrackballArgs trackballArgs) onTrackballChanged;
  final void Function(ActualRangeChangedArgs args) onActualRangeChanged;

  @override
  Widget build(BuildContext context) {
    if (x.isEmpty && y.isEmpty && z.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return SfCartesianChart(
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.top,
        height: '10%',
      ),
      primaryXAxis: primaryXAxis,
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
      onActualRangeChanged: onActualRangeChanged,
      series: [
        SplineSeries(
          width: 1.4,
          dataSource: x,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          cardinalSplineTension: 1,
          color: Colors.red,
          legendItemText: 'x',
        ),
        SplineSeries(
          width: 1.4,
          dataSource: y,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          cardinalSplineTension: 1,
          color: Colors.green,
          legendItemText: 'y',
        ),
        SplineSeries(
          width: 1.4,
          dataSource: z,
          xValueMapper: (data, index) => index,
          yValueMapper: (data, index) => data,
          cardinalSplineTension: 1,
          color: Colors.blue,
          legendItemText: 'z',
        ),
      ],
    );
  }
}
