#!/usr/bin/env bash
set -euo pipefail

MINISHELL="${1:-}"
if [[ -z "$MINISHELL" || ! -x "$MINISHELL" ]]; then
  echo "Usage: $0 /absolute/path/to/minishell" >&2
  exit 2
fi

OUTDIR="results_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"/{bash,ms,logs}

run_bash_c() { local n="$1" c="$2" st; set +e; bash -c "$c" >"$OUTDIR/bash/$n.out" 2>"$OUTDIR/bash/$n.err"; st=$?; set -e; echo "$st" >"$OUTDIR/bash/$n.status"; }
run_ms_c()   { local n="$1" c="$2" st; set +e; "$MINISHELL" -c "$c" >"$OUTDIR/ms/$n.out" 2>"$OUTDIR/ms/$n.err";   st=$?; set -e; echo "$st" >"$OUTDIR/ms/$n.status"; }

strict_compare() { local n="$1" any=0; for f in out err status; do if ! diff -u "$OUTDIR/bash/$n.$f" "$OUTDIR/ms/$n.$f" >"$OUTDIR/logs/$n.$f.diff" 2>/dev/null; then any=1; else rm -f "$OUTDIR/logs/$n.$f.diff"; fi; done; return $any; }

status_of() { cat "$1"; }
ok_err() { # $1=ms_status $2=want_status $3=stderr_file $4=regex
  [[ "$1" == "$2" ]] || return 1
  grep -E -q "$4" "$3"
}

report_strict() { local n="$1" c="$2"; run_bash_c "$n" "$c"; run_ms_c "$n" "$c"
  if strict_compare "$n"; then printf "✅ %-28s %s\n" "$n" "$c"
  else printf "❌ %-28s %s\n" "$n" "$c"; printf "   See diffs in %s/logs/%s.*.diff\n" "$OUTDIR" "$n"; fi; }

report_error() { local n="$1" c="$2" want="$3" re="$4"; run_bash_c "$n" "$c"; run_ms_c "$n" "$c"
  local st ms_err="$OUTDIR/ms/$n.err"; st="$(status_of "$OUTDIR/ms/$n.status")"
  if ok_err "$st" "$want" "$ms_err" "$re"; then printf "✅ %-28s %s\n" "$n" "$c"
  else printf "❌ %-28s %s\n   Expect: status=%s, stderr~/%s/\n   Got:    status=%s\n" "$n" "$c" "$want" "$re" "$st"; echo "   --- minishell stderr ---"; sed 's/^/   | /' "$ms_err" || true; echo "   ------------------------"; fi; }

# ---------- STRICT (success) ----------
STRICT_TESTS=(
  "t01_pwd::pwd"
  "t02_echo::echo hello"
  "t03_echo_n::echo -n hello"
  "t04_echo_spaces::echo '  a   b  '"
  "t05_path_exec::/bin/echo OK"
  # env expansion & quotes
  "t06_env_basic::echo \$USER"
  "t07_env_dq::echo \"user=\$USER\""
  "t08_env_sq::echo '\$USER'"
  "t09_unchanged_if_undef::unset FOO >/dev/null 2>&1; echo \"[\$FOO]\""
  # $? (last foreground pipeline status)
  "t10_status_simple::false; echo \$?"
  "t11_status_pipeline_last::false | true; echo \$?"
  "t12_status_pipeline_last2::true | false; echo \$?"
  # redirections
  "t13_redir_out::echo hi > $OUTDIR/f1; cat $OUTDIR/f1"
  "t14_redir_append::echo A > $OUTDIR/f2; echo B >> $OUTDIR/f2; cat $OUTDIR/f2"
  "t15_redir_in::printf 'xyz\n' > $OUTDIR/in; cat < $OUTDIR/in"
  # pipes
  "t16_pipe_simple::printf 'a\nb\n' | wc -l"
  "t17_pipe_chain::printf 'Abc\nxYz\n' | tr '[:lower:]' '[:upper:]' | grep Z"
  # pipe + redir
  "t18_pipe_to_file::printf 'a\nb\n' | wc -l > $OUTDIR/lines; cat $OUTDIR/lines"
  # builtins (non-stateful)
  "t19_builtin_pwd::pwd"
  "t20_builtin_echo_opt::echo -n foo"
  "t21_env_builtin::env | grep -E '^(PATH|USER)=' | head -n 1"
)

# ---------- ERROR (tolerant; exit+regex) ----------
# Expected per subject/bash:
# command not found → 127; syntax/redir errors → 2. :contentReference[oaicite:1]{index=1}
ERROR_TESTS=(
  "e01_cmd_not_found::___no_such_cmd___::127::(command not found)"
  "e02_trailing_pipe::echo hi |::2::(syntax error|unexpected token|unexpected end)"
  "e03_missing_redir_target::echo >::2::(syntax error.*newline)"
  "e04_toomany_redir_gt::echo hi >>> $OUTDIR/x::2::(syntax error.*[>])"
  "e05_toomany_redir_lt::cat <<< $OUTDIR/x::2::(syntax error.*[<])"
  "e06_pipe_double_bar::echo hi || echo bye::2::(syntax error|unexpected token)" # minishell (no || in mandatory)
)

echo "Writing outputs to: $OUTDIR/"
echo
for E in "${STRICT_TESTS[@]}"; do n="${E%%::*}"; cmd="${E#*::}"; report_strict "$n" "$cmd"; done
for E in "${ERROR_TESTS[@]}";  do n="${E%%::*}"; tmp="${E#*::}"; cmd="${tmp%%::*}"; tmp="${tmp#*::}"; want="${tmp%%::*}"; re="${tmp#*::}"; report_error "$n" "$cmd" "$want" "$re"; done
echo
echo "Done. Results in: $OUTDIR/"
echo " - Bash:      $OUTDIR/bash/"
echo " - Minishell: $OUTDIR/ms/"
echo " - Diffs:     $OUTDIR/logs/"
