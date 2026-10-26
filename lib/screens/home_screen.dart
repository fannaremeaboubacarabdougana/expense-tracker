import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../charts/expense_chart.dart';
import '../models/expense.dart';
import '../services/currency_service.dart';
import '../services/export_service.dart';
import '../services/firestore_expense_service.dart';
import '../services/theme_service.dart';
import '../widgets/expense_card.dart';
import '../widgets/statistics_grid.dart';
import 'add_expense_screen.dart';
import 'recurring_expenses_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ThemeService themeService;
  final CurrencyService currencyService;

  const HomeScreen({
    super.key,
    required this.themeService,
    required this.currencyService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreExpenseService _service = FirestoreExpenseService();
  final ExportService _exportService = ExportService();

  late final Stream<List<Expense>> _expenseStream;

  bool _isExporting = false;

  String searchQuery = '';
  String selectedCategory = 'All';
  String sortBy = 'Newest';

  final List<String> categories = [
    'All',
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Bills',
    'Other',
  ];

  final List<String> sortOptions = [
    'Newest',
    'Oldest',
    'Highest Amount',
    'Lowest Amount',
  ];

  @override
  void initState() {
    super.initState();

    _expenseStream = _service.watchExpenses();
    widget.currencyService.addListener(_onCurrencyChanged);

    _checkNewSchedules();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.currencyService != widget.currencyService) {
      oldWidget.currencyService.removeListener(_onCurrencyChanged);
      widget.currencyService.addListener(_onCurrencyChanged);
    }
  }

  void _onCurrencyChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.currencyService.removeListener(_onCurrencyChanged);
    super.dispose();
  }

  // --------------------------------------------------
  // RECURRING EXPENSE PROCESSING
  // --------------------------------------------------

  Future<void> _checkNewSchedules() async {
    try {
      await _service.processRecurringExpenses();
    } catch (error) {
      _showError(error);
    }
  }

  // --------------------------------------------------
  // FILTERING AND SORTING
  // --------------------------------------------------

  List<Expense> filterExpenses(List<Expense> expenses) {
    final filtered = expenses.where((expense) {
      final matchesSearch = expense.title.toLowerCase().contains(
        searchQuery.toLowerCase(),
      );

      final matchesCategory =
          selectedCategory == 'All' || expense.category == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    switch (sortBy) {
      case 'Oldest':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;

      case 'Highest Amount':
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
        break;

      case 'Lowest Amount':
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
        break;

      default:
        filtered.sort((a, b) => b.date.compareTo(a.date));
    }

    return filtered;
  }

  // --------------------------------------------------
  // FIREBASE CRUD OPERATIONS
  // --------------------------------------------------

  Future<void> _addExpense(
    String title,
    double amount,
    String category,
    bool isRecurring,
    String recurrence,
  ) async {
    final expense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: category,
      date: DateTime.now(),
      isRecurring: isRecurring,
      recurrence: recurrence,
    );

    await _service.addExpense(expense);
  }

  Future<void> _updateExpense(
    Expense oldExpense,
    String title,
    double amount,
    String category,
    bool isRecurring,
    String recurrence,
  ) async {
    final updatedExpense = Expense(
      id: oldExpense.id,
      title: title,
      amount: amount,
      category: category,
      date: oldExpense.date,
      isRecurring: isRecurring,
      recurrence: recurrence,
      recurringParentId: oldExpense.recurringParentId,
    );

    await _service.updateExpense(updatedExpense);
  }

  Future<void> _deleteExpense(Expense expense) async {
    await _service.deleteExpense(expense.id);
  }

  // --------------------------------------------------
  // SAVE AND UPDATE CALLBACKS
  // --------------------------------------------------

  Future<void> _saveExpense(
    String title,
    double amount,
    String category,
    bool isRecurring,
    String recurrence,
  ) async {
    // Do not swallow errors here.
    // AddExpenseScreen handles errors and loading state.
    await _addExpense(title, amount, category, isRecurring, recurrence);
  }

  Future<void> _saveUpdatedExpense(
    Expense oldExpense,
    String title,
    double amount,
    String category,
    bool isRecurring,
    String recurrence,
  ) async {
    await _updateExpense(
      oldExpense,
      title,
      amount,
      category,
      isRecurring,
      recurrence,
    );
  }

  Future<void> _removeExpense(Expense expense) async {
    try {
      await _deleteExpense(expense);
    } catch (error) {
      _showError(error);
    }
  }

  // --------------------------------------------------
  // ERROR HANDLING
  // --------------------------------------------------

  void _showError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Operation failed: $error')));
  }

  // --------------------------------------------------
  // CSV EXPORT
  // --------------------------------------------------

  Future<void> _exportCsv(List<Expense> expenses) async {
    if (_isExporting || expenses.isEmpty) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await _exportService.exportExpensesToCsv(
        expenses: expenses,
        currencyService: widget.currencyService,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV export completed. Check your downloads.'),
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // PDF EXPORT
  // --------------------------------------------------

  Future<void> _exportPdf(List<Expense> expenses) async {
    if (_isExporting || expenses.isEmpty) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await _exportService.exportExpensesToPdf(
        expenses: expenses,
        currencyService: widget.currencyService,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF export completed. Check your downloads.'),
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  // --------------------------------------------------
  // ADD AND EDIT EXPENSE BOTTOM SHEETS
  // --------------------------------------------------

  void _openAddExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExpenseScreen(onAddExpense: _saveExpense),
    );
  }

  void _openEditExpense(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddExpenseScreen(
        expense: expense,
        onAddExpense: (title, amount, category, isRecurring, recurrence) {
          return _saveUpdatedExpense(
            expense,
            title,
            amount,
            category,
            isRecurring,
            recurrence,
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (error) {
        _showError(error);
      }
    }
  }

  // --------------------------------------------------
  // SECTION HEADER
  // --------------------------------------------------

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // SUMMARY CARD
  // --------------------------------------------------

  Widget _buildSummaryCard(
    BuildContext context,
    double totalExpenses,
    int transactionCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Total Expenses',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
              Icon(
                Icons.trending_up,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ],
          ),

          const SizedBox(height: 18),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.currencyService.formatAmount(totalExpenses),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            '$transactionCount transactions recorded',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SEARCH, CATEGORY AND SORT FILTERS
  // --------------------------------------------------

  Widget _buildFilters(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Search expenses...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 14),

            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 500;

                final categoryFilter = DropdownButtonFormField<String>(
                  key: ValueKey('category-$selectedCategory'),
                  initialValue: selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedCategory = value;
                      });
                    }
                  },
                );

                final sortFilter = DropdownButtonFormField<String>(
                  key: ValueKey('sort-$sortBy'),
                  initialValue: sortBy,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(),
                  ),
                  items: sortOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        sortBy = value;
                      });
                    }
                  },
                );

                if (narrow) {
                  return Column(
                    children: [
                      categoryFilter,
                      const SizedBox(height: 12),
                      sortFilter,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: categoryFilter),
                    const SizedBox(width: 12),
                    Expanded(child: sortFilter),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------

  Widget _buildEmptyState(bool hasExpenses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
        child: Column(
          children: [
            Icon(
              hasExpenses
                  ? Icons.search_off_outlined
                  : Icons.receipt_long_outlined,
              size: 56,
              color: Colors.grey,
            ),

            const SizedBox(height: 12),

            Text(
              hasExpenses ? 'No matching expenses' : 'No expenses yet',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              hasExpenses
                  ? 'Try another search or change your filters.'
                  : 'Start tracking your spending by adding an expense.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),

            if (!hasExpenses) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _openAddExpense,
                icon: const Icon(Icons.add),
                label: const Text('Add your first expense'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // MAIN DASHBOARD
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Recurring Expenses',
            icon: const Icon(Icons.autorenew),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecurringExpensesScreen(
                    currencyService: widget.currencyService,
                  ),
                ),
              );
            },
          ),

          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    themeService: widget.themeService,
                    currencyService: widget.currencyService,
                  ),
                ),
              );
            },
          ),

          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),

      body: StreamBuilder<List<Expense>>(
        stream: _expenseStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load expenses: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data!;
          final filteredExpenses = filterExpenses(expenses);

          final totalExpenses = expenses.fold<double>(
            0,
            (sum, expense) => sum + expense.amount,
          );

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your Spending Overview',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Track and understand your expenses in one place.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildSummaryCard(
                        context,
                        totalExpenses,
                        expenses.length,
                      ),

                      const SizedBox(height: 24),

                      _buildSectionHeader(
                        context,
                        'Spending Analytics',
                        Icons.insights_outlined,
                      ),

                      const SizedBox(height: 14),

                      StatisticsGrid(
                        expenses: expenses,
                        currencyService: widget.currencyService,
                      ),

                      const SizedBox(height: 20),

                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: ExpenseChart(
                            expenses: expenses,
                            currencyService: widget.currencyService,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // CSV and PDF export buttons
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final csvButton = OutlinedButton.icon(
                            onPressed: expenses.isEmpty || _isExporting
                                ? null
                                : () => _exportCsv(expenses),
                            icon: const Icon(Icons.table_view_outlined),
                            label: const Text('Export CSV'),
                          );

                          final pdfButton = OutlinedButton.icon(
                            onPressed: expenses.isEmpty || _isExporting
                                ? null
                                : () => _exportPdf(expenses),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Export PDF'),
                          );

                          final buttons = Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [csvButton, pdfButton],
                          );

                          if (constraints.maxWidth < 650) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  context,
                                  'Recent Expenses',
                                  Icons.receipt_long_outlined,
                                ),
                                const SizedBox(height: 12),
                                buttons,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _buildSectionHeader(
                                  context,
                                  'Recent Expenses',
                                  Icons.receipt_long_outlined,
                                ),
                              ),
                              buttons,
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildFilters(context),

                      const SizedBox(height: 14),

                      Text(
                        '${filteredExpenses.length} of '
                        '${expenses.length} expenses',
                        style: theme.textTheme.bodySmall,
                      ),

                      const SizedBox(height: 12),

                      if (filteredExpenses.isEmpty)
                        _buildEmptyState(expenses.isNotEmpty)
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredExpenses.length,
                          itemBuilder: (context, index) {
                            final expense = filteredExpenses[index];

                            return ExpenseCard(
                              expense: expense,
                              currencyService: widget.currencyService,
                              onDelete: () => _removeExpense(expense),
                              onEdit: () => _openEditExpense(expense),
                            );
                          },
                        ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
