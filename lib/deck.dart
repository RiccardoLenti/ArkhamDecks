import 'package:arkham_decks/arkham_card.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class Deck extends ChangeNotifier {
  final String name;
  final String investigatorName;
  final String deckOptions;
  final List<DeckCard> deckCards = [];

  Deck({
    required this.name,
    required this.investigatorName,
    required this.deckOptions,
  });

  List<SimplifiedCard> get cards =>
      deckCards.map((deckCard) => deckCard.card).toList();

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
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
    final deckCard = deckCards.firstWhereOrNull((d) => d.card.code == cardToAdd.card.code);
    if (deckCard == null) {
      deckCards.add(DeckCard(cardToAdd.card, 1));
    } else if (deckCard.count < 2) {
      //TODO: this needs to be adjusted for myriads
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
}

class DeckCard {
  final SimplifiedCard card;
  int count;

  DeckCard(this.card, this.count);
}
