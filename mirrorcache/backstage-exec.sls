{% from "mirrorcache/macros.jinja" import var_if_pillar with context -%}

include:
  - .repo
  - .common-packages-exec
  - .common-conf

mirrorcache-backstage-exec:
  service.running:
    - name: mirrorcache-backstage-exec
    - enable: true

