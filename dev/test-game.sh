#!/usr/bin/env bash
# Run the in-game tests in Docker. Extra arguments go to `factorio-test run`.
set -euo pipefail

FACTORIO_VERSION="${FACTORIO_VERSION:-2.1.23}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE="microcircuits-test:$FACTORIO_VERSION"

docker build -q -t "$IMAGE" --build-arg "FACTORIO_VERSION=$FACTORIO_VERSION" "$ROOT/dev" >/dev/null

args=(
    --rm
    -u "$(id -u):$(id -g)"
    -e HOME=/tmp/home
    -e CI
    -e NPM_CONFIG_UPDATE_NOTIFIER=false
    -e FACTORIO_USERNAME
    -e FACTORIO_TOKEN
    -v "$ROOT":/mod
)
# Mod portal credentials, used to download the test dependencies (flib, factorio-test)
if [ -f "$HOME/.factorio/player-data.json" ]; then
    args+=(-v "$HOME/.factorio/player-data.json":/tmp/home/.factorio/player-data.json:ro)
fi

docker run "${args[@]}" "$IMAGE" sh -c '
    set -e
    [ -d node_modules ] || npm ci --no-audit --no-fund
    exec npx --no-install factorio-test run \
        --factorio-path "$FACTORIO_PATH" \
        --data-directory .factorio-test-data "$@"
' sh "$@"
