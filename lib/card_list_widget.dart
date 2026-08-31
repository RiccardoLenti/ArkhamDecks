import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_list.dart';
import 'package:arkham_decks/card_pager_screen.dart';
import 'package:arkham_decks/deck.dart';
import 'package:arkham_decks/deck_screen.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:arkham_decks/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

/// If sticky this uses slivers.
/// If !sticky this uses a column.
class CardListWidget extends StatelessWidget {
  final CardList cardList;
  final Deck? deck;
  final bool sticky;
  final bool side;

  const CardListWidget({
    super.key,
    required this.cardList,
    this.deck,
    bool? sticky,
    bool? side,
  }) : sticky = sticky ?? true,
       side = side ?? false;

  @override
  Widget build(BuildContext context) {
    if (!sticky) {
      return _buildColumn(context);
    } else {
      return CustomScrollView(slivers: buildSlivers(context));
    }
  }

  Widget _buildColumn(BuildContext context) {
    return Column(
      children:
          cardList.sections.where((section) => section.cards.isNotEmpty).map((
            sectionCards,
          ) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 40.0,
                  color: Theme.of(context).colorScheme.surfaceDim,
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _SectionHeader(
                      name: sectionCards.section.name,
                      slots: sectionCards.section.slots,
                    ),
                  ),
                ),

                ...sectionCards.cards.map((card) {
                  return Column(
                    children: [
                      CardListTile(
                        key: ValueKey(card.code),
                        card: card,
                        cards: cardList.cards,
                        index: cardList.cards.indexOf(card), //TODO: ?
                        trailing: AddCardButton(card: card, side: side),
                      ),
                      const Divider(height: 0),
                    ],
                  );
                }),
              ],
            );
          }).toList(),
    );
  }

  List<Widget> buildSlivers(BuildContext context) {
    return cardList.sections.where((section) => section.cards.isNotEmpty).map((
      sectionCards,
    ) {
      return SliverStickyHeader(
        sticky: sticky,
        header: Container(
          height: 40.0,
          color: Theme.of(context).colorScheme.surfaceDim,
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _SectionHeader(
              name: sectionCards.section.name,
              slots: sectionCards.section.slots,
            ),
          ),
        ),

        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: sectionCards.cards.length,
            (context, i) {
              final card = sectionCards.cards[i];
              return Column(
                children: [
                  CardListTile(
                    key: ValueKey(card.code),
                    card: card,
                    cards: cardList.cards,
                    index: i + cardList.offset(sectionCards.section),
                    trailing:
                        deck == null
                            ? null
                            : AddCardButton(card: card, side: side),
                  ),
                  // TODO: bad solution but works for now
                  Divider(height: 0),
                ],
              );
            },
          ),
        ),
      );
    }).toList();
  }
}

class _SectionHeader extends StatelessWidget {
  final String name;
  final List<String>? slots;

  const _SectionHeader({super.key, required this.name, this.slots});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 18, fontWeight: FontWeight.bold);

    if (slots == null || slots!.isEmpty) {
      return Text(name, style: style);
    }

    return Row(
      children: [
        Text('$name  •  ${slots!.join(' - ')}', style: style),
        Spacer(),
        ...slots!.map((slotName) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: IconManager().getIcon(
              '${slotName.toLowerCase().replaceAll(' ', '_')}_inverted',
              color: Theme.of(context).colorScheme.onSurface,
              size: 30,
            ),
          );
        }),
      ],
    );
  }
}

class CardListTile extends StatelessWidget {
  const CardListTile({
    super.key,
    required this.card,
    required this.cards,
    required this.index,
    this.trailing,
  });

  final SimplifiedCard card;
  final List<SimplifiedCard> cards;
  final int index;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CostLevelCircle(card: card),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(card.name),
      ),
      subtitle: _CardListTileSubtitle(card: card),
      trailing: trailing,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CardPagerScreen(cards: cards, initialIndex: index),
          ),
        );
      },
    );
  }
}

class _CardListTileSubtitle extends StatelessWidget {
  final SimplifiedCard card;

  const _CardListTileSubtitle({required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        card.taboo == null
            ? SizedBox.shrink()
            : Padding(
              padding: const EdgeInsets.only(right: 2.0),
              child: IconManager().getIcon(
                "tablet",
                size: 15.0,
                color: AppColors.taboo,
              ),
            ),
        card.taboo?.xp == null
            ? SizedBox.shrink()
            : Padding(
              padding: const EdgeInsets.only(right: 2.0),
              child: Text(
                (card.taboo!.xp! > 0 ? '•' : '-') * card.taboo!.xp!.abs(),
                style: TextStyle(color: AppColors.taboo, fontSize: 14.0),
              ),
            ),
        Text(card.subname ?? ''),
      ],
    );
  }
}
