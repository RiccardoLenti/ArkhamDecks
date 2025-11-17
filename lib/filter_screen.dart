import 'package:arkham_decks/search_filters.dart';
import 'package:arkham_decks/search_filters_widgets.dart';
import 'package:flutter/material.dart';

class FilterScreen extends StatelessWidget {
  final SearchFilters filters;

  const FilterScreen({super.key, required this.filters});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: filters,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Text('Filters'),
                ValueListenableBuilder(
                  valueListenable: filters.cardCount,
                  builder: (context, cardCount, _) {
                    return Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        '\t\t[$cardCount cards]',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () => filters.clear(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              spacing: 12.0,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FactionFilterWidget(filter: filters.factionFilter),
                TypeFilterWidget(filter: filters.typeFilter),
                LevelFilterWidget(filter: filters.levelFilter),
                CostFilterWidget(filter: filters.costFilter),
                TraitFilterWidget(filter: filters.traitFilter),
                ExpansionFilterWidget(filter: filters.expansionFilter),
              ],
            ),
          ),
        );
      },
    );
  }
}
