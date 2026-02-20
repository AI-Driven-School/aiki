#!/usr/bin/env bash
# record-demo.sh - Record the viral demo as .cast + .gif
# Usage: bash landing/record-demo.sh
#
# For best results, run this in a real terminal (not piped):
#   1. Open Terminal.app or iTerm2
#   2. Set font size to 16pt, window to 80x24
#   3. Run: bash landing/record-demo.sh
#   4. Files saved to landing/demo.cast + landing/demo.gif

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== aiki Demo Recorder ==="
echo ""
echo "Output: landing/demo.cast + landing/demo.gif"
echo ""

# Check dependencies
for cmd in asciinema agg; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Missing: $cmd (brew install $cmd)"
        exit 1
    fi
done

# Record
echo "Recording..."
asciinema rec \
    --cols 80 \
    --rows 24 \
    --overwrite \
    -c "bash '$SCRIPT_DIR/scripts/demo-mode.sh'" \
    "$SCRIPT_DIR/landing/demo.cast"

echo ""
echo "Converting to GIF..."
agg \
    --cols 80 \
    --rows 24 \
    --font-size 16 \
    --speed 1.0 \
    "$SCRIPT_DIR/landing/demo.cast" \
    "$SCRIPT_DIR/landing/demo.gif"

echo ""
echo "Done!"
ls -lh "$SCRIPT_DIR/landing/demo.cast" "$SCRIPT_DIR/landing/demo.gif"
echo ""
echo "Next steps:"
echo "  1. Preview: open landing/demo.gif"
echo "  2. Upload to asciinema.org: asciinema upload landing/demo.cast"
echo "  3. Post on X/Twitter with the GIF"
