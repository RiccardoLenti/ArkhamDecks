import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/expansions.dart';
import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart';

class FilterBox extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isActive;
  final Widget child;
  final Function clear;

  const FilterBox({
    super.key,
    required this.title,
    this.subtitle,
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
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                  const SizedBox(width: 4),
                  isActive
                      ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      )
                      : const SizedBox(width: 6),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium!.copyWith(fontSize: 18),
                  ),
                  if (subtitle != null)
                    Text(
                      ' :  $subtitle',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium!.copyWith(fontSize: 18),
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
                            color: AppColors.factions[faction]!.light,
                            size: 36,
                          )
                          : IconManager().getIcon(
                            faction.name,
                            size: 36,
                            color: Colors.white70,
                          ),
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
          subtitle: !filter.isActive ? null : '${filter.min} - ${filter.max}',
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
          subtitle: !filter.isActive ? null : '${filter.min} - ${filter.max}',
          isActive: filter.isActive,
          clear: filter.clear,
          child: RangeSlider(
            values: RangeValues(filter.min.toDouble(), filter.max.toDouble()),
            divisions: 20,
            min: 0.0,
            max: 20.0,
            onChanged: (values) => filter.updateValues(values),
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
  State<TraitsSelectorScreen> createState() => _TraitsSelectorScreenState();
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
      appBar: AppBar(title: Text('Traits')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomSearchBar(
              controller: _searchController,
              onChanged: (text) => setState(() => _searchText = text.trim()),
              clear: _clearSearch,
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
  final PackFilter filter;

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
                    filter.isEmpty
                        ? Text(
                          'None',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                        : Text(
                          filter.selectedText(),
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
  final PackFilter filter;
  const ExpansionsSelectorScreen({super.key, required this.filter});

  @override
  State<ExpansionsSelectorScreen> createState() =>
      _ExpansionsSelectorScreenState();
}

class _ExpansionsSelectorScreenState extends State<ExpansionsSelectorScreen> {
  late final List<Cycle> _cycles;

  @override
  void initState() {
    super.initState();
    _cycles = Cycle.values;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cycles')),
      body: AnimatedBuilder(
        animation: widget.filter,
        builder: (context, _) {
          return ListView.builder(
            itemCount: _cycles.length,
            itemBuilder: (context, index) {
              final cycle = _cycles[index];
              final checked = widget.filter.contains(cycle);

              return ListTile(
                title: Text(cycle.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: checked,
                      tristate: true,
                      onChanged: (bool? value) {
                        if (value == true) {
                          widget.filter.addCycle(cycle);
                        } else {
                          widget.filter.removeCycle(cycle);
                        }
                      },
                    ),

                    cycle.packs.length <= 1
                        ? SizedBox(width: 48.0)
                        : IconButton(
                          icon: Icon(Icons.arrow_right_alt),
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => PacksSelectorScreen(
                                        filter: widget.filter,
                                        cycle: cycle,
                                      ),
                                ),
                              ),
                        ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class PacksSelectorScreen extends StatefulWidget {
  final PackFilter filter;
  final Cycle cycle;

  const PacksSelectorScreen({
    super.key,
    required this.filter,
    required this.cycle,
  });

  @override
  State<PacksSelectorScreen> createState() => _PacksSelectorScreenState();
}

class _PacksSelectorScreenState extends State<PacksSelectorScreen> {
  late final List<Pack> _packs;

  @override
  void initState() {
    super.initState();
    _packs = widget.cycle.packs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.cycle.name} Packs')),
      body: AnimatedBuilder(
        animation: widget.filter,
        builder: (context, _) {
          return ListView.builder(
            itemCount: _packs.length,
            itemBuilder: (context, index) {
              final pack = _packs[index];
              final checked = widget.filter.containsPack(widget.cycle, pack);

              return CheckboxListTile(
                title: Text(pack.name),
                value: checked,
                onChanged: (bool? value) {
                  if (value == true) {
                    widget.filter.addPack(widget.cycle, pack);
                  } else {
                    widget.filter.removePack(widget.cycle, pack);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
