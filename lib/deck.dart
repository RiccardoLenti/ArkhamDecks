import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/investigator_filter.dart';
import 'package:flutter/material.dart';

// hardcoded
const _deckSizeModifiers = {
  '06167': 5,
  '07303': 5,
  '08031': 15,
  '09077': 10,
  '08046': -5,
};

class Deck extends ChangeNotifier {
  final int id;
  String _name;
  final ArkhamCard investigator;
  final String deckOptions;
  final String deckRequirements;
  final int size;
  final int signaturesCount;
  final Map<String, DeckCard> _main = {};
  final Map<String, DeckCard> _side = {};

  Deck({
    required this.id,
    required String name,
    required this.investigator,
    required this.deckOptions,
    required this.deckRequirements,
    required this.size,
    required this.signaturesCount,
  }) : _name = name;

  String get name => _name;

  static Iterable<List<String>> requiredCards(String deckRequirements) =>
      deckRequirements
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.startsWith('card:'))
          .map((part) => part.split(':').skip(1).toList());

  late final List<String> requiredCodes =
      requiredCards(deckRequirements).expand((codes) => codes).toList();

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
    final cards = requiredCards(deckRequirements).fold<Map<String, int>>(
      {'01000': 1},
      (counts, codes) =>
          counts..update(codes.first, (count) => count + 1, ifAbsent: () => 1),
    );

    for (final part in parts) {
      if (part.startsWith('size:')) {
        size = int.parse(part.substring(5));
      }
    }

    final deckId = await db.insert('decks', {
      'name': name,
      'investigator_code': investigator.code,
      'size': size,
      'signatures_count': cards.values.fold<int>(0, (acc, el) => acc + el),
    });

    await Future.wait(
      cards.entries.map(
        (entry) => db.insert('deck_cards', {
          'deck_id': deckId,
          'card_code': entry.key,
          'count': entry.value,
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

  List<String> get extraDeckOptions =>
      _main.values
          .where((deckCard) => deckCard.card.deckOptions != null)
          .expand(
            (deckCard) =>
                List.filled(deckCard.count, deckCard.card.deckOptions!),
          )
          .toList();

  List<SimplifiedCard> get sideCards =>
      _side.values.map((card) => card.card).toList(growable: false);

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'],
      name: map['deck_name'],
      deckOptions: map['deck_options'],
      deckRequirements: map['deck_requirements'],
      size: map['size'],
      signaturesCount: map['signatures_count'],
      investigator: ArkhamCard.fromMap(map),
    );
  }

  DeckCard lookup(SimplifiedCard card, {required bool side}) =>
      (side ? _side[card.code] : _main[card.code]) ?? DeckCard(card, 0, side);

  late final InvestigatorFilter _limitFilter = InvestigatorFilter(deckOptions);
  List<int>? _cachedLimitCounts;

  List<int> get _limitCounts {
    if (_cachedLimitCounts != null) {
      return _cachedLimitCounts!;
    }

    final counts = List.filled(_limitFilter.limits.length, 0);

    for (final deckCard in _main.values.where(
      (deckCard) => !_isExtra(deckCard.card),
    )) {
      for (var copy = 0; copy < deckCard.count; copy++) {
        final charged = _limitFilter.chargedLimit(deckCard.card, counts);

        if (charged != null) {
          counts[charged]++;
        }
      }
    }

    return _cachedLimitCounts = counts;
  }

  bool canAdd(SimplifiedCard card, {required bool side}) =>
      lookup(card, side: side).count < card.deckLimit;

  void _invalidateLimits() {
    _cachedLimitCounts = null;
    _limitFilter.setExtraOptions(extraDeckOptions);
  }

  void addCard(DeckCard cardToAdd) {
    if (!canAdd(cardToAdd.card, side: cardToAdd.side)) {
      return;
    }

    final collection = cardToAdd.side ? _side : _main;
    final deckCard = collection[cardToAdd.card.code];
    if (deckCard == null) {
      collection[cardToAdd.card.code] = DeckCard(
        cardToAdd.card,
        1,
        cardToAdd.side,
      );
    } else {
      deckCard.count++;
    }

    _invalidateLimits();
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

    _invalidateLimits();
    notifyListeners();
  }

  String get investigatorName => investigator.name;

  int get cardsCount => _main.values.fold(0, (acc, el) => acc + el.count);

  int get xpCount =>
      _main.values.fold(0, (acc, el) => acc + el.count * (el.card.level ?? 0));

  int get deckSizeModifier => _main.values.fold(
    0,
    (acc, el) => acc + el.count * (_deckSizeModifiers[el.card.code] ?? 0),
  );

  int get effectiveSize => size + deckSizeModifier;

  bool _isExtra(SimplifiedCard card) =>
      card.subtype != null || requiredCodes.contains(card.code);

  // TODO: signaturesCount is dead now, drop the column
  int get nonExtraCardsCount => _main.values
      .where((deckCard) => !_isExtra(deckCard.card))
      .fold(0, (acc, el) => acc + el.count);

  bool get _hasRequiredCards =>
      requiredCards(
        deckRequirements,
      ).every((codes) => codes.any(_main.containsKey)) &&
      (!deckRequirements.contains('random:subtype:basicweakness') ||
          _main.values.any(
            (deckCard) => deckCard.card.subtype == Subtype.basicWeakness,
          ));

  bool get _hasTooManyCopies => [
    ..._main.values,
    ..._side.values,
  ].any((deckCard) => deckCard.count > deckCard.card.deckLimit);

  DeckError? get _limitError {
    final limits = _limitFilter.limits;

    for (var i = 0; i < limits.length; i++) {
      if (limits[i] != null && _limitCounts[i] > limits[i]!.limit) {
        return DeckError(limits[i]!.error);
      }
    }

    return null;
  }

  DeckError? get _atLeastError {
    final error = _limitFilter.atLeastError(
      _main.values
          .where((deckCard) => !_isExtra(deckCard.card))
          .map((deckCard) => (deckCard.card, deckCard.count)),
    );

    return error == null ? null : DeckError(error);
  }

  DeckError? validate() {
    if (!_hasRequiredCards) {
      return DeckError.missingRequired;
    } else if (_hasTooManyCopies) {
      return DeckError.tooManyCopies;
    } else if (_limitError != null) {
      return _limitError;
    } else if (nonExtraCardsCount > effectiveSize) {
      return DeckError.tooManyCards;
    } else if (nonExtraCardsCount < effectiveSize) {
      return DeckError.notEnoughCards;
    } else if (_atLeastError != null) {
      return _atLeastError;
    }

    return null;
  }

  Future<void> fetchCards() async {
    final db = await DatabaseHelper.instance.db;
    final rows = await db.rawQuery(
      'SELECT cards.*, deck_cards.count, deck_cards.side_deck, '
      'taboo_cards.code AS "taboo.code", taboo_cards.xp AS "taboo.xp", '
      'taboo_cards.deck_limit AS "taboo.deck_limit" '
      'FROM cards JOIN deck_cards ON card_code = cards.code '
      'LEFT JOIN taboo_cards ON taboo_cards.code = cards.code '
      'AND taboo_cards.taboo_list = (SELECT MAX(code) FROM taboos) '
      'WHERE deck_cards.deck_id = ?',
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

    _invalidateLimits();
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

@immutable
class DeckError {
  final String text;

  const DeckError(this.text);

  static const notEnoughCards = DeckError("Deck contains too few cards");
  static const tooManyCards = DeckError("Deck contains too many cards");
  static const missingRequired = DeckError("Deck is missing a required card");
  static const tooManyCopies = DeckError(
    "Deck contains too many copies of a card",
  );
  static const generic = DeckError("");
}
