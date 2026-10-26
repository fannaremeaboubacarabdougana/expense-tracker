import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/currency_service.dart';

class ExpenseChart extends StatelessWidget {
  final List<Expense> expenses;
  final CurrencyService currencyService;

  const ExpenseChart({
    super.key,
    required this.expenses,
    required this.currencyService,
  });

  static const List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];

  static const List<String> _emojis = ['🍔', '🚗', '🛒', '🧾', '🎬', '📦'];

  static const List<Color> _colors = [
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate the total spending in each category.
    final totals = _categories.map((category) {
      return expenses
          .where((expense) => expense.category == category)
          .fold<double>(0, (sum, expense) => sum + expense.amount);
    }).toList();

    final totalSpending = totals.fold<double>(0, (sum, amount) => sum + amount);

    if (expenses.isEmpty || totalSpending <= 0) {
      return _buildEmptyState(context);
    }

    final highestAmount = totals.reduce(math.max);

    // Give the tallest bar some space above it.
    final maxY = math.max(100.0, highestAmount * 1.25);
    final interval = maxY / 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expenses by Category',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'See how your spending is distributed.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, constraints) {
            // Allow horizontal scrolling on narrow screens.
            final chartWidth = math.max(360.0, constraints.maxWidth);

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 280,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: 0,
                    maxY: maxY,

                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.35),
                          strokeWidth: 1,
                        );
                      },
                    ),

                    borderData: FlBorderData(show: false),

                    barGroups: List.generate(
                      _categories.length,
                      (index) =>
                          _bar(index, totals[index], _colors[index], maxY),
                    ),

                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final index = group.x;

                          return BarTooltipItem(
                            '${_categories[index]}\n'
                            '${currencyService.formatAmount(totals[index])}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),

                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 72,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value > maxY) {
                              return const SizedBox.shrink();
                            }

                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                _shortCurrency(value),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                ),
                              ),
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
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= _emojis.length) {
                              return const SizedBox.shrink();
                            }

                            return SideTitleWidget(
                              meta: meta,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _emojis[index],
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 22),

        Text(
          'Category Breakdown',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        // Display category totals below the chart.
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 450 ? 1 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                mainAxisExtent: 56,
              ),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 5, backgroundColor: _colors[index]),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          _categories[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Flexible(
                        child: Text(
                          currencyService.formatAmount(totals[index]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),

            const SizedBox(height: 12),

            Text(
              'No spending data yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add your first expense to see '
              'your spending analytics.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _shortCurrency(double amount) {
    final symbol = currencyService.currencySymbol;

    if (amount >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    }

    if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }

    return '$symbol${amount.toStringAsFixed(0)}';
  }

  BarChartGroupData _bar(int x, double value, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value,
          width: 20,
          color: color,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: Colors.grey.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
