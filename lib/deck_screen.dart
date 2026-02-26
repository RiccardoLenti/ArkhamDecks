import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_list.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/cards_screen.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:arkham_decks/search_filters.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart' hide BoxBorder;
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
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deck.name),
                        Text(
                          deck.investigatorName,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium!.copyWith(fontSize: 12.0),
                        ),
                      ],
                    ),

                    actions: [
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _showDeleteDeckDialog(context, deck),
                      ),
                    ],
                  ),

                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        InvestigatorDetail(investigator: deck.investigator),
                        Container(
                          height: 40.0,
                          decoration: BoxDecoration(
                            color:
                                AppColors
                                    .factions[deck.investigator.faction]!
                                    .dark,
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12.0),
                              IconManager().getIcon(
                                'xp-bold',
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              Text('${deck.xpCount} XP'),
                              const SizedBox(width: 16.0),
                              IconManager().getIcon(
                                'upgrade',
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              const Text('0 XP'),
                              SizedBox(width: 16.0),
                              IconManager().getIcon(
                                'card-outline-bold',
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              Text('x ${deck.cardsCount}'),

                              const Spacer(),

                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                  ),
                                  child: IconButton(
                                    icon: IconManager().getIcon(
                                      'upgrade',
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                    ),
                                    onPressed:
                                        () => _showUpgradeDialog(context, deck),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20.0),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16.0),
                        // TODO: do I want an horizontal padding from here down?
                        BoxBorder(
                          color:
                              AppColors
                                  .factions[deck.investigator.faction]!
                                  .dark,
                          thickTop: true,
                          center: Text(
                            "Deck",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          trailing: Padding(
                            padding: const EdgeInsetsGeometry.only(right: 16.0),
                            child: IconButton(
                              icon: const Icon(Icons.edit),
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
                            ),
                          ),
                          child: CardsListWidget(
                            cardList: CardList.fromList(deck.deckCards),
                            deck: deck,
                            sticky: false,
                          ),
                        ),
                        const Divider(height: 64.0),
                        BoxBorder(
                          color:
                              AppColors
                                  .factions[deck.investigator.faction]!
                                  .dark,
                          thickTop: true,
                          center: Text(
                            "Side Deck",
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          trailing: Padding(
                            padding: const EdgeInsetsGeometry.only(right: 16.0),
                            child: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed:
                                  () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => ChangeNotifierProvider.value(
                                            value: deck,
                                            child: CardsScreen(
                                              searchFilters: _searchFilters,
                                              sideDeck: true,
                                            ),
                                          ),
                                    ),
                                  ),
                            ),
                          ),
                          child: CardsListWidget(
                            cardList: CardList.fromList(deck.sideCards),
                            deck: deck,
                            sticky: false,
                          ),
                        ),
                        const SizedBox(height: 75.0),
                      ],
                    ),
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

  void _showUpgradeDialog(BuildContext context, Deck deck) {}

  void _showDeleteDeckDialog(BuildContext context, Deck deck) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Delete Deck?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
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
  final bool side;
  const AddCardButton({super.key, required this.card, required this.side});

  @override
  Widget build(BuildContext context) {
    return Consumer<Deck>(
      builder: (context, deck, _) {
        final deckCard = deck.lookup(card, side: side);
        final canRemove = deckCard.count > 0;
        final canAdd = deckCard.count < deckCard.card.deckLimit;
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                if (!canRemove) return;
                deck.removeCard(deckCard);
              },
              color:
                  canRemove
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).disabledColor,
            ),
            Text('${deckCard.count}x', style: Theme.of(context).textTheme.bodySmall),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                if (!canAdd) return;
                deck.addCard(deckCard);
              },
              color:
                  canAdd
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).disabledColor,
            ),
          ],
        );
      },
    );
  }
}

class InvestigatorDetail extends StatelessWidget {
  final ArkhamCard investigator;

  const InvestigatorDetail({super.key, required this.investigator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: Column(
        spacing: 14.0,
        children: [
          InvestigatorStats(card: investigator),
          HealthSanityIcon(
            valueHealth: investigator.health,
            valueSanity: investigator.sanity,
          ),
          CardText(card: investigator, buildBar: false),
        ],
      ),
    );
  }
}
