{% from "mirrorcache/macros.jinja" import var_if_pillar with context -%}

common.conf.env:
  file.keyvalue:
    - name: /etc/mirrorcache/conf.env
    - separator: '='
    - append_if_not_found: True
    - key_values:
        {{ var_if_pillar('root',     'http://download.opensuse.org') -}}
        {{ var_if_pillar('root_nfs', '') -}}
        {{ var_if_pillar('db_provider', 'mariadb') -}}
        MIRRORCACHE_DBHOST: '{{ salt['pillar.get']('mirrorcache:db:host', '') }}'
        MIRRORCACHE_DBUSER: 'mirrorcache'
        MIRRORCACHE_DBPASS: '{{ salt['pillar.get']('mysql:user:mirrorcache:password', '') }}'
        MOJO_PUBSUB_EXPERIMENTAL: '1'



