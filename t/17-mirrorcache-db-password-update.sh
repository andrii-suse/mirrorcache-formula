#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache mariadb

set -ex

# Define the password transition
PASS_OLD="oldpass123"
PASS_NEW="newpass456"

# ----------------------------------------------------
# Step 1: Initialize Database & Apply States with OLD password
# ----------------------------------------------------
mariadb --version || zypper -n in mariadb
rcmariadb start
mariadb -e 'create database mirrorcache'
mariadb -e "create user mirrorcache@localhost identified by '$PASS_OLD'"
mariadb -e "grant all on mirrorcache.* to mirrorcache@localhost; flush privileges;"

# Populate the local pillars with the old password
echo "
mirrorcache:
  dbpass: $PASS_OLD
mysql:
  user:
    mirrorcache:
      password: $PASS_OLD
" > /srv/pillar/testpreset.sls

# Apply initial states
salt-call --local state.apply 'mirrorcache.mariadb'
salt-call --local state.apply 'mirrorcache.webui'
salt-call --local state.apply 'mirrorcache.backstage'

# Wait up to 10 seconds for hypnotoad to be fully up and ready
for i in {1..10}; do
  if curl -s 127.0.0.1:3000/update/?json | grep -i leap; then
    echo "Service is ready!"
    break
  fi
  echo "Waiting for service to be ready..."
  sleep 1
done

# Verify the services are running and can query MariaDB with the old password
curl -s 127.0.0.1:3000/update/?json | grep leap

# ----------------------------------------------------
# Step 2: Trigger the Password Update Transition
# ----------------------------------------------------
# Rewrite local pillars with the new password
echo "
mirrorcache:
  dbpass: $PASS_NEW
mysql:
  user:
    mirrorcache:
      password: $PASS_NEW
" > /srv/pillar/testpreset.sls

# 1. Update the password in MariaDB (executes ALTER USER)
salt-call --local state.apply 'mirrorcache.mariadb'

# 2. Update the password in the /etc/mirrorcache/conf.env configuration file
salt-call --local state.apply 'mirrorcache.webui'
salt-call --local state.apply 'mirrorcache.backstage'

# ----------------------------------------------------
# Step 3: Restart Services to Load the New Credentials
# ----------------------------------------------------
rcmirrorcache-hypnotoad restart
rcmirrorcache-backstage restart

# Wait up to 10 seconds for hypnotoad to be fully up and ready with new config
for i in {1..10}; do
  if curl -s 127.0.0.1:3000/distribution/?json | grep -i leap; then
    echo "Service is ready with new password!"
    break
  fi
  echo "Waiting for service to reload..."
  sleep 1
done

# ----------------------------------------------------
# Step 4: Verification & Validation
# ----------------------------------------------------

# Check 1: Verify the updated password is written in the service configuration
grep "MIRRORCACHE_DBPASS=$PASS_NEW" /etc/mirrorcache/conf.env

# Check 2: Verify database access with NEW password succeeds
mariadb -h 127.0.0.1 -umirrorcache -p$PASS_NEW -e 'select database()' mirrorcache

# Check 3: Verify database access with OLD password is now strictly denied
rc=0
mariadb -h 127.0.0.1 -umirrorcache -p$PASS_OLD -e 'select database()' mirrorcache || rc=$?
if [ "$rc" -eq 0 ]; then
    echo "ERROR: Database is still accepting the old password!"
    exit 1
fi

# Check 4: Verify the web service functions flawlessly using the updated credentials
curl -s 127.0.0.1:3000/distribution/?json | grep -i leap

# Cleanup: Stop the running hypnotoad and backstage services
rcmirrorcache-hypnotoad stop
rcmirrorcache-backstage stop

echo success
