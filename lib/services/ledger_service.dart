import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'store_codec.dart';

/// Serialized, journaled mutations: interrupted multi-box writes roll back at startup.
class LedgerService {
  static Future<void> _tail = Future.value();
  static Future<void> initialize() async {
    final journal = await Hive.openBox<String>('operationJournal');
    final pending = journal.get('pending');
    if (pending != null) {
      await StoreCodec.replace(
        StoreCodec.decode(
          jsonDecode(pending) as Map<String, dynamic>,
          validateReferences: false,
        ),
      );
      await journal.delete('pending');
      await journal.flush();
    }
  }

  static Future<T> mutate<T>(Future<T> Function() operation) {
    final done = Completer<T>();
    _tail = _tail.then((_) async {
      final journal = Hive.box<String>('operationJournal');
      final before = StoreCodec.snapshot();
      try {
        await journal.put('pending', jsonEncode(before));
        await journal.flush();
        final result = await operation();
        for (final name in StoreCodec.boxes) {
          await StoreCodec.box(name).flush();
        }
        await journal.delete('pending');
        await journal.flush();
        done.complete(result);
      } catch (error, stack) {
        try {
          await StoreCodec.replace(
            StoreCodec.decode(before, validateReferences: false),
          );
          await journal.delete('pending');
          await journal.flush();
        } catch (_) {
          /* Keep the journal so startup can recover. */
        }
        done.completeError(error, stack);
      }
    });
    return done.future;
  }
}
