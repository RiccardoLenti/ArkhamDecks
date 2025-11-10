import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/cards_screen.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/material.dart';

class DeckScreen extends StatefulWidget {
  final Deck deck;

  const DeckScreen({super.key, required this.deck});

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  final SearchFilters _searchFilters = SearchFilters();

  @override
  void initState() {
    super.initState();
    widget.deck.addListener(_onDeckChanged);
  }

  void _onDeckChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.deck.removeListener(_onDeckChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.name, style: TextStyle(fontFamily: 'Arkhamic')),
      ),
      body: ListView.builder(
        itemCount: deck.cards.length,
        itemBuilder: (context, index) {
          final deckCard = deck.deckCards[index];
          return CardListTile(
            card: deckCard.card,
            cards: deck.cards,
            index: index,
            trailing: Text('${deckCard.count.toString()}x'),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) =>
                        CardsScreen(deck: deck, searchFilters: _searchFilters),
              ),
            ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Widget buildAddCardButton(Deck deck, SimplifiedCard card) {
  final deckCard = deck.getDeckCard(card);

  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(Icons.remove),
        onPressed: deckCard.count == 0 ? null : () => deck.removeCard(deckCard),
      ),
      Text('${deckCard.count}x'),
      IconButton(
        icon: Icon(Icons.add),
        onPressed: deckCard.count == 2 ? null : () => deck.addCard(deckCard),
      ),
    ],
  );
}
