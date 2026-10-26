import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';
import '../models/recurring_schedule.dart';

class FirestoreExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please log in first.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _db.collection('users').doc(_uid).collection('expenses');

  CollectionReference<Map<String, dynamic>> get _schedules =>
      _db.collection('users').doc(_uid).collection('recurringSchedules');

  Stream<List<Expense>> watchExpenses() {
    final collection = _expenses;
    return collection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Expense.fromFirestore).toList());
  }

  Stream<List<RecurringSchedule>> watchSchedules() {
    final collection = _schedules;
    return collection.snapshots().map((snapshot) {
      final schedules = snapshot.docs
          .map(RecurringSchedule.fromDocument)
          .toList();

      schedules.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      return schedules;
    });
  }

  // The original date is always used as the anchor.
  // Jan 31 -> Feb 28 -> Mar 31, without date drift.
  static DateTime occurrenceDate(DateTime anchor, String frequency, int index) {
    if (index < 0) {
      throw ArgumentError('Index cannot be negative');
    }

    if (frequency == 'Daily' || frequency == 'Weekly') {
      final days = frequency == 'Daily' ? index : index * 7;
      return DateTime(
        anchor.year,
        anchor.month,
        anchor.day + days,
        anchor.hour,
        anchor.minute,
        anchor.second,
        anchor.millisecond,
        anchor.microsecond,
      );
    }

    if (frequency == 'Monthly' || frequency == 'Yearly') {
      final firstDay = frequency == 'Monthly'
          ? DateTime(anchor.year, anchor.month + index, 1)
          : DateTime(anchor.year + index, anchor.month, 1);

      final lastDay = DateTime(firstDay.year, firstDay.month + 1, 0).day;

      final day = anchor.day > lastDay ? lastDay : anchor.day;

      return DateTime(
        firstDay.year,
        firstDay.month,
        day,
        anchor.hour,
        anchor.minute,
        anchor.second,
        anchor.millisecond,
        anchor.microsecond,
      );
    }

    throw ArgumentError('Unsupported frequency: $frequency');
  }

  // Find the first occurrence strictly after now.
  static int nextFutureIndex(
    DateTime anchor,
    String frequency,
    DateTime now, {
    int startIndex = 1,
  }) {
    var index = startIndex;

    // Protect against invalid data or extreme schedules.
    for (var attempt = 0; attempt < 100000; attempt++) {
      final date = occurrenceDate(anchor, frequency, index);
      if (date.isAfter(now)) return index;
      index++;
    }

    throw StateError('Schedule is too old to process safely.');
  }

  // New recurring expenses create a separate schedule.
  // The initial expense is saved as a normal transaction.
  Future<void> addExpense(Expense expense) async {
    if (!expense.isRecurring) {
      await _expenses.doc(expense.id).set(expense.toFirestore());
      return;
    }

    final index = nextFutureIndex(
      expense.date,
      expense.recurrence,
      DateTime.now(),
    );

    final batch = _db.batch();
    final expenseRef = _expenses.doc(expense.id);
    final scheduleRef = _schedules.doc(expense.id);

    batch.set(expenseRef, {...expense.toFirestore(), 'isRecurring': false});

    batch.set(scheduleRef, {
      'title': expense.title,
      'amount': expense.amount,
      'category': expense.category,
      'frequency': expense.recurrence,
      'status': 'active',
      'anchorDate': Timestamp.fromDate(expense.date),
      'nextIndex': index,
      'nextDueDate': Timestamp.fromDate(
        occurrenceDate(expense.date, expense.recurrence, index),
      ),
    });

    await batch.commit();
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenses.doc(expense.id).update({
      ...expense.toFirestore(),
      // Individual expense editing cannot create a schedule.
      'isRecurring': false,
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expenses.doc(expenseId).delete();
  }

  // Migrates legacy recurring roots without deleting history.
  // Existing generated occurrences are left untouched.
  Future<int> migrateLegacyRecurringExpenses() async {
    final expenseCollection = _expenses;
    final scheduleCollection = _schedules;

    final legacy = await expenseCollection
        .where('isRecurring', isEqualTo: true)
        .get();

    var migrated = 0;

    for (final doc in legacy.docs) {
      final expense = Expense.fromFirestore(doc);

      // Generated records are never schedule roots.
      if (expense.recurringParentId != null) continue;

      final scheduleRef = scheduleCollection.doc(doc.id);
      final now = DateTime.now();

      final index = nextFutureIndex(expense.date, expense.recurrence, now);

      final created = await _db.runTransaction<bool>((tx) async {
        final existingSchedule = await tx.get(scheduleRef);
        final currentExpense = await tx.get(doc.reference);

        if (existingSchedule.exists ||
            !currentExpense.exists ||
            currentExpense.data()?['isRecurring'] != true) {
          return false;
        }

        tx.set(scheduleRef, {
          'title': expense.title,
          'amount': expense.amount,
          'category': expense.category,
          'frequency': expense.recurrence,
          'status': 'active',
          'anchorDate': Timestamp.fromDate(expense.date),
          'nextIndex': index,
          'nextDueDate': Timestamp.fromDate(
            occurrenceDate(expense.date, expense.recurrence, index),
          ),
        });

        tx.update(doc.reference, {'isRecurring': false});
        return true;
      });

      if (created) migrated++;
    }

    return migrated;
  }

  // Generate due expenses using transactions and stable IDs.
  // Up to 100 due occurrences per schedule per run.
  Future<void> processRecurringExpenses() async {
    final scheduleCollection = _schedules;
    final expenseCollection = _expenses;
    final userId = _uid;

    final snapshot = await scheduleCollection
        .where('status', isEqualTo: 'active')
        .get();

    for (final scheduleDoc in snapshot.docs) {
      for (var attempt = 0; attempt < 100; attempt++) {
        // Stop if the user has switched accounts.
        if (FirebaseAuth.instance.currentUser?.uid != userId) {
          return;
        }

        final processed = await _db.runTransaction<bool>((tx) async {
          final current = await tx.get(scheduleDoc.reference);
          if (!current.exists) return false;

          final schedule = RecurringSchedule.fromDocument(current);

          if (schedule.status != 'active') return false;

          final now = DateTime.now();
          if (schedule.nextDueDate.isAfter(now)) return false;

          final dueDate = schedule.nextDueDate;
          final index = schedule.nextIndex;

          final revision = (current.data()?['revision'] as num?)?.toInt() ?? 0;

          final occurrenceId =
              '${schedule.id}_revision_${revision}_scheduled_$index';

          final expenseRef = expenseCollection.doc(occurrenceId);
          final existingExpense = await tx.get(expenseRef);

          if (!existingExpense.exists) {
            tx.set(expenseRef, {
              'title': schedule.title,
              'amount': schedule.amount,
              'category': schedule.category,
              'date': Timestamp.fromDate(dueDate),
              'isRecurring': false,
              'recurrence': schedule.frequency,
              'recurringParentId': schedule.id,
            });
          }

          final nextIndex = index + 1;
          final nextDate = occurrenceDate(
            schedule.anchorDate,
            schedule.frequency,
            nextIndex,
          );

          tx.update(scheduleDoc.reference, {
            'nextIndex': nextIndex,
            'nextDueDate': Timestamp.fromDate(nextDate),
          });

          return true;
        });

        if (!processed) break;
      }
    }
  }

  Future<void> pauseSchedule(String id) async {
    await _schedules.doc(id).update({'status': 'paused'});
  }

  Future<void> resumeSchedule(String id) async {
    final ref = _schedules.doc(id);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw StateError('Schedule not found');

      final schedule = RecurringSchedule.fromDocument(doc);
      if (schedule.status == 'stopped') {
        throw StateError('Stopped schedules cannot be resumed');
      }

      final index = nextFutureIndex(
        schedule.anchorDate,
        schedule.frequency,
        DateTime.now(),
        startIndex: schedule.nextIndex,
      );

      tx.update(ref, {
        'status': 'active',
        'nextIndex': index,
        'nextDueDate': Timestamp.fromDate(
          occurrenceDate(schedule.anchorDate, schedule.frequency, index),
        ),
      });
    });
  }

  Future<void> stopSchedule(String id) async {
    await _schedules.doc(id).update({'status': 'stopped'});
  }

  // Changes future occurrences only.
  Future<void> editSchedule({
    required String id,
    required String title,
    required double amount,
    required String category,
    required String frequency,
  }) async {
    final ref = _schedules.doc(id);

    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw StateError('Schedule not found');

      final schedule = RecurringSchedule.fromDocument(doc);

      if (schedule.status == 'stopped') {
        throw StateError('Stopped schedules cannot be edited');
      }

      final updates = <String, dynamic>{
        'title': title,
        'amount': amount,
        'category': category,
      };

      if (frequency != schedule.frequency) {
        // Changing frequency starts a new schedule from now.
        // A new anchor prevents conflicts with old occurrences.
        final anchor = DateTime.now();
        final nextIndex = 1;

        updates.addAll({
          'frequency': frequency,
          'anchorDate': Timestamp.fromDate(anchor),
          'nextIndex': nextIndex,
          'nextDueDate': Timestamp.fromDate(
            occurrenceDate(anchor, frequency, nextIndex),
          ),
        });

        // A frequency change needs a new occurrence ID namespace.
        // We address that with a revision counter below.
        updates['revision'] =
            ((doc.data()?['revision'] as num?)?.toInt() ?? 0) + 1;
      }

      tx.update(ref, updates);
    });
  }
}
