import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, required this.onAddExpense, this.expense});

  final Expense? expense;

  final Future<void> Function(
    String title,
    double amount,
    String category,
    bool isRecurring,
    String recurrence,
  )
  onAddExpense;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController amountController;

  late String category;
  late bool isRecurring;
  late String recurrence;

  static const List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];

  static const List<String> recurrenceOptions = [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.expense?.title ?? '');

    amountController = TextEditingController(
      text: widget.expense?.amount.toString() ?? '',
    );

    final existingCategory = widget.expense?.category ?? 'Food';

    category = categories.contains(existingCategory)
        ? existingCategory
        : 'Other';

    isRecurring = widget.expense?.isRecurring ?? false;

    final existingRecurrence = widget.expense?.recurrence ?? 'Monthly';

    recurrence = recurrenceOptions.contains(existingRecurrence)
        ? existingRecurrence
        : 'Monthly';
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';

    if (title.isEmpty) {
      return 'Please enter an expense title.';
    }

    if (title.length < 2) {
      return 'The title must contain at least 2 characters.';
    }

    if (title.length > 100) {
      return 'The title cannot exceed 100 characters.';
    }

    return null;
  }

  String? _validateAmount(String? value) {
    final input = value?.trim() ?? '';

    if (input.isEmpty) {
      return 'Please enter an amount.';
    }

    final amount = double.tryParse(input);

    if (amount == null || !amount.isFinite) {
      return 'Please enter a valid number.';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero.';
    }

    if (amount > 1000000000) {
      return 'Amount cannot exceed 1,000,000,000.';
    }

    return null;
  }

  Future<void> _saveExpense() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final title = titleController.text.trim();
      final amount = double.parse(amountController.text.trim());

      await widget.onAddExpense(
        title,
        amount,
        category,
        isRecurring,
        recurrence,
      );

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save expense: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.expense != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  isEditing ? 'Edit Expense' : 'Add Expense',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isEditing
                      ? 'Update the details of your expense.'
                      : 'Enter the details of your new expense.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: titleController,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 100,
                  validator: _validateTitle,
                  decoration: const InputDecoration(
                    labelText: 'Expense Title',
                    hintText: 'e.g. Lunch, Transport, Rent',
                    prefixIcon: Icon(Icons.edit_note),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: _validateAmount,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    hintText: 'e.g. 45.50',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 18),

                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((item) {
                    return DropdownMenuItem(value: item, child: Text(item));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => category = value);
                    }
                  },
                  validator: (value) {
                    if (value == null || !categories.contains(value)) {
                      return 'Please select a category.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  child: CheckboxListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    title: const Text('Recurring Expense'),
                    subtitle: const Text(
                      'For expenses such as rent, '
                      'subscriptions, and regular payments.',
                    ),
                    value: isRecurring,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      setState(() {
                        isRecurring = value ?? false;
                      });
                    },
                  ),
                ),

                if (isRecurring) ...[
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: recurrence,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      prefixIcon: Icon(Icons.repeat),
                      border: OutlineInputBorder(),
                    ),
                    items: recurrenceOptions.map((item) {
                      return DropdownMenuItem(value: item, child: Text(item));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => recurrence = value);
                      }
                    },
                    validator: (value) {
                      if (isRecurring && !recurrenceOptions.contains(value)) {
                        return 'Please select a repeat frequency.';
                      }

                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 28),

                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveExpense,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isEditing
                              ? Icons.save_outlined
                              : Icons.add_circle_outline,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : isEditing
                        ? 'Update Expense'
                        : 'Save Expense',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
