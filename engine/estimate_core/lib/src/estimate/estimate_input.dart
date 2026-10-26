import 'package:electrical_core/electrical_core.dart' show unset;
import 'package:estimate_core/src/board/board_arrangement.dart';
import 'package:estimate_core/src/catalog/catalog.dart';
import 'package:estimate_core/src/catalog/price.dart';
import 'package:meta/meta.dart';

/// Price scenario: selects the manufacturer segment for automatic selection.
enum EstimateScenario(
  /// Segment.
  final Tier tier,
) {
  /// Budget brands.
  economy(Tier.budget),

  /// Mid segment.
  standard(Tier.mid),

  /// Premium brands.
  premium(Tier.premium),
}

/// Model chosen by the user for a slot; stored as a snapshot so that catalog updates do not
/// change an existing estimate silently.
@immutable
final class const ApparatusSelection({
  /// Snapshot of the model.
  required final ApparatusProduct product,

  /// Catalog version the snapshot was taken from.
  required final String catalogVersion,

  /// Price entered by the user (per unit).
  final PriceRange? customPrice,
}) {
  /// Parses JSON produced by [toJson].
  factory fromJson(Map<String, Object?> json) => ApparatusSelection(
    product: ApparatusProduct.fromJson(json['product']! as Map<String, Object?>),
    catalogVersion: json['catalog_version']! as String,
    customPrice: json['custom_price'] == null
        ? null
        : PriceRange.fromJson(json['custom_price']! as Map<String, Object?>),
  );

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
    'product': product.toJson(),
    'catalog_version': catalogVersion,
    if (customPrice != null) 'custom_price': customPrice!.toJson(),
  };
}

/// User choices for the estimate; persisted next to the project input.
@immutable
final class const EstimateInput({
  /// Price scenario.
  final EstimateScenario scenario = EstimateScenario.standard,

  /// Copper cable mark; `null` – ВВГнг(А)-LS. Aluminium lines always use АВВГнг(А)-LS.
  final String? cableMarkId,

  /// Cable length reserve for routing and terminations (1,1 = +10 %).
  final double cableReserveFactor = 1.1,

  /// Voltage relay; `null` – recommended (included).
  final bool? voltageRelay,

  /// Surge protective device; `null` – included for houses and garages.
  final bool? surgeProtection,

  /// Load switch that turns off every circuit except the non-switchable ones; `null` –
  /// included.
  final bool? loadSwitch,

  /// Service socket on the DIN rail with its own RCBO; `null` – included.
  final bool? dinSocket,

  /// Overhead supply line: SPD type 1+2 instead of type 2.
  final bool overheadSupply = false,

  /// Chosen models by slot id.
  final Map<String, ApparatusSelection> selections = const {},

  /// Cable price per metre entered by the user, by circuit id (`incomer` for the incomer cable).
  final Map<String, PriceRange> cableCustomPrices = const {},

  /// Switchboard arrangement.
  final BoardArrangement board = const BoardArrangement(),
}) {
  /// Parses JSON produced by [toJson].
  factory fromJson(Map<String, Object?> json) => EstimateInput(
    scenario: EstimateScenario.values.byName(json['scenario'] as String? ?? 'standard'),
    cableMarkId: json['cable_mark_id'] as String?,
    cableReserveFactor: (json['cable_reserve_factor'] as num?)?.toDouble() ?? 1.1,
    voltageRelay: json['voltage_relay'] as bool?,
    surgeProtection: json['surge_protection'] as bool?,
    loadSwitch: json['load_switch'] as bool?,
    dinSocket: json['din_socket'] as bool?,
    overheadSupply: json['overhead_supply'] as bool? ?? false,
    selections: {
      for (final e in (json['selections'] as Map<String, Object?>? ?? const {}).entries)
        e.key: ApparatusSelection.fromJson(e.value! as Map<String, Object?>),
    },
    cableCustomPrices: {
      for (final e in (json['cable_custom_prices'] as Map<String, Object?>? ?? const {}).entries)
        e.key: PriceRange.fromJson(e.value! as Map<String, Object?>),
    },
    board: json['board'] == null
        ? const BoardArrangement()
        : BoardArrangement.fromJson(json['board']! as Map<String, Object?>),
  );

  /// Returns a copy with the given fields replaced; pass `null` explicitly to clear an
  /// optional field.
  EstimateInput copyWith({
    EstimateScenario? scenario,
    Object? cableMarkId = unset,
    double? cableReserveFactor,
    Object? voltageRelay = unset,
    Object? surgeProtection = unset,
    Object? loadSwitch = unset,
    Object? dinSocket = unset,
    bool? overheadSupply,
    Map<String, ApparatusSelection>? selections,
    Map<String, PriceRange>? cableCustomPrices,
    BoardArrangement? board,
  }) => EstimateInput(
    scenario: scenario ?? this.scenario,
    cableMarkId: identical(cableMarkId, unset) ? this.cableMarkId : cableMarkId as String?,
    cableReserveFactor: cableReserveFactor ?? this.cableReserveFactor,
    voltageRelay: identical(voltageRelay, unset) ? this.voltageRelay : voltageRelay as bool?,
    surgeProtection: identical(surgeProtection, unset)
        ? this.surgeProtection
        : surgeProtection as bool?,
    loadSwitch: identical(loadSwitch, unset) ? this.loadSwitch : loadSwitch as bool?,
    dinSocket: identical(dinSocket, unset) ? this.dinSocket : dinSocket as bool?,
    overheadSupply: overheadSupply ?? this.overheadSupply,
    selections: selections ?? this.selections,
    cableCustomPrices: cableCustomPrices ?? this.cableCustomPrices,
    board: board ?? this.board,
  );

  /// Serializes to JSON.
  Map<String, Object?> toJson() => {
    'scenario': scenario.name,
    if (cableMarkId != null) 'cable_mark_id': cableMarkId,
    'cable_reserve_factor': cableReserveFactor,
    if (voltageRelay != null) 'voltage_relay': voltageRelay,
    if (surgeProtection != null) 'surge_protection': surgeProtection,
    if (loadSwitch != null) 'load_switch': loadSwitch,
    if (dinSocket != null) 'din_socket': dinSocket,
    'overhead_supply': overheadSupply,
    'selections': {for (final e in selections.entries) e.key: e.value.toJson()},
    'cable_custom_prices': {for (final e in cableCustomPrices.entries) e.key: e.value.toJson()},
    if (!board.isAuto) 'board': board.toJson(),
  };
}
