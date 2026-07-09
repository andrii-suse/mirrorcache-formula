#!lib/test-in-container-systemd.sh postgresql-server postgresql

set -ex

zypper -n in postgresql-server

# 1. Set up a custom data directory for PostgreSQL on SLES/openSUSE
mkdir -p /var/lib/pgsql/custom_dir
chown postgres:postgres /var/lib/pgsql/custom_dir

# Configure the custom data directory in the system configuration file
echo 'POSTGRES_DATADIR="/var/lib/pgsql/custom_dir"' > /etc/sysconfig/postgresql

# 2. Run the base state (this will initialize PostgreSQL in the custom directory!)
salt-call --local state.apply 'mirrorcache.postgres'

# Verify that PostgreSQL successfully initialized in the custom directory
test -f /var/lib/pgsql/custom_dir/pg_hba.conf
test ! -d /var/lib/pgsql/data

# 3. Set up pillars WITHOUT postgres:hba_file to test dynamic discovery of the running/disk configuration!
echo "
postgres:
  user:
    mirrorcache:
      password: custom_path_pass
  remote_host: 10.0.0.99/32
  remote_auth: scram-sha-256
" > /srv/pillar/testpreset.sls

# 4. Apply our postgres-hba state file
# This will query the active PostgreSQL instance or find the file on disk,
# finding `/var/lib/pgsql/custom_dir/pg_hba.conf` automatically!
salt-call --local state.apply 'mirrorcache.postgres-hba'

# 5. Verify that the custom HBA file was updated correctly
grep -E '^local\s+all\s+all\s+md5' /var/lib/pgsql/custom_dir/pg_hba.conf
grep -E '^host\s+all\s+all\s+127\.0\.0\.1/32\s+md5' /var/lib/pgsql/custom_dir/pg_hba.conf
grep -E '^host\s+all\s+all\s+::1/128\s+md5' /var/lib/pgsql/custom_dir/pg_hba.conf
grep -E '^host\s+all\s+all\s+10\.0\.0\.99/32\s+scram-sha-256' /var/lib/pgsql/custom_dir/pg_hba.conf

echo "success"
