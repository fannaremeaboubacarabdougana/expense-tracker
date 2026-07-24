import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    final food = expenses
        .where((e) => e.category == "Food")
        .fold(0.0, (sum, item) => sum + item.amount);

    final transport = expenses
        .where((e) => e.category == "Transport")
        .fold(0.0, (sum, item) => sum + item.amount);

    final shopping = expenses
        .where((e) => e.category == "Shopping")
        .fold(0.0, (sum, item) => sum + item.amount);

    final other = expenses
        .where((e) => e.category == "Other")
        .fold(0.0, (sum, item) => sum + item.amount);

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            _bar(0, food, Colors.orange),
            _bar(1, transport, Colors.blue),
            _bar(2, shopping, Colors.purple),
            _bar(3, other, Colors.green),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('🍔', style: TextStyle(fontSize: 18)),
                      );
                    case 1:
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('🚗', style: TextStyle(fontSize: 18)),
                      );
                    case 2:
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('🛒', style: TextStyle(fontSize: 18)),
                      );
                    case 3:
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('📦', style: TextStyle(fontSize: 18)),
                      );
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  BarChartGroupData _bar(int x, double value, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value == 0 ? 0.1 : value,
          width: 26,
          color: color,
          borderRadius: BorderRadius.circular(10),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}
