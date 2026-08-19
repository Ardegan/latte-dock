# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Latte Dock (upstream: https://invent.kde.org/plasma/latte-dock) is a KDE Plasma dock. It is **not** a
standalone GUI toolkit app: it is a `Plasma::Corona` host process (`latte-dock`) plus a set of
KPackage/QML packages (shell, containment, tasks plasmoid, indicators) that Plasma loads by
*installed* plugin id, not from the source tree.

**Branch matters.** `master` is the Qt5/KF5/Plasma5 line and is effectively unmaintained upstream (its
CI was dropped in 2026 because Plasma 5 CI no longer exists). Active work happens on **`qt6-port`**
(local, based on upstream `origin/work/plasma6` merged with `origin/master`) — see "Qt6 port status".

Stack on `qt6-port`: C++20 / Qt 6.5+ / KF6 6.0+ / Plasma 6. On `master`: C++17 / Qt 5.15 / KF5 5.88.
Version is set in the top-level `CMakeLists.txt`
(`set(VERSION ...)`); the QML side carries its own compatibility version in
`containment/package/contents/ui/main.qml` (`root.version`), used by the applet-facing `LatteBridge` API.

## Build / install / run

`install.sh` predates the port and does not pass any Qt6 selection, but the top-level `CMakeLists.txt`
hard-requires Qt6/KF6 on this branch, so it works as-is:

```bash
sh install.sh                 # cmake -DCMAKE_INSTALL_PREFIX=/usr Release into ./build, make, sudo make install
sh install.sh Debug           # Debug build (enables qmllint + QT_FATAL_WARNINGS, see below)
sh install.sh --translations  # also `make fetch-translations` (trunk; --translations-stable for stable)
sh uninstall.sh               # uses build/install_manifest.txt
```

Manual equivalent when iterating:

```bash
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Debug -DKDE_L10N_AUTO_TRANSLATIONS=OFF
cmake --build build -j$(nproc)
sudo cmake --install build
```

**QML edits require a reinstall.** All QML lives in KPackages installed via `plasma_install_package`
(`org.kde.latte.shell`, `org.kde.latte.containment`, `org.kde.latte.plasmoid`) and
`share/latte/indicators/*`. Editing a `.qml` in the source tree has no effect until `make install`.
After installing, restart with:

```bash
latte-dock --replace --clear-cache -d      # -d/--debug prints qDebug to stdout
```

A Nix flake (`flake.nix` + `.envrc`) is checked in for pulling KF6 build deps; set
`GENERATE_COMPILE_COMMANDS=1` in the environment to get `compile_commands.json`.

There is **no test suite** and no lint target beyond qmllint. `./formatter.sh` runs `astyle` with
`astylerc` (mozilla style, 4 spaces, `--align-pointer=name`) over `*.cpp`/`*.h` up to depth 3 — match
existing formatting rather than reformatting untouched files.

Debug builds (`CMAKE_BUILD_TYPE=Debug`, see `app/FakeTarget.cmake`) add a PRE_BUILD `qmllint` pass over
every `.qml`/`.js` under `shell/`, `containment/`, `plasmoid/`, and define `QT_FATAL_WARNINGS` — a QML
warning aborts the process at runtime. `fake-target` exists only so IDEs list the QML files.

### Runtime debug flags (hidden from `--help`, defined in `app/main.cpp`)

`--graphics` (boxes around applets), `--with-window` (debug window), `--mask`, `--timers`, `--spacers`,
`--overloaded-icons`, `--kwinedges`, `--localgeometry`, `--layouter`, `--input`, `--events-sink`,
`--debug-text <substr>`, `--log-file <path>`. Also useful: `--available-layouts`,
`--available-dock-templates`, `--layout <name>`, `--single` / `--multiple` memory mode.

User state lives in `~/.config/lattedockrc` (screens, universal settings) and `~/.config/latte/`
(`*.layout.latte` files, `templates/`).

## Qt6 port status (`qt6-port` branch)

The port is well advanced but **not finished and not runtime-verified**. Done:

- CMake fully on Qt6/KF6: `Qt6 6.5+`, `KF6 6.0+`, C++20, `KDEInstallDirs6`, and the Plasma libraries
  split into their own packages (`Plasma::Plasma`, `Plasma::PlasmaQuick`, `Plasma::Activities`,
  `Plasma::KWaylandClient`). No `Qt5::`/`KF5::` targets remain.
- QML root types migrated to Plasma 6 requirements: `ContainmentItem` in
  `containment/package/contents/ui/main.qml`, `PlasmoidItem` in `plasmoid/package/contents/ui/main.qml`.
- All 41 `QtGraphicalEffects` users moved to `Qt5Compat.GraphicalEffects`; all 47
  `PlasmaComponents 2.0` users moved to `3.0`; 14 files moved to `org.kde.ksvg`.
- C++ API updates: `KSvg` instead of `Plasma::Theme::ColorGroup`, `KX11Extras` for compositing state,
  `QX11Info` obtained via `Qt::GuiPrivate` (18 call sites, all X11-guarded),
  `legacy/ManagedTextureNode.{cpp,h}` vendored since Plasma no longer exports it.

Verified build state (Qt 6.10.2 / KF6 6.24.0 / Plasma 6.6.5): **the whole project compiles and links
from a clean tree** — `latte-dock` plus `liblattecoreplugin.so`, `liblattecontainmentplugin.so`,
`liblattetasksplugin.so`, `plasma_containmentactions_lattecontextmenu.so` and `latte_indicator.so`.
It has **never been run**; nothing below is runtime-verified.

Fixes applied on top of upstream `work/plasma6`:

1. **`GuiPrivate` CMake component** (`CMakeLists.txt`). `Qt::GuiPrivate` is a separate CMake package in
   Qt6, not part of the `Gui` component; `app/` links it under `HAVE_X11` for `QX11Info`.
2. **Activity-state shim** (`app/activities/activitiesstate.{h,cpp}`) — see below.
3. **`#include <QHash>`** in `app/shortcuts/shortcutstracker.h`; Qt6 no longer pulls it in transitively.
4. **`#include <PlasmaActivities/Info>`** in `app/settings/settingsdialog/layoutsmodel.h`, which used to
   get the type transitively through `activitydata.h`.

### Activity states: `Latte::Activities::Monitor`

Plasma 6 keeps the `KActivities::` namespace but deleted the entire run-state concept from
plasma-activities: `Info::State`, `Info::state()`, `Info::stateChanged`,
`Consumer::runningActivities()`, `Consumer::runningActivitiesChanged`, and
`Controller::startActivity()`/`stopActivity()`. `Info::Availability`
(`Nothing`/`BasicInfo`/`Everything`) replaced `State` and describes how much info is *loaded*, not run
state. Latte needs run state for its *multiple* layouts memory mode, which binds layouts to running
activities.

`app/activities/activitiesstate.h` restores the **read** side by talking to
`org.kde.ActivityManager` `/ActivityManager/Activities` directly:

- `Latte::Activities::State` — enum with the **same numeric values as the old KF5 one**
  (`Invalid=0, Running=2, Starting=3, Stopped=4`), so values read off the wire compare directly.
- `Monitor::self()` — singleton (function-local static; the constructor is private, so
  `Q_GLOBAL_STATIC` cannot reach it). It is a singleton rather than a Corona member because
  `WindowSystem::AbstractWindowInterface` and others have no Corona pointer and used to build their own
  `Consumer`.
- `state(id)`, `runningActivities()`, `runningActivitiesChanged` — backed by
  `ListActivitiesWithInformation` (`a(ssssi)`; only the id and the trailing state int are consumed, so
  the order of the three middle strings is deliberately not relied on), refreshed on the
  `ActivityAdded`/`ActivityRemoved`/`ActivityStarted`/`ActivityStopped` signals.

**The write side cannot be restored.** kactivitymanagerd 6.6.4 exposes no `StartActivity`/`StopActivity`
D-Bus method (confirmed by introspecting every activity/plasma/kwin service on the session bus),
`libPlasmaActivities` exports no such symbols, and no installed Plasma QML or KCM references stopping an
activity. **Activities can no longer be stopped at all on Plasma 6** — every existing activity is
permanently running. Hence `Monitor::canStopActivities()` returns `false` as an explicit predicate, so
callers read as deliberate rather than silently doing nothing. Two call sites degraded:

- `Synchronizer::pauseLayout()` — used to stop every activity a layout was assigned to. Now warns and
  returns. Harmless in practice: it is **dead code**, with no caller anywhere in the tree, not
  `Q_INVOKABLE`, not on the D-Bus interface, and not reachable from QML.
- `Synchronizer::switchToLayout()` — dropped the "start the activity if not running" guard; the
  following `Controller::setCurrentActivity()` (which still exists) is sufficient.

The shim's D-Bus demarshalling was exercised standalone against the live session bus: it returns the
Default activity with state `2` (Running) and `Invalid` for an unknown id.

### Taskmanager module (`plasmoid/plugin/taskmanager/`)

Plasma 6 no longer ships `org.kde.plasma.private.taskmanager` as an importable QML module — the applet
registers `Backend`/`SmartLauncherItem` into `org.kde.plasma.taskmanager`, embedded in a qrc inside
`plugins/plasma/applets/org.kde.plasma.taskmanager.so`, unreachable from another process. Latte vendors
the sources and registers them under `org.kde.latte.private.tasks`. See
`plasmoid/plugin/taskmanager/README.latte` for provenance and every local change. **Re-sync that
directory when bumping the Plasma baseline.**

The Plasma 6 `Backend` is much smaller than the Plasma 5 one Latte targets, so the vendored copy adds
back `generateMimeData`/`jsonArrayToUrlList` (from Plasma 5) and re-implements `highlightWindows`,
`windowViewAvailable`, `windowsHovered()`, `cancelHighlightWindows()`, `activateWindowView()` over the
KWin D-Bus interfaces the Plasma 6 applet now calls from QML — in C++, so Latte's QML call sites are
unchanged.

### PlasmaCore migration — done

`org.kde.plasma.core` in Plasma 6 exports only `Action`, `ActionGroup`, `Applet`, `AppletPopup`,
`Containment`, `Dialog`, `PopupPlasmaWindow`, `ToolTipArea`, `Types`, `Window`, `WindowThumbnail`.
`PlasmaCore.Types` (595 uses), `Dialog` (12) and `WindowThumbnail` are fine and were left alone.
Everything else has been migrated: the Svg family to `org.kde.ksvg`, `IconItem` to
`LatteCore.IconItem`, `ColorScope` to `Kirigami.Theme`, `Theme.ButtonColorGroup` to `KSvg.Svg.Button`,
and the `colorGroup` property to `colorSet`.

When auditing which types survive, read the export strings out of
`/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/plasma/core/corebindingsplugin.qmltypes` with a pattern like
`"org\.kde\.plasma\.core/[A-Za-z]+ [0-9.]+"` — matching only the first `exports:` entry per component
silently misses types that have several version entries.

### Fast QML feedback loop

Chasing one runtime error per launch is slow. A ~25-line harness that walks the tree with
`QQmlComponent` and reports only structural errors (`Cannot assign to non-existent property`,
`is not a type`, `is not installed`) surfaces the whole backlog in one pass. Two caveats: it reports
`org.kde.latte.private.app` as missing (that module is registered by the `latte-dock` executable, not
installed as a QML module), and `PlasmoidItem` fails outside an applet context — both are artifacts.

### Remaining blockers for the Latte Tasks plasmoid

| Issue | Sites | Notes |
|---|---|---|
| `QtQuick.Controls 1.x` imports | 26 | Controls 1 does not exist in Qt6; needs a Controls 2 port |
| `iconSource:` on PlasmaComponents buttons | 14 | Components 3 uses `icon.name` |
| `PlasmaComponents.ContextMenu`, `PC2.ModelContextMenu` | 2 | Components 2 menus, removed |
| `tooltip:` on custom buttons | 2 | |
| `PipeWireThumbnail.5.24/5.25.qml` | 2 | version-gated legacy files; check the loader still excludes them |

MPRIS is separate: the `mpris2` data engine is gone, so `Plasma5Support.DataSource` loads but stays
empty. Media controls in tooltips and the task context menu (~20 call sites) need porting to
`org.kde.plasma.private.mpris`, which is on the import path.

### Still unverified

Nothing has been launched, so all QML-side concerns remain open:

| Item | Scope |
|---|---|
| `ecm_find_qmlmodule` asks for `plasma.components 2.0` while QML imports `3.0` | configure passes anyway — resolves against Plasma 6.6.5 |
| `org.kde.kquickcontrolsaddons` imports | 10 QML files |
| `import org.kde.plasma.core 2.0` / `plasmoid 2.0` version literals | 122 / 97 QML files |
| `QtQuick.Controls 1` imports | 24 QML files — Controls 1 does not exist in Qt6 |
| `KDE_COMPILERSETTINGS_LEVEL "5.84.0"` | left at the KF5 value |

Because Debug builds define `QT_FATAL_WARNINGS`, any unresolved QML import will abort at runtime
rather than warn.

### Build dependencies

Installed on this machine via `./install-qt6-deps.sh` (Debian/Ubuntu names, resolved by matching each
required CMake config to its providing package). Two gotchas baked into that script:

- `libplasma-dev` provides **both** `Plasma::Plasma` and `Plasma::PlasmaQuick`; the activities package
  is `libplasmaactivities-dev`, Kirigami is `libkirigami-dev`, and KWayland is `kwayland-dev` — not the
  `libkf6*-dev` names the pattern would suggest.
- **Do not install `qt6-wayland-dev-tools`.** `qtwaylandscanner` now ships in `qt6-base-dev-tools`, and
  the older 6.9.2 package `Breaks:` against it, making the transaction unsatisfiable.

## Generated files — do not edit the copies

The top-level `CMakeLists.txt` uses `configure_file` to duplicate sources so that separately-loaded
modules share types. Edit the **source**, never the generated copy:

| Source | Generated copies |
|---|---|
| `declarativeimports/coretypes.h.in` | `declarativeimports/core/types.h`, `app/coretypes.h`, `containment/plugin/lattetypes.h` (each with a different include guard) |
| `app/settings/generic/generictools.{h,cpp}` | `containmentactions/contextmenu/generictools.{h,cpp}` |
| `app/data/contextmenudata.h` | `containmentactions/contextmenu/contextmenudata.h` |

So `Latte::Types::*` (ViewType, Visibility, Alignment, …) is one enum set exposed three times: to C++,
to QML as `LatteCore.Types`, and to the containment plugin.

## Architecture

### Host process (`app/`)

`Latte::Corona` (`app/lattecorona.cpp`) is the root object; everything hangs off it and most subsystems
take a `Corona*`. Its main collaborators:

- **`Layouts::Manager`** (`app/layouts/`) — the central concept. A *layout* is a `.layout.latte` file
  (a KConfig file of containments/applets). Layouts are **active** (loaded into the Corona) or
  **passive** (only on disk). `Synchronizer` maps layouts↔Activities, `Storage` does all file-level
  read/write/validation, `Importer` handles import/export and legacy migration. Memory modes: *single*
  (one active layout) vs *multiple* (per-Activity layouts).
- **`Layout::AbstractLayout` → `GenericLayout` → `CentralLayout`** (`app/layout/`) — a loaded layout
  owning its `Latte::View`s. `GenericLayout` holds the `ViewsMap` (screen → edge → view id).
- **`Latte::View`** (`app/view/`) — a `PlasmaQuick::ContainmentView` window, one per dock/panel. It is
  deliberately split into small `ViewPart::` helpers exposed to QML as properties: `Positioner`
  (geometry/screen), `VisibilityManager` (autohide/dodge modes), `Effects` (mask, blur, shadows),
  `ContainmentInterface` (applet tracking, Latte-vs-Plasma tasks), `Parabolic`, `EventsSink`,
  `Indicator`, `WindowsTracker`. `OriginalView`/`ClonedView` implement per-screen clones.
- **`WindowSystem::AbstractWindowInterface`** (`app/wm/`) — the only place that knows about the
  windowing system; `XWindowInterface` (guarded by `HAVE_X11`) and `WaylandInterface` implement it.
  `wm/tracker/` tracks windows per-screen/per-layout for "dodge"/"transparency when touching" logic.
- **`PlasmaExtended::`** (`app/plasma/extended/`) — reads Plasma's own theme, wallpaper and screen
  config to colorize the dock against the desktop background.
- **`app/settings/`** — the Qt Widgets settings dialogs (`.ui` files + `Data::` model classes from
  `app/data/`, which are plain value/table types like `Data::View`, `Data::Layout`, `Data::GenericTable`).
- **`app/dbus/org.kde.LatteDock.xml`** — the external API (`switchToLayout`, `addView`,
  `updateDockItemBadge`, …), generated onto `Latte::Corona` via `qt_add_dbus_adaptor` (`qt5_add_dbus_adaptor` on `master`).

### QML packages

- `shell/package/` (`org.kde.latte.shell`) — the dock configuration UI (`configuration/`,
  `configuration/pages/`), widget explorer, and the `templates/*.layout.latte` / `*.view.latte` shipped
  defaults.
- `containment/package/` (`org.kde.latte.containment`) — the dock canvas itself: applet wrapping
  (`ui/applet/`), layout containers (`ui/layouts/`), background (`ui/background/`), colorizer,
  visibility, edit-mode overlay. Backed by the `org.kde.latte.private.containment` C++ plugin
  (`containment/plugin/`, mainly `LayoutManager`).
- `plasmoid/package/` (`org.kde.latte.plasmoid`) — the "Latte Tasks" applet (window tasks with the
  parabolic effect), backed by `org.kde.latte.private.tasks`.
- `indicators/` — active-window/task indicators as data-only KPackages installed to
  `share/latte/indicators/`; the package structure plugin is `app/packageplugins/indicator/`. Third
  parties can ship indicators; `default`, `org.kde.latte.plasma`, `org.kde.latte.plasmatabstyle` are bundled.
- `containmentactions/contextmenu/` — the Plasma containmentaction providing Latte's context menu.

### The "abilities" system (`declarativeimports/abilities/`)

This is the non-obvious core of the QML side and the thing to understand before touching containment or
plasmoid QML. Each cross-cutting concern (Metrics, Animations, ParabolicEffect, Indexer, Indicators,
Launchers, MyView, ThinTooltip, PositionShortcuts, Environment, Debug, UserRequests) exists in four layers:

- **`definition/`** — the pure property schema, with no behaviour. Both host and client inherit it, so a
  new property must be added here first.
- **`host/`** — what the *containment* provides; each host ability exposes a read-only `publicApi` Item.
  Real implementations live in `containment/package/contents/ui/abilities/` (+ `privates/`).
- **`bridge/`** — a per-applet `BridgeItem` (`host` + `client` + `appletIndex`) handed to each applet by
  `containment/.../applet/communicator/LatteBridge.qml`.
- **`client/`** — what an *applet* consumes. Each client ability reads `bridge.<ability>` when bridged and
  falls back to a `local` definition instance when the applet runs outside a Latte containment. This
  fallback is why Latte Tasks also works in a plain Plasma panel — preserve it when editing client abilities.

`client/AppletAbilities.qml` is the single entry point an applet instantiates. `items/BasicItem.qml`
is the shared parabolic-aware item used by tasks and indicators.

Other QML imports: `org.kde.latte.core` (`declarativeimports/core/`, C++ plugin: `Environment`,
`IconItem`, `Dialog`, `WindowSystem`, `Tools`, `Types`) and `org.kde.latte.components`
(pure-QML shared controls).

`LatteBridge.qml` is a **public, versioned API for third-party applets** — its properties are documented
inline with `@since` tags. Treat changes there as API changes and bump/guard on `root.version`.

## Conventions

- Every file needs SPDX headers; the repo is REUSE-compliant (`LICENSES/`, `.reuse/dep5`). New C++/QML
  files use `SPDX-License-Identifier: GPL-2.0-or-later`.
- C++ is namespaced `Latte::` with sub-namespaces mirroring directories (`Latte::Layouts`, `Latte::ViewPart`,
  `Latte::WindowSystem`, `Latte::Data`, `Latte::Settings`).
- Comment blocks use the `//!` prefix; section markers `//! START:` / `//! END:` are common in long files.
- User-visible strings go through `i18n`/`i18nc`; each package sets its own `TRANSLATION_DOMAIN`.
  `po/` and the `Messages.sh` scripts are synced from KDE's translation infrastructure — do not hand-edit
  `po/` (commits touching it are made by scripty as `GIT_SILENT`/`SVN_SILENT`).
- Config schemas are KConfigXT `config/main.xml` files inside each package; a new setting means editing
  that XML plus the shell configuration page.
