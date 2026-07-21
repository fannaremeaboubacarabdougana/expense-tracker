import 'package:flutter/material.dart';
import '../models/expense.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Expense> expenses = [
    Expense(
      id: '1',
      title: 'Lunch',
      amount: 15.50,
      date: DateTime.now(),
      category: 'Food',
    ),
    Expense(
      id: '2',
      title: 'Uber',
      amount: 8.75,
      date: DateTime.now(),
      category: 'Transport',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Expense Tracker"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: const [
                    Text("Current Balance", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Text(
                      "\$0.00",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text("Add Expense"),
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.attach_money),
                      ),
                      title: Text(expense.title),
                      subtitle: Text(expense.category),
                      trailing: Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
