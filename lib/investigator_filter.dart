import 'dart:convert';

import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/foundation.dart';

//right now we handle factions (list), levels (json), traits (list), types (list)
class InvestigatorFilter extends BaseFilter {
  final String? deckOptions;
  final List<String> requiredCodes;
  final Map<String, OptionConstraint> _constraints;
  Map<String, String> _selections;
  List<String> _extraOptions = const [];
  List<Map<String, dynamic>>? _cachedOptions;
  List<Map<String, dynamic>>? _cachedCountedOptions;
  List<DeckLimit?>? _cachedLimits;

  InvestigatorFilter(
    this.deckOptions, {
    this.requiredCodes = const [],
    Map<String, String> selections = const {},
  }) : _selections = selections,
       _constraints = {
         'faction': FactionConstraint(),
         'level': LevelConstraint(),
         'trait': TraitConstraint(),
         'type': TypeConstraint(),
         'tag': TagConstraint(),
         'uses': UsesConstraint(),
         'slot': SlotConstraint(),
       };

  @override
  /// This should never be called
  void clear() {}

  @override
  bool get isActive => deckOptions != null;

  void setSelections(Map<String, String> selections) {
    if (mapEquals(_selections, selections)) {
      return;
    }

    _selections = selections;
    _cachedOptions = null;
    _cachedCountedOptions = null;
    _cachedLimits = null;
    notifyListeners();
  }

  void setExtraOptions(List<String> options) {
    if (listEquals(_extraOptions, options)) {
      return;
    }

    _extraOptions = options;
    _cachedOptions = null;
    _cachedCountedOptions = null;
    _cachedLimits = null;
    notifyListeners();
  }

  @override
  SqlClause get whereClause {
    final List<String> allowed = [], forbidden = [];
    final List<String> allowedArgs = [], forbiddenArgs = [];

    if (requiredCodes.isNotEmpty) {
      final placeholders = List.filled(requiredCodes.length, '?').join(', ');
      allowed.add('(code IN ($placeholders))');
      allowedArgs.addAll(requiredCodes);
    }

    allowed.add('(subtype_code = ?)');
    allowedArgs.add(Subtype.basicWeakness.name);

    for (final option in _options) {
      // ancestral knowledge
      if (option['virtual'] == true) {
        continue;
      }

      final (condition, args) = _buildOption(option);

      if (condition == null) {
        continue;
      }

      if (option['not'] == true) {
        forbidden.add('NOT IFNULL($condition, 0)');
        forbiddenArgs.addAll(args);
      } else {
        allowed.add(condition);
        allowedArgs.addAll(args);
      }
    }

    final conditions = [
      if (allowed.isNotEmpty) allowed.join(' OR '),
      ...forbidden,
    ];

    return SqlClause(conditions.map((c) => '($c)').join(' AND '), [
      ...allowedArgs,
      ...forbiddenArgs,
    ]);
  }

  List<Map<String, dynamic>> get _options =>
      _cachedOptions ??=
          [
            ...jsonDecode(deckOptions!),
            for (final extra in _extraOptions) ...jsonDecode(extra),
          ].cast<Map<String, dynamic>>().map(_resolve).toList();

  Map<String, dynamic> _resolve(Map<String, dynamic> option) {
    if (option['faction_select'] != null) {
      final key = option['id'] as String? ?? 'faction_selected';
      final selected = _selections[key];

      return {
        ...option,
        'faction': selected == null ? option['faction_select'] : [selected],
      };
    }

    if (option['option_select'] != null) {
      final key = option['id'] as String? ?? 'option_selected';
      final subs =
          (option['option_select'] as List).cast<Map<String, dynamic>>();
      final chosen = subs.where((sub) => sub['id'] == _selections[key]);

      return {...option, ...(chosen.isEmpty ? subs.first : chosen.first)};
    }

    return option;
  }

  List<Map<String, dynamic>> get _countedOptions {
    final allowed = _options.where(
      (option) => option['not'] != true && option['virtual'] != true,
    );

    return _cachedCountedOptions ??= [
      ...allowed.where((option) => option['limit'] == null),
      ...allowed.where((option) => option['limit'] != null),
    ];
  }

  List<DeckLimit?> get limits =>
      _cachedLimits ??= _countedOptions.map(DeckLimit.fromOption).toList();

  /// index into [limits] of the slot this card takes, null if it takes none
  int? chargedLimit(SimplifiedCard card, List<int> counts) {
    final limits = this.limits;
    int? full;

    for (var i = 0; i < _countedOptions.length; i++) {
      if (!_satisfiedBy(_countedOptions[i], card)) {
        continue;
      }

      final limit = limits[i];

      if (limit == null) {
        return null;
      }
      if (counts[i] < limit.limit) {
        return i;
      }

      full = i;
    }

    return full;
  }

  bool allows(SimplifiedCard card) =>
      (card.subtype == Subtype.basicWeakness ||
          requiredCodes.contains(card.code) ||
          _countedOptions.any((option) => _satisfiedBy(option, card))) &&
      !_options.any(
        (option) => option['not'] == true && _satisfiedBy(option, card),
      );

  String? atLeastError(Iterable<(SimplifiedCard, int)> cards) {
    for (final option in _options) {
      final atLeast = option['atleast'] as Map<String, dynamic>?;

      if (atLeast == null) {
        continue;
      }

      final key = atLeast.keys.firstWhere((key) => key != 'min');
      final min = atLeast['min'] as int;
      final counts = <String, int>{};

      for (final (card, count) in cards) {
        if (!_satisfiedBy(option, card)) {
          continue;
        }

        for (final group in _atLeastGroups(option, key, card)) {
          counts[group] = (counts[group] ?? 0) + count;
        }
      }

      if (counts.values.where((count) => count >= min).length < atLeast[key]) {
        return option['error'] ??
            "Doesn't comply with the Investigator requirements";
      }
    }

    return null;
  }

  Iterable<String> _atLeastGroups(
    Map<String, dynamic> option,
    String key,
    SimplifiedCard card,
  ) => switch (key) {
    'factions' => (card.multiFactions.isEmpty
            ? [card.faction]
            : card.multiFactions)
        .map((faction) => faction.name)
        .where((name) => (option['faction'] as List?)?.contains(name) ?? true),
    'types' => [card.type],
    _ => const [],
  };

  bool _satisfiedBy(Map<String, dynamic> option, SimplifiedCard card) {
    final known = option.entries.where(
      (entry) => _constraints.containsKey(entry.key),
    );

    return known.isNotEmpty &&
        known.every(
          (entry) => _constraints[entry.key]!.satisfiedBy(entry.value, card),
        );
  }

  (String?, List<String>) _buildOption(Map<String, dynamic> option) {
    final List<String> conditions = [];
    final List<String> args = [];

    for (final optionEntry in option.entries) {
      final constraint = _constraints[optionEntry.key];
      // TODO: remove this check as it's useless when all constraints will be supported
      if (constraint != null) {
        final (constraintCondition, constraintArgs) = constraint.buildQuery(
          optionEntry.value,
        );

        conditions.add(constraintCondition);
        args.addAll(constraintArgs);
      }
    }

    if (conditions.isEmpty) {
      return (null, const []);
    }

    return ('(${conditions.join(' AND ')})', args);
  }
}

@immutable
class DeckLimit {
  final int limit;
  final String error;

  const DeckLimit({required this.limit, required this.error});

  static DeckLimit? fromOption(Map<String, dynamic> option) =>
      option['limit'] == null
          ? null
          : DeckLimit(
            limit: option['limit'],
            error:
                option['error'] ??
                "Doesn't comply with the Investigator requirements",
          );
}

@immutable
abstract class OptionConstraint {
  (String, List<String>) buildQuery(dynamic value);
  bool satisfiedBy(dynamic value, SimplifiedCard card);
}

bool _contains(String? haystack, dynamic value) {
  final needles = (value as List).cast<String>();

  return needles.any(
    (needle) => haystack?.toLowerCase().contains(needle.toLowerCase()) ?? false,
  );
}

class FactionConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final factions = (value as List).cast<String>();

    final placeholders = List.filled(factions.length, '? ').join(', ');

    return (
      "(faction_code IN ($placeholders) OR faction2_code IN ($placeholders) OR faction3_code IN ($placeholders))",
      [...factions, ...factions, ...factions],
    );
  }

  @override
  bool satisfiedBy(dynamic value, SimplifiedCard card) {
    final factions = (value as List).cast<String>();
    final cardFactions =
        card.multiFactions.isEmpty ? [card.faction] : card.multiFactions;

    return cardFactions.any((faction) => factions.contains(faction.name));
  }
}

class LevelConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final level = value as Map<String, dynamic>;

    final minXp = level['min'] as int;
    final maxXp = level['max'] as int;

    return ("(xp BETWEEN ? AND ?)", ['$minXp', '$maxXp']);
  }

  @override
  bool satisfiedBy(dynamic value, SimplifiedCard card) {
    final level = value as Map<String, dynamic>;

    return card.level != null &&
        card.level! >= level['min'] &&
        card.level! <= level['max'];
  }
}

class TraitConstraint implements OptionConstraint {
  //TODO: this is exactly identical to TraitFilter. MH.
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final traits = (value as List).cast<String>();

    final condition = List.filled(traits.length, 'traits LIKE ?').join(' OR ');
    final args = traits.map((trait) => '%$trait%').toList();

    return ('($condition)', args);
  }

  @override
  bool satisfiedBy(dynamic value, SimplifiedCard card) =>
      _contains(card.traits.join(' '), value);
}

class TypeConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final types = (value as List).cast<String>();

    final placeholders = List.filled(types.length, '?').join(', ');

    return ('(type_code IN ($placeholders))', types);
  }

  @override
  bool satisfiedBy(dynamic value, SimplifiedCard card) =>
      (value as List).cast<String>().contains(card.type);
}

class TagConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final tags = (value as List).cast<String>();

    final condition = List.filled(tags.length, 'tags LIKE ?').join(' OR ');
    final args = tags.map((tag) => '%$tag%').toList();

    return ('($condition)', args);
  }

  @override
  bool satisfiedBy(dynamic value, SimplifiedCard card) =>
      _contains(card.tags, value);
}

class UsesConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final uses = (value as List).cast<String>();

    final placeholders = List.filled(uses.length, '?').join(', ');

    return ('(uses IN ($placeholders))', uses);
  }

  @override
  bool satisfiedBy(dynamic value, SimplifiedCard card) =>
      (value as List).cast<String>().contains(card.uses);
}

class SlotConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final slots = (value as List).cast<String>();

    final condition = List.filled(slots.length, 'slot LIKE ?').join(' OR ');
    final args = slots.map((slot) => '%$slot%').toList();

    return ('($condition)', args);
  }

  @override
  bool satisfiedBy(dynamic value, SimplifiedCard card) =>
      _contains(card.slots?.join(' '), value);
}
