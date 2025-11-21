import 'package:arkham_decks/card_view.dart';
import 'package:flutter/material.dart';
import 'package:arkham_decks/arkham_card.dart';

//TODO: This could be optimized by making it a stateful widget so that it doesn't reload data at every rebuild but the future is loaded only once
class CardDetailScreen extends StatelessWidget {
  final String code;
  const CardDetailScreen({super.key, required this.code});

  Future<List<ArkhamCard>> _loadAllCards() async {
    final mainCard = await ArkhamCard.fromDb(code);
    final extras = await Future.wait([
      for (final extraCode in mainCard.additionalCards)
        ArkhamCard.fromDb(extraCode),
    ]);
    return [mainCard, ...extras];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<ArkhamCard>>(
        future: _loadAllCards(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final cards = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                children: [
                  CardView(card: cards.first),
                  if (cards.length > 1) ...[
                    DividerWithText(text: 'Bonded Cards'),

                    for (final card in cards.skip(1)) ...[
                      CardView(card: card),
                      SizedBox(height: 25.0),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DividerWithText extends StatelessWidget {
  final String text;
  static const Divider _divider = Divider(thickness: 2.5, height: 30);

  const DividerWithText({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: _divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                text,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const Expanded(child: _divider),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
