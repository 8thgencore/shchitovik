import 'package:flutter/src/widgets/icon_data.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icons of the app: Lucide with a 1.55 stroke (the `300` weight), matching the hairlines.
///
/// Screens use these names only, so the set or the weight changes in one place.
abstract final class UiIcons() {
  /// Back.
  static const IconData back = LucideIcons.arrowLeft300;

  /// Forward, next step.
  static const IconData next = LucideIcons.arrowRight300;

  /// Close an overlay.
  static const IconData close = LucideIcons.x300;

  /// Add.
  static const IconData add = LucideIcons.plus300;

  /// Edit.
  static const IconData edit = LucideIcons.pencil300;

  /// Delete.
  static const IconData delete = LucideIcons.trash2300;

  /// More actions.
  static const IconData more = LucideIcons.ellipsisVertical300;

  /// Search.
  static const IconData search = LucideIcons.search300;

  /// Selected item, completed step.
  static const IconData check = LucideIcons.check300;

  /// Opens a list.
  static const IconData chevronDown = LucideIcons.chevronDown300;

  /// Opens details.
  static const IconData chevronRight = LucideIcons.chevronRight300;

  /// PDF report.
  static const IconData report = LucideIcons.fileText300;

  /// Export or share.
  static const IconData share = LucideIcons.share300;

  /// Import a file.
  static const IconData import = LucideIcons.fileInput300;

  /// Copy.
  static const IconData copy = LucideIcons.copy300;

  /// Retry.
  static const IconData retry = LucideIcons.refreshCw300;

  /// Settings.
  static const IconData settings = LucideIcons.settings300;

  /// List of projects.
  static const IconData projects = LucideIcons.folder300;

  /// Brand mark.
  static const IconData brand = LucideIcons.zap300;

  /// Switchboard view.
  static const IconData board = LucideIcons.layoutGrid300;

  /// List view.
  static const IconData list = LucideIcons.list300;

  /// Object setup.
  static const IconData object = LucideIcons.house300;

  /// Rooms.
  static const IconData rooms = LucideIcons.doorOpen300;

  /// Circuits.
  static const IconData circuits = LucideIcons.listChecks300;

  /// Estimate.
  static const IconData estimate = LucideIcons.receipt300;

  /// Apartment.
  static const IconData apartment = LucideIcons.building2300;

  /// House.
  static const IconData house = LucideIcons.house300;

  /// Garage or workshop.
  static const IconData garage = LucideIcons.warehouse300;

  /// Commercial premises.
  static const IconData shop = LucideIcons.store300;

  /// Empty room.
  static const IconData room = LucideIcons.square300;

  /// Information.
  static const IconData info = LucideIcons.info300;

  /// Passed.
  static const IconData success = LucideIcons.circleCheck300;

  /// Needs review.
  static const IconData warning = LucideIcons.triangleAlert300;

  /// Failed.
  static const IconData danger = LucideIcons.circleX300;

  /// Preliminary, not evaluated.
  static const IconData pending = LucideIcons.circleDashed300;

  /// Question, needs a decision.
  static const IconData help = LucideIcons.circleHelp300;

  /// Not evaluated.
  static const IconData notEvaluated = LucideIcons.circleMinus300;

  /// Reset to automatic.
  static const IconData reset = LucideIcons.rotateCcw300;

  /// Rearrange mode.
  static const IconData rearrange = LucideIcons.move300;

  /// Move left.
  static const IconData moveLeft = LucideIcons.arrowLeft300;

  /// Move right.
  static const IconData moveRight = LucideIcons.arrowRight300;

  /// Move up.
  static const IconData moveUp = LucideIcons.arrowUp300;

  /// Move down.
  static const IconData moveDown = LucideIcons.arrowDown300;
}
