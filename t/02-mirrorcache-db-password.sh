#!lib/test-in-container-systemd.sh mariadb

set -ex

# hack the pillar
echo "
mysql:
  user:
    mirrorcache:
      password: mypass123
" > /srv/pillar/testpreset.sls

salt-call --local pillar.get mysql:user:mirrorcache:password

salt-call --local pillar.item mysql:user:mirrorcache:password | grep mypass123

pass=$(echo $(salt-call --local pillar.get mysql:user:mirrorcache:password) | tail -n 1 | grep -Eo '[^ ]+$')
test "$pass" == mypass123

salt-call --local state.apply 'mirrorcache.mariadb'

set -a
shopt -s expand_aliases
alias sql="mariadb -h 127.0.0.1 -umirrorcache -p$pass -e"
(

sql 'select user(), current_user(), version()'

echo test access denied to mysql database
rc=0
sql 'select user, host from mysql.user' || rc=$?
test "$rc" -gt 0

echo test wrong password is denied
rc=0
sql 'select user(), current_user(), version()' -p"wrongpassword" || rc=$?
test "$rc" -gt 0
)

rcmariadb status

echo success
