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

# 1. Apply webui state
salt-call -l debug --local state.apply 'mirrorcache.webui'

# Verify service is running
systemctl is-active mirrorcache-hypnotoad.service

# 2. Apply mirrorcache.oauth2 state with defaults (no pillar overrides)
salt-call -l debug --local state.apply 'mirrorcache.oauth2'

# Verify package perl-Mojolicious-Plugin-OAuth2 is installed
rpm -q perl-Mojolicious-Plugin-OAuth2

# Verify default settings in conf.ini
test -f /etc/mirrorcache/conf.ini
grep -F '[auth]' /etc/mirrorcache/conf.ini
grep -F 'method = OAuth2' /etc/mirrorcache/conf.ini
grep -F '[oauth2]' /etc/mirrorcache/conf.ini
grep -F 'provider = custom' /etc/mirrorcache/conf.ini
grep -F 'authorize_url = https://id-stage.suse.com/application/o/authorize/?response_type=code' /etc/mirrorcache/conf.ini
grep -F 'token_url = https://id-stage.suse.com/application/o/token/' /etc/mirrorcache/conf.ini
grep -F 'user_url = https://id-stage.suse.com/application/o/userinfo/' /etc/mirrorcache/conf.ini
grep -F 'token_scope = email profile openid sub communityUidAsopenId' /etc/mirrorcache/conf.ini
grep -F 'token_label = Bearer' /etc/mirrorcache/conf.ini
grep -F 'id_from = communityUidAsopenId' /etc/mirrorcache/conf.ini
grep -F 'nickname_from = sub' /etc/mirrorcache/conf.ini
grep -F 'unique_name = suseid' /etc/mirrorcache/conf.ini
grep -F 'key = xoo9ahphiqu5daiThaiXaech3Jik9EeFee3aht4u' /etc/mirrorcache/conf.ini
grep -F 'secret = xxx' /etc/mirrorcache/conf.ini

# Verify login redirect with defaults
curl -sI http://127.0.0.1:3000/login | grep -i 'Location: https://id-stage.suse.com/application/o/authorize/?response_type=code'
curl -sI http://127.0.0.1:3000/login | grep -i 'client_id=xoo9ahphiqu5daiThaiXaech3Jik9EeFee3aht4u'

# 3. Configure pillar for id.opensuse.org
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

# Apply oauth2 state with pillar
salt-call -l debug --local state.apply 'mirrorcache.oauth2'

# Verify updated settings in conf.ini
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

# 4. Verify idempotency
salt-call -l debug --local state.apply 'mirrorcache.oauth2'

echo success
