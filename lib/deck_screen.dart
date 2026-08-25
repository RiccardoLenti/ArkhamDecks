import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_list.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/card_list_widget.dart';
import 'package:arkham_decks/cards_screen.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_choices.dart';
import 'package:arkham_decks/factions.dart';
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
    _searchFilters = SearchFilters(
      deckOptions: widget.deck.deckOptions,
      investigator: widget.deck.investigator,
      requiredCodes: widget.deck.requiredCodes,
      selections: widget.deck.selections,
    );
    _deckFuture = widget.deck.fetchCards().then(_syncFilters);
    widget.deck.addListener(_syncFilters);
  }

  // TODO: re-queries the whole card list whenever a card with deck options is
  // added or removed, might get too slow
  void _syncFilters([_]) =>
      _searchFilters.investigatorFilter
        ..setSelections(widget.deck.selections)
        ..setExtraOptions(widget.deck.extraDeckOptions);

  @override
  void dispose() {
    widget.deck.removeListener(_syncFilters);
    super.dispose();
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
                        icon: Icon(Icons.edit),
                        onPressed: () => _showRenameDeckDialog(context, deck),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _showDeleteDeckDialog(context, deck),
                      ),
                    ],
                  ),

                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        _InvestigatorDetail(investigator: deck.investigator),

                        _DeckChoices(deck: deck),

                        _DeckInvalidError(error: deck.validate()),

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
                              Text(
                                'x ${deck.nonExtraCardsCount} (${deck.cardsCount})',
                              ),

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
                          child: CardListWidget(
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
                          child: CardListWidget(
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

                      Navigator.pop(context);
                      Navigator.pop(context);
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

  void _showRenameDeckDialog(BuildContext context, Deck deck) {
    final controller = TextEditingController(text: deck.name);

    showDialog(
      context: context,
      builder: (context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Rename Deck",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Deck Name",
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
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
                        final newName = controller.text.trim();
                        if (newName.isEmpty) {
                          setState(() {
                            errorText = "Name cannot be empty";
                          });
                          return;
                        }

                        await deck.updateName(newName);

                        Navigator.pop(context);
                      },
                      label: const Text('Confirm'),
                      icon: Icon(Icons.check),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
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
        final canAdd = deck.canAdd(card, side: side);
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
            Text(
              '${deckCard.count}x',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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

class _InvestigatorDetail extends StatelessWidget {
  final ArkhamCard investigator;

  const _InvestigatorDetail({required this.investigator});

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

class _DeckChoices extends StatelessWidget {
  final Deck deck;

  const _DeckChoices({required this.deck});

  @override
  Widget build(BuildContext context) {
    if (deck.choices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children:
            deck.choices.map((choice) => _buildChip(context, choice)).toList(),
      ),
    );
  }

  Widget _buildChip(BuildContext context, DeckChoice choice) {
    final selected = deck.selections[choice.key];
    final value = choice.values.where((value) => value.id == selected);
    final faction = Faction.fromString(selected);

    return ActionChip(
      avatar:
          faction == null
              ? const Icon(Icons.tune, size: 16.0)
              : IconManager().getIcon(
                faction.name,
                size: 16.0,
                color: AppColors.factions[faction]!.light,
              ),
      label: Text(
        '${choice.label}: ${value.isEmpty ? '—' : value.first.label}',
      ),
      onPressed: () => _showChoiceDialog(context, choice),
    );
  }

  void _showChoiceDialog(BuildContext context, DeckChoice choice) {
    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        final selections = {...deck.selections};

        return StatefulBuilder(
          builder:
              (context, setState) => AlertDialog(
                title: Text(
                  choice.label,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                content: DeckChoicePicker(
                  choices: deck.choices,
                  only: choice.key,
                  selections: selections,
                  onChanged: (key, id) => setState(() => selections[key] = id),
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
                          await deck.updateSelections(selections);

                          if (context.mounted) Navigator.pop(context);
                        },
                        label: const Text('Confirm'),
                        icon: Icon(Icons.check),
                      ),
                    ],
                  ),
                ],
              ),
        );
      },
    );
  }
}

class _DeckInvalidError extends StatelessWidget {
  final DeckError? error;

  const _DeckInvalidError({required this.error});

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsGeometry.only(bottom: 12.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          border: Border.all(color: scheme.error, width: 1.0),
          borderRadius: BorderRadiusGeometry.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18.0),
            const SizedBox(width: 10.0),
            Expanded(
              child: Text(
                error!.text,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontSize: 13.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
