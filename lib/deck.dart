import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/database.dart';
import 'package:flutter/material.dart';

class Deck extends ChangeNotifier {
  final int id;
  String _name;
  final ArkhamCard investigator;
  final String deckOptions;
  final Map<String, DeckCard> _main = {};
  final Map<String, DeckCard> _side = {};

  Deck({
    required this.id,
    required String name,
    required this.investigator,
    required this.deckOptions,
  }) : _name = name;

  String get name => _name;

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
