#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache postgresql postgresql-server

set -ex

zypper -vn in postgresql postgresql-server && rcpostgresql start
sudo -u postgres createdb mirrorcache
sudo -u postgres createuser mirrorcache

mkdir -p /srv/pillar
# hack the pillar
echo "
mirrorcache:
  db_provider: postgresql
" > /srv/pillar/testpreset.sls

salt-call --local state.apply 'mirrorcache.webui'

test -f /etc/mirrorcache/conf.env
grep MIRRORCACHE_ROOT /etc/mirrorcache/conf.env

rc=0
grep MIRRORCACHE_BACKSTAGE_WORKERS /etc/mirrorcache/conf.env || rc=$?
test $rc -gt 0

curl -si 127.0.0.1:3000/?json
curl -s 127.0.0.1:3000/?json | grep repositories

echo success
