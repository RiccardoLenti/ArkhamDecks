import 'dart:core';

import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CardList {
  final List<SimplifiedCard> investigators;
  final List<SimplifiedCard> assets;
  final List<SimplifiedCard> events;
  final List<SimplifiedCard> skills;
  final List<SimplifiedCard> others;

  const CardList({
    List<SimplifiedCard>? investigators,
    List<SimplifiedCard>? assets,
    List<SimplifiedCard>? events,
    List<SimplifiedCard>? skills,
    List<SimplifiedCard>? others,
  }) : investigators = investigators ?? const [],
       assets = assets ?? const [],
       events = events ?? const [],
       skills = skills ?? const [],
       others = others ?? const [];

  List<SimplifiedCard> get cards => [
    ...investigators,
    ...assets,
    ...events,
    ...skills,
    ...others,
  ];

  int get length =>
      investigators.length +
      assets.length +
      events.length +
      skills.length +
      others.length;

  static Future<CardList> queryDb(String query, List<String> args) async {
    final db = await DatabaseHelper.instance.db;

    final res = await Future.wait([
      _queryType(db, query, args, 'investigator'),
      _queryType(db, query, args, 'asset'),
      _queryType(db, query, args, 'event'),
      _queryType(db, query, args, 'skill'),
      _queryOthers(db, query, args),
    ]);

    return CardList(
      investigators: res[0],
      assets: res[1],
      events: res[2],
      skills: res[3],
      others: res[4],
    );
  }

  static Future<List<SimplifiedCard>> _queryType(
    Database db,
    String baseWhere,
    List<String> args,
    String type,
  ) async {
    final String extraWhere = 'type_code =  ?';
    final String where =
        baseWhere.isEmpty ? extraWhere : '($baseWhere) AND $extraWhere';

    final maps = await db.query(
      'cards',
      where: where,
      whereArgs: [...args, type],
    );

    return maps.map((map) => SimplifiedCard.fromMap(map)).toList();
  }

  static Future<List<SimplifiedCard>> _queryOthers(
    Database db,
    String baseWhere,
    List<String> args,
  ) async {
    final String extraWhere = 'type_code NOT IN (?, ?, ?, ?)';
    final String where =
        baseWhere.isEmpty ? extraWhere : '($baseWhere) AND $extraWhere';

    final maps = await db.query(
      'cards',
      where: where,
      whereArgs: [...args, 'investigator', 'asset', 'event', 'skill'],
    );

    return maps.map((map) => SimplifiedCard.fromMap(map)).toList();
  }

  List<Section> get sections {
    return [
      Section(name: 'Investigator', cards: investigators),
      Section(name: 'Asset', cards: assets),
      Section(name: 'Event', cards: events),
      Section(name: 'Skill', cards: skills),
      Section(name: 'Other', cards: others),
    ];
  }

  int globalIndex(String sectionName, int index) {
    int offset = 0;

    switch (sectionName) {
      case 'Asset':
        offset = investigators.length;
        break;

      case 'Event':
        offset = investigators.length + assets.length;
        break;

      case 'Skill':
        offset = investigators.length + assets.length + events.length;
        break;

      case 'Other':
        offset =
            investigators.length +
            assets.length +
            events.length +
            skills.length;
        break;
    }

    return index + offset;
  }
}

class Section {
  final String name;
  final List<SimplifiedCard> cards;

  const Section({required this.name, required this.cards});
}
