#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache mariadb

set -ex

mkdir -p /srv/pillar
# hack the pillar
echo "
mirrorcache:
  root: /srv/mirrorcache/dt
  hashes_collect: 1
  zsync_collect: dat

mysql:
  user:
    mirrorcache:
      allow_passwordless: True
" > /srv/pillar/testpreset.sls

salt-call --local state.apply 'mirrorcache.mariadb'
salt-call --local state.apply 'mirrorcache.backstage' -l debug

ls -la /etc/mirrorcache
ls -la /etc/mirrorcache | grep 'drwxr-x--- 2 root mirrorcache 4096'

rcmirrorcache-backstage status || sleep 1
rcmirrorcache-backstage status || sleep 1
rcmirrorcache-backstage status || journalctl -u rcmirrorcache-backstage
rcmirrorcache-backstage status
rc=0
rcmirrorcache-hypnotoad || rc=$?
test $rc -gt 0

(
set -a
shopt -s expand_aliases
source /etc/mirrorcache/conf.env

test "$MIRRORCACHE_ROOT" == /srv/mirrorcache/dt

mkdir -p $MIRRORCACHE_ROOT/distribution
echo 1111111111 > $MIRRORCACHE_ROOT/distribution/file1.1.dat

/usr/share/mirrorcache/script/mirrorcache minion job -e folder_sync -a '["'/distribution'"]'

sleep 2

alias sql='mariadb -h127.0.0.1 -u mirrorcache --batch -D mirrorcache -Ne'

test 1 == $(sql 'select count(*) from file') || sleep 2
test 1 == $(sql 'select count(*) from file') || sleep 2
test 1 == $(sql 'select count(*) from file') || sleep 2
test 1 == $(sql 'select count(*) from file')

test 1 == $(sql 'select count(*) from hash') || sleep 2
test 1 == $(sql 'select count(*) from hash') || sleep 2
test 1 == $(sql 'select count(*) from hash') || sleep 2
test 1 == $(sql 'select count(*) from hash') || sleep 2
test 1 == $(sql 'select count(*) from hash')
test b2c5860a03d2c4f1f049a3b2409b39a8 == $(sql 'select md5 from hash where file_id=1')
test 5179db3d4263c9cb4ecf0edbc653ca460e3678b7 == $(sql 'select sha1 from hash where file_id=1')
test 63d19a99ef7db94ddbb1e4a5083062226551cd8197312e3aa0aa7c369ac3e458 == $(sql 'select sha256 from hash where file_id=1')
test 2a276e680779492af2ed54ba5661ac5f35b39e363c95a55ddfac644c1aca2c3f68333225362e66536460999a7f86b1f2dc7e8ef469e3dc5042ad07d491f13de2 == $(sql 'select sha512 from hash where file_id=1')

test '1,2,3' == "$(sql 'select zlengths from hash')"

)

echo success
