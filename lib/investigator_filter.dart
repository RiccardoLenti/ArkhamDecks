import 'dart:convert';

import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/foundation.dart';

//right now we handle factions (list), levels (json), traits (list)
class InvestigatorFilter extends BaseFilter {
  final String? deckOptions;
  final Map<String, OptionConstraint> _constraints;

  InvestigatorFilter(this.deckOptions)
    : _constraints = {
        'faction': FactionConstraint(),
        'level': LevelConstraint(),
      };

  @override
  /// This should never be called
  void clear() {}

  @override
  bool get isActive => deckOptions != null;

  @override
  SqlClause get whereClause {
    final List<String> conditions = [];
    final List<String> args = [];

    for (final Map<String, dynamic> option in jsonDecode(deckOptions!)) {
      final List<String> optionConditions = [];

      for (final optionEntry in option.entries) {
        final constraint = _constraints[optionEntry.key];
        // TODO: remove this check as it's useless when all constraints will be supported
        if (constraint != null) {
          final (constraintCondition, constraintArgs) = constraint.buildQuery(
            optionEntry.value,
          );

          optionConditions.add(constraintCondition);
          args.addAll(constraintArgs);
        }
      }

      conditions.add(optionConditions.join(' AND '));
    }

    return SqlClause(conditions.join(' OR '), args);
  }
}

@immutable
abstract class OptionConstraint {
  (String, List<String>) buildQuery(dynamic value);
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
}

class LevelConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final level = value as Map<String, dynamic>;

    final minXp = level['min'] as int;
    final maxXp = level['max'] as int;

    return ("(xp BETWEEN ? AND ?)", ['$minXp', '$maxXp']);
  }
}
