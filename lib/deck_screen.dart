import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/cards_screen.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeckScreen extends StatelessWidget {
  final Deck deck;
  final SearchFilters _searchFilters;

  DeckScreen({super.key, required this.deck})
    : _searchFilters = SearchFilters(deckOptions: deck.deckOptions);

  @override
  Widget build(BuildContext context) {
    return Consumer<Deck>(builder: (consumer, deck, _) => Scaffold(
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
                    (_) => ChangeNotifierProvider.value(
                      value: deck,
                      child: CardsScreen(
                        searchFilters: _searchFilters,
                      ),
                    ),
              ),
            ),
        child: const Icon(Icons.add),
      ),
    ));
  }
}

class AddCardButton extends StatelessWidget {
  final SimplifiedCard card;
  const AddCardButton({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Consumer<Deck>(
      builder: (context, deck, _) {
        final deckCard = deck.getDeckCard(card);
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed:
                  deckCard.count <= 0 ? null : () => deck.removeCard(deckCard),
            ),
            Text('${deckCard.count}x'),
            IconButton(
              icon: Icon(Icons.add),
              onPressed:
                  deckCard.count >= 2 ? null : () => deck.addCard(deckCard),
            ),
          ],
        );
      },
    );
  }
}
