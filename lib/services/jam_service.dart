import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/jam_session.dart';
import '../models/jam_person.dart';
import '../models/jam_expense.dart';
import '../core/hive_boxes.dart';
import 'transaction_service.dart';

class SettlementTransfer {
  final String from;
  final String to;
  final double amount;
  const SettlementTransfer({required this.from, required this.to, required this.amount});
}

class PersonSummary {
  final JamPerson person;
  final double totalPaid;
  final double fairShare;
  final double balance; // positive = owed money, negative = owes money
  const PersonSummary({
    required this.person,
    required this.totalPaid,
    required this.fairShare,
    required this.balance,
  });
}

class JamService {
  static Box<JamSession> get _sessions  => Hive.box<JamSession>(HiveBoxes.jamSessions);
  static Box<JamPerson>  get _persons   => Hive.box<JamPerson>(HiveBoxes.jamPersons);
  static Box<JamExpense> get _expenses  => Hive.box<JamExpense>(HiveBoxes.jamExpenses);
  static const _uuid = Uuid();

  // ── Sessions ──────────────────────────────────────────
  static List<JamSession> getAllSessions() {
    final list = _sessions.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<String> createSession(String name) async {
    final session = JamSession()
      ..id = _uuid.v4()
      ..name = name
      ..createdAt = DateTime.now()
      ..isSettled = false;
    await _sessions.put(session.id, session);

    // Auto-add owner as "Me"
    final owner = JamPerson()
      ..id = _uuid.v4()
      ..sessionId = session.id
      ..name = 'Me'
      ..isOwner = true;
    await _persons.put(owner.id, owner);

    return session.id;
  }

  static Future<void> deleteSession(String sessionId) async {
    final personIds = _persons.values
        .where((p) => p.sessionId == sessionId)
        .map((p) => p.id)
        .toList();
    for (final pid in personIds) {
      final expIds = _expenses.values
          .where((e) => e.personId == pid)
          .map((e) => e.id)
          .toList();
      for (final eid in expIds) await _expenses.delete(eid);
      await _persons.delete(pid);
    }
    await _sessions.delete(sessionId);
  }

  // ── Persons ───────────────────────────────────────────
  static List<JamPerson> getPersons(String sessionId) {
    final list = _persons.values.where((p) => p.sessionId == sessionId).toList();
    list.sort((a, b) => a.isOwner ? -1 : (b.isOwner ? 1 : 0));
    return list;
  }

  static Future<String> addPerson(String sessionId, String name) async {
    final person = JamPerson()
      ..id = _uuid.v4()
      ..sessionId = sessionId
      ..name = name
      ..isOwner = false;
    await _persons.put(person.id, person);
    return person.id;
  }

  static Future<void> deletePerson(String personId) async {
    final expIds = _expenses.values
        .where((e) => e.personId == personId)
        .map((e) => e.id)
        .toList();
    for (final eid in expIds) await _expenses.delete(eid);
    await _persons.delete(personId);
  }

  // ── Expenses ──────────────────────────────────────────
  static List<JamExpense> getExpensesForPerson(String personId) =>
      _expenses.values.where((e) => e.personId == personId).toList();

  static Future<void> addExpense(
      String personId, String sessionId, String description, double amount) async {
    final expense = JamExpense()
      ..id = _uuid.v4()
      ..personId = personId
      ..sessionId = sessionId
      ..description = description
      ..amount = amount;
    await _expenses.put(expense.id, expense);
  }

  static Future<void> deleteExpense(String expenseId) async =>
      await _expenses.delete(expenseId);

  static double getTotalPaidByPerson(String personId) => _expenses.values
      .where((e) => e.personId == personId)
      .fold(0.0, (sum, e) => sum + e.amount);

  static double getSessionTotal(String sessionId) => _expenses.values
      .where((e) => e.sessionId == sessionId)
      .fold(0.0, (sum, e) => sum + e.amount);

  // ── Settlement ────────────────────────────────────────
  static List<PersonSummary> getPersonSummaries(String sessionId) {
    final persons = getPersons(sessionId);
    if (persons.isEmpty) return [];
    final total = getSessionTotal(sessionId);
    final fairShare = total / persons.length;
    return persons.map((p) {
      final paid = getTotalPaidByPerson(p.id);
      return PersonSummary(
          person: p, totalPaid: paid, fairShare: fairShare, balance: paid - fairShare);
    }).toList();
  }

  // Greedy minimum-transfers algorithm
  static List<SettlementTransfer> calculateSettlement(String sessionId) {
    final summaries = getPersonSummaries(sessionId);
    final transfers = <SettlementTransfer>[];
    final bal = <String, double>{for (final s in summaries) s.person.id: s.balance};
    final nameMap = {for (final s in summaries) s.person.id: s.person.name};

    while (true) {
      String? creditorId, debtorId;
      double maxCredit = 0.005, maxDebt = 0.005;
      for (final e in bal.entries) {
        if (e.value > maxCredit)  { maxCredit = e.value;        creditorId = e.key; }
        if (e.value < -maxDebt)   { maxDebt   = e.value.abs();  debtorId   = e.key; }
      }
      if (creditorId == null || debtorId == null) break;

      final amount = min(maxCredit, maxDebt);
      transfers.add(SettlementTransfer(
        from:   nameMap[debtorId]!,
        to:     nameMap[creditorId]!,
        amount: double.parse(amount.toStringAsFixed(2)),
      ));
      bal[creditorId] = bal[creditorId]! - amount;
      bal[debtorId]   = bal[debtorId]!   + amount;
    }
    return transfers;
  }

  static Future<void> settleSession(String sessionId, String walletId) async {
    final session = _sessions.get(sessionId);
    if (session == null) return;
    final summaries   = getPersonSummaries(sessionId);
    final ownerSummary = summaries.where((s) => s.person.isOwner).firstOrNull;

    if (ownerSummary != null && ownerSummary.fairShare > 0) {
      await TransactionService.add(
        walletId: walletId,
        label:    session.name,
        amount:   ownerSummary.fairShare,
        isExpense: true,
        category: 'Entertainment',
        date:     DateTime.now(),
        note:     'Jam session · my share (${getPersons(sessionId).length} people)',
      );
    }
    session.isSettled = true;
    await session.save();
  }
}