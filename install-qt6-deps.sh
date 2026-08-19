#!/bin/bash
# Build dependencies for the Qt6/KF6 port of Latte Dock (branch: qt6-port).
# Deliberately excludes qt6-wayland-dev-tools: qtwaylandscanner now ships in
# qt6-base-dev-tools, and the older 6.9.2 package Breaks against it.
set -e

PKGS=(
  qt6-base-dev
  qt6-declarative-dev
  qt6-wayland-dev

  libkf6archive-dev
  libkf6config-dev
  libkf6coreaddons-dev
  libkf6crash-dev
  libkf6dbusaddons-dev
  libkf6declarative-dev
  libkf6globalaccel-dev
  libkf6guiaddons-dev
  libkf6i18n-dev
  libkf6iconthemes-dev
  libkf6kio-dev
  libkf6newstuff-dev
  libkf6notifications-dev
  libkf6package-dev
  libkf6svg-dev
  libkf6windowsystem-dev
  libkf6xmlgui-dev
  libkirigami-dev

  libplasma-dev
  libplasmaactivities-dev
  # for the taskmanager Backend vendored into plasmoid/plugin/taskmanager
  libplasmaactivitiesstats-dev
  libksysguard-dev
  kwayland-dev
  plasma-workspace-dev
)

echo "Installing ${#PKGS[@]} packages..."
# -y because this is run non-interactively (no stdin for apt's prompt).
# Plan reviewed beforehand: 155 new, 14 upgraded, 0 removed, ~409 MB.
sudo apt install -y "${PKGS[@]}"
