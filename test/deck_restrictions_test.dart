import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/investigator_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

const libraryPass = 'trait:miskatonic, trait:scholar';

SimplifiedCard seeker([String? restrictions]) =>
    testCard(code: 'c', faction: 'seeker', restrictions: restrictions);

InvestigatorFilter filterFor(String traits) => InvestigatorFilter(
  seekerOptions,
  investigator: testCard(
    code: '00001',
    faction: 'seeker',
    type: 'investigator',
    level: null,
    traits: traits,
  ),
);

void main() {
  group('restrictions', () {
    test('a matching trait allows the card', () {
      expect(
        filterFor('Miskatonic. Scholar.').allows(seeker(libraryPass)),
        true,
      );
    });

    test('a multi-word trait is not split on spaces', () {
      expect(
        filterFor(
          'Cultist. Silver Twilight.',
        ).allows(seeker('trait:cultist, trait:cursed, trait:silver twilight')),
        true,
      );
    });

    test('no matching trait forbids the card', () {
      expect(filterFor('Drifter.').allows(seeker(libraryPass)), false);
    });

    test('only the named investigator gets a signature', () {
      expect(
        filterFor('Miskatonic.').allows(seeker('investigator:02002')),
        false,
      );
      expect(
        filterFor('Miskatonic.').allows(seeker('investigator:00001')),
        true,
      );
    });

    test('unrestricted cards are unaffected', () {
      expect(filterFor('Drifter.').allows(seeker()), true);
    });

    test('without an investigator nothing is gated', () {
      expect(
        InvestigatorFilter(seekerOptions).allows(seeker(libraryPass)),
        true,
      );
    });

    test('the clause carries one pattern per trait plus the code', () {
      final args = filterFor('Cultist. Silver Twilight.').whereClause.args;

      expect(
        args,
        containsAll(<String>[
          '%investigator:00001%',
          '%trait:cultist,%',
          '%trait:silver twilight,%',
        ]),
      );
    });

    test('a restricted card in the deck is not allowed', () {
      final deck = testDeck(
        seekerOptions,
        size: 1,
        investigatorTraits: 'Drifter.',
      )..addCard(DeckCard(seeker(libraryPass), 1, false));

      expect(deck.validate(), DeckError.notAllowed);
    });
  });
}
