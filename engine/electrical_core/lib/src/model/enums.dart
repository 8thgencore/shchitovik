/// Type of the object being designed; selects the load calculation method.
enum ObjectType() {
  /// Apartment in a multi-apartment building (СП 256, 7.1).
  apartment,

  /// Single-family house (СП 256, 7.1, табл. 7.1 прим. 11).
  house,

  /// Garage or workshop.
  garageWorkshop,

  /// Small commercial premises (СП 256, 7.2).
  commercial,
}

/// Supply system of the object.
enum SupplyPhases() {
  single,
  three,
}

/// Phase a single-phase circuit is connected to.
enum Phase() {
  l1,
  l2,
  l3,
}

/// Fuel of kitchen cooking appliances (СП 256, табл. 7.1).
enum CookingFuel() {
  naturalGas,
  liquefiedGasOrSolidFuel,
  electric,
}

/// How residual current protection is arranged.
enum RcdStrategy() {
  /// RCBO (дифавтомат) on every circuit that needs an RCD. Default.
  rcboPerCircuit,

  /// Separate RCD on every circuit that needs one, after its MCB.
  rcdPerCircuit,

  /// One RCD for several circuits (СП 256, А.1.1); expert mode.
  groupedRcd,
}

/// Purpose of a circuit.
enum CircuitPurpose() {
  /// General lighting.
  lighting,

  /// Socket-outlets and small fixed appliances of a room.
  power,

  /// Single receiver on its own circuit.
  dedicated,
}

/// Protection device of a circuit.
enum ProtectionDevice() {
  /// Circuit-breaker only.
  mcb,

  /// Circuit-breaker followed by an RCD.
  mcbAndRcd,

  /// RCBO (дифавтомат).
  rcbo,

  /// Circuit-breaker; the RCD is shared with other circuits (see grouped RCDs).
  mcbUnderGroupRcd,
}

/// Status of a single check.
enum CheckStatus() {
  passed,
  warning,
  failed,
  notEvaluated,
}

/// Overall status of a circuit or of the project.
enum CalculationStatus() {
  /// Everything checked and passed.
  passed,

  /// Passed with warnings.
  warning,

  /// Passed, but relies on assumptions or missing data that must be confirmed.
  requiresReview,

  /// Not enough data for the mandatory checks (e.g. no cable length).
  preliminary,

  /// A mandatory check failed.
  failed,
}

/// Severity of an issue.
enum IssueSeverity() {
  info,
  warning,
  error,
}

/// Origin of a circuit parameter.
enum ValueSource() {
  automatic,
  manual,
}
