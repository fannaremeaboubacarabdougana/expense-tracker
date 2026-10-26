import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../models/recurring_schedule.dart';
import '../services/firestore_expense_service.dart';

class RecurringExpensesScreen extends StatefulWidget {
  final CurrencyService currencyService;

  const RecurringExpensesScreen({super.key, required this.currencyService});

  @override
  State<RecurringExpensesScreen> createState() =>
      _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  final service = FirestoreExpenseService();
  bool migrating = false;
  bool processing = false;

  void showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: $error')));
  }

  Future<void> migrate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Migrate old recurring expenses?'),
        content: const Text(
          'This creates schedules for your old recurring '
          'expenses. Existing payment history will remain. '
          'Only run this after reviewing your Firestore data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Migrate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => migrating = true);
    try {
      final count = await service.migrateLegacyRecurringExpenses();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count legacy schedule(s) migrated.')),
      );
    } catch (error) {
      showError(error);
    } finally {
      if (mounted) setState(() => migrating = false);
    }
  }

  Future<void> processDue() async {
    setState(() => processing = true);
    try {
      await service.processRecurringExpenses();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Due expenses checked.')));
    } catch (error) {
      showError(error);
    } finally {
      if (mounted) setState(() => processing = false);
    }
  }

  Future<void> perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      showError(error);
    }
  }

  Future<void> editSchedule(RecurringSchedule schedule) async {
    final titleController = TextEditingController(text: schedule.title);
    final amountController = TextEditingController(
      text: schedule.amount.toString(),
    );

    var category = schedule.category;
    var frequency = schedule.frequency;

    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, updateDialog) => AlertDialog(
            title: const Text('Edit recurring expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${widget.currencyService.currencySymbol} ',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items:
                        [
                              'Food',
                              'Transport',
                              'Shopping',
                              'Entertainment',
                              'Bills',
                              'Other',
                            ]
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        updateDialog(() => category = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        updateDialog(() => frequency = value);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );

      if (submitted != true) return;

      final title = titleController.text.trim();
      final amount = double.tryParse(amountController.text.trim());

      if (title.isEmpty || amount == null || !amount.isFinite || amount <= 0) {
        showError('Enter a valid title and positive amount.');
        return;
      }

      await perform(
        () => service.editSchedule(
          id: schedule.id,
          title: title,
          amount: amount,
          category: category,
          frequency: frequency,
        ),
      );
    } finally {
      titleController.dispose();
      amountController.dispose();
    }
  }

  String dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recurring Expenses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: migrating ? null : migrate,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(migrating ? 'Migrating...' : 'Migrate old'),
                ),
                OutlinedButton.icon(
                  onPressed: processing ? null : processDue,
                  icon: const Icon(Icons.sync),
                  label: Text(processing ? 'Checking...' : 'Check due'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RecurringSchedule>>(
              stream: service.watchSchedules(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final schedules = snapshot.data!;

                if (schedules.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No recurring schedules yet.\n'
                        'Create one using Add Expense, '
                        'or migrate your old recurring expenses.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    final schedule = schedules[index];
                    final active = schedule.status == 'active';
                    final paused = schedule.status == 'paused';
                    final stopped = schedule.status == 'stopped';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    schedule.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Chip(label: Text(schedule.status)),
                              ],
                            ),
                            Text(
                              '${widget.currencyService.formatAmount(schedule.amount)}'
                              ' • ${schedule.category}'
                              ' • ${schedule.frequency}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Next scheduled: '
                              '${dateLabel(schedule.nextDueDate)}',
                            ),
                            if (stopped) const Text('This schedule has ended.'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (active)
                                  OutlinedButton.icon(
                                    onPressed: () => perform(
                                      () => service.pauseSchedule(schedule.id),
                                    ),
                                    icon: const Icon(Icons.pause),
                                    label: const Text('Pause'),
                                  ),
                                if (paused)
                                  OutlinedButton.icon(
                                    onPressed: () => perform(
                                      () => service.resumeSchedule(schedule.id),
                                    ),
                                    icon: const Icon(Icons.play_arrow),
                                    label: const Text('Resume'),
                                  ),
                                if (!stopped)
                                  OutlinedButton.icon(
                                    onPressed: () => editSchedule(schedule),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Edit'),
                                  ),
                                if (!stopped)
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text(
                                            'Stop this schedule?',
                                          ),
                                          content: const Text(
                                            'Future payments will stop. '
                                            'Past expenses will remain. '
                                            'This cannot be undone.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Stop'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await perform(
                                          () =>
                                              service.stopSchedule(schedule.id),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.stop_circle),
                                    label: const Text('Stop'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
