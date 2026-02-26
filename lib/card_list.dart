import 'dart:core';

import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/database.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class CardList {
  final List<SectionCards> _sections;

  const CardList({List<SectionCards>? sections})
    : _sections = sections ?? const [];

  factory CardList.fromLists(
    List<SimplifiedCard> investigators,
    List<SimplifiedCard> assets,
    List<SimplifiedCard> events,
    List<SimplifiedCard> skills,
    List<SimplifiedCard> others,
  ) {
    final assetsSplit = _splitAssets(assets, investigators.length);
    final cards = [investigators, ...assetsSplit, events, skills, others];
    final List<SectionCards> sectionCards = [];

    for (final (index, section) in Section.values.indexed) {
      sectionCards.add(
        SectionCards(
          section: section,
          cards: cards[index],
          offset:
              index == 0
                  ? 0
                  : sectionCards[index - 1].offset +
                      sectionCards[index - 1].cards.length,
        ),
      );
    }

    return CardList(sections: sectionCards);
  }

  factory CardList.fromList(List<SimplifiedCard> cards) {
    final List<SimplifiedCard> investigators = [],
        assets = [],
        events = [],
        skills = [],
        others = [];

    for (final card in cards) {
      switch (card.type) {
        case 'investigator':
          investigators.add(card);
          break;

        case 'asset':
          assets.add(card);
          break;

        case 'event':
          events.add(card);
          break;

        case 'skill':
          skills.add(card);
          break;

        default:
          others.add(card);
          break;
      }
    }

    return CardList.fromLists(investigators, assets, events, skills, others);
  }

  static List<List<SimplifiedCard>> _splitAssets(
    List<SimplifiedCard> assets,
    int startingOffset,
  ) {
    final Map<String, List<SimplifiedCard>> map = {
      for (final section in Section.assets()) section.slots!.join('|'): [],
    };

    for (final card in assets) {
      if (card.slots == null) {
        continue;
      }

      map[card.slots!.join('|')]!.add(card);
    }

    return Section.assets()
        .map((section) => map[section.slots!.join('|')]!)
        .toList(growable: false);
  }

  List<SimplifiedCard> get cards =>
      _sections.fold([], (acc, el) => [...acc, ...el.cards]);

  int get length =>
      _sections.fold(0, (value, element) => value + element.cards.length);

  static Future<CardList> queryDb(String query, List<String> args) async {
    final db = await DatabaseHelper.instance.db;

    final res = await Future.wait([
      _queryType(db, query, args, 'investigator'),
      _queryType(db, query, args, 'asset'),
      _queryType(db, query, args, 'event'),
      _queryType(db, query, args, 'skill'),
      _queryOthers(db, query, args),
    ]);

    return CardList.fromLists(res[0], res[1], res[2], res[3], res[4]);
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
      'cards JOIN printings AS printing on cards.code = printing.canonical_code',
      columns: [
        'cards.code',
        'cards.name',
        'cards.subname',
        'cards.type_code',
        'cards.faction_code',
        'cards.faction2_code',
        'cards.faction3_code',
        'cards.cost',
        'cards.xp',
        'cards.deck_limit',
        'cards.slot',
        'printing.pack_code',
        'printing.position',
        'printing.quantity',
      ],
      where: where,
      whereArgs: [...args, type],
      groupBy: 'cards.code',
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
      'cards JOIN printings AS printing on cards.code = printing.canonical_code',
      columns: [
        'cards.code',
        'cards.name',
        'cards.subname',
        'cards.type_code',
        'cards.faction_code',
        'cards.faction2_code',
        'cards.faction3_code',
        'cards.cost',
        'cards.xp',
        'cards.deck_limit',
        'cards.slot',
        'printing.pack_code',
        'printing.position',
        'printing.quantity',
      ],
      where: where,
      whereArgs: [...args, 'investigator', 'asset', 'event', 'skill'],
      groupBy: 'cards.code',
    );

    return maps.map((map) => SimplifiedCard.fromMap(map)).toList();
  }

  List<SectionCards> get sections => List.unmodifiable(_sections);

  int offset(Section section) {
    return _sections.firstWhere((s) => s.section == section).offset;
  }
}

class SectionCards {
  final Section section;
  final List<SimplifiedCard> cards;
  final int offset;

  const SectionCards({
    required this.section,
    required this.cards,
    required this.offset,
  });
}

enum Section {
  investigator('Investigator', null),
  hand('Asset', ['Hand']),
  handx2('Asset', ['Hand x2']),
  accessory('Asset', ['Accessory']),
  ally('Asset', ['Ally']),
  arcane('Asset', ['Arcane']),
  arcanex2('Asset', ['Arcane x2']),
  body('Asset', ['Body']),
  tarot('Asset', ['Tarot']),
  bodyArcane('Asset', ['Body', 'Arcane']),
  bodyHandx2('Asset', ['Body', 'Hand x2']),
  handArcane('Asset', ['Hand', 'Arcane']),
  handx2Arcane('Asset', ['Hand x2', 'Arcane']),
  allyArcane('Asset', ['Ally', 'Arcane']),
  asset('Asset', []),
  event('Event', null),
  skill('Skill', null),
  other('Other', null);

  const Section(this.name, this.slots);

  final String name;
  final List<String>? slots;

  static List<Section> assets() => [
    hand,
    handx2,
    accessory,
    ally,
    arcane,
    arcanex2,
    body,
    tarot,
    bodyArcane,
    bodyHandx2,
    handArcane,
    handx2Arcane,
    allyArcane,
    asset,
  ];
}
