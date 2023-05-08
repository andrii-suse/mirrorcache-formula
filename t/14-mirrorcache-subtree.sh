#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache mariadb

set -ex

mkdir -p /srv/pillar
# hack the pillar
echo "
mirrorcache:
  subtree: /update
  top_folders_subtree: '"leap tumbleweed"'
" > /srv/pillar/testpreset.sls

zypper -vn in mariadb && rcmariadb start
mariadb -e 'create database mirrorcache'
mariadb -e 'create user mirrorcache@localhost'
mariadb -e 'grant all on mirrorcache.* to mirrorcache@localhost'
salt-call -l debug --local state.apply 'mirrorcache.webui-subtree'

rcmirrorcache-subtree status || rcmirrorcache-subtree status

curl -si 127.0.0.1:3001/?json || echo $?
curl -si 127.0.0.1:3001/?json || sleep 2
curl -si 127.0.0.1:3001/?json || sleep 2
curl -si 127.0.0.1:3001/?json || sleep 1
curl -si 127.0.0.1:3001/?json || echo $?
curl -s 127.0.0.1:3001/?json | grep 'leap\\/'

echo success
