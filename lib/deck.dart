import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/database.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class Deck extends ChangeNotifier {
  final int id;
  final String name;
  final String investigatorName;
  final String deckOptions;
  List<DeckCard> deckCards = [];

  Deck({
    required this.id,
    required this.name,
    required this.investigatorName,
    required this.deckOptions,
  });

  List<SimplifiedCard> get cards =>
      deckCards.map((deckCard) => deckCard.card).toList();

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['name'],
      investigatorName: map['investigator_name'],
      deckOptions: map['deck_options'],
    );
  }

  // TODO: make deckCards a map for O(1) lookup
  DeckCard getDeckCard(SimplifiedCard card) {
    // TODO: override equality operator for this type
    return deckCards.firstWhereOrNull(
          (deckCard) => deckCard.card.code == card.code,
        ) ??
        DeckCard(card, 0);
  }

  void addCard(DeckCard cardToAdd) {
    final deckCard = deckCards.firstWhereOrNull(
      (d) => d.card.code == cardToAdd.card.code,
    );
    if (deckCard == null) {
      deckCards.add(DeckCard(cardToAdd.card, 1));
    } else if (deckCard.count < deckCard.card.deckLimit) {
      deckCard.count++;
    }
    notifyListeners();
  }

  void removeCard(DeckCard cardToRemove) {
    final deckCard = deckCards.firstWhereOrNull(
      (d) => d.card.code == cardToRemove.card.code,
    );
    if (deckCard == null) {
      return;
    }
    if (deckCard.count > 1) {
      deckCard.count--;
    } else {
      deckCards.remove(cardToRemove);
    }

    notifyListeners();
  }

  Future<void> fetchCards() async {
    final db = await DatabaseHelper.instance.db;
    final rows = await db.rawQuery(
      'SELECT * FROM cards JOIN deck_cards on card_code = code WHERE deck_cards.deck_id = ?',
      [id],
    );

    deckCards = rows.map((map) => DeckCard.fromMap(map)).toList();
  }

  Future<void> storeCardsToDb() async {
    final db = await DatabaseHelper.instance.db;
    await db.delete('deck_cards', where: 'deck_id = ?', whereArgs: [id]);
    final batch = db.batch();

    for (final card in deckCards) {
      batch.insert('deck_cards', {
        'deck_id': id,
        'card_code': card.card.code,
        'count': card.count,
      });
    }

    await batch.commit();
  }
}

class DeckCard {
  final SimplifiedCard card;
  int count;

  DeckCard(this.card, this.count);

  DeckCard.fromMap(Map<String, dynamic> map)
    : card = SimplifiedCard.fromMap(map),
      count = map['count'];
}
