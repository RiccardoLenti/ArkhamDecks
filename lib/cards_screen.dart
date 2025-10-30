import 'dart:async';

import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_pager_screen.dart';
import 'package:arkham_decks/filter_screen.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/material.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<SimplifiedCard> _cards = [];
  final TextEditingController _searchController = TextEditingController();
  final SearchFilters _searchFilters = SearchFilters();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFilters.addListener(_onFiltersChanged);
    _updateCards();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFilters.removeListener(_onFiltersChanged);
    _searchFilters.dispose();
    super.dispose();
  }

  void _onFiltersChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _updateCards();
    });
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
                return ListTile(
                  leading: CostLevelCircle(card: card),
                  title: Text(card.name),
                  subtitle: Text(card.subname?? '', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0)),
                  titleAlignment: ListTileTitleAlignment.top,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CardPagerScreen(
                              cards: _cards,
                              initialIndex: index,
                            ),
                      ),
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