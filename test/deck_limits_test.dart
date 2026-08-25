import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/deck.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

List<SimplifiedCard> offClass(int count, {String prefix = 'r'}) =>
    List.generate(
      count,
      (index) => testCard(code: '$prefix$index', faction: 'rogue'),
    );

SimplifiedCard versatileCard() => testCard(
  code: '06167',
  faction: 'neutral',
  level: 2,
  deckOptions: versatileOptions,
);

List<SimplifiedCard> inClass(int count, {String prefix = 'g'}) => List.generate(
  count,
  (index) => testCard(code: '$prefix$index', faction: 'guardian', level: 1),
);

void main() {
  group('Zoey', () {
    test('a sixth off-class level 0 card goes in and is reported', () {
      final deck = testDeck(zoeyOptions);
      final cards = offClass(6);

      addCards(deck, cards.take(5));

      expect(deck.validate()?.text, isNot(zoeyLimitError));
      expect(deck.canAdd(cards[5], side: false), isTrue);

      addCards(deck, [cards[5]]);

      expect(deck.cardsCount, 6);
      expect(deck.validate()?.text, zoeyLimitError);
    });

    test('in-class and neutral cards are never charged', () {
      final deck = testDeck(zoeyOptions);

      addCards(deck, offClass(5));
      addCards(deck, [
        testCard(code: 'g1', faction: 'guardian'),
        testCard(code: 'n1', faction: 'neutral'),
      ]);

      expect(deck.cardsCount, 7);
      expect(deck.validate()?.text, isNot(zoeyLimitError));
    });

    test('removing a Versatile leaves the deck over its limit', () {
      final deck = testDeck(zoeyOptions, size: 9);
      final versatile = versatileCard();

      addCards(deck, [versatile, versatile]);
      addCards(deck, offClass(7));

      expect(deck.cardsCount, 9);
      expect(deck.validate()?.text, isNot(versatileLimitError));

      deck.removeCard(deck.lookup(versatile, side: false));

      expect(deck.validate()?.text, versatileLimitError);
    });
  });

  group('Zoey + Versatile', () {
    test('one Versatile grants a sixth off-class slot, not a seventh', () {
      final deck = testDeck(zoeyOptions);
      final cards = offClass(7);

      addCards(deck, [versatileCard()]);
      addCards(deck, cards.take(6));

      expect(deck.validate()?.text, isNot(versatileLimitError));

      addCards(deck, [cards[6]]);

      expect(deck.cardsCount, 8);
      expect(deck.validate()?.text, versatileLimitError);
    });

    test('two Versatiles grant two slots', () {
      final deck = testDeck(zoeyOptions);
      final versatile = versatileCard();
      final cards = offClass(8);

      addCards(deck, [versatile, versatile]);
      addCards(deck, cards.take(7));

      expect(deck.validate()?.text, isNot(versatileLimitError));

      addCards(deck, [cards[7]]);

      expect(deck.validate()?.text, versatileLimitError);
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

    expect(deck.validate()?.text, isNot(zoeyLimitError));

    addCards(deck, [cards[5]]);

    expect(deck.cardsCount, 8);
    expect(deck.validate()?.text, zoeyLimitError);
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
      addCards(deck, [tool]);

      expect(deck.cardsCount, 6);
      expect(deck.validate()?.text, isNot(genericLimitError));

      addCards(deck, [improvised[5]]);

      expect(deck.validate()?.text, genericLimitError);
    });

    test('an option without an error uses the generic sentence', () {
      final deck = testDeck(wilsonOptions, size: 7);
      final versatile = versatileCard();
      final improvised = List.generate(
        6,
        (index) => testCard(code: 'i$index', traits: 'Improvised.'),
      );

      addCards(deck, [versatile]);
      addCards(deck, improvised);

      expect(deck.validate()?.text, isNot(genericLimitError));

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
    addCards(deck, [testCard(code: 'h1', faction: 'seeker', tags: 'hh')]);

    expect(deck.cardsCount, 16);
    expect(deck.validate()?.text, isNot(carolynLimitError));

    addCards(deck, [plain[15]]);

    expect(deck.validate()?.text, carolynLimitError);
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
      addCards(deck, upgrades);

      expect(deck.cardsCount, 9);
      expect(deck.validate()?.text, isNot(danielaLimitError));

      addCards(deck, [zeroes[5]]);

      expect(deck.validate()?.text, danielaLimitError);
    });

    test('a multiclass card counts for its Survivor slot', () {
      final deck = testDeck(danielaOptions);
      final multi = List.generate(
        6,
        (index) =>
            testCard(code: 'm$index', faction: 'rogue', faction2: 'survivor'),
      );

      addCards(deck, multi.take(5));

      expect(deck.validate()?.text, isNot(danielaLimitError));

      addCards(deck, [multi[5]]);

      expect(deck.validate()?.text, danielaLimitError);
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
    expect(deck.validate()?.text, isNot(zoeyLimitError));
  });

  group('copy limit', () {
    test('a third copy is refused', () {
      final deck = testDeck(zoeyOptions);
      final card = testCard(code: 'c1');

      addCards(deck, [card, card, card]);

      expect(deck.cardsCount, 2);
      expect(deck.canAdd(card, side: false), isFalse);
    });

    test('a taboo deck limit overrides the printed one', () {
      final deck = testDeck(zoeyOptions);
      final banned = testCard(code: '02026', tabooDeckLimit: 0);
      final limited = testCard(code: '02027', tabooDeckLimit: 1);

      addCards(deck, [banned, limited, limited]);

      expect(deck.lookup(banned, side: false).count, 0);
      expect(deck.lookup(limited, side: false).count, 1);
    });
  });

  group('deck size modifiers', () {
    test('a Versatile raises the target by 5', () {
      final deck = testDeck(zoeyOptions, size: 30);

      addCards(deck, [versatileCard()]);
      addCards(deck, inClass(29));

      expect(deck.validate()?.text, DeckError.notEnoughCards.text);

      addCards(deck, inClass(5, prefix: 'extra'));

      expect(deck.nonExtraCardsCount, 35);
      expect(deck.validate(), isNull);
    });

    test('two Versatiles raise it by 10', () {
      final deck = testDeck(zoeyOptions, size: 30);
      final versatile = versatileCard();

      addCards(deck, [versatile, versatile]);
      addCards(deck, inClass(28));

      expect(deck.validate()?.text, DeckError.notEnoughCards.text);

      addCards(deck, inClass(10, prefix: 'extra'));

      expect(deck.nonExtraCardsCount, 40);
      expect(deck.validate(), isNull);
    });

    test('Underworld Support lowers the target by 5', () {
      final deck = testDeck(zoeyOptions, size: 30);

      addCards(deck, [
        testCard(code: '08046', faction: 'neutral', level: 3, deckLimit: 1),
      ]);
      addCards(deck, inClass(24));

      expect(deck.nonExtraCardsCount, 25);
      expect(deck.validate(), isNull);

      addCards(deck, inClass(5, prefix: 'extra'));

      expect(deck.validate()?.text, DeckError.tooManyCards.text);
    });

    test('an ordinary card leaves the target alone', () {
      final deck = testDeck(zoeyOptions, size: 30);

      addCards(deck, inClass(30));

      expect(deck.validate(), isNull);
    });
  });
}
