import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/database.dart';
import 'package:flutter/material.dart';

class Deck extends ChangeNotifier {
  final int id;
  String _name;
  final ArkhamCard investigator;
  final String deckOptions;
  final int size;
  final int signaturesCount;
  final Map<String, DeckCard> _main = {};
  final Map<String, DeckCard> _side = {};

  Deck({
    required this.id,
    required String name,
    required this.investigator,
    required this.deckOptions,
    required this.size,
    required this.signaturesCount,
  }) : _name = name;

  String get name => _name;

  static Future<void> initInDb(String name, SimplifiedCard investigator) async {
    final db = await DatabaseHelper.instance.db;
    final deckRequirements =
        (await db.query(
              'cards',
              columns: ['deck_requirements'],
              where: 'code = ?',
              whereArgs: [investigator.code],
            )).first['deck_requirements']
            as String;
    final parts = deckRequirements.split(',').map((s) => s.trim());
    int size = 0;
    List<String> cards = ['01000'];

    for (final part in parts) {
      if (part.startsWith('size:')) {
        size = int.parse(part.substring(5));
      } else if (part.startsWith('card:')) {
        final codes = part.split(':');
        cards.add(codes[1]);
      }
    }

    final deckId = await db.insert('decks', {
      'name': name,
      'investigator_code': investigator.code,
      'size': size,
      'signatures_count': cards.length,
    });

    await Future.wait(
      cards.map(
        (cardCode) => db.insert('deck_cards', {
          'deck_id': deckId,
          'card_code': cardCode,
          'count': 1,
          'side_deck': 0,
        }),
      ),
    );
  }

  Future<void> updateName(String newName) async {
    _name = newName;
    notifyListeners();

    final db = await DatabaseHelper.instance.db;
    await db.update(
      'decks',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  List<SimplifiedCard> get deckCards =>
      _main.values.map((card) => card.card).toList(growable: false);

  List<SimplifiedCard> get sideCards =>
      _side.values.map((card) => card.card).toList(growable: false);

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['deck_name'],
      deckOptions: map['deck_options'],
      size: map['size'],
      signaturesCount: map['signatures_count'],
      investigator: ArkhamCard.fromMap(map),
    );
  }

  DeckCard lookup(SimplifiedCard card, {required bool side}) =>
      (side ? _side[card.code] : _main[card.code]) ?? DeckCard(card, 0, side);

  void addCard(DeckCard cardToAdd) {
    final collection = cardToAdd.side ? _side : _main;
    final deckCard = collection[cardToAdd.card.code];
    if (deckCard == null) {
      collection[cardToAdd.card.code] = DeckCard(
        cardToAdd.card,
        1,
        cardToAdd.side,
      );
    } else if (deckCard.count < deckCard.card.deckLimit) {
      deckCard.count++;
    }

    notifyListeners();
  }

  void removeCard(DeckCard cardToRemove) {
    final collection = cardToRemove.side ? _side : _main;
    final deckCard = collection[cardToRemove.card.code];

    if (deckCard == null) {
      return;
    }
    if (deckCard.count > 1) {
      deckCard.count--;
    } else {
      collection.remove(cardToRemove.card.code);
    }

    notifyListeners();
  }

  String get investigatorName => investigator.name;

  int get cardsCount => _main.values.fold(0, (acc, el) => acc + el.count);

  int get xpCount =>
      _main.values.fold(0, (acc, el) => acc + el.count * (el.card.level ?? 0));

  int get nonExtraCardsCount => cardsCount - signaturesCount;

  Future<void> fetchCards() async {
    final db = await DatabaseHelper.instance.db;
    final rows = await db.rawQuery(
      'SELECT * FROM cards JOIN deck_cards on card_code = code WHERE deck_cards.deck_id = ?',
      [id],
    );

    _main.clear();
    _side.clear();

    rows.map((map) => DeckCard.fromMap(map)).forEach((deckCard) {
      if (deckCard.side) {
        _side[deckCard.card.code] = deckCard;
      } else {
        _main[deckCard.card.code] = deckCard;
      }
    });
  }

  Future<void> storeCardsToDb() async {
    final db = await DatabaseHelper.instance.db;
    await db.delete('deck_cards', where: 'deck_id = ?', whereArgs: [id]);
    final batch = db.batch();

    for (final card in _main.values) {
      batch.insert('deck_cards', card.toMap(id));
    }

    for (final card in _side.values) {
      batch.insert('deck_cards', card.toMap(id));
    }

    await batch.commit(noResult: true);
  }
}

class DeckCard {
  final SimplifiedCard card;
  int count;
  final bool side;

  DeckCard(this.card, this.count, this.side);

  DeckCard.fromMap(Map<String, dynamic> map)
    : card = SimplifiedCard.fromMap(map),
      count = map['count'],
      side = map['side_deck'] == 1;

  Map<String, dynamic> toMap(int deckId) {
    return {
      'deck_id': deckId,
      'card_code': card.code,
      'count': count,
      'side_deck': side ? 1 : 0,
    };
  }
}
