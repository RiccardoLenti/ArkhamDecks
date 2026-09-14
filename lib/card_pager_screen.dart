import 'package:arkham_decks/icon_manager.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  late ValueNotifier<int> _page;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _page = ValueNotifier(widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          ValueListenableBuilder(
            valueListenable: _page,
            builder:
                (context, index, _) => IconButton(
                  onPressed:
                      () => launchUrl(
                        Uri.parse(
                          'https://arkhamdb.com/card/${widget.cards[index].code}',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                  icon: IconManager().getIcon('world', color: 
                  Theme.of(context).colorScheme.onSurface),
                ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => _page.value = index,
        itemCount: widget.cards.length,
        itemBuilder: (context, index) {
          final card = widget.cards[index];
          return CardDetailScreen(key: ValueKey(card.code), code: card.code);
        },
      ),
    );
  }
}
