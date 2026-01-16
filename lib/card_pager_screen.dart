import 'package:flutter/material.dart';
import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_detail_screen.dart';

class CardPagerScreen extends StatefulWidget {
  final List<SimplifiedCard> cards;
  final int initialIndex;

  const CardPagerScreen({
    super.key,
    required this.cards,
    required this.initialIndex,
  });

  @override
  State<CardPagerScreen> createState() => _CardPagerScreenState();
}

class _CardPagerScreenState extends State<CardPagerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          return CardDetailScreen(key: ValueKey(card.code), code: card.code);
        },
      ),
    );
  }
}
