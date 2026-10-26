import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart' as csv;
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import 'currency_service.dart';

class ExportService {
  Future<void> exportExpensesToCsv({
    required List<Expense> expenses,
    required CurrencyService currencyService,
  }) async {
    final rows = <List<dynamic>>[
      [
        'Title',
        'Amount',
        'Currency',
        'Category',
        'Date',
        'Recurring',
        'Recurrence',
      ],
    ];

    for (final expense in expenses) {
      rows.add([
        expense.title,
        expense.amount.toStringAsFixed(2),
        currencyService.currencyCode,
        expense.category,
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.isRecurring ? 'Yes' : 'No',
        expense.recurrence,
      ]);
    }

    final csvContent = csv.csv.encode(rows);

    // Add UTF-8 BOM for better Excel compatibility.
    final bytes = Uint8List.fromList([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(csvContent),
    ]);

    final filename =
        'expense_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
  }

  Future<void> exportExpensesToPdf({
    required List<Expense> expenses,
    required CurrencyService currencyService,
  }) async {
    final document = pw.Document();

    final sortedExpenses = [...expenses]
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalExpenses = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final categories = [
      'Food',
      'Transport',
      'Shopping',
      'Entertainment',
      'Bills',
      'Other',
    ];

    final categoryTotals = {
      for (final category in categories)
        category: expenses
            .where((expense) => expense.category == category)
            .fold<double>(0, (sum, expense) => sum + expense.amount),
    };

    final currencyCode = currencyService.currencyCode;
    final dateFormat = DateFormat('dd MMM yyyy');

    // Use the currency code for reliable PDF font compatibility.
    String formatPdfAmount(double amount) {
      return '$currencyCode ${amount.toStringAsFixed(2)}';
    }

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'EXPENSE TRACKER',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.grey300),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 12),
          pw.Text(
            'Expense Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Currency setting: $currencyCode',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 24),

          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TOTAL EXPENSES',
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  formatPdfAmount(totalExpenses),
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${expenses.length} transactions',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Category Breakdown',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.TableHelper.fromTextArray(
            headers: ['Category', 'Total'],
            data: categories
                .map(
                  (category) => [
                    category,
                    formatPdfAmount(categoryTotals[category]!),
                  ],
                )
                .toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellPadding: const pw.EdgeInsets.all(8),
          ),

          pw.SizedBox(height: 24),
          pw.Text(
            'Transaction History',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Amount'],
            data: sortedExpenses
                .map(
                  (expense) => [
                    dateFormat.format(expense.date),
                    expense.title,
                    expense.category,
                    formatPdfAmount(expense.amount),
                  ],
                )
                .toList(),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            cellPadding: const pw.EdgeInsets.all(7),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),

          pw.SizedBox(height: 16),
          pw.Text(
            'Note: Currency settings label amounts but do not '
            'perform exchange-rate conversion.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    final bytes = await document.save();

    final filename =
        'expense_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

    await FileSaver.instance.saveFile(
      name: filename,
      bytes: bytes,
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
  }
}
