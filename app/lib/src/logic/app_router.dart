import 'package:common_ui/common_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shchitovik/src/feature/circuits/presentation/circuit_screen.dart';
import 'package:shchitovik/src/feature/circuits/presentation/circuits_screen.dart';
import 'package:shchitovik/src/feature/estimate/presentation/estimate_screen.dart';
import 'package:shchitovik/src/feature/estimate/presentation/slot_screen.dart';
import 'package:shchitovik/src/feature/project_setup/presentation/project_setup_screen.dart';
import 'package:shchitovik/src/feature/projects/presentation/project_shell.dart';
import 'package:shchitovik/src/feature/projects/presentation/projects_screen.dart';
import 'package:shchitovik/src/feature/rooms_devices/presentation/rooms_screen.dart';
import 'package:shchitovik/src/feature/settings/presentation/settings_screen.dart';

/// Route paths of the application; they double as web URLs and must stay stable.
abstract final class AppRoutes {
  /// List of projects, the start screen.
  static const projects = '/';

  /// Application settings.
  static const settings = '/settings';

  /// Showcase of the design system; debug builds only.
  static const uiGallery = '/dev/ui';

  /// Project tabs.
  static String projectSetup(String id) => '/projects/$id/setup';

  /// Rooms and devices.
  static String projectRooms(String id) => '/projects/$id/rooms';

  /// Circuits.
  static String projectCircuits(String id) => '/projects/$id/circuits';

  /// Estimate.
  static String projectEstimate(String id) => '/projects/$id/estimate';

  /// Circuit details.
  static String circuit(String id, String circuitId) =>
      '/projects/$id/circuits/${Uri.encodeComponent(circuitId)}';

  /// Model choice for an estimate slot.
  static String slot(String id, String slotId) =>
      '/projects/$id/estimate/slots/${Uri.encodeComponent(slotId)}';
}

/// Creates the application [GoRouter].
GoRouter createAppRouter() => GoRouter(
  initialLocation: AppRoutes.projects,
  routes: [
    GoRoute(path: AppRoutes.projects, builder: (context, state) => const ProjectsScreen()),
    GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.uiGallery,
        builder: (context, state) => UiGallery(onBack: () => context.go(AppRoutes.settings)),
      ),
    GoRoute(
      path: '/projects/:id',
      redirect: (context, state) => AppRoutes.projectCircuits(state.pathParameters['id']!),
    ),
    ShellRoute(
      builder: (context, state, child) => ProjectShell(
        projectId: state.pathParameters['id']!,
        location: state.uri.path,
        child: child,
      ),
      routes: [
        _noTransition('/projects/:id/setup', (_) => const ProjectSetupScreen()),
        _noTransition('/projects/:id/rooms', (_) => const RoomsScreen()),
        _noTransition('/projects/:id/circuits', (_) => const CircuitsScreen()),
        _noTransition('/projects/:id/estimate', (_) => const EstimateScreen()),
        GoRoute(
          path: '/projects/:id/circuits/:circuitId',
          builder: (context, state) => CircuitScreen(circuitId: state.pathParameters['circuitId']!),
        ),
        GoRoute(
          path: '/projects/:id/estimate/slots/:slotId',
          builder: (context, state) => SlotScreen(slotId: state.pathParameters['slotId']!),
        ),
      ],
    ),
  ],
);

GoRoute _noTransition(String path, Widget Function(GoRouterState) builder) => GoRoute(
  path: path,
  pageBuilder: (context, state) => NoTransitionPage(child: builder(state)),
);
