{% from "mirrorcache/macros.jinja" import var_if_pillar with context -%}

include:
  - .common

packages-backstage:
  pkg.installed:
    - refresh: False
    - pkgs:
      - perl-Digest-MD4
      - perl-Digest-Zsync

backstage.conf.env:
  file.keyvalue:
    - name: /etc/mirrorcache/conf.env
    - separator: '='
    - append_if_not_found: True
    - key_values:
        {{ var_if_pillar('hashes_import',     '') -}}
        {{ var_if_pillar('hashes_collect',    '') -}}
        {{ var_if_pillar('backstage_workers', '') -}}
        {{ var_if_pillar('zsync_collect',     'xml.gz') }}

mirrorcache-backstage:
  service.running:
    - name: mirrorcache-backstage
    - enable: true

mirrorcache-backstage-hashes:
  service.running:
    - name: mirrorcache-backstage-hashes
    - enable: true

