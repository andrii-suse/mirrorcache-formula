{% from "mirrorcache/macros.jinja" import var_if_pillar with context -%}

include:
  - .common
  - .webui-conf

mirrorcache:
  service.running:
    - name: mirrorcache-hypnotoad
    - enable: true
