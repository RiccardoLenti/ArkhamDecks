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
      final maps = (await db.query(
        'cards',
        where: 'type_code = ? AND pack_code = ?',
        whereArgs: ['investigator', expansion.packCode],
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
      appBar: AppBar(title: Text('New Deck', style: TextStyle(fontFamily: 'Arkhamic'))),
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

    return [
      buildDividerWithText(expansion.name),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: investigators.length,
          itemBuilder: (context, index) {
            final investigator = investigators[index];
            return ListTile(
              title: Text(investigator.name),
              subtitle: Text(investigator.code.toString()),
            );
          },
      ),
    ];
  }
}
