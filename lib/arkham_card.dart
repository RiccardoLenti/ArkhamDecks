import 'package:arkham_decks/database.dart';
import 'package:flutter/material.dart';
import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/icon_manager.dart';

class SimplifiedCard {
  final String code;
  final int? cost;
  final String name;
  final String? subname;
  final Faction faction;
  final List<Faction> multiFactions;
  final String type;
  final int? level;
  final int deckLimit;

  SimplifiedCard({
    required this.code,
    required this.cost,
    required this.name,
    required this.subname,
    required this.faction,
    required this.type,
    required this.level,
    required this.deckLimit,
    this.multiFactions = const [],
  });

  factory SimplifiedCard.fromMap(Map<String, dynamic> map) {
    if (map['faction2_code'] != null) {
      final multiFactions = [
        Faction.fromString(map['faction_code']),
        Faction.fromString(map['faction2_code']),
        Faction.fromString(map['faction3_code']),
      ];

      // TODO: fix the deckLimit check. The only cards without a deck_limit 
      // are sophie and the disciplines back sides. They are linked with back_link
      return SimplifiedCard(
        code: map['code'],
        cost: map['cost'],
        name: map['name'],
        subname: map['subname'],
        faction: Faction.multi,
        multiFactions: multiFactions.nonNulls.toList(growable: false),
        type: map['type_code'],
        level: map['xp'],
        deckLimit: map['deck_limit'] ?? 1,
      );
    } else {
      return SimplifiedCard(
        code: map['code'],
        cost: map['cost'],
        name: map['name'],
        subname: map['subname'],
        faction: Faction.fromString(map['faction_code'])!,
        type: map['type_code'],
        level: map['xp'],
        deckLimit: map['deck_limit'] ?? 1,
      );
    }
  }
}

class ArkhamCard extends SimplifiedCard {
  final String? text;
  final String? flavor;
  final List<String>? traits;
  final List<String>? slots;
  final int? health, sanity;
  final bool isUnique;
  final List<String> customizationText;
  final List<String> additionalCards;
  final List<int?> commitSkills;

  ArkhamCard({
    required super.code,
    required super.cost,
    required super.name,
    required super.subname,
    required super.faction,
    required super.type,
    required super.level,
    required super.deckLimit,
    super.multiFactions,

    this.text,
    this.flavor,
    List<String>? traits,
    List<String>? slots,
    this.health,
    this.sanity,
    this.isUnique = false,
    List<String>? customizationText,
    List<String>? additionalCards,
    required this.commitSkills,
  }) : traits = traits ?? const [],
       slots = slots ?? const [],
       customizationText = customizationText ?? const [],
       additionalCards = additionalCards ?? const [];

  ///calling this constructor directly DOES NOT handle bonded cards
  factory ArkhamCard.fromMap(
    Map<String, dynamic> map, {
    List<String>? restrictedCards,
  }) {
    const commitSkillNames = [
      'skill_willpower',
      'skill_intellect',
      'skill_combat',
      'skill_agility',
      'skill_wild',
    ];

    final simplified = SimplifiedCard.fromMap(map);

    final isUnique = (map['is_unique'] as int) == 1 ? true : false;
    final customizationText = (map['customization_text'] as String?)?.split(
      '\n',
    );

    return ArkhamCard(
      code: simplified.code,
      cost: simplified.cost,
      name: simplified.name,
      subname: simplified.subname,
      faction: simplified.faction,
      multiFactions: simplified.multiFactions,
      type: simplified.type,
      level: simplified.level,
      deckLimit: simplified.deckLimit,

      text: map['text'] as String?,
      traits: (map['traits'] as String?)?.split(' '),
      slots: (map['slot'] as String?)?.split('. '),
      health: map['health'] as int?,
      sanity: map['sanity'] as int?,
      flavor: map['flavor'] as String?,
      isUnique: isUnique,
      customizationText: customizationText,
      additionalCards: [...?restrictedCards],
      commitSkills: commitSkillNames.map((name) => map[name] as int?).toList(),
    );
  }

  static Future<ArkhamCard> fromDb(String code) async {
    final db = await DatabaseHelper.instance.db;
    final rows = await db.query(
      'cards',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    // TODO: actual bonded cards
    // for now we only grab investigators' signature and weakness
    final additionalCards = await db.query(
      'cards',
      distinct: true,
      columns: ['code'],
      where: "restrictions LIKE 'investigator:' || ? || '%'",
      whereArgs: [code],
    );

    return ArkhamCard.fromMap(
      rows.first,
      restrictedCards:
          additionalCards.map((map) => map['code'] as String).toList(),
    );
  }
}

class CostLevelCircle extends StatelessWidget {
  final SimplifiedCard card;
  final bool onlyOutline;

  const CostLevelCircle({
    super.key,
    required this.card,
    this.onlyOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final circleDiameter = constraints.maxHeight * 0.9;
        late final Widget composedIcon;

        if (card.type == 'investigator') {
          composedIcon = IconManager().getIcon(
            card.faction.name,
            color: card.faction.color,
          );
        } else if (card.type == 'skill' ||
            card.type == 'event' ||
            card.type == 'asset') {
          composedIcon = Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              onlyOutline
                  ? IconManager().getIcon(
                    'inverted_level_${card.level ?? 'none'}',
                    color: Colors.white,
                  )
                  : IconManager().getIcon(
                    'level_${card.level ?? 'none'}',
                    color: card.faction.color,
                  ),

              _buildInnerPart(circleDiameter),
            ],
          );
        } else {
          composedIcon = IconManager().getIcon(
            'weakness',
            color: Colors.black54,
          );
        }

        return SizedBox(
          height: circleDiameter,
          width: circleDiameter,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 2.0,
              right: 2.0,
              top: 5.0,
              bottom: 2.0,
            ),
            child: composedIcon,
          ),
        );
      },
    );
  }

  Widget _buildInnerPart(double circleDiameter) {
    if (card.type == 'skill') {
      return Container(
        padding: EdgeInsets.only(
          left: circleDiameter * 0.1,
          right: circleDiameter * 0.1,
          top: circleDiameter * 0.04,
          bottom: circleDiameter * 0.28,
        ),
        child: IconManager().getIcon(card.faction.name, color: Colors.white),
      );
    } else if (card.cost == -2) {
      return Padding(
        padding: EdgeInsets.only(right: 8.0, left: 8.0, top: 6.0, bottom: 10.5),
        child: IconManager().getIcon('x-fill', color: Colors.white),
      );
    }

    return Align(
      alignment: Alignment(0.0, -0.55),
      child: Text(
        card.cost?.toString() ?? '-',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: circleDiameter * 0.4,
          color: Colors.white,
          fontFamily: 'Cost',
        ),
      ),
    );
  }
}
