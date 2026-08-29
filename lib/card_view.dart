import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/card_detail_screen.dart';
import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/icon_manager.dart';
import 'package:arkham_decks/theme.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class CardView extends StatelessWidget {
  final ArkhamCard card;

  static const commitSkillNames = [
    'skill_willpower',
    'skill_intellect',
    'skill_combat',
    'skill_agility',
    'skill_wild',
  ];

  const CardView({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BoxBorder(
          color: AppColors.factions[card.faction]!.dark,
          thickTop: true,
          leading:
              card.type == 'investigator'
                  ? null
                  : Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: CostLevelCircle(card: card, onlyOutline: true),
                  ),
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
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(fontSize: 11.0),
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            spacing: 10.0,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 10.0,
                                  children: [
                                    TypeAndSlots(card: card),
                                    if (card.traits.isNotEmpty)
                                      Traits(card: card),
                                    if (card.commitSkills.isNotEmpty)
                                      CommitIcons(card: card),

                                    if (card.health != null ||
                                        card.sanity != null)
                                      HealthSanityIcon(
                                        valueHealth: card.health,
                                        valueSanity: card.sanity,
                                      ),
                                  ],
                                ),
                              ),

                              if (card.slots != null && card.slots!.isNotEmpty)
                                Slots(card: card),

                              CardArt(card: card),
                            ],
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
                                  : CardFlavor(text: card.flavor!),
                            ],
                          ),
                        ),

                        if (card.taboo != null)
                          TabooTextBox(taboo: card.taboo!),

                        Footer(card: card),
                      ],
                    ),
          ),
        ),

        // the check on backFlavor literally exists only for the multiple Hank Samson backs
        if (card.type == 'investigator' && card.backFlavor != null)
          InvestigatorBack(investigator: card),

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
              color: Theme.of(context).colorScheme.surfaceDim,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                IconManager().getIcon(
                  CardView.commitSkillNames[index],
                  size: 24,
                  color: AppColors.stats[index],
                ),

                IconManager().getIcon(
                  '${CardView.commitSkillNames[index]}_inverted',
                  size: 24,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      }
    }

    return Wrap(spacing: 5.0, runSpacing: 5.0, children: children);
  }
}

class Slots extends StatelessWidget {
  final ArkhamCard card;

  const Slots({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        ...card.slots!.map((slotName) {
          return Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceDim,
            ),
            child: Stack(
              children: [
                IconManager().getIcon(
                  slotName.toLowerCase().replaceAll(' ', '_'),
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.onSurface, // this can be variant
                  size: 26,
                ),

                IconManager().getIcon(
                  '${slotName.toLowerCase().replaceAll(' ', '_')}_inverted',
                  color: Theme.of(context).colorScheme.surface,
                  size: 26,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class CardArt extends StatelessWidget {
  final ArkhamCard card;

  const CardArt({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: AppColors.factions[card.faction]!.dark,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.5),
        child: Image.asset(
          'assets/images/art/${card.code}.webp',
          fit: BoxFit.cover,
          cacheHeight: 300,
        ),
      ),
    );
  }
}

class TypeAndSlots extends StatelessWidget {
  final ArkhamCard card;

  const TypeAndSlots({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final type = card.type[0].toUpperCase() + card.type.substring(1);

    return Text(
      card.slots == null || card.slots!.isEmpty
          ? type
          : '$type  •  ${card.slots!.join(' - ')}',
      style: TextStyle(
        fontFamily: 'Alegreya',
        height: 0.4,
        fontSize: 16,
        fontVariations: [FontVariation('wght', 800)],
      ),
    );
  }
}

///assumes traits != null
class Traits extends StatelessWidget {
  final ArkhamCard card;

  const Traits({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Text(
      card.traits.join('  '),
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontStyle: FontStyle.italic,
        fontVariations: [FontVariation('wght', 800)],
        height: 1.1,
      ),
      textHeightBehavior: TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
      softWrap: true,
      overflow: TextOverflow.visible,
    );
  }
}

class HealthSanityIcon extends StatelessWidget {
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
              IconManager().getIcon(
                'health',
                size: 32,
                color: AppColors.health,
              ),
              IconManager().getIcon(
                '$numberHealth-fill',
                size: 19,
                color: Colors.white,
              ),
              IconManager().getIcon(
                '$numberHealth-outline',
                size: 19,
                color: AppColors.health,
              ),
            ],
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconManager().getIcon(
                'sanity',
                size: 32,
                color: AppColors.sanity,
              ),
              IconManager().getIcon(
                '$numberSanity-fill',
                size: 19,
                color: Colors.white,
              ),
              IconManager().getIcon(
                '$numberSanity-outline',
                size: 19,
                color: AppColors.sanity,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InvestigatorThumb extends StatelessWidget {
  final String code;
  final Faction faction;
  final double size;
  final bool light;

  const InvestigatorThumb({
    super.key,
    required this.code,
    required this.faction,
    this.size = 44,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          color: AppColors.factions[faction]!.dark,
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: Image.asset(
          'assets/images/thumb/$code.webp',
          fit: BoxFit.cover,
          cacheWidth: 132,
        ),
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
          final color = AppColors.stats[index];
          return Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
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
// TODO: move this in a widgets.dart file with custom widgets
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadiusGeometry.circular(8.0),
            border: Border(
              top: BorderSide(color: color, width: (thickTop ? 50 : 4)),
              bottom: BorderSide(color: color, width: 4),
              left: BorderSide(color: color, width: 4),
              right: BorderSide(color: color, width: 4),
            ),
          ),
          width: MediaQuery.of(context).size.width,
          child: child,
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
  final bool buildBar;

  const CardText({super.key, required this.card, bool? buildBar})
    : buildBar = buildBar ?? true;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (buildBar) _TextLeftBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: TextWithIcons(
                text: card.taboo?.replacementText ?? card.text!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TextWithIcons extends StatelessWidget {
  final String text;
  final Color? iconColor;
  // matches everything like [tag], ignores [[tag]]
  static final pattern = RegExp(r'(?<!\[)\[([^\[\]]+)\](?!\])');

  const TextWithIcons({super.key, required this.text, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final processedText = text
        .replaceAll('\n- ', '\n<icon name="bullet"/></icon>')
        .replaceAll('\n', '<br>')
        .replaceAll(
          '[fast]',
          '[free]',
        ) // new version of json data doesn't have free anymore
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
          builder: (extensionContext) {
            final iconName = extensionContext.element?.attributes['name'];

            return Padding(
              padding: const EdgeInsets.only(right: 2.5, bottom: 2.5),
              child: IconManager().getIcon(
                iconName!,
                size: 18,
                color: iconColor ?? Theme.of(context).colorScheme.onSurface,
              ),
            );
          },
        ),

        TagExtension(
          tagsToExtend: {'cite'},
          builder: (extensionContext) {
            final text = '  --  ${extensionContext.element!.text}';

            return Text(text);
          },
        ),
      ],
      style: {
        "body": Style(
          textAlign: TextAlign.left,
          margin: Margins.zero,
          fontSize: FontSize(15),
          //lineHeight: LineHeight(1.1),
        ),
        "icon": Style(display: Display.inlineBlock),
      },
    );
  }
}

class CardFlavor extends StatelessWidget {
  final String text;

  CardFlavor({super.key, required String text})
    : text = text
          .replaceAll('<cite>', '\n- ')
          .replaceAll('</cite>', '')
          .replaceAll(
            '<u>',
            '',
          ) // TODO: actually do something about this (curiosity)
          .replaceAll('</u>', '');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall!),
    );
  }
}

class Footer extends StatelessWidget {
  final ArkhamCard card;

  const Footer({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontSize: 14.0);

    return Padding(
      padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 6.0),
      child: Column(
        children: [
          const Divider(height: 0.0),
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
            child: Column(
              children: [
                ...card.printings!.map((printing) {
                  final iconName =
                      printing.pack.cycle.code != 'investigator'
                          ? printing.pack.cycle.code
                          : printing.pack.code;

                  return Row(
                    spacing: 2.0,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(printing.pack.name, style: textTheme),
                      IconManager().getIcon(
                        iconName,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 18.0,
                      ),
                      Text('${printing.position}', style: textTheme),
                      const SizedBox(width: 2.0),
                      IconManager().getIcon(
                        'card-outline',
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 18.0,
                      ),

                      Text('x${printing.quantity}', style: textTheme),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
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
        DividerWithText(text: 'Customization Table'),
        BoxBorder(
          color: AppColors.factions[card.faction]!.dark,
          thickTop: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(card.customizationText.length * 2 - 1, (
                index,
              ) {
                if (index.isOdd) {
                  return Divider(thickness: 0.75, height: 10);
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            spacing: 10.0,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10.0,
                  children: [
                    TypeAndSlots(card: card),
                    if (card.traits.isNotEmpty) Traits(card: card),
                    InvestigatorStats(card: card),
                    HealthSanityIcon(
                      valueHealth: card.health,
                      valueSanity: card.sanity,
                    ),
                  ],
                ),
              ),

              CardArt(card: card),
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
              card.flavor != null
                  ? CardFlavor(text: card.flavor!)
                  : SizedBox.shrink(),
            ],
          ),
        ),

        if (card.taboo != null) TabooTextBox(taboo: card.taboo!),

        Footer(card: card),
      ],
    );
  }
}

class InvestigatorBack extends StatelessWidget {
  final ArkhamCard investigator;
  const InvestigatorBack({super.key, required this.investigator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsGeometry.only(top: 16.0),
      child: BoxBorder(
        color: AppColors.factions[investigator.faction]!.dark,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TextLeftBar(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: TextWithIcons(text: investigator.backText!),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 8.0),
              CardFlavor(text: investigator.backFlavor!),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextLeftBar extends StatelessWidget {
  final Color? color;

  const _TextLeftBar({this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      margin: EdgeInsets.only(right: 8, left: 8),
      decoration: BoxDecoration(
        color: color ?? Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class TabooTextBox extends StatelessWidget {
  final Taboo taboo;

  const TabooTextBox({super.key, required this.taboo});

  @override
  Widget build(BuildContext context) {
    final String text;

    if (taboo.xp != null) {
      final prefix = taboo.xp! > 0 ? "Chained" : "Unchained";
      text = "$prefix: ${taboo.xp} xp.";
    } else if (taboo.replacementText != null) {
      text = "Mutated.";
    } else if (taboo.text != null) {
      text = taboo.text!;
    } else {
      text = "";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TextLeftBar(color: AppColors.taboo),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: TextWithIcons(
                  text: '[tablet] Taboo list\n$text',
                  iconColor: AppColors.taboo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
