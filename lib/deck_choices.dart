import 'dart:convert';

import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart';

enum ChoiceKind { faction, deckSize, option }

const deckSizeKey = 'deck_size_selected';

@immutable
class DeckChoiceValue {
  final String id;
  final String label;

  const DeckChoiceValue(this.id, this.label);
}

@immutable
class DeckChoice {
  final String key;
  final String label;
  final ChoiceKind kind;
  final List<DeckChoiceValue> values;

  const DeckChoice({
    required this.key,
    required this.label,
    required this.kind,
    required this.values,
  });

  static List<DeckChoice> parse(String? deckOptions) {
    if (deckOptions == null) {
      return const [];
    }

    return (jsonDecode(deckOptions) as List)
        .cast<Map<String, dynamic>>()
        .map(fromOption)
        .whereType<DeckChoice>()
        .toList();
  }

  static DeckChoice? fromOption(Map<String, dynamic> option) {
    final label = option['name'] as String? ?? 'Choice';

    if (option['faction_select'] != null) {
      return DeckChoice(
        key: option['id'] as String? ?? 'faction_selected',
        label: label,
        kind: ChoiceKind.faction,
        values:
            (option['faction_select'] as List)
                .cast<String>()
                .map((faction) => DeckChoiceValue(faction, _titleCase(faction)))
                .toList(),
      );
    }

    if (option['deck_size_select'] != null) {
      return DeckChoice(
        key: option['id'] as String? ?? deckSizeKey,
        label: label,
        kind: ChoiceKind.deckSize,
        values:
            (option['deck_size_select'] as List)
                .cast<String>()
                .map((size) => DeckChoiceValue(size, '$size cards'))
                .toList(),
      );
    }

    if (option['option_select'] != null) {
      return DeckChoice(
        key: option['id'] as String? ?? 'option_selected',
        label: label,
        kind: ChoiceKind.option,
        values:
            (option['option_select'] as List)
                .cast<Map<String, dynamic>>()
                .map(
                  (sub) => DeckChoiceValue(
                    sub['id'] as String,
                    sub['name'] as String,
                  ),
                )
                .toList(),
      );
    }

    return null;
  }

  static Map<String, String> defaults(List<DeckChoice> choices) {
    final taken = <String>{};

    return {
      for (final choice in choices)
        choice.key: choice.values
            .map((value) => value.id)
            .firstWhere(taken.add, orElse: () => choice.values.first.id),
    };
  }
}

String _titleCase(String value) =>
    '${value[0].toUpperCase()}${value.substring(1)}';

class DeckChoicePicker extends StatelessWidget {
  final List<DeckChoice> choices;
  final Map<String, String> selections;
  final String? only;
  final void Function(String key, String id) onChanged;

  const DeckChoicePicker({
    super.key,
    required this.choices,
    required this.selections,
    required this.onChanged,
    this.only,
  });

  Set<String> _taken(DeckChoice choice) =>
      choices
          .where(
            (other) => other.key != choice.key && other.kind == choice.kind,
          )
          .map((other) => selections[other.key])
          .whereType<String>()
          .toSet();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children:
        choices
            .where((choice) => only == null || choice.key == only)
            .map((choice) => _buildChoice(context, choice))
            .toList(),
  );

  Widget _buildChoice(BuildContext context, DeckChoice choice) {
    final taken = _taken(choice);

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: DropdownButtonFormField<String>(
        initialValue: selections[choice.key],
        isExpanded: true,
        decoration: InputDecoration(
          labelText: choice.label,
          border: const OutlineInputBorder(),
        ),
        items:
            choice.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value.id,
                    enabled: !taken.contains(value.id),
                    child: _buildValue(context, choice, value, taken),
                  ),
                )
                .toList(),
        onChanged: (id) => id == null ? null : onChanged(choice.key, id),
      ),
    );
  }

  Widget _buildValue(
    BuildContext context,
    DeckChoice choice,
    DeckChoiceValue value,
    Set<String> taken,
  ) {
    final faction = Faction.fromString(value.id);
    final disabled = taken.contains(value.id);

    return Row(
      spacing: 8.0,
      children: [
        if (faction != null)
          IconManager().getIcon(
            faction.name,
            color: AppColors.factions[faction]!.light,
          ),
        Text(
          value.label,
          style:
              disabled
                  ? TextStyle(color: Theme.of(context).disabledColor)
                  : null,
        ),
      ],
    );
  }
}
