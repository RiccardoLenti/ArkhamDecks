enum Expansion {
  core('Core', 'core'),
  dwl('The Dunwich Legacy', 'dwl'),
  ptc('The Path to Carcosa', 'ptc'),
  tfa('The Forgotten Age', 'tfa'),
  tcu('The Circle Undone', 'tcu'),
  tde('The Dream-Eaters', 'tde'),
  tic('The Innsmouth Conspiracy', 'tic'),
  eoe('Edge of the Earth', 'eoep'),
  tsk('The Scarlet Keys', 'tskp'),
  fhv('The Feast of Hemlock Vale', 'fhvp'),
  tdc('The Drowned City', 'tdcp'),
  nat('Nathaniel Cho', 'nat'),
  har('Harvey Walters', 'har'),
  win('Winifred Habbamock', 'win'),
  jac('Jacqueline Fine', 'jac'),
  ste('Stella Clark', 'ste');

  const Expansion(this.name, this.packCode);

  final String name;
  final String packCode;
}
