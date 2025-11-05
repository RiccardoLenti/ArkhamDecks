class Deck {
  final String name;
  final String investigatorName;

  Deck({required this.name, required this.investigatorName});

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      name: map['name'],
      investigatorName: map['investigator_name'],
    );
  }
}