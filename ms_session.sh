#!/usr/bin/env bash
set -euo pipefail

MINISHELL="${1:-}"
if [[ -z "$MINISHELL" || ! -x "$MINISHELL" ]]; then
  echo "Usage: $0 /absolute/path/to/minishell" >&2
  exit 2
fi

OUTDIR="session_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"

# Strip ANSI + prompts from minishell output
STRIP() {
  sed -E $'s/\x1B\\[[0-9;]*[A-Za-z]//g' | sed -E 's/(^|^.*@.*:.*[$] )//'
}

SCPT="$OUTDIR/script.sh"
cat > "$SCPT" <<'EOF'
pwd
echo hello world
echo -n no_newline; echo _tail
echo "USER=$USER"
echo '$USER'
unset FOO
echo "[$FOO]"
false
echo "st=$?"
true | false
echo "pipe_last=$?"
export FOO=bar
echo "FOO=$FOO"
env | grep '^FOO='
unset FOO
echo "FOO_after_unset=[$FOO]"
pwd
cd /
pwd
cd -
pwd
echo A > __t1
echo B >> __t1
cat __t1
printf 'a\nb\n' | wc -l > __lines
cat __lines
exit
EOF

set +e
bash < "$SCPT" > "$OUTDIR/bash.out" 2> "$OUTDIR/bash.err";  bst=$?
"$MINISHELL" < "$SCPT" > "$OUTDIR/ms.raw"  2> "$OUTDIR/ms.err"; mst=$?
set -e

STRIP < "$OUTDIR/ms.raw" > "$OUTDIR/ms.out"

echo "Session outputs in: $OUTDIR"
echo "bash status: $bst   minishell status: $mst"
if diff -u "$OUTDIR/bash.out" "$OUTDIR/ms.out" > "$OUTDIR/diff.out"; then
  echo "✅ session: stdout matches"
else
  echo "❌ session: see $OUTDIR/diff.out"
fi
if [[ -s "$OUTDIR/ms.err" ]]; then
  echo "--- minishell stderr (head) ---"; head -n 10 "$OUTDIR/ms.err"; echo "-------------------------------"
fi
