#!/usr/bin/env bash
#
# Verifies the web image emits the required security headers on every response.
#
# Hermetic: builds a throwaway nginx:alpine image from the REAL docker/nginx.conf
# (plus docker/security-headers.conf when it exists) and tiny static fixtures, then
# curls "/", a ".js" and a ".png" and asserts each carries the headers. Using fixtures
# instead of build/web keeps it fast and isolates the nginx config under test.
#
# Requires Docker. Exit 0 = all headers present; 1 = a header missing/incorrect;
# 2 = environment/build problem.
set -euo pipefail

DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE="oc-web-headers-test:local"
NAME="oc-web-headers-test"
PORT="${PORT:-18080}"

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

# Assemble the build context: the real config + the snippet (if present) + fixtures.
cp "$DOCKER_DIR/nginx.conf" "$BUILD_DIR/nginx.conf"
SNIPPET_COPY=""
if [ -f "$DOCKER_DIR/security-headers.conf" ]; then
  cp "$DOCKER_DIR/security-headers.conf" "$BUILD_DIR/security-headers.conf"
  SNIPPET_COPY=$'RUN mkdir -p /etc/nginx/snippets\nCOPY security-headers.conf /etc/nginx/snippets/security-headers.conf'
fi
mkdir -p "$BUILD_DIR/html"
printf '<!doctype html><title>fixture</title>' > "$BUILD_DIR/html/index.html"
printf 'console.log(1);'                        > "$BUILD_DIR/html/app.js"
printf 'body{}'                                 > "$BUILD_DIR/html/style.css"
printf 'PNG'                                    > "$BUILD_DIR/html/icon.png"

cat > "$BUILD_DIR/Dockerfile" <<DOCKERFILE
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
${SNIPPET_COPY}
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

# Wait for nginx to accept connections.
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
check() { # check <path> <regex> <description>
  local path="$1" regex="$2" desc="$3" headers
  if ! headers="$(curl -sS --retry 3 --retry-connrefused -D - -o /dev/null "http://localhost:$PORT$path")"; then
    echo "ERROR [$path] request failed: $desc"
    fail=1
    return
  fi
  if printf '%s' "$headers" | grep -iqE "$regex"; then
    echo "ok   [$path] $desc"
  else
    echo "FAIL [$path] $desc"
    fail=1
  fi
}

for path in "/" "/app.js" "/icon.png"; do
  check "$path" '^Content-Security-Policy:'                                                  "CSP header present"
  check "$path" '^Content-Security-Policy:.*connect-src[^;]*storage\.googleapis\.com'        "CSP connect-src allows GCS (upload/playback)"
  check "$path" '^Content-Security-Policy:.*connect-src[^;]*fonts\.gstatic\.com'             "CSP connect-src allows CanvasKit font fallback (fonts.gstatic.com)"
  check "$path" '^Content-Security-Policy:.*connect-src[^;]*tripod-backend\.shemaywam\.com'  "CSP connect-src allows backend"
  check "$path" "^Content-Security-Policy:.*script-src[^;]*'wasm-unsafe-eval'"               "CSP script-src allows wasm-unsafe-eval (CanvasKit)"
  check "$path" '^X-Content-Type-Options: *nosniff'                                          "X-Content-Type-Options: nosniff"
  check "$path" '^Referrer-Policy: *strict-origin-when-cross-origin'                         "Referrer-Policy"
  check "$path" '^X-Frame-Options: *SAMEORIGIN'                                              "X-Frame-Options: SAMEORIGIN"
done

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL — security headers missing or incorrect"
  exit 1
fi
echo "RESULT: PASS — required security headers present on /, .js and .png"
