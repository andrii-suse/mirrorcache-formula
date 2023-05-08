{% from "mirrorcache/macros.jinja" import var_if_pillar_subtree with context -%}

include:
  - .common
  - .webui-conf

/etc/mirrorcache/conf-subtree.env:
  file.prepend:
    - require:
      - /etc/mirrorcache
    - text: |
        # managed by salt - do not edit!

webui-subtree.conf.env:
  file.keyvalue:
    - name: /etc/mirrorcache/conf-subtree.env
    - separator: '='
    - append_if_not_found: True
    - key_values:
        MIRRORCACHE_SUBTREE: '{{ salt['pillar.get']('mirrorcache:subtree', '') }}'
        MOJO_LISTEN: 'http://[::]:3001'
        {{ var_if_pillar_subtree('root', '') -}}
        {{ var_if_pillar_subtree('top_folders', '') -}}
        {{ var_if_pillar_subtree('branding', '') }}
        {{ var_if_pillar_subtree('metalink_publisher',     '') }}
        {{ var_if_pillar_subtree('metalink_publisher_url', '') }}

mirrorcache-subtree:
  service.running:
    - name: mirrorcache-subtree
    - enable: true
