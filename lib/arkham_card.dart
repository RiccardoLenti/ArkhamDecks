import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/expansions.dart';
import 'package:arkham_decks/theme.dart';
import 'package:collection/collection.dart';
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
  final Subtype? subtype;
  final List<String>? slots;
  final int? level;
  final int deckLimit;
  final Taboo? taboo;
  final String? deckOptions;

  SimplifiedCard({
    required this.code,
    required this.cost,
    required this.name,
    required this.subname,
    required this.faction,
    required this.type,
    List<String>? slots,
    required this.level,
    required this.deckLimit,
    this.multiFactions = const [],
    this.subtype,
    this.taboo,
    this.deckOptions,
  }) : slots = slots ?? const [];

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
        subtype: Subtype.fromString(map['subtype_code']),
        slots: (map['slot'] as String?)?.split('. '),
        level: map['xp'],
        deckLimit: map['taboo.deck_limit'] ?? map['deck_limit'] ?? 1,
        taboo: Taboo.fromSimplifiedMap(map),
        deckOptions: map['deck_options'],
      );
    } else {
      return SimplifiedCard(
        code: map['code'],
        cost: map['cost'],
        name: map['name'],
        subname: map['subname'],
        faction: Faction.fromString(map['faction_code'])!,
        type: map['type_code'],
        subtype: Subtype.fromString(map['subtype_code']),
        slots: (map['slot'] as String?)?.split('. '),
        level: map['xp'],
        deckLimit: map['taboo.deck_limit'] ?? map['deck_limit'] ?? 1,
        taboo: Taboo.fromSimplifiedMap(map),
        deckOptions: map['deck_options'],
      );
    }
  }
}

class ArkhamCard extends SimplifiedCard {
  final String? text;
  final String? flavor;
  final String? backText;
  final String? backFlavor;
  final List<String>? traits;
  final int? health, sanity;
  final bool isUnique;
  final List<String> customizationText;
  final List<String> additionalCards;
  final List<int?> commitSkills;
  final List<Printing>? printings;
  final Taboo? taboo;

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
    super.subtype,
    super.slots,

    this.text,
    this.flavor,
    List<String>? traits,
    this.health,
    this.sanity,
    this.isUnique = false,
    List<String>? customizationText,
    List<String>? additionalCards,
    required this.commitSkills,
    this.printings,
    this.backText,
    this.backFlavor,
    this.taboo,
  }) : traits = traits ?? const [],
       customizationText = customizationText ?? const [],
       additionalCards = additionalCards ?? const [];

  ///calling this constructor directly DOES NOT handle bonded cards
  factory ArkhamCard.fromMap(
    Map<String, dynamic> map, {
    List<Printing>? printings,
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
      subtype: simplified.subtype,
      slots: simplified.slots,
      level: simplified.level,
      deckLimit: simplified.deckLimit,
      printings: printings,

      text: map['text'] as String?,
      health: map['health'] as int?,
      sanity: map['sanity'] as int?,
      flavor: map['flavor'] as String?,
      traits: (map['traits'] as String?)?.split(' '),
      backText: map['back_text'] as String?,
      backFlavor: map['back_flavor'] as String?,
      isUnique: isUnique,
      customizationText: customizationText,
      additionalCards: [...?restrictedCards],
      commitSkills: commitSkillNames.map((name) => map[name] as int?).toList(),
      taboo: Taboo.fromFullMap(map),
    );
  }

  static Future<ArkhamCard> fromDb(String code) async {
    final db = await DatabaseHelper.instance.db;
    final rows = await db.rawQuery(
      'SELECT * FROM card_details WHERE code = ?',
      [code],
    );

    final printings =
        rows.map((row) {
          final packCode = row['pack_code'] as String;
          final pack = Pack.fromCode(packCode);

          return Printing(
            pack: pack,
            position: row['position'] as int,
            quantity: row['quantity'] as int,
          );
        }).toList();

    final additionalCards = await db.query(
      'cards',
      distinct: true,
      columns: ['code'],
      where:
          "restrictions LIKE 'investigator:' || ? || '%' OR bonded_to LIKE ?",
      whereArgs: [code, rows.first['name']],
    );

    return ArkhamCard.fromMap(
      rows.first,
      printings: printings,
      restrictedCards:
          additionalCards.map((map) => map['code'] as String).toList(),
    );
  }
}

class Printing {
  final int position;
  final int quantity;
  final Pack pack;

  const Printing({
    required this.position,
    required this.quantity,
    required this.pack,
  });
}

enum Subtype {
  weakness('weakness', 'Weakness'),
  basicWeakness('basicweakness', 'Basic Weakness');

  const Subtype(this.name, this.label);

  final String name;
  final String label;

  static Subtype? fromString(String? value) =>
      Subtype.values.firstWhereOrNull((subtype) => subtype.name == value);
}

class Taboo {
  final int? xp;
  final int? deckLimit;
  final String? text;
  final String? replacementText;

  const Taboo({
    required this.xp,
    this.deckLimit,
    this.text,
    this.replacementText,
  });

  static Taboo? fromSimplifiedMap(Map<String, dynamic> map) {
    if (map['taboo.code'] == null) return null;

    return Taboo(
      xp: map['taboo.xp'] as int?,
      deckLimit: map['taboo.deck_limit'] as int?,
    );
  }

  static Taboo? fromFullMap(Map<String, dynamic> map) {
    if (map['taboo.code'] == null) return null;

    return Taboo(
      text: map['taboo.text'],
      xp: map['taboo.xp'] as int?,
      deckLimit: map['taboo.deck_limit'] as int?,
      replacementText: map['taboo.replacement_text'],
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
          composedIcon = Transform.translate(
            offset: Offset(0, -constraints.maxHeight * 0.08),
            child: IconManager().getIcon(
              card.faction.name,
              // TODO: I don't like this being light but on dark neutral is impossible to see
              color: AppColors.factions[card.faction]!.light,
            ),
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
                    color: Theme.of(context).colorScheme.onSurface,
                  )
                  : IconManager().getIcon(
                    'level_${card.level ?? 'none'}',
                    color: AppColors.factions[card.faction]!.light,
                  ),

              _buildInnerPart(context, circleDiameter, onlyOutline),
            ],
          );
        } else {
          composedIcon = IconManager().getIcon(
            'weakness',
            color:
                onlyOutline
                    ? Theme.of(context).colorScheme.onSurface
                    : AppColors.factions[card.faction]!.light,
          );
        }

        return SizedBox(
          height: circleDiameter,
          width: circleDiameter,
          child: composedIcon,
        );
      },
    );
  }

  Widget _buildInnerPart(
    BuildContext context,
    double circleDiameter,
    bool onlyOutline,
  ) {
    final color =
        onlyOutline
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.surface;

    if (card.type == 'skill') {
      return Container(
        padding: EdgeInsets.only(
          left: circleDiameter * 0.1,
          right: circleDiameter * 0.1,
          top: circleDiameter * 0.04,
          bottom: circleDiameter * 0.28,
        ),
        child: IconManager().getIcon(card.faction.name, color: color),
      );
    } else if (card.cost == -2) {
      return Padding(
        padding: EdgeInsets.only(
          right: 10.0,
          left: 10.0,
          top: 8.0,
          bottom: 13.5,
        ),
        child: IconManager().getIcon('x-fill', color: color),
      );
    }

    return Align(
      alignment: Alignment(0, -0.55),
      child: Text(
        card.cost?.toString() ?? '-',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: circleDiameter * 0.5,
          color: color,
          fontFamily: 'Cost',
        ),
      ),
    );
  }
}
