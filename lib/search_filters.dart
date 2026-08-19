import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_list.dart';
import 'package:arkham_decks/expansions.dart';
import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/investigator_filter.dart';
import 'package:flutter/material.dart';

class SearchFilters extends ChangeNotifier {
  String _searchText = '';
  final ValueNotifier<int> cardCount = ValueNotifier<int>(0);
  final FactionFilter factionFilter = FactionFilter();
  final TypeFilter typeFilter = TypeFilter();
  final WeaknessFilter weaknessFilter = WeaknessFilter();
  final LevelFilter levelFilter = LevelFilter();
  final CostFilter costFilter = CostFilter();
  final TraitFilter traitFilter = TraitFilter();
  final PackFilter expansionFilter = PackFilter();
  late final InvestigatorFilter investigatorFilter;

  Iterable<BaseFilter> get filters => [
    factionFilter,
    typeFilter,
    weaknessFilter,
    levelFilter,
    costFilter,
    traitFilter,
    expansionFilter,
    investigatorFilter,
  ];
  //TODO: investigatorFilter might be handled differently if the computation becomes too slow
  //(the query is quite long and it's constant, it can be computed only once instead of at every call)

  @override
  SearchFilters({String? deckOptions, List<String> requiredCodes = const []}) {
    investigatorFilter = InvestigatorFilter(
      deckOptions,
      requiredCodes: requiredCodes,
    );

    for (final filter in filters) {
      filter.addListener(notifyListeners);
    }
  }

  @override
  void dispose() {
    for (final filter in filters) {
      filter.removeListener(notifyListeners);
    }
    super.dispose();
  }

  void clear() {
    for (final filter in filters) {
      filter.clear();
    }
  }

  void updateSearchText(String text) {
    _searchText = text.trim();
    notifyListeners();
  }

  String get searchText => _searchText;

  Future<CardList> queryDb() async {
    List<String> whereConditions = [];
    List<String> whereArgs = [];

    if (_searchText.isNotEmpty) {
      final pattern = '%${_searchText.toLowerCase()}%';
      whereConditions.add('(LOWER(name) LIKE ? OR LOWER(subname) LIKE ?)');
      whereArgs.addAll([pattern, pattern]);
    }

    for (final filter in filters) {
      if (filter.isActive) {
        final clause = filter.whereClause;
        whereConditions.add('(${clause.sql})');
        whereArgs.addAll(clause.args);
      }
    }

    whereConditions.add('NOT hidden');

    final cardList = await CardList.queryDb(
      whereConditions.join(' AND '),
      whereArgs,
    );

    cardCount.value = cardList.length;
    return cardList;
  }
}

class SqlClause {
  final String sql;
  final List<String> args;
  SqlClause(this.sql, this.args);
}

abstract class BaseFilter extends ChangeNotifier {
  bool get isActive;

  ///This is only called if the filter is active
  SqlClause get whereClause;
  void clear();
}

class FactionFilter extends BaseFilter {
  final Set<Faction> _selected = {};

  Set<Faction> get selected => Set.unmodifiable(_selected);

  @override
  bool get isActive => selected.isNotEmpty;

  void setActives(Set<Faction> actives) {
    _selected
      ..clear()
      ..addAll(actives);
    notifyListeners();
  }

  bool isFactionSelected(Faction faction) {
    return selected.contains(faction);
  }

  @override
  void clear() {
    _selected.clear();
    notifyListeners();
  }

  @override
  SqlClause get whereClause {
    final placeholders = List.filled(selected.length, '?').join(',');
    final args = selected.map((faction) => faction.name).toList();

    return SqlClause(
      '(faction_code IN ($placeholders) OR faction2_code IN ($placeholders) OR faction3_code IN ($placeholders))',
      [...args, ...args, ...args],
    );
  }
}

//TODO: export this somewhere decent
enum Type {
  //investigator('investigator'),
  asset('asset'),
  event('event'),
  skill('skill');

  const Type(this.name);

  final String name;
}

class TypeFilter extends BaseFilter {
  final Set<Type> _selected = {};

  Set<Type> get selected => Set.unmodifiable(_selected);

  @override
  bool get isActive => _selected.isNotEmpty;

  void setActives(Set<Type> actives) {
    _selected
      ..clear()
      ..addAll(actives);
    notifyListeners();
  }

  @override
  void clear() {
    _selected.clear();
    notifyListeners();
  }

  @override
  SqlClause get whereClause {
    final placeholders = List.filled(selected.length, '?').join(',');
    final args =
        selected.map((type) {
          return type.name;
        }).toList();

    return SqlClause('(type_code IN ($placeholders))', args);
  }
}

class WeaknessFilter extends BaseFilter {
  final Set<Subtype> _selected = {};

  Set<Subtype> get selected => Set.unmodifiable(_selected);

  @override
  bool get isActive => _selected.isNotEmpty;

  void setActives(Set<Subtype> actives) {
    _selected
      ..clear()
      ..addAll(actives);
    notifyListeners();
  }

  @override
  void clear() {
    _selected.clear();
    notifyListeners();
  }

  @override
  SqlClause get whereClause {
    final placeholders = List.filled(selected.length, '?').join(',');
    final args = selected.map((subtype) => subtype.name).toList();

    return SqlClause('(subtype_code IN ($placeholders))', args);
  }
}

class LevelFilter extends BaseFilter {
  int _min = 0, _max = 5;

  int get min => _min;
  int get max => _max;

  @override
  bool get isActive => _min != 0 || _max != 5;

  void updateValues(RangeValues values) {
    _min = values.start.toInt();
    _max = values.end.toInt();
    notifyListeners();
  }

  @override
  void clear() {
    _min = 0;
    _max = 5;
    notifyListeners();
  }

  @override
  SqlClause get whereClause {
    //TODO: this should not be called xp
    return SqlClause('(xp BETWEEN ? AND ?)', [
      _min.toString(),
      _max.toString(),
    ]);
  }
}

class CostFilter extends BaseFilter {
  int _min = 0, _max = 20;

  int get min => _min;
  int get max => _max;

  @override
  bool get isActive => _min != 0 || _max != 20;

  void updateValues(RangeValues values) {
    _min = values.start.toInt();
    _max = values.end.toInt();

    notifyListeners();
  }

  @override
  void clear() {
    _min = 0;
    _max = 20;
    notifyListeners();
  }

  @override
  SqlClause get whereClause {
    return SqlClause('(cost <= ? AND cost >= ?)', [
      _max.toString(),
      _min.toString(),
    ]);
  }
}

class TraitFilter extends BaseFilter {
  final Set<String> _traits = {};

  Set<String> get traits => Set.unmodifiable(_traits);

  @override
  void clear() {
    _traits.clear();
    notifyListeners();
  }

  @override
  bool get isActive => _traits.isNotEmpty;

  bool contains(String trait) => _traits.contains(trait);

  void addTrait(String trait) {
    if (_traits.add(trait)) {
      notifyListeners();
    }
  }

  void removeTrait(String trait) {
    if (_traits.remove(trait)) {
      notifyListeners();
    }
  }

  @override
  SqlClause get whereClause {
    final condition = List.filled(_traits.length, 'traits LIKE ?').join(' OR ');
    final args = _traits.map((trait) => '%$trait%').toList();

    return SqlClause('($condition)', args);
  }
}

// TODO: this was just renamed from Expansion to Cycle temporarily, it's very wonky
class PackFilter extends BaseFilter {
  final Map<Cycle, List<Pack>> _selectedPacks = {};

  @override
  PackFilter() {
    for (final cycle in Cycle.values) {
      _selectedPacks[cycle] = [];
    }
  }

  @override
  void clear() {
    _selectedPacks.forEach((key, value) => value.clear());
    notifyListeners();
  }

  @override
  bool get isActive => _selectedPacks.entries
      .map((entry) => entry.value.isNotEmpty)
      .fold(false, (p, v) => p | v);

  bool get isEmpty => !isActive;

  String selectedText() {
    final List<String> res = [];

    for (final entry in _selectedPacks.entries) {
      final cycle = entry.key;
      final packs = entry.value;

      if (cycle.packs.length == packs.length) {
        res.add(cycle.name);
      } else {
        res.addAll(packs.map((p) => p.name));
      }

      // 100 character limit for this field
      if (res.fold<int>(0, (prev, el) => prev + el.length) >= 100) {
        res.add('...');
        break;
      }
    }

    return res.join(', ');
  }

  void addCycle(Cycle cycle) {
    _selectedPacks[cycle]!.addAll(cycle.packs);
    notifyListeners();
  }

  void removeCycle(Cycle cycle) {
    _selectedPacks[cycle] = [];
    notifyListeners();
  }

  void addPack(Cycle cycle, Pack pack) {
    _selectedPacks[cycle]!.add(pack);
    notifyListeners();
  }

  void removePack(Cycle cycle, Pack pack) {
    _selectedPacks[cycle]!.remove(pack);
    notifyListeners();
  }

  bool? contains(Cycle cycle) {
    if (_selectedPacks[cycle]!.isEmpty) {
      return false;
    } else if (cycle.packs.length == _selectedPacks[cycle]!.length) {
      return true;
    } else {
      return null;
    }
  }

  bool containsPack(Cycle cycle, Pack pack) {
    return _selectedPacks[cycle]!.contains(pack);
  }

  @override
  SqlClause get whereClause {
    final List<String> conditions = [];
    final List<String> args = [];

    for (final entry in _selectedPacks.entries) {
      final packs = entry.value;
      conditions.add(
        '(pack_code IN (${List.filled(packs.length, '?').join(',')}))',
      );
      args.addAll(packs.map((p) => p.code));
    }

    return SqlClause(conditions.join(' OR '), args);
  }
}
