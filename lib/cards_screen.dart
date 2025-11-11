import 'dart:async';

import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_screen.dart';
import 'package:arkham_decks/filter_screen.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/material.dart';

class CardsScreen extends StatefulWidget {
  final Deck? deck;
  final SearchFilters searchFilters;

  const CardsScreen({super.key, this.deck, required this.searchFilters});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<SimplifiedCard> _cards = [];
  late final TextEditingController _searchController;
  late final SearchFilters _searchFilters;

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Investigator Cards'),
        backgroundColor: Colors.deepPurple,
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
            icon: Icon(Icons.filter_alt, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchFilters.updateSearchText('');
                  },
                  icon: Icon(Icons.clear),
                ),
              ),
              onChanged:
                  (searchText) => _searchFilters.updateSearchText(searchText),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return CardListTile(
                  card: card,
                  cards: _cards,
                  index: index,
                  trailing:
                      widget.deck == null
                          ? null
                          : buildAddCardButton(widget.deck!, card),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
