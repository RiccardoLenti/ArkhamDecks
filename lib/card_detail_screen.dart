import 'package:collection/collection.dart';
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
  String? _flavor;
  List<String>? _traits;
  List<String>? _slots;
  int? _health, _sanity;
  bool? _isUnique;
  List<String>? _customizationText;
  static const _skillBackgroundColor = Color.fromARGB(255, 123, 118, 118);

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
        _traits = (queryRes.first['traits'] as String?)?.split(' ');
        _slots = (queryRes.first['slot'] as String?)?.split('. ');
        _health = queryRes.first['health'] as int?;
        _sanity = queryRes.first['sanity'] as int?;
        _flavor = queryRes.first['flavor'] as String?;
        _isUnique = (queryRes.first['is_unique'] as int) == 1 ? true : false;
        _customizationText = (queryRes.first['customization_text'] as String?)
            ?.split('\n');

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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.0),
          child: Column(
            children: [
              _buildBoxBorder(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child:
                      _card!.type == 'investigator'
                          ? _investigatorDetailScreen()
                          : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 250,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 7.0,
                                          children: [
                                            _buildCardTypeSlots(),
                                            _buildTraits(),
                                            _buildCommitIcons(),
                                            _buildSlots(),

                                            if (_health != null ||
                                                _sanity != null)
                                              _buildHealthSanityIcon(
                                                _health,
                                                _sanity,
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

                              // TODO: export this into a single Widget function
                              Padding(
                                padding: EdgeInsets.only(top: 15, bottom: 8),
                                child: Column(
                                  spacing: 5.0,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _text == null
                                        ? SizedBox.shrink()
                                        : _buildCardText(),
                                    _flavor == null
                                        ? SizedBox.shrink()
                                        : _buildCardFlavor(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
                leading: CostLevelCircle(card: _card!, onlyOutline: true),
                center: Text(
                  _isUnique! ? '✷ ${_card!.name}' : _card!.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontFamily: 'Arkhamic',
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildFactionIcons(),
                ),
              ),
              if (_customizationText != null) _buildCustomizationTable(),
            ],
          ),
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
              color: _skillBackgroundColor,
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

  Widget _buildHealthSanityIcon(int? valueHealth, int? valueSanity) {
    //final numberIconName = value != null ? 'num$value' : 'numNull';
    const healthColor = Color(0xFF8D181E);
    const sanityColor = Color(0xFF165385);
    final numberHealth = valueHealth != null ? 'num$valueHealth' : 'numNull';
    final numberSanity = valueSanity != null ? 'num$valueSanity' : 'numNull';

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

  Widget _buildTraits() {
    return (_traits == null)
        ? SizedBox.shrink()
        : Text(
          _traits!.join(' '),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        );
  }

  Widget _buildCardTypeSlots() {
    return Text(
      _slots == null ? _card!.type : '${_card!.type} • ${_slots!.join(' - ')}',
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  ///assumes text != null
  Widget _buildCardText() {
    // matches everything like [tag], ignores [[tag]]

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
          Expanded(child: _buildTextWithIcons(_text!)),
        ],
      ),
    );
  }

  Widget _buildTextWithIcons(String text) {
    final pattern = RegExp(r'(?<!\[)\[([^\[\]]+)\](?!\])');
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

  ///assumes flavor != null
  Widget _buildCardFlavor() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      child: Text(
        _flavor!,
        style: TextStyle(
          fontFamily: 'Alegreya',
          fontStyle: FontStyle.italic,
          fontSize: 15.0,
          fontVariations: [FontVariation('wght', 450)],
        ),
      ),
    );
  }

  Widget _buildBoxBorder({
    required Widget child,
    Widget? center,
    Widget? leading,
    Widget? trailing,
  }) {
    return Stack(
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
              child: child,
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

  ///assumes _customizationText != null
  Widget _buildCustomizationTable() {
    return Column(
      children: [
        Divider(color: Colors.black54, thickness: 2, height: 30),
        _buildBoxBorder(
          center: Text(
            'Customization',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Arkhamic',
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_customizationText!.length * 2 - 1, (
                index,
              ) {
                if (index.isOdd) {
                  return Divider(
                    color: Colors.black26,
                    thickness: 0.75,
                    height: 10,
                  );
                } else {
                  return _buildTextWithIcons(_customizationText![index ~/ 2]);
                }
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _investigatorDetailScreen() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 7.0,
            children: [
              _buildCardTypeSlots(),
              _buildTraits(),
              Image.network(
                'https://arkhamdb.com/bundles/cards/${_card!.code}.png',
                fit: BoxFit.cover,
              ),
              _buildInvestigatorStats(),
              _buildHealthSanityIcon(_health, _sanity),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 15, bottom: 8),
          child: Column(
            spacing: 5.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardText(),
              _flavor != null ? _buildCardFlavor() : SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvestigatorStats() {
    return Row(
      spacing: 5.0,
      children: [
        ..._commitSkills.take(_commitSkills.length - 1).mapIndexed((
          index,
          value,
        ) {
          final name = _commitSkillNames[index];
          final color = _commitSkillColors[index];
          return Container(
            width: 50,
            height: 30,
            decoration: BoxDecoration(
              color: _skillBackgroundColor,
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
                  style: TextStyle(
                    fontFamily: 'Arkhamic',
                    fontSize: 24,
                    color: Colors.white,
                  ),
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
