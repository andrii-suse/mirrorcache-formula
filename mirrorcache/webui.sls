{% from "mirrorcache/macros.jinja" import var_if_pillar with context -%}

{% set oauth2_key = salt['pillar.get']('mirrorcache:oauth2:key', salt['pillar.get']('mirrorcache:oauth2_key')) %}
{% set oauth2_secret = salt['pillar.get']('mirrorcache:oauth2:secret', salt['pillar.get']('mirrorcache:oauth2_secret')) %}

include:
  - .common
  - .webui-conf
{%- if oauth2_key and oauth2_secret %}
  - .oauth2
{%- endif %}

mirrorcache:
  service.running:
    - name: mirrorcache-hypnotoad
    - enable: true
