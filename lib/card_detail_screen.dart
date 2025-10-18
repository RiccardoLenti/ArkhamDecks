import 'package:flutter/material.dart';
import 'package:arkham_decks/arkham_card.dart';
import 'package:arkham_decks/database.dart';
import 'package:arkham_decks/factions.dart';
import 'package:arkham_decks/icon_manager.dart';

import 'package:flutter_html/flutter_html.dart';

class CardDetailScreen extends StatefulWidget {
  final String code;
  const CardDetailScreen({super.key, required this.code});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  ArkhamCard? _card;
  String? _text;
  List<String>? _traits;
  List<String>? _slots;
  int? _health, _sanity;

  static const _commitSkillNames = [
    'skill_willpower',
    'skill_intellect',
    'skill_combat',
    'skill_agility',
    'skill_wild',
  ];

  //TODO: purge this.
  static const _commitSkillColors = [
    Color(0xFF2C7FC0),
    Color(0xFF7C3C85),
    Color(0xFFAE4236),
    Color(0xFF14854D),
    Color(0xFF8A7D5A),
  ];

  final List<int?> _commitSkills = [];

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    final db = await DatabaseHelper.instance.db;
    final queryRes = await db.query(
      'cards',
      where: 'code = ?',
      whereArgs: [widget.code],
      limit: 1,
    );

    if (queryRes.isNotEmpty) {
      setState(() {
        _card = ArkhamCard.fromMap(queryRes.first);
        _text = queryRes.first['text'] as String?;
        _traits = (queryRes.first['traits'] as String).split(' ');
        _slots = (queryRes.first['slot'] as String?)?.split('. ');
        _health = queryRes.first['health'] as int?;
        _sanity = queryRes.first['sanity'] as int?;

        _commitSkills.clear();
        for (var name in _commitSkillNames) {
          _commitSkills.add(queryRes.first[name] as int?);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_card == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.0),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: IntrinsicHeight(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: _card!.faction.color, width: 45),
                      bottom: BorderSide(color: _card!.faction.color, width: 4),
                      left: BorderSide(color: _card!.faction.color, width: 4),
                      right: BorderSide(color: _card!.faction.color, width: 4),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
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
                                      Text(
                                        _slots == null
                                            ? _card!.type
                                            : '${_card!.type} • ${_slots!.join(' - ')}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _traits!.join(' '),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 16,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),

                                      _buildCommitIcons(),

                                      _buildSlots(),

                                      if (_health != null || _sanity != null)
                                        Padding(
                                          padding: EdgeInsets.only(left: 4.0),
                                          child: Row(
                                            spacing: 15.0,
                                            children: [
                                              _buildHealthSanityIcon(
                                                'health',
                                                _health,
                                                Color(0xFF8D181E),
                                              ),
                                              _buildHealthSanityIcon(
                                                'sanity',
                                                _sanity,
                                                Color(0xFF165385),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Image.network(
                                  'https://arkhamdb.com/bundles/cards/${_card!.code}.png',
                                  fit: BoxFit.cover,
                                ),
                              ],
                            ),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.only(top: 15, bottom: 8),
                          child:
                              _text == null
                                  ? SizedBox.shrink()
                                  : IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 3,
                                          margin: EdgeInsets.only(
                                            right: 8,
                                            left: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: _buildCardText()),
                                      ],
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 45),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CostLevelCircle(card: _card!, onlyOutline: true),
                    ),
                    Center(
                      child: Text(
                        _card!.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontFamily: 'Arkhamic',
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 5.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _buildFactionIcons(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommitIcons() {
    final List<Widget> children = [];

    for (final (index, value) in _commitSkills.indexed) {
      if (value == null) {
        continue;
      }

      for (var i = 0; i < value; i++) {
        children.add(
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 123, 118, 118),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Stack(
              children: [
                IconManager().getIcon(
                  _commitSkillNames[index],
                  size: 22,
                  color: _commitSkillColors[index],
                ),

                IconManager().getIcon(
                  '${_commitSkillNames[index]}_inverted',
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

  Widget _buildHealthSanityIcon(String type, int? value, Color color) {
    final numberIconName = value != null ? 'num$value' : 'numNull';

    return Stack(
      alignment: Alignment.center,
      children: [
        IconManager().getIcon(type, size: 40, color: color),
        IconManager().getIcon('$numberIconName-fill', color: color),
        IconManager().getIcon('$numberIconName-outline', color: Colors.white),
      ],
    );
  }

  Widget _buildSlots() {
    if (_slots == null) {
      return const SizedBox.shrink();
    }

    return Row(
      spacing: 12,
      children: [
        ..._slots!.map((slotName) {
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

  List<Widget> _buildFactionIcons() {
    if (_card!.faction == Faction.multi) {
      return _card!.multiFactions
          .map(
            (faction) => IconManager().getIcon(
              faction.name,
              size: 34,
              color: Colors.white,
            ),
          )
          .toList();
    } else {
      return [
        IconManager().getIcon(
          _card!.faction.name,
          size: 34,
          color: Colors.white,
        ),
      ];
    }
  }

  Widget _buildCardText() {
    // matches everything like [tag], discards [[tag]]
    final pattern = RegExp(r'(?<!\[)\[([^\[\]]+)\](?!\])');
    final processedText = _text!
        .replaceAll('\n', '<br>')
        .replaceAll('[fast]', '[free]')
        .replaceAll('[[', '<b><i>')
        .replaceAll(']]', '</i></b>')
        .replaceAll('- ', '<icon name="bullet"/></icon>')
        .replaceAllMapped(
          pattern,
          (m) => '<icon name="${m.group(1)}"/></icon>',
        );

    return Html(
      data: processedText,  
      extensions: [
        TagExtension(
          tagsToExtend: {'icon'},
          builder: (context) {
            final iconName = context.element?.attributes['name'];

            return Padding(
              padding: const EdgeInsets.only(right: 2.5),
              child: IconManager().getIcon(
                iconName!,
                size: 18,
                color: Colors.black,
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
