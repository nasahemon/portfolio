#!/usr/bin/env bash
# Smoke test a deployment before it is promoted to production.
# Usage: scripts/smoke-test.sh <deployment-url>
# Optional env: VERCEL_AUTOMATION_BYPASS_SECRET (needed when Vercel Deployment Protection is on).
set -euo pipefail

url="${1:?usage: smoke-test.sh <deployment-url>}"
url="${url%/}"
curl_args=(--silent --show-error --max-time 20 --retry 3 --retry-delay 3)
if [[ -n "${VERCEL_AUTOMATION_BYPASS_SECRET:-}" ]]; then
  curl_args+=(-H "x-vercel-protection-bypass: ${VERCEL_AUTOMATION_BYPASS_SECRET}")
fi

fail() { echo "❌ $*" >&2; exit 1; }

echo "Smoke testing ${url}"

# 1. Home page is up and is the right page.
# A new deployment URL can return 404 for a few seconds while it propagates, so wait up to ~60s.
for _ in $(seq 1 12); do
  status=$(curl "${curl_args[@]}" -o /tmp/home.html -w '%{http_code}' "${url}/")
  [[ "$status" == "200" ]] && break
  echo "… home page returned ${status}, waiting for deployment to be ready"
  sleep 5
done
[[ "$status" == "200" ]] || fail "home page returned ${status}"
grep -q "Hasibul Hasan Emon" /tmp/home.html || fail "home page content missing"
echo "✅ home page 200 with expected content"

# 2. Static assets are served.
for path in /styles.css /main.js /assets/favicon.svg; do
  s=$(curl "${curl_args[@]}" -o /dev/null -w '%{http_code}' "${url}${path}")
  [[ "$s" == "200" ]] || fail "${path} returned ${s}"
done
echo "✅ static assets 200"

# 3. Security headers are present.
headers=$(curl "${curl_args[@]}" -D - -o /dev/null "${url}/")
for h in content-security-policy strict-transport-security x-content-type-options referrer-policy; do
  grep -qi "^${h}:" <<<"$headers" || fail "missing header: ${h}"
done
echo "✅ security headers present"

# 4. Unknown paths return 404 (not a 200 soft-error).
s=$(curl "${curl_args[@]}" -o /dev/null -w '%{http_code}' "${url}/this-page-does-not-exist")
[[ "$s" == "404" ]] || fail "unknown path returned ${s}, expected 404"
echo "✅ 404 handling"

echo "All smoke tests passed."
