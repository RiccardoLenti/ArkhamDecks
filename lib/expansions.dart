class Cycle {
  static late List<Cycle> _values;

  final String code;
  final String name;
  final List<Pack> packs;

  Cycle({required this.code, required this.name, required List<Pack> packs})
    : packs = List.unmodifiable(packs);

  static List<Cycle> get values => List.unmodifiable(_values);

  static void initValues(
    List<Map<String, dynamic>> cyclesRows,
    List<Map<String, dynamic>> packsRows,
  ) {
    final Map<String, List<Pack>> packsByCycle = {};

    for (final packMap in packsRows) {
      final cycleCode = packMap['cycle_code'] as String;
      packsByCycle
          .putIfAbsent(cycleCode, () => [])
          .add(Pack(code: packMap['code'], name: packMap['name']));
    }

    _values = cyclesRows
        .map((cycleMap) {
          final code = cycleMap['code'] as String;
          return Cycle(
            code: code,
            name: cycleMap['name'],
            packs: packsByCycle[code]!,
          );
        })
        .toList(growable: false);
  }
}

class Pack {
  final String code;
  final String name;

  Pack({required this.code, required this.name});
}
