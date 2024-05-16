{%- if 'mirrorcache_formula_enable_repository' in pillar and pillar.mirrorcache_formula_enable_repository -%}
  {% set repourl = salt['pillar.get']('mirrorcache:repourl', 'http://download.opensuse.org/repositories/openSUSE:/infrastructure:/MirrorCache/$releasever/') %}
mc:
  pkgrepo.managed:
    - baseurl: {{ repourl }}
    - gpgautoimport: True
{%- endif -%}
