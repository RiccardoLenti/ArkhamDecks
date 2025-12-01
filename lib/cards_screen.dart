import 'dart:async';

import 'package:arkham_decks/card_list.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_screen.dart';
import 'package:arkham_decks/filter_screen.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class CardsScreen extends StatefulWidget {
  final SearchFilters searchFilters;

  const CardsScreen({super.key, required this.searchFilters});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  bool _isLoading = true;
  CardList _cardList = CardList();
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
    setState(() => _isLoading = true);

    final cards = await _searchFilters.queryDb();

    setState(() {
      _isLoading = false;
      _cardList = cards;
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
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(
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
          ),

          _isLoading
              ? CircularProgressIndicator()
              : Expanded(
                child: CustomScrollView(
                  slivers:
                      _cardList.sections
                          .where((section) => section.cards.isNotEmpty)
                          .map((section) {
                            if (section.cards.isEmpty) {
                              return SizedBox.shrink();
                            }

                            return SliverStickyHeader(
                              header: Container(
                                height: 40.0,
                                color: Theme.of(context).colorScheme.surfaceDim,
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    section.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium!.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  childCount: section.cards.length,
                                  (context, i) {
                                    final card = section.cards[i];
                                    return Column(
                                      children: [
                                        if (i != 0) Divider(height: 0),
                                        CardListTile(
                                          key: ValueKey(card.code),
                                          card: card,
                                          cards: _cardList.cards,
                                          index: _cardList.globalIndex(
                                            section.name,
                                            i,
                                          ),
                                          trailing:
                                              _deck == null
                                                  ? null
                                                  : AddCardButton(card: card),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          })
                          .toList(),
                ),
              ),
        ],
      ),
    );
  }
}
