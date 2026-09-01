import 'package:drift/drift.dart';

class OutboxEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get registroLocalId => text().nullable()();
  TextColumn get endpoint => text()();
  TextColumn get method => text()(); // POST, PUT
  TextColumn get payloadJson => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending|syncing|done|failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
}
