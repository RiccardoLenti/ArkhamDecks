import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_screen.dart';
import 'package:arkham_decks/new_deck_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  late Future<List<Deck>> _decksFuture;

  @override
  void initState() {
    super.initState();
    _decksFuture = fetchDecks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Decks')),
      body: FutureBuilder(
        future: _decksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final decks = snapshot.data!;

          return ListView.builder(
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                title: Text(
                  deck.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                subtitle: Text(deck.investigatorName),
                onTap: () async {
                  final bool? res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChangeNotifierProvider.value(
                            value: deck,
                            child: DeckScreen(deck: deck),
                          ),
                    ),
                  );

                  if (res != null && res) {
                    setState(() {
                      _decksFuture = fetchDecks();
                    }); // rebuilds
                  }
                },
              );
            },
          );
        },
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

  Future<List<Deck>> fetchDecks() async {
    final db = await DatabaseHelper.instance.db;

    final rows = await db.rawQuery('''
      SELECT decks.id, decks.name, decks.investigator_code, cards.name AS investigator_name, cards.deck_options
      FROM decks
      JOIN cards ON decks.investigator_code = cards.code
    ''');

    return rows.map((map) => Deck.fromMap(map)).toList();
  }
}
