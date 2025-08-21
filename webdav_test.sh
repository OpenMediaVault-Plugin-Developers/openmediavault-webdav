#!/usr/bin/env bash
# WebDAV smoke/regression tester (curl + optional cadaver/davix)
# - Redirect: /webdav -> /webdav/
# - OPTIONS, PROPFIND, MKCOL, PUT, COPY, MOVE, DELETE
# - LOCK/UNLOCK: exclusive write lock; PUT without token should 423; PUT with If: token should 201/204
# - Second client: cadaver (batch) if installed; optional davix if installed

set -euo pipefail

# -------- config / CLI --------
BASE_URL="http://localhost/webdav"
USER=""
PASS=""
VERBOSE=0
USE_CADAVER=1
USE_DAVIX=1

usage() {
  cat <<EOF
Usage: $0 [-b BASE_URL_NO_TRAILING_SLASH] [-u USER] [-p PASS] [-v] [--no-cadaver] [--no-davix]
Example:
  $0 -b http://localhost/webdav -u myuser -p mypass
Notes:
  * BASE_URL should be the NON-slash form; the script tests both /webdav and /webdav/
  * Install 'cadaver' (Debian/Ubuntu: apt install cadaver) for the second-client test
  * Install 'davix' (e.g., 'davix-put') for an additional second-client test (optional)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b) BASE_URL="${2%/}"; shift 2 ;;
    -u) USER="$2"; shift 2 ;;
    -p) PASS="$2"; shift 2 ;;
    -v) VERBOSE=1; shift ;;
    --no-cadaver) USE_CADAVER=0; shift ;;
    --no-davix) USE_DAVIX=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

AUTH_ARGS=()
if [[ -n "$USER" || -n "$PASS" ]]; then
  AUTH_ARGS=(-u "$USER:$PASS")
fi

SLASH_URL="${BASE_URL}/"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

TESTFILE_LOCAL="$TMPDIR/testfile.txt"
printf "hello webdav %s\n" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$TESTFILE_LOCAL"

TESTCOL="testcol-$$"
TESTFILE_REMOTE="testfile-$$.txt"
COPYFILE_REMOTE="testfile-copy-$$.txt"
MOVEFILE_REMOTE="testfile-moved-$$.txt"
LOCK_FILE="${TESTCOL}/lock-target-$$.txt"

# files used by run_curl()
HEADERS_FILE="$TMPDIR/headers.txt"
BODY_FILE="$TMPDIR/body.bin"

# -------- helpers --------
hr() { printf '%*s\n' 70 | tr ' ' -; }
title() { echo; hr; echo ">>> $*"; hr; }

# run_curl METHOD URL [extra curl args...]
# writes headers to $HEADERS_FILE, body to $BODY_FILE, and ECHOs HTTP code
run_curl() {
  : > "$HEADERS_FILE"
  : > "$BODY_FILE"
  local method="$1"; shift
  local url="$1"; shift
  local curl_args=(-X "$method" "${AUTH_ARGS[@]}" "$url" "$@")
  if [[ $VERBOSE -eq 1 ]]; then
    # verbose prints to stderr; still capture code and write headers/body
    curl -sS "${curl_args[@]}" -D "$HEADERS_FILE" -o "$BODY_FILE" -w "%{http_code}" || true
  else
    curl -sS "${curl_args[@]}" -D "$HEADERS_FILE" -o "$BODY_FILE" -w "%{http_code}" || true
  fi
}

expect() {
  local code="$1"; shift
  local ok_codes="$1"; shift
  local msg="$*"
  if grep -qw "$code" <<<"$ok_codes"; then
    printf "  %-46s -> %s (OK)\n" "$msg" "$code"
  else
    printf "  %-46s -> %s (UNEXPECTED; expected: %s)\n" "$msg" "$code" "$ok_codes"
    # keep going; this is a tester
  fi
}

extract_lock_token() {
  # Prefer header: Lock-Token: <opaquelocktoken:...>
  local tok=""
  tok="$(grep -i '^Lock-Token:' "$HEADERS_FILE" 2>/dev/null | sed -E 's/^[Ll]ock-[Tt]oken:\s*<([^>]+)>.*/\1/' | tr -d '\r' || true)"
  if [[ -z "$tok" ]]; then
    tok="$(grep -Eo 'opaquelocktoken:[0-9a-fA-F-]+' "$BODY_FILE" 2>/dev/null | head -1 || true)"
  fi
  printf "%s" "$tok"
}

# -------- tests --------
title "1) Redirect behavior: /webdav (no slash) should 301/308 -> /webdav/"
code="$(run_curl PROPFIND "$BASE_URL" -H "Depth: 0")"
expect "$code" "301 308" "PROPFIND $BASE_URL (no slash)"
# Try to show Location header without tripping -e/pipefail
loc="$(grep -i '^Location:' "$HEADERS_FILE" 2>/dev/null | awk '{print $2}' | tr -d '\r' || true)"
printf "  %-46s -> %s\n" "Location header" "${loc:-<none>}"

title "2) OPTIONS and PROPFIND on /webdav/"
code="$(run_curl OPTIONS "$SLASH_URL")"
expect "$code" "200 204" "OPTIONS $SLASH_URL"
code="$(run_curl PROPFIND "$SLASH_URL" \
  -H "Depth: 0" -H 'Content-Type: text/xml; charset="utf-8"' \
  --data-binary @- <<<'<?xml version="1.0"?><propfind xmlns="DAV:"><allprop/></propfind>')"
expect "$code" "207" "PROPFIND (Depth:0) $SLASH_URL"

title "3) MKCOL create a collection"
code="$(run_curl MKCOL "${SLASH_URL}${TESTCOL}")"
expect "$code" "201 405" "MKCOL ${SLASH_URL}${TESTCOL}"

title "4) PUT upload a file"
code="$(run_curl PUT "${SLASH_URL}${TESTCOL}/${TESTFILE_REMOTE}" --data-binary @"$TESTFILE_LOCAL")"
expect "$code" "201 204" "PUT ${SLASH_URL}${TESTCOL}/${TESTFILE_REMOTE}"

title "5) PROPFIND Depth:1 on collection"
code="$(run_curl PROPFIND "${SLASH_URL}${TESTCOL}/" \
  -H "Depth: 1" -H 'Content-Type: text/xml; charset="utf-8"' \
  --data-binary @- <<<'<?xml version="1.0"?><propfind xmlns="DAV:"><propname/></propfind>')"
expect "$code" "207" "PROPFIND (Depth:1) ${SLASH_URL}${TESTCOL}/"

title "6) COPY the file"
DEST_COPY="${SLASH_URL}${TESTCOL}/${COPYFILE_REMOTE}"
code="$(run_curl COPY "${SLASH_URL}${TESTCOL}/${TESTFILE_REMOTE}" -H "Destination: ${DEST_COPY}")"
expect "$code" "201 204" "COPY -> ${COPYFILE_REMOTE}"

title "7) MOVE the file"
DEST_MOVE="${SLASH_URL}${TESTCOL}/${MOVEFILE_REMOTE}"
code="$(run_curl MOVE "${SLASH_URL}${TESTCOL}/${COPYFILE_REMOTE}" -H "Destination: ${DEST_MOVE}")"
expect "$code" "201 204" "MOVE ${COPYFILE_REMOTE} -> ${MOVEFILE_REMOTE}"

title "8) LOCK/UNLOCK on a file"
# Ensure target file exists
code="$(run_curl PUT "${SLASH_URL}${LOCK_FILE}" --data-binary @"$TESTFILE_LOCAL")"
expect "$code" "201 204" "PUT ${SLASH_URL}${LOCK_FILE}"

# Acquire exclusive write lock
LOCK_BODY='<?xml version="1.0" encoding="utf-8"?>
<d:lockinfo xmlns:d="DAV:">
  <d:lockscope><d:exclusive/></d:lockscope>
  <d:locktype><d:write/></d:locktype>
  <d:owner><d:href>webdav_smoketest</d:href></d:owner>
</d:lockinfo>'
code="$(run_curl LOCK "${SLASH_URL}${LOCK_FILE}" \
  -H 'Content-Type: text/xml; charset="utf-8"' \
  --data-binary @- <<<"$LOCK_BODY")"
expect "$code" "200 201" "LOCK ${SLASH_URL}${LOCK_FILE}"
LOCK_TOKEN="$(extract_lock_token)"
printf "  %-46s -> %s\n" "Lock-Token" "${LOCK_TOKEN:-<none found>}"

# Attempt write WITHOUT lock (ideally 423)
code="$(run_curl PUT "${SLASH_URL}${LOCK_FILE}" --data-binary @- <<<"unauthorized write $(date -u)")"
expect "$code" "423 409" "PUT without lock token (expect 423/409)"

# Attempt write WITH lock using If: header
if [[ -n "$LOCK_TOKEN" ]]; then
  code="$(run_curl PUT "${SLASH_URL}${LOCK_FILE}" \
    -H "If: (<${LOCK_TOKEN}>)" \
    --data-binary @- <<<"authorized write $(date -u)")"
  expect "$code" "204 201" "PUT with If: (<token>)"
else
  echo "  Skipping PUT with lock (no token parsed)."
fi

# UNLOCK
if [[ -n "$LOCK_TOKEN" ]]; then
  code="$(run_curl UNLOCK "${SLASH_URL}${LOCK_FILE}" -H "Lock-Token: <${LOCK_TOKEN}>")"
  expect "$code" "204 200" "UNLOCK ${SLASH_URL}${LOCK_FILE}"
else
  echo "  Skipping UNLOCK (no token parsed)."
fi

title "9) DELETE file and collection"
code="$(run_curl DELETE "${SLASH_URL}${TESTCOL}/${TESTFILE_REMOTE}")"
expect "$code" "204 200 404" "DELETE file ${TESTFILE_REMOTE}"
code="$(run_curl DELETE "${SLASH_URL}${TESTCOL}/${MOVEFILE_REMOTE}")"
expect "$code" "204 200 404" "DELETE file ${MOVEFILE_REMOTE}"
code="$(run_curl DELETE "${SLASH_URL}${LOCK_FILE}")"
expect "$code" "204 200 404" "DELETE file lock-target"
code="$(run_curl DELETE "${SLASH_URL}${TESTCOL}/")"
expect "$code" "204 200 404" "DELETE collection ${TESTCOL}/"

title "10) Sanity re-check"
code="$(run_curl PROPFIND "$SLASH_URL" \
  -H "Depth: 0" -H 'Content-Type: text/xml; charset="utf-8"' \
  --data-binary @- <<<'<propfind xmlns="DAV:"><propname/></propfind>')"
expect "$code" "207" "PROPFIND $SLASH_URL"
code="$(run_curl PROPFIND "$BASE_URL" \
  -H "Depth: 0" -H 'Content-Type: text/xml; charset="utf-8"' \
  --data-binary @- <<<'<propfind xmlns="DAV:"><propname/></propfind>')"
expect "$code" "301 308" "PROPFIND $BASE_URL (no slash)"

# -------- Second client(s) --------
# cadaver
if [[ $USE_CADAVER -eq 1 && -x "$(command -v cadaver)" ]]; then
  title "11) Second client (cadaver) batch test"
  CAD_URL="$SLASH_URL"
  if [[ -n "$USER" || -n "$PASS" ]]; then
    proto="$(printf "%s" "$BASE_URL" | sed -E 's#^(https?)://.*#\1#')"
    hostpath="$(printf "%s" "$BASE_URL" | sed -E 's#^https?://##')"
    CAD_URL="${proto}://${USER}:${PASS}@${hostpath}/"
  fi
  CAD_SCRIPT="$TMPDIR/cad.commands"
  {
    echo "open $CAD_URL"
    echo "mkcol cadaver-$TESTCOL"
    echo "cd cadaver-$TESTCOL"
    echo "put $TESTFILE_LOCAL cadaver-$TESTFILE_REMOTE"
    echo "lock cadaver-$TESTFILE_REMOTE"
    echo "unlock cadaver-$TESTFILE_REMOTE"
    echo "rm cadaver-$TESTFILE_REMOTE"
    echo "cd .."
    echo "rmdir cadaver-$TESTCOL"
    echo "quit"
  } > "$CAD_SCRIPT"

  if cadaver < "$CAD_SCRIPT" >/dev/null 2>&1; then
    echo "  cadaver batch: OK"
  else
    echo "  cadaver batch: FAILED (run with -v and manually retry to inspect)"
  fi
else
  echo "Note: cadaver not run (missing or disabled)."
fi

# davix (optional)
if [[ $USE_DAVIX -eq 1 && -x "$(command -v davix-put)" ]]; then
  title "12) Second client (davix) quick test"
  # davix does not speak LOCK/UNLOCK, but we can PUT/GET/LS/DEL
  DAVIX_AUTH=()
  if [[ -n "$USER" || -n "$PASS" ]]; then
    DAVIX_AUTH=(--user "$USER" --passwd "$PASS")
  fi
  davix-put "${DAVIX_AUTH[@]}" "$TESTFILE_LOCAL" "${SLASH_URL}davix-$TESTFILE_REMOTE" >/dev/null 2>&1 && echo "  davix PUT: OK" || echo "  davix PUT: FAILED"
  davix-ls  "${DAVIX_AUTH[@]}" "${SLASH_URL}" >/dev/null 2>&1 && echo "  davix LS : OK"  || echo "  davix LS : FAILED"
  davix-rm  "${DAVIX_AUTH[@]}" "${SLASH_URL}davix-$TESTFILE_REMOTE" >/dev/null 2>&1 && echo "  davix RM : OK"  || echo "  davix RM : FAILED"
else
  echo "Note: davix not run (missing or disabled)."
fi

echo
echo "Done."
