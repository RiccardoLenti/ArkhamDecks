import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_detail_screen.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/expansions.dart';
import 'package:flutter/material.dart';

class NewDeckScreen extends StatefulWidget {
  const NewDeckScreen({super.key});

  @override
  State<NewDeckScreen> createState() => _NewDeckScreenState();
}

class _NewDeckScreenState extends State<NewDeckScreen> {
  Map<Expansion, List<SimplifiedCard>>? _investigatorMap;

  @override
  void initState() {
    super.initState();
    _loadInvestigators();
  }

  Future<void> _loadInvestigators() async {
    final Map<Expansion, List<SimplifiedCard>> res = {};

    final db = await DatabaseHelper.instance.db;

    for (final expansion in Expansion.values) {
      // the group by is needed so that it returns only 1 Hank Samson
      final maps = (await db.query(
        'cards',
        where: 'type_code = ? AND pack_code = ?',
        whereArgs: ['investigator', expansion.packCode],
        groupBy: 'name',
        orderBy: 'code',
      ));

      res[expansion] = maps.map((map) => SimplifiedCard.fromMap(map)).toList();
    }

    setState(() {
      _investigatorMap = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Deck', style: TextStyle(fontFamily: 'Arkhamic')),
      ),
      body:
          _investigatorMap == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  children: [
                    for (final expansion in Expansion.values)
                      ..._buildInvestigatorsList(expansion),
                  ],
                ),
              ),
    );
  }

  List<Widget> _buildInvestigatorsList(Expansion expansion) {
    final investigators = _investigatorMap![expansion]!;
    final textEditingController = TextEditingController();

    return [
      buildDividerWithText(expansion.name),
      ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: investigators.length,
        itemBuilder: (context, index) {
          final investigator = investigators[index];
          return Container(
            decoration: BoxDecoration(
              color: investigator.faction.color,
              border: Border.all(color: Colors.white, width: 3.0),
            ),
            child: ListTile(
              title: Text(
                investigator.name,
                style: const TextStyle(fontFamily: 'Arkhamic', fontSize: 18),
              ),
              subtitle: Text(investigator.code.toString()),
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: EdgeInsets.only(left: 22.0),
              onTap: () {
                showDialog(
                  context: context,
                  useRootNavigator: false,
                  builder: (context) {
                    String? errorText;

                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: Text('New ${investigator.name} Deck'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (errorText != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text(
                                    errorText!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),

                              TextField(
                                controller: textEditingController,
                                decoration: InputDecoration(
                                  hintText: 'Deck name:',
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    textEditingController.clear();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final name =
                                        textEditingController.text.trim();
                                    if (name.isEmpty) {
                                      setState(() {
                                        errorText = 'Name cannot be empty';
                                      });
                                      return; // dialog is not closed
                                    }

                                    final db = await DatabaseHelper.instance.db;
                                    await db.insert('decks', {
                                      'name': name,
                                      'investigator_code': investigator.code,
                                    });

                                    textEditingController.clear();
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
              },
            ),
          );
        },
      ),
    ];
  }
}
