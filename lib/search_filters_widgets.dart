import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/material.dart';

class FilterBox extends StatelessWidget {
  final String title;
  final bool isActive;
  final Widget child;
  final Function clear;

  const FilterBox({
    super.key,
    required this.title,
    required this.isActive,
    required this.child,
    required this.clear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(127),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(width: 2),
                  isActive
                      ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      )
                      : const SizedBox(width: 8),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(icon: Icon(Icons.clear), onPressed: () => clear()),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class FactionFilterWidget extends StatelessWidget {
  final FactionFilter filter;

  const FactionFilterWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: filter,
      builder: (context, _) {
        return FilterBox(
          title: 'Faction',
          isActive: filter.isActive,
          clear: filter.clear,
          child: SegmentedButton(
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              ...Faction.valuesWithoutMulti().map((faction) {
                return ButtonSegment<Faction>(
                  value: faction,
                  icon:
                      filter.selected.contains(faction)
                          ? IconManager().getIcon(
                            faction.name,
                            color: faction.color,
                            size: 36,
                          )
                          : IconManager().getIcon(faction.name, size: 36),
                );
              }),
            ],
            selected: filter.selected,
            onSelectionChanged:
                (Set<Faction> newSelection) => filter.setActives(newSelection),
          ),
        );
      },
    );
  }
}

class TypeFilterWidget extends StatelessWidget {
  final TypeFilter filter;

  const TypeFilterWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: filter,
      builder: (context, _) {
        return FilterBox(
          title: 'Type',
          isActive: filter.isActive,
          clear: filter.clear,
          child: SegmentedButton(
            multiSelectionEnabled: true,
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            segments: [
              ...Type.values.map((type) {
                return ButtonSegment<Type>(
                  value: type,
                  label: Text(type.name, style: TextStyle(fontSize: 9.5)),
                );
              }),
            ],
            selected: filter.selected,
            onSelectionChanged:
                (Set<Type> newSelection) => filter.setActives(newSelection),
          ),
        );
      },
    );
  }
}

class LevelFilterWidget extends StatelessWidget {
  final LevelFilter filter;

  const LevelFilterWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: Size(130.0, 40.0),
    );

    return AnimatedBuilder(
      animation: filter,
      builder: (context, _) {
        return FilterBox(
          title: 'Level',
          isActive: filter.isActive,
          clear: filter.clear,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 22.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed:
                          () => filter.updateValues(RangeValues(0.0, 0.0)),
                      style: buttonStyle,
                      child: Text('0'),
                    ),
                    ElevatedButton(
                      onPressed:
                          () => filter.updateValues(RangeValues(1.0, 5.0)),
                      style: buttonStyle,
                      child: Text('1-5'),
                    ),
                  ],
                ),
              ),
              RangeSlider(
                values: RangeValues(
                  filter.min.toDouble(),
                  filter.max.toDouble(),
                ),
                divisions: 5,
                min: 0.0,
                max: 5.0,
                onChanged: (values) => filter.updateValues(values),
                labels: RangeLabels(
                  filter.min.toString(),
                  filter.max.toString(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CostFilterWidget extends StatelessWidget {
  final CostFilter filter;

  const CostFilterWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: filter,
      builder: (context, _) {
        return FilterBox(
          title: 'Cost',
          isActive: filter.isActive,
          clear: filter.clear,
          child: RangeSlider(
            values: RangeValues(filter.min.toDouble(), filter.max.toDouble()),
            divisions: 20,
            min: 0.0,
            max: 20.0,
            onChanged: (values) => filter.updateValues(values),
            labels: RangeLabels(filter.min.toString(), filter.max.toString()),
          ),
        );
      },
    );
  }
}

class TraitFilterWidget extends StatelessWidget {
  final TraitFilter filter;

  const TraitFilterWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: filter,
      builder: (context, _) {
        return FilterBox(
          title: 'Traits',
          isActive: filter.isActive,
          clear: filter.clear,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 12.0),
              Expanded(
                child: Wrap(
                  children: [
                    filter.traits.isEmpty
                        ? Text(
                          'None',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                        : Text(
                          filter.traits.join(', '),
                          softWrap: true,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_right_alt),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TraitsSelectorScreen(filter: filter),
                      ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TraitsSelectorScreen extends StatefulWidget {
  final TraitFilter filter;
  const TraitsSelectorScreen({super.key, required this.filter});

  @override
  State<StatefulWidget> createState() => _TraitsSelectorScreenState();
}

class _TraitsSelectorScreenState extends State<TraitsSelectorScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';
  final traitsList = DatabaseHelper.instance.traitsSet.toList()..sort();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchText = '');
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _searchText.isEmpty
            ? traitsList
            : traitsList
                .where(
                  (t) => t.toLowerCase().contains(_searchText.toLowerCase()),
                )
                .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Traits'), backgroundColor: Colors.deepPurple),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(Icons.clear),
                ),
              ),
              onChanged: (text) => setState(() => _searchText = text.trim()),
            ),
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: widget.filter,
              builder: (context, _) {
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final trait = filtered[index];
                    final checked = widget.filter.contains(trait);

                    return CheckboxListTile(
                      title: Text(trait),
                      value: checked,
                      onChanged: (bool? value) {
                        if (value == true) {
                          widget.filter.addTrait(trait);
                        } else {
                          widget.filter.removeTrait(trait);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ExpansionFilterWidget extends StatelessWidget {
  final ExpansionFilter filter;

  const ExpansionFilterWidget({super.key, required this.filter});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: filter,
      builder: (context, _) {
        return FilterBox(
          title: 'Expansion',
          isActive: filter.isActive,
          clear: filter.clear,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 12.0),
              Expanded(
                child: Wrap(
                  children: [
                    filter.expansions.isEmpty
                        ? Text(
                          'None',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                        : Text(
                          filter.expansions.join(', '),
                          softWrap: true,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.arrow_right_alt),
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ExpansionsSelectorScreen(filter: filter),
                      ),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExpansionsSelectorScreen extends StatefulWidget {
  final ExpansionFilter filter;

  const ExpansionsSelectorScreen({super.key, required this.filter});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}
