import 'package:arkham_decks/arkham_card.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

List<SimplifiedCard> offClass(int count, {String prefix = 'r'}) =>
    List.generate(
      count,
      (index) => testCard(code: '$prefix$index', faction: 'rogue'),
    );

void main() {
  group('Zoey', () {
    test('five off-class level 0 cards fit, the sixth does not', () {
      final deck = testDeck(zoeyOptions);
      final cards = offClass(6);

      addCards(deck, cards.take(5));

      expect(deck.cardsCount, 5);
      expect(deck.canAdd(cards[5], side: false), isFalse);

      addCards(deck, [cards[5]]);

      expect(deck.cardsCount, 5);
      expect(deck.validate()?.text, isNot(contains('Guardian')));
    });

    test('in-class and neutral cards keep adding past the limit', () {
      final deck = testDeck(zoeyOptions);

      addCards(deck, offClass(5));
      addCards(deck, [
        testCard(code: 'g1', faction: 'guardian'),
        testCard(code: 'n1', faction: 'neutral'),
      ]);

      expect(deck.cardsCount, 7);
    });

    test('an over-limit deck is reported by validate', () {
      final deck = testDeck(zoeyOptions, size: 7);
      final versatile = testCard(
        code: '06167',
        faction: 'neutral',
        level: 2,
        deckOptions: versatileOptions,
      );

      addCards(deck, [versatile, versatile]);
      addCards(deck, offClass(7));

      expect(deck.cardsCount, 9);

      deck.removeCard(deck.lookup(versatile, side: false));

      expect(deck.validate()?.text, 'Too many off-class cards for Versatile');
    });
  });

  group('Zoey + Versatile', () {
    test('one Versatile grants a sixth off-class slot, not a seventh', () {
      final deck = testDeck(zoeyOptions);
      final versatile = testCard(
        code: '06167',
        faction: 'neutral',
        level: 2,
        deckOptions: versatileOptions,
      );
      final cards = offClass(7);

      addCards(deck, [versatile]);
      addCards(deck, cards.take(6));

      expect(deck.cardsCount, 7);
      expect(deck.canAdd(cards[6], side: false), isFalse);
    });

    test('two Versatiles grant two slots', () {
      final deck = testDeck(zoeyOptions);
      final versatile = testCard(
        code: '06167',
        faction: 'neutral',
        level: 2,
        deckOptions: versatileOptions,
      );
      final cards = offClass(8);

      addCards(deck, [versatile, versatile]);
      addCards(deck, cards.take(7));

      expect(deck.cardsCount, 9);
      expect(deck.canAdd(cards[7], side: false), isFalse);
    });
  });

  test('On Your Own does not swallow cards from their normal slot', () {
    final deck = testDeck(zoeyOptions);
    final ally = testCard(code: 'a1', faction: 'guardian', slot: 'Ally');
    final onYourOwn = testCard(
      code: '53010',
      faction: 'survivor',
      level: 3,
      deckLimit: 1,
      deckOptions: onYourOwnOptions,
    );
    final cards = offClass(6);

    addCards(deck, [ally, onYourOwn]);
    addCards(deck, cards.take(5));

    expect(deck.cardsCount, 7);
    expect(deck.canAdd(cards[5], side: false), isFalse);
  });

  group('Wilson', () {
    test('a Tool is free while a plain Improvised card is charged', () {
      final deck = testDeck(wilsonOptions);
      final tool = testCard(code: 't1', traits: 'Tool. Improvised.');
      final improvised = List.generate(
        6,
        (index) => testCard(code: 'i$index', traits: 'Improvised.'),
      );

      addCards(deck, improvised.take(5));

      expect(deck.canAdd(improvised[5], side: false), isFalse);
      expect(deck.canAdd(tool, side: false), isTrue);

      addCards(deck, [tool]);

      expect(deck.cardsCount, 6);
    });

    test('an option without an error uses the generic sentence', () {
      final deck = testDeck(wilsonOptions, size: 7);
      final versatile = testCard(
        code: '06167',
        faction: 'neutral',
        level: 2,
        deckOptions: versatileOptions,
      );
      final improvised = List.generate(
        6,
        (index) => testCard(code: 'i$index', traits: 'Improvised.'),
      );

      addCards(deck, [versatile]);
      addCards(deck, improvised);

      expect(deck.validate(), isNull);

      deck.removeCard(deck.lookup(versatile, side: false));

      expect(deck.validate()?.text, genericLimitError);
    });
  });

  test('Carolyn charges an untagged Seeker card but not a healing one', () {
    final deck = testDeck(carolynOptions);
    final plain = List.generate(
      16,
      (index) => testCard(code: 'p$index', faction: 'seeker'),
    );

    addCards(deck, plain.take(15));

    expect(deck.canAdd(plain[15], side: false), isFalse);
    expect(
      deck.canAdd(
        testCard(code: 'h1', faction: 'seeker', tags: 'hh'),
        side: false,
      ),
      isTrue,
    );
  });

  group('Daniela', () {
    test('five level 0 Survivor cards fit, higher levels are uncapped', () {
      final deck = testDeck(danielaOptions);
      final zeroes = List.generate(
        6,
        (index) => testCard(code: 's$index', faction: 'survivor'),
      );
      final upgrades = List.generate(
        4,
        (index) => testCard(code: 'u$index', faction: 'survivor', level: 3),
      );

      addCards(deck, zeroes.take(5));

      expect(deck.canAdd(zeroes[5], side: false), isFalse);

      addCards(deck, upgrades);

      expect(deck.cardsCount, 9);
    });

    test('a multiclass card counts for its Survivor slot', () {
      final deck = testDeck(danielaOptions);
      final multi = List.generate(
        6,
        (index) =>
            testCard(code: 'm$index', faction: 'rogue', faction2: 'survivor'),
      );

      addCards(deck, multi.take(5));

      expect(deck.canAdd(multi[5], side: false), isFalse);
    });
  });

  test('extras and side-deck cards are never charged', () {
    final deck = testDeck(zoeyOptions);
    final weakness = testCard(code: 'w1', subtype: 'weakness', deckLimit: 1);
    final sideCard = testCard(code: 'sd1');

    addCards(deck, offClass(5));
    addCards(deck, [weakness]);
    addCards(deck, [sideCard], side: true);

    expect(deck.cardsCount, 6);
    expect(deck.canAdd(weakness, side: false), isFalse);
    expect(deck.validate()?.text, isNot(contains('Guardian')));
  });
}
