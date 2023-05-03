#!lib/test-in-container-systemd.sh postgresql-server postgresql

set -ex

# hack the pillar
echo "
postgres:
  user:
    mirrorcache:
      password: mypass123
" > /srv/pillar/testpreset.sls

pass=$(echo $(salt-call --local pillar.get postgres:user:mirrorcache:password) | tail -n 1 | grep -Eo '[^ ]+$')
test "$pass" == mypass123

salt-call --local state.apply 'mirrorcache.postgres'
sed -E -i 's/(host\s+all\s+all\s+127.0.0.1\/32\s+)ident/\1md5/' /var/lib/pgsql/data/pg_hba.conf
rcpostgresql reload

set -a
shopt -s expand_aliases
alias sql="psql -d mirrorcache -U mirrorcache --host 127.0.0.1 -c"
(
export PGPASSWORD=$pass
sql 'select user, current_user, version()'

echo test access denied to system database
sql 'select * from pg_authid' -d postgres 2>&1 | grep 'permission denied'

echo test wrong password is denied
export PGPASSWORD=wrongpassword
rc=0
sql 'select user, current_user, version()' || rc=$?
test "$rc" -gt 0
)

rcpostgresql status

echo success
