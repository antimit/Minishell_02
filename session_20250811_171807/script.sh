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
