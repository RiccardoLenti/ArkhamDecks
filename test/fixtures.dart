import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/deck.dart';

const zoeyOptions =
    '[{"faction": ["guardian", "neutral"], "level": {"min": 0, "max": 5}}, {"level": {"min": 0, "max": 0}, "limit": 5, "error": "You cannot have more than 5 cards that are not Guardian or Neutral"}]';

const wilsonOptions =
    '[{"trait": ["tool"], "level": {"min": 0, "max": 5}}, {"faction": ["guardian"], "level": {"min": 0, "max": 4}}, {"faction": ["neutral"], "level": {"min": 0, "max": 5}}, {"trait": ["improvised", "upgrade"], "level": {"min": 0, "max": 1}, "limit": 5}]';

const carolynOptions =
    '[{"not": true, "trait": ["weapon"], "level": {"min": 1, "max": 5}}, {"faction": ["guardian"], "level": {"min": 0, "max": 3}}, {"faction": ["neutral"], "level": {"min": 0, "max": 5}}, {"text": ["[Hh]eals? horror"], "tag": ["hh"], "level": {"min": 0, "max": 5}}, {"faction": ["seeker", "mystic"], "level": {"min": 0, "max": 1}, "limit": 15, "error": "You cannot have more than 15 level 0-1 Seeker and/or Mystic cards"}]';

const danielaOptions =
    '[{"faction": ["guardian"], "level": {"min": 0, "max": 0}}, {"faction": ["neutral"], "level": {"min": 0, "max": 5}}, {"faction": ["survivor"], "level": {"min": 1, "max": 5}}, {"faction": ["survivor"], "level": {"min": 0, "max": 0}, "limit": 5, "error": "You cannot have more than 5 level 0 Survivor cards"}]';

const versatileOptions =
    '[{"name": "Versatile", "level": {"min": 0, "max": 0}, "limit": 1, "error": "Too many off-class cards for Versatile"}]';

const onYourOwnOptions = '[{"not": true, "slot": ["Ally"]}]';

const lolaOptions =
    '[{"faction": ["survivor", "guardian", "seeker", "rogue", "mystic"], "level": {"min": 0, "max": 3}, "atleast": {"factions": 3, "min": 7}, "error": "You must have at least 7 cards from 3 different factions"}, {"faction": ["neutral"], "level": {"min": 0, "max": 5}}]';

const seekerOptions =
    '[{"faction": ["seeker", "neutral"], "level": {"min": 0, "max": 5}}]';

const ancestralOptions =
    '[{"name": "Ancestral Knowledge", "type": ["skill"], "atleast": {"types": 1, "min": 10}, "virtual": true, "error": "Your deck must include at least 10 skills"}]';

const tonyOptions =
    '[{"faction": ["rogue", "neutral"], "level": {"min": 0, "max": 5}}, {"name": "Secondary Class", "faction_select": ["guardian", "seeker", "survivor"], "level": {"min": 0, "max": 1}, "type": ["event", "skill"], "limit": 10}]';

const charlieOptions =
    '[{"faction": ["neutral"], "level": {"min": 0, "max": 5}}, {"trait": ["ally"], "level": {"min": 0, "max": 5}}, {"name": "Class Choice", "id": "faction_1", "faction_select": ["guardian", "seeker", "rogue", "mystic", "survivor"], "level": {"min": 0, "max": 2}}, {"name": "Class Choice", "id": "faction_2", "faction_select": ["guardian", "seeker", "rogue", "mystic", "survivor"], "level": {"min": 0, "max": 2}}]';

const mandyOptions =
    '[{"name": "Deck Size", "deck_size_select": ["30", "40", "50"], "faction": []}, {"faction": ["seeker", "neutral"], "level": {"min": 0, "max": 5}}, {"name": "Secondary Class", "faction_select": ["mystic", "rogue", "survivor"], "level": {"min": 0, "max": 1}, "type": ["event", "skill"], "limit": 10}]';

const marionOptions =
    '[{"faction": ["guardian", "neutral"], "level": {"min": 0, "max": 5}}, {"name": "Trait Choice", "option_select": [{"id": "improvised", "name": "Improvised", "trait": ["improvised"], "type": ["event"], "level": {"min": 0, "max": 2}}, {"id": "gambit", "name": "Gambit", "trait": ["gambit"], "type": ["event"], "level": {"min": 0, "max": 2}}, {"id": "fortune", "name": "Fortune", "trait": ["fortune"], "type": ["event"], "level": {"min": 0, "max": 2}}]}, {"faction": ["survivor"], "level": {"min": 0, "max": 0}, "limit": 5}]';

const genericLimitError = "Doesn't comply with the Investigator requirements";

const zoeyLimitError =
    'You cannot have more than 5 cards that are not Guardian or Neutral';

const carolynLimitError =
    'You cannot have more than 15 level 0-1 Seeker and/or Mystic cards';

const danielaLimitError = 'You cannot have more than 5 level 0 Survivor cards';

const versatileLimitError = 'Too many off-class cards for Versatile';

const lolaAtLeastError =
    'You must have at least 7 cards from 3 different factions';

const ancestralAtLeastError = 'Your deck must include at least 10 skills';

SimplifiedCard testCard({
  required String code,
  String faction = 'rogue',
  String? faction2,
  int? level = 0,
  String type = 'asset',
  String? subtype,
  String? traits,
  String? restrictions,
  String? tags,
  String? slot,
  String? deckOptions,
  int deckLimit = 2,
  int? tabooDeckLimit,
}) => SimplifiedCard.fromMap({
  'code': code,
  'name': code,
  'faction_code': faction,
  'faction2_code': faction2,
  'type_code': type,
  'subtype_code': subtype,
  'xp': level,
  'traits': traits,
  'restrictions': restrictions,
  'tags': tags,
  'slot': slot,
  'deck_options': deckOptions,
  'deck_limit': deckLimit,
  'taboo.code': tabooDeckLimit == null ? null : code,
  'taboo.deck_limit': tabooDeckLimit,
});

Deck testDeck(
  String deckOptions, {
  int size = 30,
  String? deckRequirements,
  String investigatorTraits = '',
  Map<String, String> selections = const {},
}) => Deck(
  id: 1,
  name: 'test',
  investigator: ArkhamCard.fromMap({
    'code': '00001',
    'name': 'investigator',
    'faction_code': 'guardian',
    'type_code': 'investigator',
    'traits': investigatorTraits,
    'deck_limit': 1,
    'is_unique': 1,
  }),
  deckOptions: deckOptions,
  deckRequirements: deckRequirements ?? 'size:$size',
  size: size,
  selections: selections,
  signaturesCount: 0,
);

void addCards(Deck deck, Iterable<SimplifiedCard> cards, {bool side = false}) {
  for (final card in cards) {
    deck.addCard(DeckCard(card, 0, side));
  }
}
