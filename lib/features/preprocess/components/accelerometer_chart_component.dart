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
    required this.isVerticalLayout,
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
  final bool isVerticalLayout;
  final void Function(TrackballArgs trackballArgs) onTrackballChanged;
  final void Function(ActualRangeChangedArgs args) onActualRangeChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (x.isEmpty && y.isEmpty && z.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Card.filled(
      margin: isVerticalLayout
          ? const EdgeInsets.all(2)
          : const EdgeInsets.fromLTRB(8, 4, 4, 4),
      color: ElevationOverlay.applySurfaceTint(
        colorScheme.surface,
        colorScheme.surfaceTint,
        1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SfCartesianChart(
          legend: const Legend(
            isVisible: true,
            position: LegendPosition.top,
            height: '10%',
          ),
          primaryXAxis: primaryXAxis,
          plotAreaBorderWidth: 0,
          primaryYAxis: const NumericAxis(
            axisLine: AxisLine(width: 0),
            maximum: 8000,
            minimum: -8000,
            majorTickLines: MajorTickLines(width: 0),
            majorGridLines: MajorGridLines(
              width: 0.4,
              dashArray: [5, 5],
              color: Colors.grey,
            ),
            decimalPlaces: 0,
          ),
          zoomPanBehavior: zoomPanBehavior,
          trackballBehavior: trackballBehavior,
          onTrackballPositionChanging: onTrackballChanged,
          onActualRangeChanged: onActualRangeChanged,
          series: [
            FastLineSeries<num, num>(
              width: 1.4,
              dataSource: x,
              xValueMapper: (data, index) => index,
              yValueMapper: (data, index) => data,
              color: Colors.red,
              legendItemText: 'x',
            ),
            FastLineSeries<num, num>(
              width: 1.4,
              dataSource: y,
              xValueMapper: (data, index) => index,
              yValueMapper: (data, index) => data,
              color: Colors.green,
              legendItemText: 'y',
            ),
            FastLineSeries<num, num>(
              width: 1.4,
              dataSource: z,
              xValueMapper: (data, index) => index,
              yValueMapper: (data, index) => data,
              color: Colors.blue,
              legendItemText: 'z',
            ),
          ],
        ),
      ),
    );
  }
}
