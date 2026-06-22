#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache mariadb

set -ex

PASS=mypass12

salt-call --local state.apply 'mirrorcache.mariadb'
salt-call --local state.apply 'mirrorcache.backstage'
salt-call --local state.apply 'mirrorcache.backstage-exec'

(
set -a
shopt -s expand_aliases
source /etc/mirrorcache/conf.env
/usr/share/mirrorcache/script/mirrorcache minion job -e exec -a '["mkdir tttttt"]' -q exec
/usr/share/mirrorcache/script/mirrorcache minion job -e exec -a '[{"CMD":"touch aaaaaa","TIMEOUT":6}]' -q exec
)

# Wait up to 30 seconds for the async background minion jobs to execute
for i in {1..30}; do
  if find /var/lib/mirrorcache-exec | grep -q tttttt && find /var/lib/mirrorcache-exec | grep -q aaaaaa; then
    echo "Jobs completed successfully!"
    break
  fi
  echo "Waiting for jobs to process..."
  sleep 1
done

if ! (find /var/lib/mirrorcache-exec | grep -q tttttt && find /var/lib/mirrorcache-exec | grep -q aaaaaa); then
  echo "=== DIAGNOSTICS ==="
  systemctl status mirrorcache-backstage-exec || true
  journalctl -u mirrorcache-backstage-exec || true
  echo "=== DATABASE JOBS ==="
  mariadb -h127.0.0.1 -u mirrorcache -D mirrorcache -e "show tables" || true
  mariadb -h127.0.0.1 -u mirrorcache -D mirrorcache -e "select * from minion_jobs\G" || true
  mariadb -h127.0.0.1 -u mirrorcache -D mirrorcache -e "select * from minion_workers\G" || true
  echo "==================="
fi

find /var/lib/mirrorcache-exec | grep tttttt
find /var/lib/mirrorcache-exec | grep aaaaaa


echo success
