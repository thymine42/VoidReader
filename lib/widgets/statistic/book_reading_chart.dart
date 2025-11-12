import 'package:anx_reader/utils/date/convert_seconds.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BookReadingChart extends StatefulWidget {
  final List<int> readingTimes;
  final List<String> xLabels;
  final int maxReadingTime;

  const BookReadingChart({
    super.key,
    required this.readingTimes,
    required this.xLabels,
    required this.maxReadingTime,
  });

  @override
  State<BookReadingChart> createState() => _BookReadingChartState();
}

class _BookReadingChartState extends State<BookReadingChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = primaryColor.withAlpha(80);

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (LineBarSpot touchedSpot) {
              return Colors.white.withAlpha(100);
            },
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < widget.readingTimes.length) {
                  return LineTooltipItem(
                    '${widget.xLabels[index]}\n${convertSeconds(widget.readingTimes[index])}',
                    TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (widget.readingTimes.length - 1).toDouble(),
        minY: 0,
        maxY: widget.maxReadingTime > 0 ? widget.maxReadingTime * 1.2 : 1,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              widget.readingTimes.length,
              (index) => FlSpot(
                  index.toDouble(), widget.readingTimes[index].toDouble()),
            ),
            isCurved: true,
            color: primaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: secondaryColor,
              gradient: LinearGradient(
                colors: [
                  primaryColor.withAlpha(75),
                  primaryColor.withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
