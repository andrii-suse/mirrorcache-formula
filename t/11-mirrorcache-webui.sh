#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache mariadb

set -ex

zypper -vn in mariadb && rcmariadb start
mariadb -e 'create database mirrorcache'
mariadb -e 'create user mirrorcache@localhost'
mariadb -e 'grant all on mirrorcache.* to mirrorcache@localhost'
salt-call -l debug --local state.apply 'mirrorcache.webui'

test -f /etc/mirrorcache/conf.env
grep MIRRORCACHE_ROOT /etc/mirrorcache/conf.env

rc=0
grep MIRRORCACHE_BACKSTAGE_WORKERS /etc/mirrorcache/conf.env || rc=$?
test $rc -gt 0

curl -si 127.0.0.1:3000/?json
curl -s 127.0.0.1:3000/?json | grep repositories

grep MIRRORCACHE_INI=/etc/mirrorcache/conf.ini /etc/mirrorcache/conf.env
grep root=http://download.opensuse.org /etc/mirrorcache/conf.ini

echo success
