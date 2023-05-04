{% from "mirrorcache/macros.jinja" import var_if_pillar with context -%}

{% set db_provider = 'mariadb' %}
{% set db_provider_from_pillar = salt['pillar.get']('mirrorcache:db_provider') %}
{% if db_provider_from_pillar %}
  {% set db_provider = db_provider_from_pillar %}
{% else %}
  {% set db_provider_from_env = salt['environ.get']('MIRRORCACHE_DB_PROVIDER') %}
  {% if db_provider_from_env %}
    {% set db_provider = db_provider_from_env %}
  {% endif %}
{% endif %}


common.conf.env:
  file.keyvalue:
    - name: /etc/mirrorcache/conf.env
    - separator: '='
    - append_if_not_found: True
    - key_values:
        {{ var_if_pillar('root',     'http://download.opensuse.org') -}}
        {{ var_if_pillar('root_nfs', '') -}}
        MIRRORCACHE_DB_PROVIDER: {{ db_provider }}
        MIRRORCACHE_DBHOST: '{{ salt['pillar.get']('mirrorcache:db:host', '') }}'
        MIRRORCACHE_DBUSER: 'mirrorcache'
        MIRRORCACHE_DBPASS: '{{ salt['pillar.get']('mysql:user:mirrorcache:password', '') }}'
        MOJO_PUBSUB_EXPERIMENTAL: '1'

