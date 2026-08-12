#!/usr/bin/env bash
# Drives lib/main_screenshots.dart on a booted simulator and grabs a frame
# every time the harness says a screen has settled.
#
# The harness announces its sandbox with SHOT_DOCS and then blocks until a
# go.txt appears there -- installing the build moves the container, so nothing
# can be seeded until it is on the device. It prints SHOT <name> once a screen
# has settled and dwells afterwards, which is the window this captures in.
set -uo pipefail

SIM="${SIM:-$(xcrun simctl list devices booted -j | python3 -c "import json,sys;d=json.load(sys.stdin)['devices'];print(next(x['udid'] for v in d.values() for x in v))")}"
PROJ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$PROJ/screenshots"
LOG="${LOG:-$(mktemp -t inventa-shots)}"

cd "$PROJ" || exit 1
rm -rf "$OUT"; mkdir -p "$OUT"
: > "$LOG"

flutter run -t lib/main_screenshots.dart -d "$SIM" ${DART_DEFINES:-} > "$LOG" 2>&1 &
RUN_PID=$!

gated=0
captured=0

# tail the log rather than piping flutter through the loop, so killing the
# reader at the end cannot leave flutter attached to a dead pipe.
tail -n +1 -f "$LOG" | while IFS= read -r line; do
  case "$line" in
    *SHOT_DOCS*)
      [ "$gated" -eq 1 ] && continue
      docs="${line#*SHOT_DOCS }"
      docs="$(printf '%s' "$docs" | tr -d '\r')"
      echo "GATE -> $docs/go.txt"
      touch "$docs/go.txt" && gated=1
      ;;
    *"SHOT done"*)
      echo "WALK COMPLETE ($captured captured)"
      kill "$RUN_PID" 2>/dev/null
      pkill -f "tail -n +1 -f $LOG" 2>/dev/null
      break
      ;;
    *SHOT_WARN*)
      echo "WARN ${line#*SHOT_WARN }"
      ;;
    *"SHOT "*)
      name="${line##*SHOT }"
      name="$(printf '%s' "$name" | tr -d '\r' | tr -cd 'a-zA-Z0-9._-')"
      [ -z "$name" ] && continue
      sleep 1.2
      if xcrun simctl io "$SIM" screenshot "$OUT/$name.png" >/dev/null 2>&1; then
        captured=$((captured + 1))
        echo "CAPTURED $name"
      else
        echo "CAPTURE FAILED $name"
      fi
      ;;
  esac
done

wait "$RUN_PID" 2>/dev/null
echo "DONE"
