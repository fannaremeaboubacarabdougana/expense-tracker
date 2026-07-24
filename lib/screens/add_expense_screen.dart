import 'package:flutter/material.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatelessWidget {
  AddExpenseScreen({super.key, required this.onAddExpense, this.expense});

  final Expense? expense;

  final void Function(String title, double amount, String category)
  onAddExpense;

  late final TextEditingController titleController = TextEditingController(
    text: expense?.title ?? "",
  );

  late final TextEditingController amountController = TextEditingController(
    text: expense != null ? expense!.amount.toString() : "",
  );

  late String category = expense?.category ?? "Food";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expense == null ? "Add Expense" : "Edit Expense",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Amount",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: "Food", child: Text("Food")),
                DropdownMenuItem(value: "Transport", child: Text("Transport")),
                DropdownMenuItem(value: "Shopping", child: Text("Shopping")),
                DropdownMenuItem(value: "Bills", child: Text("Bills")),
              ],
              onChanged: (value) {
                category = value!;
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final amount = double.tryParse(amountController.text);

                  if (title.isEmpty || amount == null || amount <= 0) {
                    return;
                  }

                  onAddExpense(title, amount, category);

                  Navigator.of(context).pop();
                },
                child: Text(
                  expense == null ? "Save Expense" : "Update Expense",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
