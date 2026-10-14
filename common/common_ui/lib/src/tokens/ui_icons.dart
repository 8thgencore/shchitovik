import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icons of the app: Lucide with a 1.55 stroke (the `300` weight), matching the hairlines.
///
/// Screens use these names only, so the set or the weight changes in one place.
abstract final class UiIcons {
  /// Back.
  static const back = LucideIcons.arrowLeft300;

  /// Forward, next step.
  static const next = LucideIcons.arrowRight300;

  /// Close an overlay.
  static const close = LucideIcons.x300;

  /// Add.
  static const add = LucideIcons.plus300;

  /// Edit.
  static const edit = LucideIcons.pencil300;

  /// Delete.
  static const delete = LucideIcons.trash2300;

  /// More actions.
  static const more = LucideIcons.ellipsisVertical300;

  /// Search.
  static const search = LucideIcons.search300;

  /// Selected item, completed step.
  static const check = LucideIcons.check300;

  /// Opens a list.
  static const chevronDown = LucideIcons.chevronDown300;

  /// Opens details.
  static const chevronRight = LucideIcons.chevronRight300;

  /// PDF report.
  static const report = LucideIcons.fileText300;

  /// Export or share.
  static const share = LucideIcons.share300;

  /// Import a file.
  static const import = LucideIcons.fileInput300;

  /// Copy.
  static const copy = LucideIcons.copy300;

  /// Retry.
  static const retry = LucideIcons.refreshCw300;

  /// Settings.
  static const settings = LucideIcons.settings300;

  /// List of projects.
  static const projects = LucideIcons.folder300;

  /// Brand mark.
  static const brand = LucideIcons.zap300;

  /// Switchboard view.
  static const board = LucideIcons.layoutGrid300;

  /// List view.
  static const list = LucideIcons.list300;

  /// Object setup.
  static const object = LucideIcons.house300;

  /// Rooms.
  static const rooms = LucideIcons.doorOpen300;

  /// Circuits.
  static const circuits = LucideIcons.listChecks300;

  /// Estimate.
  static const estimate = LucideIcons.receipt300;

  /// Apartment.
  static const apartment = LucideIcons.building2300;

  /// House.
  static const house = LucideIcons.house300;

  /// Garage or workshop.
  static const garage = LucideIcons.warehouse300;

  /// Commercial premises.
  static const shop = LucideIcons.store300;

  /// Empty room.
  static const room = LucideIcons.square300;

  /// Information.
  static const info = LucideIcons.info300;

  /// Passed.
  static const success = LucideIcons.circleCheck300;

  /// Needs review.
  static const warning = LucideIcons.triangleAlert300;

  /// Failed.
  static const danger = LucideIcons.circleX300;

  /// Preliminary, not evaluated.
  static const pending = LucideIcons.circleDashed300;

  /// Question, needs a decision.
  static const help = LucideIcons.circleHelp300;

  /// Not evaluated.
  static const notEvaluated = LucideIcons.circleMinus300;

  /// Reset to automatic.
  static const reset = LucideIcons.rotateCcw300;
}
