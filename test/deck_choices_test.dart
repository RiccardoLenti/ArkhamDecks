import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_choices.dart';
import 'package:arkham_decks/investigator_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

List<SimplifiedCard> events(int count, String faction, {String prefix = 'e'}) =>
    List.generate(
      count,
      (index) =>
          testCard(code: '$prefix$index', faction: faction, type: 'event'),
    );

void main() {
  group('parse', () {
    test('Tony has one faction choice under the default key', () {
      final choices = DeckChoice.parse(tonyOptions);

      expect(choices.length, 1);
      expect(choices.first.key, 'faction_selected');
      expect(choices.first.kind, ChoiceKind.faction);
      expect(choices.first.label, 'Secondary Class');
      expect(choices.first.values.map((value) => value.id), [
        'guardian',
        'seeker',
        'survivor',
      ]);
    });

    test('Charlie has two faction choices under their own ids', () {
      final choices = DeckChoice.parse(charlieOptions);

      expect(choices.map((choice) => choice.key), ['faction_1', 'faction_2']);
      expect(
        choices.every((choice) => choice.kind == ChoiceKind.faction),
        true,
      );
    });

    test('Mandy has a deck size choice and a faction choice', () {
      final choices = DeckChoice.parse(mandyOptions);

      expect(choices.map((choice) => choice.kind), [
        ChoiceKind.deckSize,
        ChoiceKind.faction,
      ]);
      expect(choices.first.key, deckSizeKey);
      expect(choices.first.values.map((value) => value.id), ['30', '40', '50']);
    });

    test('Marion has one option choice', () {
      final choices = DeckChoice.parse(marionOptions);

      expect(choices.length, 1);
      expect(choices.first.key, 'option_selected');
      expect(choices.first.kind, ChoiceKind.option);
      expect(choices.first.values.map((value) => value.id), [
        'improvised',
        'gambit',
        'fortune',
      ]);
    });

    test('an investigator without choices yields none', () {
      expect(DeckChoice.parse(zoeyOptions), isEmpty);
      expect(DeckChoice.parse(null), isEmpty);
    });
  });

  group('defaults', () {
    test("Charlie's two class choices differ", () {
      final selections = DeckChoice.defaults(DeckChoice.parse(charlieOptions));

      expect(selections['faction_1'], 'guardian');
      expect(selections['faction_2'], 'seeker');
    });

    test('Mandy defaults to the smallest deck and the first class', () {
      final selections = DeckChoice.defaults(DeckChoice.parse(mandyOptions));

      expect(selections[deckSizeKey], '30');
      expect(selections['faction_selected'], 'mystic');
    });
  });

  group('pool', () {
    test('Tony only offers the chosen secondary class', () {
      final args =
          InvestigatorFilter(
            tonyOptions,
            selections: const {'faction_selected': 'seeker'},
          ).whereClause.args;

      expect(args, contains('seeker'));
      expect(args, isNot(contains('guardian')));
      expect(args, isNot(contains('survivor')));
    });

    test('no selection falls back to the whole selectable list', () {
      final args = InvestigatorFilter(tonyOptions).whereClause.args;

      expect(args, contains('guardian'));
      expect(args, contains('seeker'));
      expect(args, contains('survivor'));
    });

    test("Charlie's two choices stay separate branches", () {
      final args =
          InvestigatorFilter(
            charlieOptions,
            selections: const {'faction_1': 'guardian', 'faction_2': 'mystic'},
          ).whereClause.args;

      expect(args, contains('guardian'));
      expect(args, contains('mystic'));
      expect(args, isNot(contains('rogue')));
    });

    test('Marion only offers the chosen trait', () {
      final args =
          InvestigatorFilter(
            marionOptions,
            selections: const {'option_selected': 'gambit'},
          ).whereClause.args;

      expect(args, contains('%gambit%'));
      expect(args, isNot(contains('%fortune%')));
      expect(args, isNot(contains('%improvised%')));
    });

    test('Marion with no selection falls back to the first sub-option', () {
      final args = InvestigatorFilter(marionOptions).whereClause.args;

      expect(args, contains('%improvised%'));
      expect(args, isNot(contains('%gambit%')));
    });
  });

  group('limits', () {
    test('11 seeker events charge the slot when seeker is chosen', () {
      final deck = testDeck(
        tonyOptions,
        selections: const {'faction_selected': 'seeker'},
      );

      addCards(deck, events(11, 'seeker'));

      expect(deck.validate()?.text, genericLimitError);
    });

    test('11 mystic events never charge the slot', () {
      final deck = testDeck(
        tonyOptions,
        selections: const {'faction_selected': 'seeker'},
      );

      addCards(deck, events(11, 'mystic'));

      expect(deck.validate()?.text, isNot(genericLimitError));
    });
  });

  group('Mandy', () {
    Deck mandyDeck(int size) => testDeck(
      mandyOptions,
      size: size,
      deckRequirements: 'size:30, card:06008, card:06009',
      selections: {deckSizeKey: '$size'},
    );

    SimplifiedCard signature(String code, {int deckLimit = 1}) =>
        testCard(code: code, faction: 'seeker', deckLimit: deckLimit);

    test('too few Occult Evidence outranks the size error', () {
      final deck = mandyDeck(50);

      addCards(deck, [signature('06008', deckLimit: 3), signature('06009')]);

      expect(deck.validate()?.text, DeckError.missingRequired.text);
    });

    test('three copies satisfy a 50 card deck', () {
      final deck = mandyDeck(50);
      final occultEvidence = signature('06008', deckLimit: 3);

      addCards(deck, [
        occultEvidence,
        occultEvidence,
        occultEvidence,
        signature('06009'),
      ]);

      expect(deck.validate()?.text, DeckError.notEnoughCards.text);
    });

    test('one copy satisfies a 30 card deck', () {
      final deck = mandyDeck(30);

      addCards(deck, [signature('06008', deckLimit: 3), signature('06009')]);

      expect(deck.validate()?.text, DeckError.notEnoughCards.text);
    });

    test('a chosen deck size sets the target', () {
      final deck = testDeck(
        mandyOptions,
        size: 50,
        selections: const {deckSizeKey: '50'},
      );

      addCards(deck, events(30, 'seeker'));

      expect(deck.validate()?.text, DeckError.notEnoughCards.text);
    });
  });
}
