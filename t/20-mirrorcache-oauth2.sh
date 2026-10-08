#!lib/test-in-container-systemd.sh openSUSE:infrastructure:MirrorCache mariadb perl-Mojolicious-Plugin-OAuth2

set -ex

if [ -d /opt/project/mirrorcache ]; then
  rm -rf /srv/salt/mirrorcache
  cp -a /opt/project/mirrorcache /srv/salt/mirrorcache
fi

zypper -vn in mariadb && rcmariadb start
mariadb -e 'create database mirrorcache'
mariadb -e 'create user mirrorcache@localhost'
mariadb -e 'grant all on mirrorcache.* to mirrorcache@localhost'

# 1. Apply webui state without OAuth2 pillar
salt-call -l debug --local state.apply 'mirrorcache.webui'

# Verify service is running
systemctl is-active mirrorcache-hypnotoad.service

# Verify oauth2 was not configured and package is not installed yet
rpm -q perl-Mojolicious-Plugin-OAuth2 && exit 1 || true
grep -F '[oauth2]' /etc/mirrorcache/conf.ini && exit 1 || true

# 2. Configure pillar for id.opensuse.org (providing key and secret)
mkdir -p /srv/pillar
cat << "EOF" > /srv/pillar/testpreset.sls
mirrorcache:
  oauth2:
    provider: custom
    authorize_url: https://id.opensuse.org/openidc/Authorization?response_type=code
    token_url: https://id.opensuse.org/openidc/Token
    user_url: https://id.opensuse.org/openidc/UserInfo
    token_scope: openid profile email
    token_label: Bearer
    id_from: sub
    nickname_from: nickname
    unique_name: opensuse
    key: myopensusekey
    secret: mysecretsecret
EOF

# Apply webui state again - it should now automatically apply oauth2
salt-call -l debug --local state.apply 'mirrorcache.webui'

# Verify package perl-Mojolicious-Plugin-OAuth2 is installed
rpm -q perl-Mojolicious-Plugin-OAuth2

# Verify updated settings in conf.ini
grep -F '[auth]' /etc/mirrorcache/conf.ini
grep -F 'method = OAuth2' /etc/mirrorcache/conf.ini
grep -F '[oauth2]' /etc/mirrorcache/conf.ini
grep -F 'provider = custom' /etc/mirrorcache/conf.ini
grep -F 'authorize_url = https://id.opensuse.org/openidc/Authorization?response_type=code' /etc/mirrorcache/conf.ini
grep -F 'token_url = https://id.opensuse.org/openidc/Token' /etc/mirrorcache/conf.ini
grep -F 'user_url = https://id.opensuse.org/openidc/UserInfo' /etc/mirrorcache/conf.ini
grep -F 'token_scope = openid profile email' /etc/mirrorcache/conf.ini
grep -F 'token_label = Bearer' /etc/mirrorcache/conf.ini
grep -F 'id_from = sub' /etc/mirrorcache/conf.ini
grep -F 'nickname_from = nickname' /etc/mirrorcache/conf.ini
grep -F 'unique_name = opensuse' /etc/mirrorcache/conf.ini
grep -F 'key = myopensusekey' /etc/mirrorcache/conf.ini
grep -F 'secret = mysecretsecret' /etc/mirrorcache/conf.ini

# Verify login redirect to id.opensuse.org
curl -sI http://127.0.0.1:3000/login | grep -i 'Location: https://id.opensuse.org/openidc/Authorization?response_type=code'
curl -sI http://127.0.0.1:3000/login | grep -i 'client_id=myopensusekey'

# 3. Verify standalone mirrorcache.oauth2 state can also be applied directly
salt-call -l debug --local state.apply 'mirrorcache.oauth2'

# 4. Verify idempotency
salt-call -l debug --local state.apply 'mirrorcache.webui'

echo success
