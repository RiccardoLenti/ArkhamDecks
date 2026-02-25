import 'dart:async';

import 'package:arkham_decks/card_list.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_screen.dart';
import 'package:arkham_decks/filter_screen.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

class CardsScreen extends StatefulWidget {
  final SearchFilters searchFilters;
  final bool sideDeck;

  const CardsScreen({super.key, required this.searchFilters, bool? sideDeck})
    : sideDeck = sideDeck ?? false;

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
                child: CardsListWidget(
                  cardList: _cardList,
                  deck: _deck,
                  side: widget.sideDeck,
                ),
              ),
        ],
      ),
    );
  }
}

class CardsListWidget extends StatelessWidget {
  final CardList cardList;
  final Deck? deck;
  final bool sticky;
  final bool side;

  const CardsListWidget({
    super.key,
    required this.cardList,
    this.deck,
    bool? sticky,
    bool? side,
  }) : sticky = sticky ?? true,
       side = side ?? false;

  @override
  Widget build(BuildContext context) {
    if (!sticky) {
      return _buildColumn(context);
    } else {
      return CustomScrollView(slivers: buildSlivers(context));
    }
  }

  Widget _buildColumn(BuildContext context) {
    return Column(
      children:
          cardList.sections.where((section) => section.cards.isNotEmpty).map((
            sectionCards,
          ) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 40.0,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _SectionHeader(
                      name: sectionCards.section.name,
                      slots: sectionCards.section.slots,
                    ),
                  ),
                ),

                ...sectionCards.cards.map((card) {
                  return Column(
                    children: [
                      CardListTile(
                        key: ValueKey(card.code),
                        card: card,
                        cards: cardList.cards,
                        index: cardList.cards.indexOf(card), //TODO: ?
                        trailing: AddCardButton(card: card, side: side),
                      ),
                      const Divider(height: 0),
                    ],
                  );
                }),
              ],
            );
          }).toList(),
    );
  }

  List<Widget> buildSlivers(BuildContext context) {
    return cardList.sections.where((section) => section.cards.isNotEmpty).map((
      sectionCards,
    ) {
      return SliverStickyHeader(
        sticky: sticky,
        header: Container(
          height: 40.0,
          color: Theme.of(context).colorScheme.surfaceDim,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _SectionHeader(
              name: sectionCards.section.name,
              slots: sectionCards.section.slots,
            ),
          ),
        ),

        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: sectionCards.cards.length,
            (context, i) {
              final card = sectionCards.cards[i];
              return Column(
                children: [
                  CardListTile(
                    key: ValueKey(card.code),
                    card: card,
                    cards: cardList.cards,
                    index: i + cardList.offset(sectionCards.section),
                    trailing:
                        deck == null
                            ? null
                            : AddCardButton(card: card, side: side),
                  ),
                  // TODO: bad solution but works for now
                  Divider(height: 0),
                ],
              );
            },
          ),
        ),
      );
    }).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String name;
  final List<String>? slots;

  const _SectionHeader({super.key, required this.name, this.slots});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.bold);

    if (slots == null || slots!.isEmpty) {
      return Text(name, style: style);
    }

    return Row(
      children: [
        Text('$name  •  ${slots!.join(' - ')}', style: style),
        Spacer(),
        ...slots!.map((slotName) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconManager().getIcon(
              '${slotName.toLowerCase().replaceAll(' ', '_')}_inverted',
              color: Theme.of(context).colorScheme.onSurface,
              size: 30,
            ),
          );
        }),
      ],
    );
  }
}
