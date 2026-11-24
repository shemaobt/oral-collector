#!/usr/bin/env bash
#
# Verifies the web image revalidates the files that keep their name across builds
# and keeps the long cache on the files whose name changes with their content.
#
# Hermetic: builds a throwaway nginx:alpine image from the REAL docker/nginx.conf and
# tiny fixtures, then curls each path. Requires Docker. Exit 0 = all correct;
# 1 = a header missing/incorrect; 2 = environment/build problem.
set -euo pipefail

DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="oc-web-cache-test:local"
NAME="oc-web-cache-test"
PORT="${PORT:-18081}"

if ! docker info >/dev/null 2>&1; then
  echo "SKIP: Docker daemon not available" >&2
  exit 2
fi

BUILD_DIR="$(mktemp -d)"
cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker rmi -f "$IMAGE" >/dev/null 2>&1 || true
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

cp "$DOCKER_DIR/nginx.conf" "$BUILD_DIR/nginx.conf"
cp "$DOCKER_DIR/security-headers.conf" "$BUILD_DIR/security-headers.conf"
mkdir -p "$BUILD_DIR/html/assets/fonts" "$BUILD_DIR/html/assets/images"
printf '<!doctype html><title>fixture</title>' > "$BUILD_DIR/html/index.html"
for f in main.dart.js flutter_bootstrap.js flutter.js sql-wasm.js sql-wasm.wasm; do
  printf 'x' > "$BUILD_DIR/html/$f"
done
printf 'x' > "$BUILD_DIR/html/assets/fonts/font.woff2"
printf 'x' > "$BUILD_DIR/html/assets/images/logo.png"

cat > "$BUILD_DIR/Dockerfile" <<'DOCKERFILE'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /etc/nginx/snippets
COPY security-headers.conf /etc/nginx/snippets/security-headers.conf
COPY html /usr/share/nginx/html
EXPOSE 8080
DOCKERFILE

if ! docker build -t "$IMAGE" "$BUILD_DIR" >"$BUILD_DIR/build.log" 2>&1; then
  echo "ERROR: docker build failed" >&2
  cat "$BUILD_DIR/build.log" >&2
  exit 2
fi

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" -p "$PORT:8080" "$IMAGE" >/dev/null

ready=0
for _ in $(seq 1 40); do
  if curl -fsS -o /dev/null "http://localhost:$PORT/" 2>/dev/null; then ready=1; break; fi
  sleep 0.25
done
if [ "$ready" -ne 1 ]; then
  echo "ERROR: nginx did not become ready" >&2
  docker logs "$NAME" >&2 || true
  exit 2
fi

fail=0
check() { # check <path> <expected Cache-Control>
  local path="$1" expected="$2" actual
  if ! actual="$(curl -sS --retry 3 --retry-connrefused -D - -o /dev/null "http://localhost:$PORT$path" \
    | tr -d '\r' | awk -F': *' 'tolower($1)=="cache-control"{print $2}' | paste -sd ',' -)"; then
    echo "ERROR [$path] request failed"
    fail=1
    return
  fi
  if [ "$actual" = "$expected" ]; then
    echo "ok   [$path] Cache-Control: $actual"
  else
    echo "FAIL [$path] Cache-Control: '$actual', expected '$expected'"
    fail=1
  fi
}

check "/"                           "no-cache"
for path in /index.html /main.dart.js /flutter_bootstrap.js /flutter.js /sql-wasm.js /sql-wasm.wasm; do
  check "$path" "no-cache"
done
check "/assets/fonts/font.woff2"    "max-age=31536000,public, immutable"
check "/assets/images/logo.png"     "max-age=31536000,public, immutable"

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL — cache headers incorrect"
  exit 1
fi
echo "RESULT: PASS — fixed-name files revalidate; content-named assets keep the long cache"
