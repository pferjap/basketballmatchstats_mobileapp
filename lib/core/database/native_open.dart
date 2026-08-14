import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the production on-disk SQLite connection for [AppDatabase].
///
/// Kept in a dedicated file (excluded from Drift codegen) because it pulls in
/// Flutter/platform plugins; the database class itself stays platform-agnostic
/// and receives this executor via its constructor.
QueryExecutor openHoopDatabase() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hoop_analytics.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
