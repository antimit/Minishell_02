# baseline echo/pwd
pwd
echo hello world
echo -n no_newline; echo _tail

# env expansion
echo "USER=$USER"
echo '$USER'           # single quotes → literal
unset FOO 2>/dev/null
echo "[$FOO]"          # undefined → empty in double quotes

# status across commands
false
echo "st=$?"
true | false
echo "pipe_last=$?"

# builtins: export/unset/env
export FOO=bar
echo "FOO=$FOO"
env | grep '^FOO='
unset FOO
echo "FOO_after_unset=[$FOO]"

# cd and pwd
pwd
cd /
pwd
cd -
pwd

# redirs
echo A > __t1
echo B >> __t1
cat __t1

# pipes + redirs
printf 'a\nb\n' | wc -l > __lines
cat __lines

# heredoc (mandatory): should read until DELIM; content to cat
cat <<DELIM
L1
L2 $USER
DELIM

# exit at the end (interactive should exit)
exit
