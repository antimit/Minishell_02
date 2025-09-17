#!/usr/bin/env bash
# Usage: ./extra_tests.sh [path_to_minishell]
# If no argument given, assumes ./minishell in current directory.

MINI=${1:-./minishell}
BASH_BIN=$(command -v bash)

if [ ! -x "$MINI" ]; then
  echo "Minishell binary '$MINI' not found or not executable" >&2
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Helper: strip minishell prompt and lone 'exit' lines so outputs are comparable
clean() {
  # remove interactive prompt lines like "minishell$ cmd", plain "minishell$" and lone "exit"
  sed -e '/^minishell\$/d' \
      -e '/^minishell\$ .*/d' \
      -e '/^exit$/d' \
      -e '/^$/d'
}

# List of non-interactive test lines
read -r -d '' TESTS <<'EOF'
echo bonjour ; |
echo bonjour | |
|
echo bonjour |;
echo bonjour ; ls
echo bonjour > test\ 1
cd $HOME/Documents
echo "\s" & echo "\s"
echo >
echo -n -n -nnnn -nnnnm
cat /dev/random | head -n 1 | cat -e
unset var1
export ""
unset ""
echo test > file test1
$
not_cmd bonjour > salut
env; export VAR1=42; env
echo bonjour >>> test
echo bonjour > > out
echo 2 >> out1 > out2
echo 2 > out1 >> out2
cat < test
export var; export var=test
echo bonjour > $test
file_name_in_current_dir
cd ../../../../../.. ; pwd
echo "bip | bip ; coyotte > < " ""
cat | cat | cat | ls
$bla
export var ="cat Makefile | grep >"
export "test=ici"=coucou
c$var Makefile
$LESS$VAR
/bin/echo bonjour
not_cmd
sleep 5 | exit
echo bonjour > $test
"exit retour a la ligne"
minishell
cat diufosgid
exit
exit -10
exit +10
;
echo coucou | ;
echo "$HOME"
echo '$HOME'
export ; env
echo $HOME
> log echo coucou
echo hudifg d | | hugdfihd
echo
echo simple
echo -n simple
echo ''
echo ""
echo "\"\"
echo "\n \n \n"
echo "\n \n \\n"
echo ;;
echo hi";" hihi
echo hi " ; " hihi
cd
cd .
cd ~
cd /
cd no_file
cd a b c d
pwd a
pwd a b c d
export LOL=lala ROR=rara
unset LOL ROR
export "HI= hi"
export "HI =hi"
/bin/ls
echo $?
echo |
| echo
sort | ls
cat < >
cat < <
cat > >
> a ls > b < Makefile
echo > a Hello World!
> a echo Hello World!
cat < Makefile | grep gcc > output
exit 0 | exit 1
exit 1 | exit 0
EOF

# Iterate over tests
IFS=$'\n'
count=0
while read -r line; do
  ((count++)) || true
  printf '\n============== Test %d =============\n' "$count"
  echo "Cmd: $line"
  # minishell
  printf '%s\nexit\n' "$line" | $MINI  | clean >"$TMP_DIR/mini_out" 2>"$TMP_DIR/mini_err"
  mini_status=$?
  # bash
  printf '%s\nexit\n' "$line" | $BASH_BIN | clean >"$TMP_DIR/bash_out" 2>"$TMP_DIR/bash_err"
  bash_status=$?
  # Compare
  if diff -q "$TMP_DIR/bash_out" "$TMP_DIR/mini_out" >/dev/null && diff -q "$TMP_DIR/bash_err" "$TMP_DIR/mini_err" >/dev/null && [ $mini_status -eq $bash_status ]; then
    echo "✅ Match (status=$mini_status)"
  else
    echo "❌ Mismatch"
    echo "-- mini stdout --"; cat "$TMP_DIR/mini_out"
    echo "-- bash stdout --"; cat "$TMP_DIR/bash_out"
    echo "-- mini stderr --"; cat "$TMP_DIR/mini_err"
    echo "-- bash stderr --"; cat "$TMP_DIR/bash_err"
    echo "mini status: $mini_status  bash status: $bash_status"
  fi
  # avoid files piling up
  : >"$TMP_DIR/mini_out"; : >"$TMP_DIR/mini_err"; : >"$TMP_DIR/bash_out"; : >"$TMP_DIR/bash_err"
  # small pause for readability with heavy loops
  sleep 0.02

# optional early exit debug:
#  read -p "Press enter for next" _

done <<< "$TESTS" 