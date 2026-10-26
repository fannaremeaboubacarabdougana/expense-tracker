import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/currency_service.dart';
import '../utils/statistics.dart';
import 'statistics_card.dart';

class StatisticsGrid extends StatelessWidget {
  final List<Expense> expenses;
  final CurrencyService currencyService;

  const StatisticsGrid({
    super.key,
    required this.expenses,
    required this.currencyService,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Adapt columns to available screen width.
        int columns;

        if (width < 360) {
          columns = 1;
        } else if (width < 700) {
          columns = 2;
        } else if (width < 1000) {
          columns = 3;
        } else {
          columns = 5;
        }

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 105,
          ),
          children: [
            StatisticsCard(
              title: 'Total',
              value: currencyService.formatAmount(
                Statistics.totalExpenses(expenses),
              ),
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),

            StatisticsCard(
              title: 'This Month',
              value: currencyService.formatAmount(
                Statistics.monthlyExpenses(expenses),
              ),
              icon: Icons.calendar_month,
              color: Colors.teal,
            ),

            StatisticsCard(
              title: 'Transactions',
              value: Statistics.transactionCount(expenses).toString(),
              icon: Icons.receipt_long,
              color: Colors.blue,
            ),

            StatisticsCard(
              title: 'Average',
              value: currencyService.formatAmount(
                Statistics.averageExpense(expenses),
              ),
              icon: Icons.analytics,
              color: Colors.orange,
            ),

            StatisticsCard(
              title: 'Top Category',
              value: Statistics.highestCategory(expenses),
              icon: Icons.star,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }
}
