/// Conductor material.
enum ConductorMaterial(
  /// Key used in the datasets.
  final String key,
) {
  copper('copper'),
  aluminium('aluminium'),
}

/// Conductor insulation; defines the maximum operating temperature (ГОСТ Р 50571.5.52, табл. 52.1).
enum Insulation(
  /// Key used in the datasets.
  final String key,
) {
  /// Thermoplastic (PVC), 70 °C.
  pvc('pvc'),

  /// Thermosetting (XLPE/EPR), 90 °C.
  xlpe('xlpe'),
}

/// Reference installation method of ГОСТ Р 50571.5.52, табл. B.52.1.
enum ReferenceMethod(
  /// Key used in the datasets.
  final String key,
) {
  a1('A1'),
  a2('A2'),
  b1('B1'),
  b2('B2'),
  c('C'),
  d1('D1'),
  d2('D2'),

  /// Multicore cable in free air or on a perforated tray.
  e('E');

  /// Whether the method is a cable laid in the ground (D1, D2).
  bool get isInGround => this == d1 || this == d2;

  /// Parses a dataset key such as `B2`.
  static ReferenceMethod fromKey(String key) => values.firstWhere((m) => m.key == key);
}

/// Medium surrounding the cable.
enum CableEnvironment() {
  air,
  ground,
}
