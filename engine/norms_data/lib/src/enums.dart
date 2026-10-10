/// Conductor material.
enum ConductorMaterial {
  copper('copper'),
  aluminium('aluminium');

  const ConductorMaterial(this.key);

  /// Key used in the datasets.
  final String key;
}

/// Conductor insulation; defines the maximum operating temperature (ГОСТ Р 50571.5.52, табл. 52.1).
enum Insulation {
  /// Thermoplastic (PVC), 70 °C.
  pvc('pvc'),

  /// Thermosetting (XLPE/EPR), 90 °C.
  xlpe('xlpe');

  const Insulation(this.key);

  /// Key used in the datasets.
  final String key;
}

/// Reference installation method of ГОСТ Р 50571.5.52, табл. B.52.1.
enum ReferenceMethod {
  a1('A1'),
  a2('A2'),
  b1('B1'),
  b2('B2'),
  c('C'),
  d1('D1'),
  d2('D2'),

  /// Multicore cable in free air or on a perforated tray.
  e('E');

  const ReferenceMethod(this.key);

  /// Key used in the datasets.
  final String key;

  /// Whether the method is a cable laid in the ground (D1, D2).
  bool get isInGround => this == d1 || this == d2;

  /// Parses a dataset key such as `B2`.
  static ReferenceMethod fromKey(String key) => values.firstWhere((m) => m.key == key);
}

/// Medium surrounding the cable.
enum CableEnvironment { air, ground }
