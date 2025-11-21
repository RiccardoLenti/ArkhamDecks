import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_detail_screen.dart';
import 'package:arkham_decks/card_pager_screen.dart';
import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class CardView extends StatelessWidget {
  final ArkhamCard card;

  static const skillBackgroundColor = Color.fromARGB(255, 123, 118, 118);

  static const commitSkillNames = [
    'skill_willpower',
    'skill_intellect',
    'skill_combat',
    'skill_agility',
    'skill_wild',
  ];

  //TODO: purge this.
  static const commitSkillColors = [
    Color(0xFF2C7FC0),
    Color(0xFF7C3C85),
    Color(0xFFAE4236),
    Color(0xFF14854D),
    Color(0xFF8A7D5A),
  ];

  const CardView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BoxBorder(
          color: card.faction.color,
          thickTop: true,
          leading: CostLevelCircle(card: card, onlyOutline: true),
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                card.isUnique ? '✷ ${card.name}' : card.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              if (card.subname != null)
                Expanded(
                  // corrects overflow check
                  child: Transform.translate(
                    offset: const Offset(0, -5),
                    child: Text(
                      card.subname!,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          trailing: FactionIcons(card: card),
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child:
                card.type == 'investigator'
                    ? InvestigatorDetailScreen(card: card)
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 250,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 7.0,
                                    children: [
                                      TypeAndSlots(card: card),
                                      Traits(card: card),
                                      CommitIcons(card: card),
                                      Slots(card: card),

                                      if (card.health != null ||
                                          card.sanity != null)
                                        HealthSanityIcon(
                                          valueHealth: card.health,
                                          valueSanity: card.sanity,
                                        ),
                                    ],
                                  ),
                                ),
                                Image.network(
                                  'https://arkhamdb.com/bundles/cards/${card.code}.png',
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // TODO: export this into a single Widget function
                        Padding(
                          padding: EdgeInsets.only(top: 15, bottom: 8),
                          child: Column(
                            spacing: 5.0,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              card.text == null
                                  ? SizedBox.shrink()
                                  : CardText(card: card),
                              card.flavor == null
                                  ? SizedBox.shrink()
                                  : CardFlavor(card: card),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
        ),
        if (card.customizationText.isNotEmpty) CustomizationTable(card: card),
      ],
    );
  }
}

class FactionIcons extends StatelessWidget {
  final ArkhamCard card;
  final List<Widget> _children;

  FactionIcons({super.key, required this.card})
    : _children =
          (card.faction == Faction.multi
              ? card.multiFactions
                  .map(
                    (faction) => IconManager().getIcon(
                      faction.name,
                      size: 34,
                      color: Colors.white,
                    ),
                  )
                  .toList()
              : [
                IconManager().getIcon(
                  card.faction.name,
                  size: 34,
                  color: Colors.white,
                ),
              ]);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: _children);
  }
}

class CommitIcons extends StatelessWidget {
  final ArkhamCard card;

  const CommitIcons({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    for (final (index, value) in card.commitSkills.indexed) {
      if (value == null) {
        continue;
      }

      for (var i = 0; i < value; i++) {
        children.add(
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: CardView.skillBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                IconManager().getIcon(
                  CardView.commitSkillNames[index],
                  size: 22,
                  color: CardView.commitSkillColors[index],
                ),

                IconManager().getIcon(
                  '${CardView.commitSkillNames[index]}_inverted',
                  size: 22,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      }
    }

    return Wrap(spacing: 5.0, children: children);
  }
}

class Slots extends StatelessWidget {
  final ArkhamCard card;

  const Slots({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    if (card.slots == null) {
      return const SizedBox.shrink();
    }

    return Row(
      spacing: 12,
      children: [
        ...card.slots!.map((slotName) {
          return Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
            child: IconManager().getIcon(
              '${slotName.toLowerCase().replaceAll(' ', '_')}_inverted',
              size: 30,
            ),
          );
        }),
      ],
    );
  }
}

class TypeAndSlots extends StatelessWidget {
  final ArkhamCard card;

  const TypeAndSlots({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Text(
      card.slots == null
          ? card.type
          : '${card.type} • ${card.slots!.join(' - ')}',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class Traits extends StatelessWidget {
  final ArkhamCard card;

  const Traits({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return (card.traits == null)
        ? SizedBox.shrink()
        : Text(
          card.traits!.join(' '),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
  }
}

class HealthSanityIcon extends StatelessWidget {
  static const healthColor = Color(0xFF8D181E);
  static const sanityColor = Color(0xFF165385);
  final String numberHealth;
  final String numberSanity;

  final int? valueHealth;
  final int? valueSanity;

  const HealthSanityIcon({
    super.key,
    required this.valueHealth,
    required this.valueSanity,
  }) : numberHealth = (valueHealth != null ? 'num$valueHealth' : 'numNull'),
       numberSanity = (valueSanity != null ? 'num$valueSanity' : 'numNull');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.0),
      child: Row(
        spacing: 15.0,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconManager().getIcon('health', size: 40, color: healthColor),
              IconManager().getIcon('$numberHealth-fill', color: Colors.white),
              IconManager().getIcon(
                '$numberHealth-outline',
                color: healthColor,
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconManager().getIcon('sanity', size: 40, color: sanityColor),
              IconManager().getIcon('$numberSanity-fill', color: Colors.white),
              IconManager().getIcon(
                '$numberSanity-outline',
                color: sanityColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InvestigatorStats extends StatelessWidget {
  final ArkhamCard card;

  const InvestigatorStats({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 5.0,
      children: [
        ...card.commitSkills.take(card.commitSkills.length - 1).mapIndexed((
          index,
          value,
        ) {
          final name = CardView.commitSkillNames[index];
          final color = CardView.commitSkillColors[index];
          return Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: CardView.skillBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 5.0,
              children: [
                Text(
                  value.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Stack(
                  children: [
                    IconManager().getIcon(name, size: 22, color: color),
                    IconManager().getIcon(
                      '${name}_inverted',
                      size: 22,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

//TODO: add texture
class BoxBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final Widget? leading;
  final Widget? center;
  final Widget? trailing;
  final bool thickTop;

  const BoxBorder({
    super.key,
    required this.child,
    required this.color,
    this.leading,
    this.center,
    this.trailing,
    bool? thickTop,
  }) : thickTop = thickTop ?? false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: IntrinsicHeight(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadiusGeometry.circular(8.0),
                border: Border(
                  top: BorderSide(color: color, width: (thickTop ? 50 : 4)),
                  bottom: BorderSide(color: color, width: 4),
                  left: BorderSide(color: color, width: 4),
                  right: BorderSide(color: color, width: 4),
                ),
              ),
              child: child,
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 50),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                leading == null
                    ? SizedBox.shrink()
                    : Align(alignment: Alignment.centerLeft, child: leading),
                center == null ? SizedBox.shrink() : Center(child: center),
                trailing == null
                    ? SizedBox.shrink()
                    : Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 5.0),
                        child: trailing,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// TODO: make bullet points text indented on multiple rows (ex: Gray's anatomy)
class CardText extends StatelessWidget {
  final ArkhamCard card;

  const CardText({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            margin: EdgeInsets.only(right: 8, left: 4),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(child: TextWithIcons(text: card.text!)),
        ],
      ),
    );
  }
}

class TextWithIcons extends StatelessWidget {
  final String text;
  // matches everything like [tag], ignores [[tag]]
  static final pattern = RegExp(r'(?<!\[)\[([^\[\]]+)\](?!\])');

  const TextWithIcons({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final processedText = text
        .replaceAll('\n- ', '\n<icon name="bullet"/></icon>')
        .replaceAll('\n', '<br>')
        .replaceAll('[fast]', '[free]')
        .replaceAll('[[', '<b><i>')
        .replaceAll(']]', '</i></b>')
        .replaceAllMapped(
          pattern,
          (m) => '<icon name="${m.group(1)}"/></icon>',
        );

    return Html(
      data: processedText,
      extensions: [
        TagExtension(
          tagsToExtend: {'icon'},
          builder: (extentionContext) {
            final iconName = extentionContext.element?.attributes['name'];

            return Padding(
              padding: const EdgeInsets.only(right: 2.5),
              child: IconManager().getIcon(
                iconName!,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            );
          },
        ),
      ],
      style: {
        "body": Style(textAlign: TextAlign.left, margin: Margins.zero),
        "icon": Style(display: Display.inlineBlock),
      },
    );
  }
}

class CardFlavor extends StatelessWidget {
  final ArkhamCard card;

  const CardFlavor({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      child: Text(card.flavor!, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

//TODO: is this the right place for this?
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
      title: Text(card.name),
      subtitle: Text(
        card.subname ?? '',
        style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12.0),
      ),
      titleAlignment: ListTileTitleAlignment.top,
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

class CustomizationTable extends StatelessWidget {
  final ArkhamCard card;

  const CustomizationTable({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DividerWithText(text: 'Customization'),
        BoxBorder(
          color: card.faction.color,
          thickTop: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(card.customizationText.length * 2 - 1, (
                index,
              ) {
                if (index.isOdd) {
                  return Divider(
                    color: Colors.black26,
                    thickness: 0.75,
                    height: 10,
                  );
                } else {
                  return TextWithIcons(
                    text: card.customizationText[index ~/ 2],
                  );
                }
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class InvestigatorDetailScreen extends StatelessWidget {
  final ArkhamCard card;

  const InvestigatorDetailScreen({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 7.0,
            children: [
              TypeAndSlots(card: card),
              Traits(card: card),
              Image.network(
                'https://arkhamdb.com/bundles/cards/${card.code}.png',
                fit: BoxFit.cover,
              ),
              InvestigatorStats(card: card),
              HealthSanityIcon(
                valueHealth: card.health,
                valueSanity: card.sanity,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 15, bottom: 8),
          child: Column(
            spacing: 5.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardText(card: card),
              card.flavor != null ? CardFlavor(card: card) : SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}
