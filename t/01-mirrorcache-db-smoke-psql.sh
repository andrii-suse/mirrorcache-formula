#!lib/test-in-container-systemd.sh postgresql postgresql-server

set -ex

salt-call --local state.apply mirrorcache.postgres

rcpostgresql status
test mirrorcache == $(sudo -u postgres psql mirrorcache -P pager=off -t -c 'select current_database()')

echo success
