import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/investigator_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

List<SimplifiedCard> factionCards(int count, String faction) => List.generate(
  count,
  (index) => testCard(code: '$faction$index', faction: faction, level: 1),
);

List<SimplifiedCard> skills(int count) => List.generate(
  count,
  (index) => testCard(code: 's$index', faction: 'guardian', type: 'skill'),
);

SimplifiedCard ancestralCard() => testCard(
  code: '07303',
  faction: 'seeker',
  level: 3,
  deckLimit: 1,
  deckOptions: ancestralOptions,
);

void main() {
  group('Lola', () {
    test('7 each from 3 factions is valid', () {
      final deck = testDeck(lolaOptions, size: 21);

      addCards(deck, factionCards(7, 'guardian'));
      addCards(deck, factionCards(7, 'seeker'));
      addCards(deck, factionCards(7, 'rogue'));

      expect(deck.validate(), isNull);
    });

    test('6 from a third faction is not enough', () {
      final deck = testDeck(lolaOptions, size: 21);

      addCards(deck, factionCards(8, 'guardian'));
      addCards(deck, factionCards(7, 'seeker'));
      addCards(deck, factionCards(6, 'rogue'));

      expect(deck.validate()?.text, lolaAtLeastError);
    });

    test('21 cards from 2 factions is not enough', () {
      final deck = testDeck(lolaOptions, size: 21);

      addCards(deck, factionCards(14, 'guardian'));
      addCards(deck, factionCards(7, 'seeker'));

      expect(deck.validate()?.text, lolaAtLeastError);
    });

    test('neutral cards do not count toward a faction group', () {
      final deck = testDeck(lolaOptions, size: 21);

      addCards(deck, factionCards(7, 'guardian'));
      addCards(deck, factionCards(7, 'seeker'));
      addCards(deck, factionCards(7, 'neutral'));

      expect(deck.validate()?.text, lolaAtLeastError);
    });

    test('a multiclass card counts for both of its factions', () {
      final deck = testDeck(lolaOptions, size: 21);

      addCards(deck, factionCards(7, 'guardian'));
      addCards(deck, factionCards(7, 'seeker'));
      addCards(deck, factionCards(6, 'rogue'));
      addCards(deck, [
        testCard(code: 'm1', faction: 'mystic', faction2: 'rogue', level: 1),
      ]);

      expect(deck.validate(), isNull);
    });

    test('level 4-5 cards fall outside the option and do not count', () {
      final deck = testDeck(lolaOptions, size: 21);

      addCards(deck, factionCards(7, 'guardian'));
      addCards(deck, factionCards(7, 'seeker'));
      addCards(deck, factionCards(6, 'rogue'));
      addCards(deck, [testCard(code: 'r9', faction: 'rogue', level: 4)]);

      expect(deck.validate()?.text, lolaAtLeastError);
    });

    test('an incomplete deck reports the minimum before its size', () {
      final deck = testDeck(lolaOptions, size: 21);

      addCards(deck, factionCards(7, 'guardian'));

      expect(deck.validate()?.text, lolaAtLeastError);
    });
  });

  group('Ancestral Knowledge', () {
    test('fewer than 10 skills is reported', () {
      final deck = testDeck(zoeyOptions, size: 5);

      addCards(deck, [ancestralCard()]);
      addCards(deck, skills(9));

      expect(deck.validate()?.text, ancestralAtLeastError);
    });

    test('10 skills is valid', () {
      final deck = testDeck(zoeyOptions, size: 6);

      addCards(deck, [ancestralCard()]);
      addCards(deck, skills(10));

      expect(deck.validate(), isNull);
    });

    test('removing the card removes the rule', () {
      final deck = testDeck(zoeyOptions, size: 5);
      final ancestral = ancestralCard();
      final cards = skills(9);

      addCards(deck, [ancestral]);
      addCards(deck, cards);

      expect(deck.validate()?.text, ancestralAtLeastError);

      deck.removeCard(deck.lookup(ancestral, side: false));
      for (final card in cards.take(4)) {
        deck.removeCard(deck.lookup(card, side: false));
      }

      expect(deck.validate(), isNull);
    });

    test('an off-class skill still charges a Zoey slot', () {
      final deck = testDeck(zoeyOptions, size: 7);

      addCards(deck, [ancestralCard()]);
      addCards(
        deck,
        List.generate(
          5,
          (index) => testCard(code: 'r$index', faction: 'rogue'),
        ),
      );
      addCards(deck, [testCard(code: 'rs1', faction: 'rogue', type: 'skill')]);

      expect(deck.validate()?.text, zoeyLimitError);
    });
  });

  test('a virtual option does not widen the pool', () {
    final filter = InvestigatorFilter(zoeyOptions)
      ..setExtraOptions([ancestralOptions]);

    expect(filter.whereClause.sql, isNot(contains('type_code IN')));
    expect(filter.whereClause.args, isNot(contains('skill')));
  });
}
