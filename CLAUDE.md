# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Latte Dock (upstream: https://invent.kde.org/plasma/latte-dock) is a KDE Plasma dock. It is **not** a
standalone GUI toolkit app: it is a `Plasma::Corona` host process (`latte-dock`) plus a set of
KPackage/QML packages (shell, containment, tasks plasmoid, indicators) that Plasma loads by
*installed* plugin id, not from the source tree.

**Branch matters.** `master` is the Qt5/KF5/Plasma5 line and is effectively unmaintained upstream (its
CI was dropped in 2026 because Plasma 5 CI no longer exists). Active work happens on **`qt6-port`**
(local, based on upstream `origin/work/plasma6` merged with `origin/master`), where the dock builds and
runs on Plasma 6 — see "Qt6 port status". Nothing on `qt6-port` has been pushed anywhere.

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

Manual equivalent when iterating. Use **Release** unless you specifically want the qmllint pass:
Debug defines `QT_FATAL_WARNINGS`, so any QML warning aborts the process at runtime.

```bash
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_L10N_AUTO_TRANSLATIONS=OFF
cmake --build build -j$(nproc)
sudo cmake --install build
```

Latte rewrites `~/.config/latte/*.layout.latte` when it exits, so **stop it before editing a layout
file by hand**, otherwise the change is overwritten on shutdown.

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

**The dock builds, runs and renders on Plasma 6.** Verified on Qt 6.10.2 / KF6 6.24.0 /
Plasma 6.6.5 (Wayland): a clean tree configures and builds with no errors, `latte-dock` starts, loads
its layout, creates its view, and the Latte Tasks plasmoid and Plasma applets appear in it. Startup
QML warnings are down to 16, of which 11 come from outside Latte.

The port started from upstream `origin/work/plasma6` (merged with `origin/master`); everything below
this line was added on top of it, because upstream's branch compiled but had never been run.

### How the Plasma 5 -> 6 API split drove most of the work

Nearly every runtime bug traced back to one change: in Plasma 5 the QML `plasmoid`/`applet` was an
`AppletInterface` — a `QQuickItem` that *also* carried `id`, `pluginName`, `status`, `configuration`.
Plasma 6 splits that into **`PlasmaQuick::AppletQuickItem`** (the Item: geometry, `Layout`, `parent`,
`anchors`, plus `expanded` and the `toolTip*` family) and **`Plasma::Applet`** (the data), reached from
QML through the **`Plasmoid` attached object**. When touching applet-facing QML, check which half a
member belongs to — read it out of
`/usr/lib/x86_64-linux-gnu/qt6/qml/org/kde/plasma/plasmoid/plasmoidplugin.qmltypes`, and use Plasma's
own `containments/panel` and `shells/org.kde.plasma.desktop/contents/applet/CompactApplet.qml` as the
reference implementations.

Consequences already handled:

- `_plasma_graphicObject` no longer exists — use `PlasmaQuick::AppletQuickItem::itemForApplet()`
  (21 C++ sites).
- `Containment::applets` is typed `QList<Plasma::Applet*>`; Qt6 will **not** implicitly convert that
  QVariant to `QList<QObject*>`, it silently yields an empty list.
- `Containment.onAppletAdded` is `(applet, geometryHint)`, not the Plasma 5 `x`/`y`.
- `Plasma::Applet::action(name)` -> `internalAction(name)`.
- Applet-level reads in containment QML go through `applet.Plasmoid.<x>`.

### Qt6 QML traps that fail silently

These produce no error and no visible symptom at the point of failure, so they cost the most time:

- **`Connections { onFoo: ... }` is never connected.** Qt6 requires
  `Connections { function onFoo() { ... } }`. 149 handlers across the tree were dead; the one driving
  `hasRestoredApplets` meant `Positioner::m_inStartup` never cleared and the view stayed parked at its
  deliberate out-of-screen `QRect(-9999, -9999, ...)` for the whole session.
- **Two `Behavior`s on one property**: Qt6 keeps the first and refuses the rest ("Attempting to set
  another interceptor"). Latte's animated + `duration: 0` pairs, toggled by `enabled`, must be merged
  into one Behavior with a conditional duration.
- **`Binding.value` is evaluated even when `when` is false**, so the value expression must guard its
  own nulls.
- **Implicit signal-handler parameter injection is gone** — declare parameters explicitly.
- `PlasmoidItem`/`ContainmentItem` may only be a **root** item. Upstream's port commit `4cfebe3b8`
  blanket-replaced `Item {` in nine files that are not applet roots, which left `plasmoid` null inside
  them.
- `latteView.visibility` is null until `View::init()` finishes; guard it, not just `latteView`.
- **Screen space is reserved through two independent paths, and they can disagree.** Desktop icons
  are repositioned because `PlasmaExtended::ScreenGeometries` broadcasts the available rect to
  plasmashell over D-Bus (`setAvailableScreenRect`), gated by the `isAvailableGeometryBroadcastedToPlasma`
  universal setting and skipping `AutoHide`/`SidebarOnDemand`/`SidebarAutoHide`. Maximized *windows*
  are governed by KWin's work area, which on Wayland comes from a **wlr-layer-shell exclusive zone**
  on the `GhostWindow` - the legacy `org_kde_plasma_surface` Panel role no longer produces a strut in
  KWin 6. Latte had only the first, so icons moved but windows slid under the dock. Check
  `workspace.clientArea(KWin.MaximizeArea, ...)` via a KWin script, not the Plasma available rect,
  when verifying window behaviour. Struts are published only from the `AlwaysVisible` branch of
  `VisibilityManager::setMode()`. A layer surface is **bound to the output it was created on** and
  cannot be re-bound, so `WaylandInterface::setViewStruts()` destroys and recreates the `GhostWindow`
  whenever the view changes screen - struts are first published while the view is still on the primary
  screen, so anything else leaves the zone reserved on the wrong monitor. Verify per-output with
  `workspace.clientArea(KWin.MaximizeArea, workspace.screens[i], ...)`, not just on the primary.
  A missing strut also shows up as a *rendering* fault: a maximized window placed at `0,0` sits under
  the view's full-height (e.g. 1969x384) transparent window, the area beneath the dock is never
  painted, and stale wallpaper shows through until hovering the dock damages the region and forces a
  repaint. That looked exactly like a blur bug in `ViewPart::Effects`, but every startup call there
  takes the `clearEffects` branch and the final region is a correct `1114x20`. Suspect the strut, not
  the effects, when a band the height of `viewHeight - strutThickness` appears under the dock.
- **`WindowId` is a `QVariant`, numeric on X11 and a `QByteArray` uuid on Wayland.** Any
  `wid.toInt() > 0` validity test silently rejects every Wayland window; that single assumption in
  `Windows::cleanupFaultyWindows()` emptied the whole tracker as fast as it filled, which killed every
  dodge mode, the active/touching window colouring and "transparent when touching". Use
  `WindowId::isValidId()`. When window-driven behaviour does nothing at all, check the tracker's window
  count before reading the state machine.
- **The Wayland strut `GhostWindow` steals pointer input.** `WaylandInterface::setViewStruts()`
  (`app/wm/waylandinterface.cpp`) creates a transparent panel-role surface sized
  `(thickness+1) x thickness`, pinned to the *horizontal centre of the view*, purely so Plasma
  reserves space. Being transparent it is invisible, but without an empty input region it consumes
  every pointer event over the middle of the dock, leaving whichever item sits there totally inert
  while still rendering normally. It now sets `Qt::WindowTransparentForInput` plus an explicit empty
  KWayland input region, re-applied on each resize. When one dock item misbehaves and its
  *neighbours* are fine, check for overlapping surfaces before reading any QML.

### Fixes applied on top of upstream `work/plasma6`

1. **`GuiPrivate` CMake component** (`CMakeLists.txt`). `Qt::GuiPrivate` is a separate CMake package in
   Qt6, not part of the `Gui` component; `app/` links it under `HAVE_X11` for `QX11Info`.
2. **Activity-state shim** (`app/activities/activitiesstate.{h,cpp}`) — see below.
3. **`#include <QHash>`** in `app/shortcuts/shortcutstracker.h`; Qt6 no longer pulls it in transitively.
4. **`#include <PlasmaActivities/Info>`** in `app/settings/settingsdialog/layoutsmodel.h`, which used to
   get the type transitively through `activitydata.h`.
5. **Wayland null guards** in `app/wm/waylandinterface.cpp`: `windowFor()` and both `winIdFor()`
   overloads dereferenced `m_windowManagement` unguarded, while their siblings checked it.
   plasma-window-management binds asynchronously, so the first view construction segfaulted reliably.
6. **`Latte::compositingActive()`** in `app/apptypes.h`. `KX11Extras::compositingActive()` warns "may
   only be used on X11" in KF6 and Latte called it on hot paths — 168 times per startup.
7. **The `Interfaces` handshake**, see below.

### The `Interfaces` handshake (`app/declarativeimports/interfaces.{h,cpp}`)

`latteView` in containment QML is `_interfaces.view`, fed by `_latte_*_object` dynamic properties that
`View::init()` sets on the containment item. Two Plasma 6 ordering problems:

- `setPlasmoidInterface()` casts to `AppletQuickItem`, but the QML `plasmoid` is now the
  `Plasma::Applet`, so the cast yielded null. `main.qml` passes the `ContainmentItem` **`root`** instead.
- Plasma 6 builds the containment item **before** `View::init()` runs, so the object binds
  `plasmoidInterface` and reads all five properties while they are still null — and cannot publish
  itself back via `view.interfacesGraphicObj`, because `view` is null at that point. `View::init()` now
  locates it with `findChild()` and calls `Interfaces::updateInterfaces()` to re-read them.

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

### MPRIS — done

The `mpris2` data engine is gone in Plasma 6. The media controls in task tooltips and the task context
menu now use `org.kde.plasma.private.mpris`: `Mpris2Model::playerForLauncherUrl(url, pid)` returns a
`PlayerContainer` directly, replacing the source-name/`data[]` indirection. `PlayerContainer` carries
`track`, `artist`, `album`, `artUrl`, `identity`, `desktopEntry`, `instancePid`, `length`, `position`,
`playbackStatus` and the `can*` flags as properties, and `Play()`, `Pause()`, `PlayPause()`, `Next()`,
`Previous()`, `Stop()`, `Quit()`, `Raise()` as methods. Two traps:

- The generated `kmpris.qmltypes` lists only seven `Property` entries for `PlayerContainer`; the rest
  are real `Q_PROPERTY`s with notify signals and are readable from QML. Read the moc string table in
  `/lib/x86_64-linux-gnu/libkmpris.so.6` rather than trusting the qmltypes here.
- `PlaybackStatus.Status` is `Unknown=0, Stopped=1, Playing=2, Paused=3` — *not* the order you would
  guess, so compare against the named enumerator.

Plasma's own `shells/org.kde.plasma.desktop/contents/lockscreen/MediaControls.qml` is the on-disk
reference implementation.

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

### Diagnosing runtime state

A Release build routes messages through Latte's own handler and prints almost nothing, so use
`latte-dock --debug`. Beyond that:

- **Is there actually a window?** Latte's view is a `QQuickWindow`, so ask the compositor rather than
  guessing. Load a throwaway KWin script that prints `workspace.windowList()` with
  `resourceClass`/`caption`/`frameGeometry`, via
  `busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting loadScript ss <file> <name>` then
  `... start`, and read the output back with `journalctl --user`. This is how the "parked at
  `-9999,-9152`" and the "no latte window exists at all" states were both identified.
- **Is a QML value what you think?** A one-shot `Timer { interval: 5000; running: true }` in
  `containment/.../main.qml` that `console.log`s the metrics, layout children and their sizes answers
  in one run what a dozen launches of error-chasing will not. That is what showed `mainLayout` holding
  two zero-sized spacers instead of the applets.
- Do **not** screenshot the whole desktop to find out what rendered. The display may be scaled, so
  logical geometry does not map to image pixels, and a mis-cropped capture will surface unrelated
  windows and their contents.

### Controls 1 / PlasmaComponents 2 migration — done

`QtQuick.Controls 1` and its styling system do not exist in Qt6. 24 files imported it but only 14 used
a Controls 1 type; the rest were stale imports. Notable points if you touch this area again:

- `ExclusiveGroup` was **removed, not converted to `ButtonGroup`**. Every site bound `checked:` to an
  authoritative state expression and 26 of 28 also set `checkable: false`, so the group drove nothing —
  and `ButtonGroup` *assigns* to `checked`, which would have broken those bindings.
- `iconSource:` -> `icon.name:`; `tooltip:` -> the attached `<Alias>.ToolTip.text`/`.visible`.
  `LatteComponents.CheckBox` keeps a `tooltip` property of its own, since ~22 config sites set it.
- `PlasmaComponents.ContextMenu`/`MenuItem` -> `PlasmaExtras.Menu`/`MenuItem`, and
  `PlasmaComponents.DialogStatus` -> `PlasmaExtras.Menu.Status` (same members).
- Controls 2 `ScrollView` exposes scrollbars as attached properties; the Flickable is `contentItem`
  and the old `viewport` is `availableWidth`/`availableHeight`.
- **Do not pin `QtQuick.Templates`/`QtQuick.Controls` to a 2.x minor.** The pins froze the API at the
  Qt5 feature level — `AbstractButton.icon` only exists from 2.3, which is what made
  `ItemDelegate`'s grouped `icon` unassignable.

### Known remaining issues

| Item | Notes |
|---|---|
| `inNormalState` binding loop (`VisibilityManager.qml`) | byte-identical to `master`, so pre-existing upstream design that Qt6 merely detects; untangling it means reworking the show/hide state machine |
| `Invalid QML element name "Types"` (x3) | `Latte::Types` is a `Q_GADGET` enum namespace, which Qt6 classes as a value type and wants lowercase. Renaming would break 595 `LatteCore.Types.*` sites and the versioned `LatteBridge` API |
| `ecm_find_qmlmodule` version literals | relaxed to non-REQUIRED; `qmlplugindump` is unreliable against the Plasma 6 modules and intermittently fails for modules that are present |
| `KDE_COMPILERSETTINGS_LEVEL "5.84.0"` | left at the KF5 value |
| Automatic icon size is recomputed only on discrete triggers | `AutoSize.updateIconSize()` drops any call arriving while `metrics.iconSize` is animating and relies on a later trigger to catch up. The `iconSizeAnimationEnded` retry fixes the max-length-ruler case, but any other input that changes size mid-animation can still lose a step |
| Task order inside a cloned Latte Tasks applet can differ from the original | seen once while switching to *multiple* layouts memory mode: the clock was in the right place but the window buttons inside the tasks applet were in a different order on the clone. The clone's tasks applet had no `launchers59` key while the original did. Not reproducible on a normal start; the applet-level ordering bug it resembles is fixed separately |
| Nothing beyond first render is exercised | Working: hover/zoom, left/middle/right click, the context menu, both settings dialogs, edit mode (max-length ruler, alignment controls, applet drag, all four config tabs), multi-screen placement with struts on the correct output for top and left edges, per-activity layouts in *multiple* memory mode (layouts load per activity, views are assigned to their layout's activity over plasma-window-management, and switching activity swaps the visible dock), and the AutoHide/DodgeActive/DodgeMaximized/DodgeAllWindows visibility modes, including AutoHide reveal-on-hover from the screen-edge strip |

Because Debug builds define `QT_FATAL_WARNINGS`, any unresolved QML import aborts at runtime rather
than warning — build Release when just running the dock.

### Build dependencies

Installed on this machine via `./install-qt6-deps.sh` (Debian/Ubuntu names, resolved by matching each
required CMake config to its providing package). Two gotchas baked into that script:

- `libplasma-dev` provides **both** `Plasma::Plasma` and `Plasma::PlasmaQuick`; the activities package
  is `libplasmaactivities-dev`, Kirigami is `libkirigami-dev`, and KWayland is `kwayland-dev` — not the
  `libkf6*-dev` names the pattern would suggest.
- `liblayershellqtinterface-dev` is required (`find_package(LayerShellQt)`); `app/` links
  `LayerShellQt::Interface` for the Wayland strut. It is in `install-qt6-deps.sh`.
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
