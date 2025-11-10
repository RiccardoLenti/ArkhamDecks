import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/factions.dart';
import 'package:flutter/material.dart';

class SearchFilters extends ChangeNotifier {
  String _searchText = '';
  late int _cardCount;
  final FactionFilter factionFilter = FactionFilter();
  final TypeFilter typeFilter = TypeFilter();
  final LevelFilter levelFilter = LevelFilter();
  final CostFilter costFilter = CostFilter();
  final TraitFilter traitFilter = TraitFilter();

  Iterable<BaseFilter> get filters => [
    factionFilter,
    typeFilter,
    levelFilter,
    costFilter,
    traitFilter,
  ];

  @override
  SearchFilters() {
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

  int get cardCount => _cardCount;

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

  Future<List<SimplifiedCard>> queryDb() async {
    final db = await DatabaseHelper.instance.db;

    List<String> whereConditions = [];
    List<String> whereArgs = [];

    if (_searchText.isNotEmpty) {
      whereConditions.add('LOWER(name) LIKE ?');
      whereArgs.add('%${_searchText.toLowerCase()}%');
    }

    for (final filter in filters) {
      if (filter.isActive) {
        final clause = filter.whereClause;
        whereConditions.add(clause.sql);
        whereArgs.addAll(clause.args);
      }
    }

    final cardMaps = await db.query(
      'cards',
      where: whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'type_code = "investigator" desc',
    );

    _cardCount = cardMaps.length;
    notifyListeners();

    return cardMaps.map((cardMap) => SimplifiedCard.fromMap(cardMap)).toList();
  }
}

class SqlClause {
  final String sql;
  final List<String> args;
  SqlClause(this.sql, this.args);
}

abstract class BaseFilter extends ChangeNotifier {
  bool get isActive;
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
  investigator('investigator'),
  asset('asset'),
  event('event'),
  skill('skill'),
  weakness('treachery');

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
    return SqlClause('(xp <= ? AND xp >= ?)', [
      _max.toString(),
      _min.toString(),
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
  }

  @override
  bool get isActive => _traits.isNotEmpty;

  bool contains(String trait) => _traits.contains(trait);

  void addTrait(String trait) {
    if(_traits.add(trait)) {
      notifyListeners();
    }
  }

  void removeTrait(String trait) {
    if(_traits.remove(trait)) {
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
