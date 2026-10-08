{% set hostname = salt['pillar.get']('mirrorcache:oauth2:hostname', salt['pillar.get']('mirrorcache:oauth2_hostname', salt['pillar.get']('mirrorcache:hostname', 'id-stage.suse.com'))) %}
{% set auth_method = salt['pillar.get']('mirrorcache:auth:method', salt['pillar.get']('mirrorcache:auth_method', salt['pillar.get']('mirrorcache:oauth2:method', 'OAuth2'))) %}
{% set ini_file = salt['pillar.get']('mirrorcache:conf_ini', '/etc/mirrorcache/conf.ini') %}

{% set oauth2_opts = {
    'provider': 'custom',
    'authorize_url': 'https://' ~ hostname ~ '/application/o/authorize/?response_type=code',
    'token_url': 'https://' ~ hostname ~ '/application/o/token/',
    'user_url': 'https://' ~ hostname ~ '/application/o/userinfo/',
    'token_scope': 'email profile openid sub communityUidAsopenId',
    'token_label': 'Bearer',
    'id_from': 'communityUidAsopenId',
    'nickname_from': 'sub',
    'unique_name': 'suseid',
    'key': 'mykey',
    'secret': 'mysecret'
} %}

{% set oauth2_pillar = salt['pillar.get']('mirrorcache:oauth2', {}) %}
{% if oauth2_pillar is mapping %}
  {% for k, v in oauth2_pillar.items() %}
    {% if k != 'hostname' and k != 'method' and v %}
      {% do oauth2_opts.update({k: v}) %}
    {% endif %}
  {% endfor %}
{% endif %}

{% for k in ['provider', 'authorize_url', 'token_url', 'user_url', 'token_scope', 'token_label', 'id_from', 'nickname_from', 'unique_name', 'key', 'secret', 'fullname_from', 'email_from'] %}
  {% set flat_val = salt['pillar.get']('mirrorcache:oauth2_' ~ k, '') %}
  {% if flat_val %}
    {% do oauth2_opts.update({k: flat_val}) %}
  {% endif %}
{% endfor %}

include:
  - .common

packages-oauth2:
  pkg.installed:
    - refresh: False
    - pkgs:
      - perl-Mojolicious-Plugin-OAuth2

oauth2.conf.ini:
  ini.options_present:
    - name: {{ ini_file }}
    - separator: '='
    - sections:
        auth:
          method: {{ auth_method }}
        oauth2:
{%- for k in ['provider', 'authorize_url', 'token_url', 'user_url', 'token_scope', 'token_label', 'id_from', 'nickname_from', 'unique_name', 'key', 'secret'] %}
          {{ k }}: {{ oauth2_opts[k] }}
{%- endfor %}
{%- for k, v in oauth2_opts.items() %}
{%- if k not in ['provider', 'authorize_url', 'token_url', 'user_url', 'token_scope', 'token_label', 'id_from', 'nickname_from', 'unique_name', 'key', 'secret'] %}
          {{ k }}: {{ v }}
{%- endif %}
{%- endfor %}
    - require:
      - file: /etc/mirrorcache/conf.ini

oauth2-service-reload:
  cmd.run:
    - name: systemctl try-restart mirrorcache-hypnotoad.service
    - onlyif: systemctl is-active mirrorcache-hypnotoad.service
    - onchanges:
      - ini: oauth2.conf.ini
      - pkg: packages-oauth2
