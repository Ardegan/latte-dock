Installation
============

This branch targets **Qt 6 / KF6 / Plasma 6**. The Qt 5 dependency lists that used to be here no
longer apply — building this tree against KF5 is not possible.

For the short version — dependencies, build, run — see [Build from source](./README.md#build-from-source)
in the README. This file covers dependencies per distribution.


Debian / Ubuntu / KDE neon / TUXEDO OS
--------------------------------------

Verified on Ubuntu 24.04 (TUXEDO OS 24.04.4). Use the bundled script, which carries the exact list:

```bash
./install-qt6-deps.sh
```

It installs:

```
qt6-base-dev qt6-declarative-dev qt6-wayland-dev
libkf6archive-dev libkf6config-dev libkf6coreaddons-dev libkf6crash-dev
libkf6dbusaddons-dev libkf6declarative-dev libkf6globalaccel-dev libkf6guiaddons-dev
libkf6i18n-dev libkf6iconthemes-dev libkf6kio-dev libkf6newstuff-dev
libkf6notifications-dev libkf6package-dev libkf6svg-dev libkf6windowsystem-dev
libkf6xmlgui-dev libkirigami-dev
libplasma-dev libplasmaactivities-dev libplasmaactivitiesstats-dev
libksysguard-dev kwayland-dev liblayershellqtinterface-dev plasma-workspace-dev
```

Two traps worth repeating:

- `libplasma-dev` provides **both** `Plasma::Plasma` and `Plasma::PlasmaQuick`. The activities package
  is `libplasmaactivities-dev`, Kirigami is `libkirigami-dev`, and KWayland is `kwayland-dev` — not the
  `libkf6*-dev` names you would guess.
- **Do not install `qt6-wayland-dev-tools`.** `qtwaylandscanner` ships in `qt6-base-dev-tools`, and the
  older 6.9.2 package `Breaks:` against it, making the transaction unsatisfiable.

You also need `cmake`, `extra-cmake-modules`, `git` and a C++20 compiler, which the script assumes are
already present on a development machine.


Other distributions
-------------------

Package names for Arch, Fedora and openSUSE are deliberately not listed here: the previous lists were
Qt 5 and had gone stale, and publishing guesses that have never been built is worse than publishing
nothing.

Instead, here is what the build actually looks for. Install whichever packages provide these CMake
config files on your distribution — if `cmake` configures, you have them all.

**Qt 6** (>= 6.5) — components `DBus`, `Gui`, `Qml`, `Quick`, plus `GuiPrivate` (a separate CMake
package in Qt 6, needed for `QX11Info` under `HAVE_X11`), and `Qt6WaylandClient`.

**KDE Frameworks 6** (>= 6.0) — components:

```
Archive  Config  CoreAddons  Crash  DBusAddons  Declarative  GlobalAccel  GuiAddons
I18n  IconThemes  KIO  Kirigami  NewStuff  Notifications  Package  Svg
WindowSystem  XmlGui
```

**Plasma and friends:**

```
ECM (extra-cmake-modules)   Plasma            PlasmaQuick
PlasmaActivities            PlasmaActivitiesStats
KWayland                    PlasmaWaylandProtocols (>= 1.6)
LayerShellQt                LibTaskManager     LibNotificationManager
KSysGuard                   QtWaylandScanner   Wayland (Client)
X11 / XCB (XCB RANDR SHAPE EVENT, libSM)
```

Notes on the less obvious ones:

- **LayerShellQt** is required. Plasma 6 reserves screen space through wlr-layer-shell exclusive
  zones, and the dock's Wayland strut depends on it. On Debian it is `liblayershellqtinterface-dev`.
- **LibTaskManager**, **LibNotificationManager** and **KSysGuard** come from plasma-workspace; on
  Debian a single `plasma-workspace-dev` covers all three.
- **PlasmaActivitiesStats** is needed by the taskmanager backend vendored into
  `plasmoid/plugin/taskmanager`.


Building and installing
-----------------------

```bash
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_L10N_AUTO_TRANSLATIONS=OFF
cmake --build build -j$(nproc)
sudo cmake --install build
```

or, equivalently, the bundled script:

```bash
sh install.sh
```

Then run `latte-dock --replace --clear-cache`. Installing to `/usr` matters: Plasma loads Latte's
KPackages by installed plugin id, not from the source tree.

To remove it again: `sh uninstall.sh` (uses `build/install_manifest.txt`).
