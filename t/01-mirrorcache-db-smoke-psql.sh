#!lib/test-in-container-systemd.sh postgresql postgresql-server

set -ex

salt-call --local state.apply mirrorcache.postgres

rcpostgresql status
test mirrorcache == $(sudo -u postgres psql mirrorcache -P pager=off -t -c 'select current_database()')

useradd mirrorcache
test mirrorcache == $(sudo -u mirrorcache psql -P pager=off -t -c 'select current_database()')

echo test the user can create tables
sudo -u mirrorcache psql -P pager=off -t -c 'create table test1 as select 1'

echo success
