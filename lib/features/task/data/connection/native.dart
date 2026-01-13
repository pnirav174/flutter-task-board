// import 'dart:io';
// import 'package:drift/drift.dart';
// import 'package:drift/native.dart';
// import 'package:flutter/foundation.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as p;

// LazyDatabase openConnection() {
//   return LazyDatabase(() async {
//     final dir = await getApplicationDocumentsDirectory();
//     final dbFile = File(p.join(dir.path, 'db.sqlite'));
//     return NativeDatabase(dbFile);
//   });
// }
import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
// import 'package:drift/native.dart'; // Remove this
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3/open.dart'; // Add this

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    // Try to load development SQLite if available
    if (Platform.isIOS || Platform.isMacOS) {
      open.overrideFor(OperatingSystem.iOS, () {
        // This might help in simulator
        return DynamicLibrary.open('libsqlite3.dylib');
      });
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(dir.path, 'db.sqlite'));

    return DatabaseConnection(
      NativeDatabase.opened(
        sqlite3.open(dbFile.path),
        // or use this for drift's implementation
        // NativeDatabase.createInBackground(dbFile)
      ),
    );
  });
}
