import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/cards_screen.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeckScreen extends StatefulWidget {
  final Deck deck;

  const DeckScreen({super.key, required this.deck});

  @override
  State<StatefulWidget> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  late final SearchFilters _searchFilters;
  late final Future<void> _deckFuture;
  bool _isDeckDeleted = false;

  @override
  void initState() {
    super.initState();
    _searchFilters = SearchFilters(deckOptions: widget.deck.deckOptions);
    _deckFuture = widget.deck.fetchCards();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Deck>(
      builder:
          (consumer, deck, _) => PopScope(
            onPopInvokedWithResult: (didPop, res) async {
              if (!_isDeckDeleted) {
                await deck.storeCardsToDb();
              }
            },

            child: FutureBuilder(
              future: _deckFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Error loading deck: ${snapshot.error}'),
                    ),
                  );
                }

                return Scaffold(
                  appBar: AppBar(
                    title: Text(
                      deck.name,
                    ),

                    actions: [
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _showDeleteDeckDialog(context, deck),
                      ),
                    ],
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
                );
              },
            ),
          ),
    );
  }

  void _showDeleteDeckDialog(BuildContext context, Deck deck) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Deck?'),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    label: const Text('Cancel'),
                    icon: Icon(Icons.close),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final db = await DatabaseHelper.instance.db;
                      await db.delete(
                        'deck_cards',
                        where: 'deck_id = ?',
                        whereArgs: [deck.id],
                      );
                      await db.delete(
                        'decks',
                        where: 'id = ?',
                        whereArgs: [deck.id],
                      );

                      setState(() => _isDeckDeleted = true);

                      Navigator.pop(context, true);
                      Navigator.pop(context, true);
                    },
                    label: const Text('Confirm'),
                    icon: Icon(Icons.check),
                  ),
                ],
              ),
            ],
          ),
    );
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
                  deckCard.count >= deckCard.card.deckLimit
                      ? null
                      : () => deck.addCard(deckCard),
            ),
          ],
        );
      },
    );
  }
}
