import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_detail_screen.dart';
import 'package:arkham_decks/database.dart';
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

  @override
  void initState() {
    super.initState();
    _loadInvestigators();
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
              : SingleChildScrollView(
                child: Column(
                  children: [
                    for (final expansion in Cycle.values)
                      ..._buildInvestigatorsList(expansion),
                  ],
                ),
              ),
    );
  }

  List<Widget> _buildInvestigatorsList(Cycle expansion) {
    final investigators = _investigatorMap![expansion]!;
    final textEditingController = TextEditingController();

    if (investigators.isEmpty) {
      return [SizedBox.shrink()];
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
              onTap: () => _newDeckDialog(investigator, textEditingController),
            ),
          );
        },
      ),
    ];
  }

  Future<dynamic> _newDeckDialog(
    SimplifiedCard investigator,
    TextEditingController controller,
  ) {
    return showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'New ${investigator.name} Deck',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Deck name:',
                  hintStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontStyle: FontStyle.italic),
                  errorText: errorText,
                ),
              ),

              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        controller.clear();
                        Navigator.pop(context);
                      },
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final name = controller.text.trim();
                        if (name.isEmpty) {
                          setState(() {
                            errorText = 'Name cannot be empty';
                          });
                          return; // dialog is not closed
                        }

                        final db = await DatabaseHelper.instance.db;

                        final deckRequirements =
                            (await db.query(
                                  'cards',
                                  columns: ['deck_requirements'],
                                  where: 'code = ?',
                                  whereArgs: [investigator.code],
                                )).first['deck_requirements']
                                as String;
                        final parts = deckRequirements
                            .split(',')
                            .map((s) => s.trim());
                        int size = 0;
                        List<String> cards = ['01000'];

                        for (final part in parts) {
                          if (part.startsWith('size:')) {
                            size = int.parse(part.substring(5));
                          } else if (part.startsWith('card:')) {
                            final codes = part.split(':');
                            cards.add(codes[1]);
                          }
                        }

                        final deckId = await db.insert('decks', {
                          'name': name,
                          'investigator_code': investigator.code,
                          'size': size,
                        });

                        await Future.wait(
                          cards.map(
                            (cardCode) => db.insert('deck_cards', {
                              'deck_id': deckId,
                              'card_code': cardCode,
                              'count': 1,
                              'side_deck': 0,
                            }),
                          ),
                        );

                        controller.clear();
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
