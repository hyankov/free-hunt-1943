#!/bin/bash
# Free Hunt 1943 updater for the R36S and other PortMaster handhelds.
# Put this file in your ports folder (e.g. roms/ports/) and run it from the Ports menu.
# Needs Wi-Fi. Downloads the newest release and installs it over the old one.
# Your settings (freehunt1943.cfg) and logbook are kept. If you already have the newest
# version it says so and downloads nothing.

REPO="https://github.com/hyankov/free-hunt-1943"
URL="$REPO/releases/latest/download/freehunt1943.zip"

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}
if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi
source "$controlfolder/control.txt"

PORTS="/$directory/ports"
TMP="$PORTS/.freehunt1943-update.zip"
OUT=/dev/tty1
[ -w "$OUT" ] || OUT=/dev/stdout
say() { printf '%s\n' "$*" > "$OUT"; echo "$*"; }

printf '\033c' > "$OUT" 2>/dev/null
say "Free Hunt 1943 updater"

# Which version is installed (every release writes it; older installs have none)?
installed=$(cat "$PORTS/freehunt1943/version.txt" 2>/dev/null | tr -d ' \r\n')
# Which is the newest? GitHub redirects .../releases/latest to .../releases/tag/beta-<version>.
latest=""
if command -v curl >/dev/null; then
  latest=$(curl -fsSIL -o /dev/null -w '%{url_effective}' --connect-timeout 15 "$REPO/releases/latest" 2>/dev/null)
elif command -v wget >/dev/null; then
  latest=$(wget -S --spider -T 15 "$REPO/releases/latest" 2>&1 | grep -i '^ *location:' | tail -1)
fi
latest=$(printf '%s' "$latest" | sed -n 's#.*/releases/tag/beta-\([0-9.-]*\).*#\1#p')

if [ -n "$latest" ] && [ "$latest" = "$installed" ]; then
  say "Already up to date ($installed)."
  sleep 3
  exit 0
fi
if [ -n "$latest" ]; then
  say "Updating ${installed:-unknown version} -> $latest"
fi
say "Downloading the latest version..."

rm -f "$TMP"
ok=0
if command -v curl >/dev/null; then
  curl -fsSL --connect-timeout 15 -o "$TMP" "$URL" && ok=1
fi
if [ $ok = 0 ] && command -v wget >/dev/null; then
  wget -q -T 15 -O "$TMP" "$URL" && ok=1
fi

if [ $ok = 0 ] || ! unzip -tq "$TMP" >/dev/null 2>&1; then
  rm -f "$TMP"
  say "Download failed."
  say "Check that Wi-Fi is on and the date and time are right"
  say "(a wrong clock makes secure downloads fail)."
  sleep 6
  exit 1
fi

say "Installing..."
# The zip holds FreeHunt1943.sh and the freehunt1943/ folder; saved settings are not in it.
if $ESUDO unzip -oq "$TMP" -d "$PORTS"; then
  rm -f "$TMP"
  chmod +x "$PORTS/FreeHunt1943.sh" "$PORTS/freehunt1943/freehunt1943.aarch64" 2>/dev/null
  sync
  say "Done! Free Hunt 1943 is up to date${latest:+ ($latest)}."
else
  rm -f "$TMP"
  say "Install failed (could not write to $PORTS)."
fi
sleep 3
