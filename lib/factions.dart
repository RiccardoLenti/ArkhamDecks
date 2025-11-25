enum Faction {
  guardian('guardian'),
  seeker('seeker'),
  rogue('rogue'),
  mystic('mystic'),
  survivor('survivor'),
  neutral('neutral'),
  multi('multi');

  const Faction(this.name);

  final String name;

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
