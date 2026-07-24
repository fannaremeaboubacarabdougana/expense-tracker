import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/database_helper.dart';

import '../widgets/expense_card.dart';
import '../widgets/statistics_grid.dart';

import '../charts/expense_chart.dart';

import 'add_expense_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Expense> expenses = [];

  String searchQuery = "";
  String selectedCategory = "All";
  final List<String> categories = [
    "All",
    "Food",
    "Transport",
    "Shopping",
    "Entertainment",
    "Bills",
    "Other",
  ];
  String sortBy = "Newest";
  final List<String> sortOptions = [
    "Newest",
    "Oldest",
    "Highest Amount",
    "Lowest Amount",
  ];

  IconData getCategoryIcon(String category) {
    switch (category) {
      case "Food":
        return Icons.restaurant;

      case "Transport":
        return Icons.directions_car;

      case "Shopping":
        return Icons.shopping_bag;

      case "Entertainment":
        return Icons.movie;

      case "Bills":
        return Icons.receipt_long;

      default:
        return Icons.category;
    }
  }

  List<Expense> get filteredExpenses {
    List<Expense> filtered = expenses.where((expense) {
      final matchesSearch = expense.title.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      final matchesCategory =
          selectedCategory == "All" || expense.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    switch (sortBy) {
      case "Newest":
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;

      case "Oldest":
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;

      case "Highest Amount":
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;

      case "Lowest Amount":
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return filtered;
  }

  double get totalExpenses {
    return expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final loadedExpenses = await DatabaseHelper.instance.getExpenses();

    setState(() {
      expenses
        ..clear()
        ..addAll(loadedExpenses);
    });
  }

  Future<void> _addExpense(String title, double amount, String category) async {
    final expense = Expense(
      id: DateTime.now().toIso8601String(),
      title: title,
      amount: amount,
      date: DateTime.now(),
      category: category,
    );

    await DatabaseHelper.instance.insertExpense(expense);

    setState(() {
      expenses.add(expense);
    });
  }

  Future<void> _deleteExpense(Expense expense) async {
    await DatabaseHelper.instance.deleteExpense(expense.id);

    setState(() {
      expenses.remove(expense);
    });
  }

  Future<void> _updateExpense(
    Expense oldExpense,
    String title,
    double amount,
    String category,
  ) async {
    final updatedExpense = Expense(
      id: oldExpense.id,
      title: title,
      amount: amount,
      category: category,
      date: DateTime.now(),
    );

    await DatabaseHelper.instance.updateExpense(updatedExpense);

    setState(() {
      final index = expenses.indexOf(oldExpense);
      expenses[index] = updatedExpense;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expense Tracker"), centerTitle: true),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => AddExpenseScreen(onAddExpense: _addExpense),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add"),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              //--------------------------------------------------
              // BALANCE CARD
              //--------------------------------------------------
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        "Current Balance",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "\$${totalExpenses.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // SEARCH
              //--------------------------------------------------
              TextField(
                decoration: InputDecoration(
                  hintText: "Search expenses...",
                  prefixIcon: const Icon(Icons.search),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  labelText: "Filter by Category",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: sortBy,
                decoration: InputDecoration(
                  labelText: "Sort By",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: sortOptions.map((option) {
                  return DropdownMenuItem(value: option, child: Text(option));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    sortBy = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // STATISTICS
              //--------------------------------------------------
              const Text(
                "Spending Analytics",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              StatisticsGrid(expenses: expenses),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // CHART
              //--------------------------------------------------
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ExpenseChart(expenses: expenses),
                ),
              ),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // EXPENSE LIST TITLE
              //--------------------------------------------------
              const Text(
                "Recent Expenses",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              //--------------------------------------------------
              // EMPTY STATE
              //--------------------------------------------------
              if (filteredExpenses.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: const [
                        Icon(Icons.receipt_long, size: 60, color: Colors.grey),

                        SizedBox(height: 12),

                        Text(
                          "No expenses found",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

              //--------------------------------------------------
              // EXPENSES
              //--------------------------------------------------
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),

                itemCount: filteredExpenses.length,

                itemBuilder: (context, index) {
                  final expense = filteredExpenses[index];

                  return ExpenseCard(
                    expense: expense,

                    onDelete: () => _deleteExpense(expense),

                    onEdit: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,

                        builder: (_) => AddExpenseScreen(
                          expense: expense,

                          onAddExpense: (title, amount, category) {
                            _updateExpense(expense, title, amount, category);
                          },
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
