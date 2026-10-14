Flutter workspace of «Щитовик» — switchboard calculator (Android, iOS, Web). Structure follows
[sizzle_starter](https://github.com/hawkkiller/sizzle_starter).

- [app](app) — entry point; features and wiring.
- [common](common) — reusable, app-independent Flutter packages; use `common_` prefix.
- [engine](engine) — pure Dart calculation core, **standalone packages outside the pub workspace**
  (own `pubspec.lock`; `package:test` can't share a solve with `flutter_test`). No Flutter imports.
  - `electrical_core` — currents, circuits, protection, phases, cables, fault loop, demand.
  - `estimate_core` — apparatus selection, compatibility, estimate.
  - `norms_data` — normative tables and catalogs (JSON with `source` for every table).

Plan, decisions and what is left: [docs/PLAN.md](docs/PLAN.md). Publishing waits for the manual part of
[verification/VERIFICATION.md](verification/VERIFICATION.md).

## Toolchain

Flutter 3.47.6 pinned via FVM (`.fvmrc`). `make bootstrap` → `make format` → `make analyze` → `make test`.

## Architecture

Pragmatic layered architecture:

- *Presentation* — Widgets, Scopes (InheritedWidget), Cubits/Blocs.
- *Application* (optional) — Services, Use Cases.
- *Domain* — Entities, Value Objects, Repository interfaces.
- *Data* — Repository implementations (DB, files, network).

Dependency rule: *Presentation → Application → Domain ← Data*. Domain never imports other layers.

Features are independent. Shared parts go to the feature's *public/* folder (no Data there).

Calculation results are never persisted: only user input, manual overrides and apparatus
selections are stored; everything else is recomputed by `engine` deterministically.

## Calculation rules

- Every rule in `engine` cites the norm it implements (document, clause/table).
- Physics in `double` with centralized tolerances; money in `int` kopecks; power in `int` watts.
- Any change that can alter results bumps `algorithmVersion`.

## Widgets

- Build screens from `common_ui` (`Ui*` widgets, `UiColors`, `UiTextStyles`, `UiIcons`); no raw
  colours, bare Material widgets or `Icons.*`. Missing piece → add it to `common_ui` and `UiGallery`.
- Prefer specific widgets (DecoratedBox, Padding, SizedBox) over Container.
- Do not use shrinkWrap in scrollable widgets.
- Do not create functions that return widgets; create a separate widget class.

## Dependency Injection

- Manual DI via composition root (`composeDependencies`).
- Each feature defines its own container (`injection.dart`), registered in `DependenciesContainer`
  and provided via `DependenciesScope`.

## Testing

- BLoCs are tested with plain `flutter_test` (`bloc_test` conflicts with freezed 4 resolution).
- No property-based testing; invariants are checked by table-driven tests on fixed grids.

## Documentation

- Write dartdoc comments for public APIs, starting with a one-sentence summary.

## UI/UX skills

Taste, a11y, bans, voice, and icon library for this project live in `.ux-profile.md`.
Run `setup-ui-ux-skills` again only to change those defaults.
Before UI or microcopy work, read `.ux-profile.md`, then the matching domain skill (page-patterns, viewports, forms, surfaces, loaders, empty-states, copy, motion).
Before creating a new page, read `page-patterns` and name the pattern. Do not write page markup until the pattern is named.
Layouts must pass `viewports` at 375px and 1280px.
Before finishing UI, run `ux-audit`.
