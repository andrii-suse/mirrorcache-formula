#!lib/test-in-container-systemd.sh postgresql-server postgresql

set -ex

# Set up pillars including postgres:remote_host and custom remote_auth
echo "
postgres:
  user:
    mirrorcache:
      password: hba_test_pass
  remote_host: 192.168.12.34/32
  remote_auth: scram-sha-256
" > /srv/pillar/testpreset.sls

pass=$(echo $(salt-call --local pillar.get postgres:user:mirrorcache:password) | tail -n 1 | grep -Eo '[^ ]+$')
test "$pass" == hba_test_pass

# Apply our new postgres-hba state file!
salt-call --local state.apply 'mirrorcache.postgres-hba'

# Verify that pg_hba.conf was updated correctly by our Salt state
grep -E '^host\s+all\s+all\s+127\.0\.0\.1/32\s+md5' /var/lib/pgsql/data/pg_hba.conf
grep -E '^host\s+all\s+all\s+::1/128\s+md5' /var/lib/pgsql/data/pg_hba.conf
grep -E '^host\s+all\s+all\s+192\.168\.12\.34/32\s+scram-sha-256' /var/lib/pgsql/data/pg_hba.conf

# Verify PostgreSQL connection works with the password
set -a
shopt -s expand_aliases
alias sql="psql -d mirrorcache -U mirrorcache --host 127.0.0.1 -c"
(
export PGPASSWORD=$pass
sql 'select user, current_user, version()'

echo "test wrong password is denied"
export PGPASSWORD=wrongpassword
rc=0
sql 'select user, current_user, version()' || rc=$?
test "$rc" -gt 0
)

rcpostgresql status

echo "success"
