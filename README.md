# <img src="logo.png" width="48"/> Latte Dock — Qt 6 / Plasma 6 port

Latte is a dock based on plasma frameworks that provides an elegant and intuitive experience for your tasks and plasmoids. It animates its contents by using parabolic zoom effect and tries to be there only when it is needed.

**"Art in Coffee"**

> ### About this fork
>
> Upstream Latte Dock targets **Qt 5 / KF5 / Plasma 5** and is effectively unmaintained — its CI was
> dropped once Plasma 5 CI disappeared. This branch (`qt6-port`) continues from upstream's
> `work/plasma6` branch and makes the dock **build and actually run on Plasma 6**, which upstream's
> branch never did.
>
> It is a personal port, not an official KDE release. There are no packages for it: you build it
> from source. See [Build from source](#build-from-source) below, and
> [Current state](#current-state) for what is known to work.

Screenshots
===========

![](https://cdn.kde.org/screenshots/latte-dock/latte-dock_regular.png)

![](https://cdn.kde.org/screenshots/latte-dock/latte-dock_settings.png)


Verified environment
====================

This branch is developed and tested on exactly this stack. Nearby versions will very likely work;
these are the ones it is known to run on.

| Component        | Verified version                          |
| ---------------- | ----------------------------------------- |
| OS               | TUXEDO OS 24.04.4 LTS (Ubuntu 24.04 base) |
| Kernel           | 6.17                                      |
| Session          | **Wayland** (KWin)                        |
| Plasma           | 6.6.5                                     |
| KDE Frameworks 6 | 6.24.0                                    |
| Qt               | 6.10.2                                    |
| CMake            | 4.2                                       |
| Compiler         | GCC 13.3 (C++20)                          |

**Wayland is the tested path.** The X11 code paths still compile and are guarded, but nothing in this
port has been exercised under an X11 session — several fixes here are specifically about Wayland
behaviour that X11 never hit (window tracking, struts, window thumbnails).

Minimum versions enforced by the build: **Qt >= 6.5**, **KF6 >= 6.0**, **Plasma >= 6.0**,
**PlasmaWaylandProtocols >= 1.6**.


Build from source
=================

The whole procedure, from a clean checkout to a running dock. Every command below was run verbatim on
the environment in the table above.

### 1. Install the build dependencies

**Debian / Ubuntu / KDE neon / TUXEDO OS** — a script with the exact package list is included:

```bash
./install-qt6-deps.sh
```

Two things that script exists to get right, and that trip people up if they resolve the names by hand:

- `libplasma-dev` provides **both** `Plasma::Plasma` and `Plasma::PlasmaQuick`. The activities package
  is `libplasmaactivities-dev`, Kirigami is `libkirigami-dev`, and KWayland is `kwayland-dev` — not the
  `libkf6*-dev` names the pattern would suggest.
- **Do not install `qt6-wayland-dev-tools`.** `qtwaylandscanner` now ships in `qt6-base-dev-tools`, and
  the older 6.9.2 package `Breaks:` against it, making the transaction unsatisfiable.

For other distributions, see [INSTALLATION.md](./INSTALLATION.md), which lists the CMake packages the
build actually looks for so you can map them to your own package names.

### 2. Build and install

```bash
cmake -B build -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_L10N_AUTO_TRANSLATIONS=OFF
cmake --build build -j$(nproc)
sudo cmake --install build
```

The bundled `install.sh` does the same thing if you prefer (`sh install.sh`, or `sh install.sh Debug`).

`/usr` is not optional in practice. Latte is a `Plasma::Corona` host plus a set of KPackages that
Plasma loads **by installed plugin id**, not from the source tree, so the packages have to land
somewhere Plasma searches.

### 3. Run it

```bash
latte-dock --replace --clear-cache
```

- `--replace` takes over from an already running instance.
- `--clear-cache` drops Plasma's QML disk cache. **Always pass it after reinstalling**, otherwise you
  can keep running the previously cached QML and think your change did nothing.
- Add `-d` / `--debug` to print debug output to stdout.

After the first run, launch **Latte Dock** from the applications menu as usual.

### Rebuilding after a change

QML lives in installed KPackages, so editing a `.qml` in the source tree has **no effect** until you
reinstall:

```bash
cmake --build build -j$(nproc) && sudo cmake --install build && latte-dock --replace --clear-cache
```

### Uninstall

```bash
sh uninstall.sh          # uses build/install_manifest.txt
```

### Note on Debug builds

`-DCMAKE_BUILD_TYPE=Debug` adds a `qmllint` pass over every QML file **and defines
`QT_FATAL_WARNINGS`**, which turns any QML warning into a hard abort at runtime. Useful for finding
QML problems, unusable for daily driving. Build **Release** unless you specifically want that.


Current state
=============

Working and exercised on Plasma 6 / Wayland: dock rendering and the parabolic zoom, left/middle/right
click, the task context menu, thin tooltips and window previews, MPRIS media controls, both settings
dialogs, edit mode (max-length ruler, alignment controls, applet drag, all config tabs), multi-screen
placement with correct per-output struts, per-activity layouts in *multiple* memory mode, and the
AutoHide / DodgeActive / DodgeMaximized / DodgeAllWindows visibility modes.

Known remaining issues, and the developer-facing notes on the port, are kept in
[CLAUDE.md](./CLAUDE.md).


Alternatives on Plasma 6
========================

If you would rather use something actively developed for Plasma 6 than a port of an unmaintained
project, these two are worth knowing about:

- **[krema](https://github.com/isac322/krema)** — a standalone dock for Plasma 6 written in C++,
  describing itself as a spiritual successor to Latte Dock. Wayland and layer-shell oriented, so it is
  the closest equivalent to what this repository is: a separate dock process rather than a panel
  widget.
- **[WaveTask](https://github.com/vickoc911/org.vicko.wavetask)** — a Plasma *applet*, not a separate
  dock. It is an icons-only task manager with macOS-style parabolic zoom that you add to an ordinary
  Plasma panel. If the zoom effect is the part of Latte you actually want, this gets you it without
  running a second shell process.

Neither is affiliated with this fork; check their own documentation for requirements and status.


Development
============

- Upstream KDE repo (Qt 5 line): https://invent.kde.org/plasma/latte-dock
- Upstream bug reports: https://bugs.kde.org/enter_bug.cgi?product=lattedock

Bugs in *this* port are not upstream's; please do not file them against KDE.

[CLAUDE.md](./CLAUDE.md) documents the architecture, the Plasma 5 → 6 API split that drove most of the
work, and the Qt 6 traps that fail silently. Read it before touching the QML.


Packages from distributions
===========================

The packages below are the **old Qt 5 / Plasma 5 release**, not this port. They are listed for
reference only; installing one will not give you this branch.

- [Ubuntu](https://packages.ubuntu.com/search?keywords=latte-dock)
- [openSUSE](https://software.opensuse.org/package/latte-dock?search_term=latte+dock)
- [Fedora](https://koji.fedoraproject.org/koji/packageinfo?packageID=24229)
- [Arch Linux](https://aur.archlinux.org/packages/latte-dock)
- [Gentoo](https://packages.gentoo.org/packages/kde-misc/latte-dock)
- [Void Linux](https://github.com/void-linux/void-packages/tree/master/srcpkgs/latte-dock)
- [FreeBSD Port](https://www.freshports.org/deskutils/latte-dock/)


Contributors
============
[Varlesh](https://github.com/varlesh): Logos and Icons.
