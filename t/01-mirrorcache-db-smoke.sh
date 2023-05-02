#!lib/test-in-container-systemd.sh mariadb

set -ex

salt-call --local state.apply mirrorcache.mariadb

rcmariadb status
test mirrorcache == $(mariadb --batch -Ne 'select database()' mirrorcache)

echo success
