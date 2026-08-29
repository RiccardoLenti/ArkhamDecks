import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_screen.dart';
import 'package:arkham_decks/card_view.dart';
import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:arkham_decks/new_deck_screen.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeckSummary {
  final Deck deck;
  final int cardsCount;
  final int nonExtraCardsCount;
  final int xpCount;

  const DeckSummary({
    required this.deck,
    required this.cardsCount,
    required this.nonExtraCardsCount,
    required this.xpCount,
  });

  factory DeckSummary.fromMap(Map<String, dynamic> map) => DeckSummary(
    deck: Deck.fromMap(map),
    cardsCount: map['cards_count'],
    nonExtraCardsCount: map['non_extra_count'],
    xpCount: map['xp_count'],
  );
}

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  late Future<List<DeckSummary>> _decksFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _decksFuture = fetchDecks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DeckSummary> _filter(List<DeckSummary> decks) {
    if (_query.isEmpty) {
      return decks;
    }

    final query = _query.toLowerCase();

    return decks
        .where(
          (summary) =>
              summary.deck.name.toLowerCase().contains(query) ||
              summary.deck.investigatorName.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Decks')),
      body: Column(
        children: [
          // TODO: maybe implement faction filtering
          Container(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: (searchText) => setState(() => _query = searchText),
                clear: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder(
              future: _decksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final decks = _filter(snapshot.data!);

                return ListView.builder(
                  itemCount: decks.length,
                  itemBuilder: (context, index) {
                    return _DeckTile(
                      summary: decks[index],
                      onReturn:
                          () => setState(() {
                            _decksFuture = fetchDecks();
                          }),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NewDeckScreen()),
          );

          if (!mounted) {
            return;
          }

          setState(() {
            _decksFuture = fetchDecks();
          }); //rebuilds
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // instr on deck_requirements instead of parsing requiredCodes
  Future<List<DeckSummary>> fetchDecks() async {
    final db = await DatabaseHelper.instance.db;

    final rows = await db.rawQuery(
      '''SELECT decks.id, decks.name AS deck_name, decks.size AS size, decks.signatures_count AS signatures_count,
      decks.selections AS selections,
      investigator.*,
      IFNULL(SUM(deck_cards.count), 0) AS cards_count,
      IFNULL(SUM(deck_cards.count * IFNULL(cards.xp, 0)), 0) AS xp_count,
      IFNULL(SUM(CASE WHEN cards.subtype_code IS NULL
        AND instr(investigator.deck_requirements, deck_cards.card_code) = 0
        THEN deck_cards.count END), 0) AS non_extra_count
      FROM decks
      JOIN cards AS investigator ON decks.investigator_code = investigator.code
      LEFT JOIN deck_cards ON deck_cards.deck_id = decks.id AND deck_cards.side_deck = 0
      LEFT JOIN cards ON cards.code = deck_cards.card_code
      GROUP BY decks.id
      ORDER BY decks.id DESC''',
    );

    return rows.map((map) => DeckSummary.fromMap(map)).toList();
  }
}

class _DeckTile extends StatelessWidget {
  final DeckSummary summary;
  final VoidCallback onReturn;

  const _DeckTile({required this.summary, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    final deck = summary.deck;
    final faction = deck.investigator.faction;
    final colorScheme = Theme.of(context).colorScheme;
    final listTileTheme = Theme.of(context).listTileTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Material(
        color: colorScheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: colorScheme.outline),
        ),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => ChangeNotifierProvider.value(
                      value: deck,
                      child: DeckScreen(deck: deck),
                    ),
              ),
            );

            await deck.pendingWrite;
            onReturn();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 4.0),
                child: Row(
                  spacing: 10.0,
                  children: [
                    InvestigatorThumb(
                      code: deck.investigator.code,
                      faction: faction,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deck.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: listTileTheme.titleTextStyle!.copyWith(
                              fontSize: 24.0,
                              height: 1.0,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),

                          Row(
                            spacing: 8.0,
                            children: [
                              Expanded(
                                child: Text(
                                  deck.investigatorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: listTileTheme.subtitleTextStyle!
                                      .copyWith(height: 1.0),
                                ),
                              ),

                              _buildStats(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // TODO: ArkhamDB and deck tags go here once syncing exists
              Ink(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(top: BorderSide(color: colorScheme.outline)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 3.0, 8.0, 4.0),
                  child: Row(children: [_FactionChip(faction: faction)]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontSize: 14.0,
      fontVariations: const [FontVariation('wght', 700)],
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2.0,
      children: [
        IconManager().getIcon('xp-bold', color: color, size: 18),
        Text('${summary.xpCount} XP', style: style),
        const SizedBox(width: 7.0),
        IconManager().getIcon('upgrade', color: color, size: 18),
        Text('0 XP', style: style),
        const SizedBox(width: 7.0),
        IconManager().getIcon('card-outline-bold', color: color, size: 18),
        Text(
          '\u00d7 ${summary.nonExtraCardsCount} (${summary.cardsCount})',
          style: style,
        ),
      ],
    );
  }
}

class _FactionChip extends StatelessWidget {
  final Faction faction;

  const _FactionChip({required this.faction});

  @override
  Widget build(BuildContext context) {
    final name = faction.name;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        color: Theme.of(context).colorScheme.surfaceDim,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2.0,
        children: [
          Transform.translate(
            offset: const Offset(0, -0.5),
            child: IconManager().getIcon(
              name,
              color: AppColors.factions[faction]!.light,
              size: 18,
            ),
          ),
          Text(
            '${name[0].toUpperCase()}${name.substring(1)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontSize: 15.0),
          ),
        ],
      ),
    );
  }
}
