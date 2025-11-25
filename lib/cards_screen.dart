import 'dart:async';

import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_screen.dart';
import 'package:arkham_decks/filter_screen.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CardsScreen extends StatefulWidget {
  final SearchFilters searchFilters;

  const CardsScreen({super.key, required this.searchFilters});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<SimplifiedCard> _cards = [];
  late final TextEditingController _searchController;
  late final SearchFilters _searchFilters;
  Deck? _deck;

  @override
  void initState() {
    super.initState();
    _searchFilters = widget.searchFilters;
    _searchFilters.addListener(_onFiltersChanged);
    _searchController = TextEditingController(text: _searchFilters.searchText);
    _updateCards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFilters.removeListener(_onFiltersChanged);
    super.dispose();
  }

  //TODO: this used to make sense, now it's just an alias for a function, it can be removed
  void _onFiltersChanged() {
    _updateCards();
  }

  Future<void> _updateCards() async {
    final cards = await _searchFilters.queryDb();

    setState(() {
      _cards = cards;
    });
  }

  @override
  Widget build(BuildContext context) {
    _deck = context.watch<Deck?>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Investigator Cards'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FilterScreen(filters: _searchFilters),
                ),
              );
            },
            icon: Icon(Icons.filter_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomSearchBar(
              controller: _searchController,
              onChanged:
                  (searchText) => _searchFilters.updateSearchText(searchText),
              clear: () {
                _searchController.clear();
                _searchFilters.updateSearchText('');
              },
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _cards.length,
              separatorBuilder: (_, _) => const Divider(height: 0.0),
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return CardListTile(
                  card: card,
                  cards: _cards,
                  index: index,
                  trailing: _deck == null ? null : AddCardButton(card: card),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
