import 'dart:convert';

import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/foundation.dart';

//right now we handle factions (list), levels (json), traits (list), types (list)
class InvestigatorFilter extends BaseFilter {
  final String? deckOptions;
  final Map<String, OptionConstraint> _constraints;
  List<String> _extraOptions = const [];

  InvestigatorFilter(this.deckOptions)
    : _constraints = {
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

  void setExtraOptions(List<String> options) {
    if (listEquals(_extraOptions, options)) {
      return;
    }

    _extraOptions = options;
    notifyListeners();
  }

  @override
  SqlClause get whereClause {
    final List<String> allowed = [], forbidden = [];
    final List<String> allowedArgs = [], forbiddenArgs = [];

    for (final option in _options) {
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
      [
        ...jsonDecode(deckOptions!),
        for (final extra in _extraOptions) ...jsonDecode(extra),
      ].cast<Map<String, dynamic>>();

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

class TraitConstraint implements OptionConstraint {
  //TODO: this is exactly identical to TraitFilter. MH.
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final traits = (value as List).cast<String>();

    final condition = List.filled(traits.length, 'traits LIKE ?').join(' OR ');
    final args = traits.map((trait) => '%$trait%').toList();

    return ('($condition)', args);
  }
}

class TypeConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final types = (value as List).cast<String>();

    final placeholders = List.filled(types.length, '?').join(', ');

    return ('(type_code IN ($placeholders))', types);
  }
}

class TagConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final tags = (value as List).cast<String>();

    final condition = List.filled(tags.length, 'tags LIKE ?').join(' OR ');
    final args = tags.map((tag) => '%$tag%').toList();

    return ('($condition)', args);
  }
}

class UsesConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final uses = (value as List).cast<String>();

    final placeholders = List.filled(uses.length, '?').join(', ');

    return ('(uses IN ($placeholders))', uses);
  }
}

class SlotConstraint implements OptionConstraint {
  @override
  (String, List<String>) buildQuery(dynamic value) {
    final slots = (value as List).cast<String>();

    final condition = List.filled(slots.length, 'slot LIKE ?').join(' OR ');
    final args = slots.map((slot) => '%$slot%').toList();

    return ('($condition)', args);
  }
}
