import 'dart:ui';

enum Faction {
  guardian('guardian', Color(0xFF1072C2)),
  seeker('seeker', Color(0xFFDB7C07)),
  rogue('rogue', Color(0xFF219428)),
  mystic('mystic', Color(0xFF7554AB)),
  survivor('survivor', Color(0xFFCC3038)),
  neutral('neutral', Color(0xFF475259)),
  multi('multi', Color(0xFFE9C06C));

  const Faction(this.name, this.color);

  final String name;
  final Color color;

  static Faction? fromString(String? value) {
    for (Faction faction in Faction.values) {
      if (value == faction.name) return faction;
    }
    return null;
  }

  static List<Faction> valuesWithoutMulti() {
    return [guardian, seeker, rogue, mystic, survivor, neutral];
  }
}
