#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache postgresql-server postgresql

set -ex

# Define the password transition
PASS_OLD="oldpass123"
PASS_NEW="newpass456"

# ----------------------------------------------------
# Step 1: Initialize Database & Apply States with OLD password
# ----------------------------------------------------
echo "
mirrorcache:
  db_provider: postgresql
  dbpass: $PASS_OLD
postgres:
  user:
    mirrorcache:
      password: $PASS_OLD
" > /srv/pillar/testpreset.sls

# Apply initial states
salt-call --local state.apply 'mirrorcache.postgres'

# Set up md5 password authentication in pg_hba.conf for localhost TCP connections
sed -E -i 's/(host\s+all\s+all\s+127.0.0.1\/32\s+)ident/\1md5/' /var/lib/pgsql/data/pg_hba.conf
rcpostgresql reload

# Check that we can connect to PostgreSQL using psql and PASS_OLD
export PGPASSWORD=$PASS_OLD
psql -d mirrorcache -U mirrorcache --host 127.0.0.1 -c 'select current_database()'

# Apply WebUI and Backstage states
salt-call --local state.apply 'mirrorcache.webui'
salt-call --local state.apply 'mirrorcache.backstage'

# Wait up to 10 seconds for hypnotoad to be fully up and ready with old password
for i in {1..10}; do
  if curl -s 127.0.0.1:3000/update/?json | grep -i leap; then
    echo "Service is ready!"
    break
  fi
  echo "Waiting for service to be ready..."
  sleep 1
done

# Verify the web service functions with OLD password
curl -s 127.0.0.1:3000/update/?json | grep leap

# ----------------------------------------------------
# Step 2: Trigger the Password Update Transition
# ----------------------------------------------------
# Rewrite local pillars with the new password
echo "
mirrorcache:
  db_provider: postgresql
  dbpass: $PASS_NEW
postgres:
  user:
    mirrorcache:
      password: $PASS_NEW
" > /srv/pillar/testpreset.sls

# 1. Update the password in PostgreSQL (executes ALTER ROLE)
salt-call --local state.apply 'mirrorcache.postgres'

# 2. Update the password in the /etc/mirrorcache/conf.env configuration file
salt-call --local state.apply 'mirrorcache.webui'
salt-call --local state.apply 'mirrorcache.backstage'

# ----------------------------------------------------
# Step 3: Restart Services to Load the New Credentials
# ----------------------------------------------------
rcmirrorcache-hypnotoad restart
rcmirrorcache-backstage restart

# Wait up to 10 seconds for hypnotoad to reload with the new password
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
export PGPASSWORD=$PASS_NEW
psql -d mirrorcache -U mirrorcache --host 127.0.0.1 -c 'select current_database()'

# Check 3: Verify database access with OLD password is now strictly denied
export PGPASSWORD=$PASS_OLD
rc=0
psql -d mirrorcache -U mirrorcache --host 127.0.0.1 -c 'select current_database()' || rc=$?
if [ "$rc" -eq 0 ]; then
    echo "ERROR: PostgreSQL is still accepting the old password!"
    exit 1
fi

# Check 4: Verify the web service functions flawlessly using the updated credentials
curl -s 127.0.0.1:3000/distribution/?json | grep -i leap

# Cleanup: Stop the running hypnotoad and backstage services
rcmirrorcache-hypnotoad stop
rcmirrorcache-backstage stop

echo success
