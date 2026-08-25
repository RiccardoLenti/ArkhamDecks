import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_detail_screen.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_choices.dart';
import 'package:arkham_decks/expansions.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart';

class NewDeckScreen extends StatefulWidget {
  const NewDeckScreen({super.key});

  @override
  State<NewDeckScreen> createState() => _NewDeckScreenState();
}

class _NewDeckScreenState extends State<NewDeckScreen> {
  Map<Cycle, List<SimplifiedCard>>? _investigatorMap;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadInvestigators();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  //TODO: when the refactoring is finishes change every 'expansion' here into something decent
  Future<void> _loadInvestigators() async {
    final Map<Cycle, List<SimplifiedCard>> res = {};

    final db = await DatabaseHelper.instance.db;

    for (final expansion in Cycle.values) {
      final List<String> packs =
          (await db.query(
            'packs',
            where: 'cycle_code = ?',
            whereArgs: [expansion.code],
          )).map((map) => map['code']).toList().cast<String>();

      final List<String> placeholders = List.filled(packs.length, '?');

      final maps = await db.rawQuery(
        '''
        SELECT * FROM cards JOIN printings on cards.code = printings.canonical_code where type_code = ? 
        AND pack_code in (${placeholders.join(', ')}) AND bonded_to IS NULL GROUP BY canonical_code ORDER BY code''',
        ['investigator', ...packs],
      );

      res[expansion] = maps.map((map) => SimplifiedCard.fromMap(map)).toList();
    }

    setState(() {
      _investigatorMap = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('New Deck')),
      body:
          _investigatorMap == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomSearchBar(
                        controller: _searchController,
                        onChanged:
                            (text) => setState(
                              () => _searchText = text.trim().toLowerCase(),
                            ),
                        clear: () {
                          _searchController.clear();
                          setState(() => _searchText = '');
                        },
                      ),
                    ),
                  ),
                  Expanded(child: _buildResults()),
                ],
              ),
    );
  }

  Widget _buildResults() {
    final results = [
      for (final expansion in Cycle.values)
        ..._buildInvestigatorsList(expansion),
    ];

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No investigators found',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return SingleChildScrollView(child: Column(children: results));
  }

  List<SimplifiedCard> _filtered(Cycle expansion) {
    final investigators = _investigatorMap![expansion]!;
    if (_searchText.isEmpty) return investigators;

    return investigators
        .where(
          (i) =>
              i.name.toLowerCase().contains(_searchText) ||
              (i.subname?.toLowerCase().contains(_searchText) ?? false),
        )
        .toList();
  }

  List<Widget> _buildInvestigatorsList(Cycle expansion) {
    final investigators = _filtered(expansion);

    if (investigators.isEmpty) {
      return const [];
    }

    return [
      DividerWithText(text: expansion.name),
      ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: investigators.length,
        itemBuilder: (context, index) {
          final investigator = investigators[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.factions[investigator.faction]!.dark,
              border: Border.all(
                width: 3.0,
                color: Theme.of(context).colorScheme.surface,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(investigator.name),
              subtitle: Text(investigator.subname!),
              contentPadding: EdgeInsets.only(left: 22.0),
              onTap: () => _newDeckDialog(investigator),
            ),
          );
        },
      ),
    ];
  }

  Future<dynamic> _newDeckDialog(SimplifiedCard investigator) {
    final choices = DeckChoice.parse(investigator.deckOptions);
    _nameController.clear();

    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        String? errorText;
        final selections = DeckChoice.defaults(choices);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'New ${investigator.name} Deck',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Deck name:',
                        hintStyle: Theme.of(context).textTheme.bodyMedium!
                            .copyWith(fontStyle: FontStyle.italic),
                        errorText: errorText,
                      ),
                    ),
                    DeckChoicePicker(
                      choices: choices,
                      selections: selections,
                      onChanged:
                          (key, id) => setState(() => selections[key] = id),
                    ),
                  ],
                ),
              ),

              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final name = _nameController.text.trim();
                        if (name.isEmpty) {
                          setState(() {
                            errorText = 'Name cannot be empty';
                          });
                          return; // dialog is not closed
                        }

                        await Deck.initInDb(name, investigator, selections);

                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: Text('Confirm'),
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
