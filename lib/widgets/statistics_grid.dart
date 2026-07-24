import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../utils/statistics.dart';
import 'statistics_card.dart';

class StatisticsGrid extends StatelessWidget {
  final List<Expense> expenses;

  const StatisticsGrid({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        StatisticsCard(
          title: "Total",
          value: "\$${Statistics.totalExpenses(expenses).toStringAsFixed(2)}",
          icon: Icons.account_balance_wallet,
          color: Colors.green,
        ),
        StatisticsCard(
          title: "This Month",
          value: "\$${Statistics.monthlyExpenses(expenses).toStringAsFixed(2)}",
          icon: Icons.calendar_month,
          color: Colors.teal,
        ),
        StatisticsCard(
          title: "Transactions",
          value: Statistics.transactionCount(expenses).toString(),
          icon: Icons.receipt_long,
          color: Colors.blue,
        ),
        StatisticsCard(
          title: "Average",
          value: "\$${Statistics.averageExpense(expenses).toStringAsFixed(2)}",
          icon: Icons.analytics,
          color: Colors.orange,
        ),
        StatisticsCard(
          title: "Top Category",
          value: Statistics.highestCategory(expenses),
          icon: Icons.star,
          color: Colors.purple,
        ),
      ],
    );
  }
}
