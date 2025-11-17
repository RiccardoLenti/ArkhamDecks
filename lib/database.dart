import 'package:arkham_decks/expansions.dart';
import 'package:path/path.dart';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._instance();
  static Database? _database;
  static final Set<String> _traits = {};

  DatabaseHelper._instance();

  Future<Database> get db async {
    _database ??= await initDb();
    return _database!;
  }

  Set<String> get traitsSet {
    return _traits;
  }

  Future<Database> initDb() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getDatabasesPath();
    final path = join(directory, "working_cards.db");

    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      final data = await rootBundle.load(url.join("assets", "db", "app.db"));
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await File(path).writeAsBytes(bytes, flush: true);
    }

    final db = await openDatabase(path);

    // initialize traits
    final nonUniqueTraits = await db.rawQuery(
      'SELECT DISTINCT traits FROM cards',
    );

    for (final row in nonUniqueTraits) {
      final traitsString = row['traits'] as String?;
      if (traitsString == null || traitsString.isEmpty) {
        continue;
      }

      _traits.addAll(
        traitsString
            .replaceAll('.', '')
            .split(' ')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty),
      );
    }

    // initialize cycles
    final cycles = await db.query('cycles');
    Cycle.initValues(cycles);

    return db;
  }
}
