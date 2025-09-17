#!/usr/bin/env bash
set -euo pipefail
MINISHELL="${1:-}"
if [[ -z "$MINISHELL" || ! -x "$MINISHELL" ]]; then
  echo "Usage: $0 /absolute/path/to/minishell" >&2; exit 2; fi

OUTDIR="heredoc_$(date +%Y%m%d_%H%M%S)"; mkdir -p "$OUTDIR"

# Minimal script that only checks heredoc behavior vs bash
SCPT="$OUTDIR/hd.sh"
cat > "$SCPT" <<'EOF'
cat <<DELIM
L1
L2 plain
DELIM
printf "X\n" | cat <<EOF2
Y
EOF2
exit
EOF

set +e
bash < "$SCPT" > "$OUTDIR/bash.out" 2> "$OUTDIR/bash.err";  bst=$?
"$MINISHELL" < "$SCPT" > "$OUTDIR/ms.out"  2> "$OUTDIR/ms.err"; mst=$?
set -e

echo "Heredoc outputs in: $OUTDIR"
if diff -u "$OUTDIR/bash.out" "$OUTDIR/ms.out" > "$OUTDIR/diff.out"; then
  echo "✅ heredoc: stdout matches"
else
  echo "❌ heredoc: see $OUTDIR/diff.out"
fi
if [[ -s "$OUTDIR/ms.err" ]]; then
  echo "--- minishell stderr (head) ---"; head -n 10 "$OUTDIR/ms.err"; echo "-------------------------------"
fi
