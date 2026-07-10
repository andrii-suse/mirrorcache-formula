#!lib/test-in-container-systemd.sh mariadb

set -ex

# hack the pillar with multiple hosts
echo "
mysql:
  user:
    mirrorcache:
      password: multihostpass123
      host:
        - localhost
        - 127.0.0.1
" > /srv/pillar/testpreset.sls

salt-call --local pillar.get mysql:user:mirrorcache:host

salt-call --local state.apply 'mirrorcache.mariadb'

# Verify that both users exist and have been granted the database
# In MariaDB, we can log in with -h localhost and -h 127.0.0.1
mariadb -h localhost -umirrorcache -pmultihostpass123 -e "select user(), current_user()"
mariadb -h 127.0.0.1 -umirrorcache -pmultihostpass123 -e "select user(), current_user()"

# Check wrong password is denied on both hosts
rc=0
mariadb -h localhost -umirrorcache -pwrongpassword -e "select 1" || rc=$?
test "$rc" -gt 0

rc=0
mariadb -h 127.0.0.1 -umirrorcache -pwrongpassword -e "select 1" || rc=$?
test "$rc" -gt 0

# Check access to the mirrorcache database
mariadb -h localhost -umirrorcache -pmultihostpass123 -D mirrorcache -e "show tables"
mariadb -h 127.0.0.1 -umirrorcache -pmultihostpass123 -D mirrorcache -e "show tables"

rcmariadb status

echo success
