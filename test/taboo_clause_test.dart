import 'dart:io';

import 'package:arkham_decks/arkham_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    db = await databaseFactory.openDatabase(
      join(Directory.current.path, 'assets', 'db', 'app.db'),
      options: OpenDatabaseOptions(readOnly: true),
    );
    TabooClause.initValues(await db.query('taboos', orderBy: 'code'));
  });

  Future<SimplifiedCard> simplified(TabooClause taboo, String code) async {
    final rows = await db.rawQuery(
      'SELECT card_simplified.*, ${taboo.columns('card_simplified')} '
      'FROM card_simplified ${taboo.join('card_simplified')} '
      'WHERE card_simplified.code = ?',
      [...taboo.args, code],
    );

    return SimplifiedCard.fromMap(rows.first);
  }

  Future<ArkhamCard> detailed(TabooClause taboo, String code) async {
    final rows = await db.rawQuery(
      'SELECT card_details.*, ${taboo.detailColumns('card_details')} '
      'FROM card_details ${taboo.join('card_details')} '
      'WHERE card_details.code = ?',
      [...taboo.args, code],
    );

    return ArkhamCard.fromMap(rows.first, printings: const []);
  }

  Future<String> requirements(TabooClause taboo, String code) async =>
      (await db.rawQuery(
            'SELECT ${taboo.resolve('deck_requirements', 'card_simplified')} '
            'FROM card_simplified ${taboo.join('card_simplified')} '
            'WHERE card_simplified.code = ?',
            [...taboo.args, code],
          )).first['deck_requirements']
          as String;

  group('a bound list resolves the printed columns', () {
    test('Key of Ys gains exceptional', () async {
      expect((await simplified(TabooClause('010'), '03315')).exceptional, true);
      expect((await detailed(TabooClause('010'), '03315')).exceptional, true);
    });

    test('Flute of the Outer Gods loses it', () async {
      expect(
        (await simplified(TabooClause('010'), '07268')).exceptional,
        false,
      );
      expect((await simplified(TabooClause('010'), '07268')).deckLimit, 1);
    });

    test('a banned card drops to zero copies', () async {
      expect((await simplified(TabooClause('010'), '02026')).deckLimit, 0);
    });

    test("Mandy's deck size and signature count change", () async {
      expect(
        await requirements(TabooClause('010'), '06002'),
        contains('size:50'),
      );
    });

    test('Runic Axe swaps its customization sheet', () async {
      final sheet = (await detailed(TabooClause('010'), '09022')).taboo!;
      expect(sheet.customizationText.any((row) => row.startsWith('□□')), true);
    });
  });

  group('a null list leaves every column printed', () {
    const none = TabooClause(null);

    test('Key of Ys is not exceptional', () async {
      expect((await simplified(none, '03315')).exceptional, false);
    });

    test('Flute of the Outer Gods keeps its printed exceptional', () async {
      expect((await simplified(none, '07268')).exceptional, true);
    });

    test('a banned card keeps its printed limit', () async {
      expect((await simplified(none, '02026')).deckLimit, 2);
    });

    test("Mandy keeps her printed deck size", () async {
      expect(await requirements(none, '06002'), contains('size:30'));
    });

    test('no taboo is attached to the card', () async {
      expect((await simplified(none, '03315')).taboo, isNull);
      expect((await detailed(none, '09022')).taboo, isNull);
    });
  });

  group('the join never shadows a card column', () {
    // every filter writes its where clause with bare column names
    for (final clause in const [
      'code IN (?, ?)',
      'xp BETWEEN ? AND ?',
      'text IS NOT ?',
      'customization_text IS NOT ?',
      'deck_limit > ?',
      'exceptional = ?',
      'deck_options IS NOT ?',
      'deck_requirements IS NOT ?',
    ]) {
      test(clause, () async {
        const taboo = TabooClause('010');
        final args = List.filled(RegExp(r'\?').allMatches(clause).length, '0');

        await expectLater(
          db.rawQuery(
            'SELECT card_details.*, ${taboo.detailColumns('card_details')} '
            'FROM card_details ${taboo.join('card_details')} '
            'WHERE $clause',
            [...taboo.args, ...args],
          ),
          completes,
        );
      });
    }
  });

  test('the decks summary query runs', () async {
    const taboo = TabooClause('010');
    final requirements = taboo.value(
      'deck_requirements',
      'investigator_resolved',
      as: 'investigator_taboo',
    );
    final exceptional = taboo.value('exceptional', 'cards', as: 'card_taboo');

    await expectLater(
      db.rawQuery(
        '''SELECT decks.id, decks.name AS deck_name, decks.size AS size,
      decks.signatures_count AS signatures_count, decks.selections AS selections,
      investigator.*,
      ${taboo.resolve('deck_options', 'investigator_resolved', as: 'investigator_taboo', name: 'investigator_deck_options')},
      $requirements AS investigator_deck_requirements,
      IFNULL(SUM(deck_cards.count), 0) AS cards_count,
      IFNULL(SUM(deck_cards.count *
        (IFNULL(cards.xp, 0) * (CASE WHEN $exceptional = 1 THEN 2 ELSE 1 END)
        + IFNULL(card_taboo.taboo_xp, 0))), 0) AS xp_count,
      IFNULL(SUM(CASE WHEN cards.subtype_code IS NULL
        AND instr($requirements, deck_cards.card_code) = 0
        THEN deck_cards.count END), 0) AS non_extra_count
      FROM decks
      JOIN cards AS investigator ON decks.investigator_code = investigator.code
      JOIN card_simplified AS investigator_resolved ON investigator_resolved.code = investigator.code
      ${taboo.join('investigator_resolved', as: 'investigator_taboo')}
      LEFT JOIN deck_cards ON deck_cards.deck_id = decks.id AND deck_cards.side_deck = 0
      LEFT JOIN card_simplified AS cards ON cards.code = deck_cards.card_code
      ${taboo.join('cards', as: 'card_taboo')}
      GROUP BY decks.id
      ORDER BY decks.id DESC''',
        [...taboo.args, ...taboo.args],
      ),
      completes,
    );
  });

  test('two lists resolve differently in the same process', () async {
    expect((await simplified(TabooClause('010'), '02026')).deckLimit, 0);
    expect((await simplified(const TabooClause(null), '02026')).deckLimit, 2);
    expect((await simplified(TabooClause('010'), '02026')).deckLimit, 0);
  });
}
