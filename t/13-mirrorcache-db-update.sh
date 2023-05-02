#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache mariadb

set -ex

PASS=mypass12

# package might be already installed
mariadb --version || zypper -n in mariadb
rcmariadb start
mariadb -e 'create database mirrorcache'
mariadb -e "create user mirrorcache@localhost identified by '$PASS'"
mariadb -e "grant all on mirrorcache.* to mirrorcache@localhost; flush privileges;"

mariadb -h 127.0.0.1 -umirrorcache -p$PASS -e 'select user(), current_user(), database()' mirrorcache

# hack the pillar
echo "
mysql:
  user:
    mirrorcache:
      password: $PASS
" > /srv/pillar/testpreset.sls

salt-call --local state.apply 'mirrorcache.mariadb'
salt-call --local state.apply 'mirrorcache.webui'
salt-call --local state.apply 'mirrorcache.backstage'

curl -s 127.0.0.1:3000/update/?json | grep leap

rcmirrorcache-hypnotoad stop
rcmirrorcache-backstage stop

echo apply now apply states again and make sure the serice survives
salt-call --local state.apply 'mirrorcache.webui'
salt-call --local state.apply 'mirrorcache.backstage'
salt-call --local state.apply 'mirrorcache.mariadb'

curl -s 127.0.0.1:3000/distribution/?json | grep -i leap

echo success
