import 'package:flutter/widgets.dart';

/// Icons of the app: Lucide with a 1.55 stroke (the `300` weight), matching the hairlines.
///
/// Only this weight is bundled (`assets/fonts/Lucide-300.ttf`): a font package would ship every
/// weight, and Flutter Web downloads all declared fonts before the first frame.
///
/// Screens use these names only, so the set or the weight changes in one place.
abstract final class UiIcons() {
  static const _family = 'Lucide';
  static const _package = 'common_ui';

  /// Back.
  static const IconData back = IconData(0xe048, fontFamily: _family, fontPackage: _package);

  /// Forward, next step.
  static const IconData next = IconData(0xe049, fontFamily: _family, fontPackage: _package);

  /// Close an overlay.
  static const IconData close = IconData(0xe1b2, fontFamily: _family, fontPackage: _package);

  /// Add.
  static const IconData add = IconData(0xe13d, fontFamily: _family, fontPackage: _package);

  /// Edit.
  static const IconData edit = IconData(0xe1f9, fontFamily: _family, fontPackage: _package);

  /// Delete.
  static const IconData delete = IconData(0xe18e, fontFamily: _family, fontPackage: _package);

  /// More actions.
  static const IconData more = IconData(0xe0b7, fontFamily: _family, fontPackage: _package);

  /// Search.
  static const IconData search = IconData(0xe151, fontFamily: _family, fontPackage: _package);

  /// Selected item, completed step.
  static const IconData check = IconData(0xe06c, fontFamily: _family, fontPackage: _package);

  /// Opens a list.
  static const IconData chevronDown = IconData(0xe06d, fontFamily: _family, fontPackage: _package);

  /// Opens details.
  static const IconData chevronRight = IconData(0xe06f, fontFamily: _family, fontPackage: _package);

  /// PDF report.
  static const IconData report = IconData(0xe0cc, fontFamily: _family, fontPackage: _package);

  /// Export or share.
  static const IconData share = IconData(0xe155, fontFamily: _family, fontPackage: _package);

  /// Import a file.
  static const IconData import = IconData(0xe0c5, fontFamily: _family, fontPackage: _package);

  /// Copy.
  static const IconData copy = IconData(0xe09e, fontFamily: _family, fontPackage: _package);

  /// Retry.
  static const IconData retry = IconData(0xe145, fontFamily: _family, fontPackage: _package);

  /// Settings.
  static const IconData settings = IconData(0xe154, fontFamily: _family, fontPackage: _package);

  /// List of projects.
  static const IconData projects = IconData(0xe0d7, fontFamily: _family, fontPackage: _package);

  /// Brand mark.
  static const IconData brand = IconData(0xe1b4, fontFamily: _family, fontPackage: _package);

  /// Switchboard view.
  static const IconData board = IconData(0xe0ff, fontFamily: _family, fontPackage: _package);

  /// List view.
  static const IconData list = IconData(0xe106, fontFamily: _family, fontPackage: _package);

  /// Object setup.
  static const IconData object = IconData(0xe0f5, fontFamily: _family, fontPackage: _package);

  /// Rooms.
  static const IconData rooms = IconData(0xe3d6, fontFamily: _family, fontPackage: _package);

  /// Circuits.
  static const IconData circuits = IconData(0xe1d0, fontFamily: _family, fontPackage: _package);

  /// Estimate.
  static const IconData estimate = IconData(0xe3d3, fontFamily: _family, fontPackage: _package);

  /// Apartment.
  static const IconData apartment = IconData(0xe290, fontFamily: _family, fontPackage: _package);

  /// House.
  static const IconData house = IconData(0xe0f5, fontFamily: _family, fontPackage: _package);

  /// Garage or workshop.
  static const IconData garage = IconData(0xe3e6, fontFamily: _family, fontPackage: _package);

  /// Commercial premises.
  static const IconData shop = IconData(0xe3e4, fontFamily: _family, fontPackage: _package);

  /// Empty room.
  static const IconData room = IconData(0xe167, fontFamily: _family, fontPackage: _package);

  /// Information.
  static const IconData info = IconData(0xe0f9, fontFamily: _family, fontPackage: _package);

  /// Passed.
  static const IconData success = IconData(0xe226, fontFamily: _family, fontPackage: _package);

  /// Needs review.
  static const IconData warning = IconData(0xe193, fontFamily: _family, fontPackage: _package);

  /// Failed.
  static const IconData danger = IconData(0xe084, fontFamily: _family, fontPackage: _package);

  /// Preliminary, not evaluated.
  static const IconData pending = IconData(0xe4b0, fontFamily: _family, fontPackage: _package);

  /// Question, needs a decision.
  static const IconData help = IconData(0xe082, fontFamily: _family, fontPackage: _package);

  /// Not evaluated.
  static const IconData notEvaluated = IconData(0xe07e, fontFamily: _family, fontPackage: _package);

  /// Reset to automatic.
  static const IconData reset = IconData(0xe148, fontFamily: _family, fontPackage: _package);

  /// Rearrange mode.
  static const IconData rearrange = IconData(0xe121, fontFamily: _family, fontPackage: _package);

  /// Move left.
  static const IconData moveLeft = IconData(0xe048, fontFamily: _family, fontPackage: _package);

  /// Move right.
  static const IconData moveRight = IconData(0xe049, fontFamily: _family, fontPackage: _package);

  /// Move up.
  static const IconData moveUp = IconData(0xe04a, fontFamily: _family, fontPackage: _package);

  /// Move down.
  static const IconData moveDown = IconData(0xe042, fontFamily: _family, fontPackage: _package);
}
