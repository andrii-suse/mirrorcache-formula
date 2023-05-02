{%- set repositories = salt['pillar.get']('zypper:repositories', {}) -%}
{%- set alreadydefined = '0' -%}

{# repository might be already defined in zypper pillar, so need to detect it #}

{%- if repositories -%}
  {%- for repo, data in repositories.items() -%}
    {%- if 'MirrorCache' in data.baseurl -%}
      {%- set alreadydefined = '1' -%}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}

{%- if alreadydefined == '0' -%}
  {% set repourl = salt['pillar.get']('mirrorcache:repourl', 'http://download.opensuse.org/repositories/openSUSE:/infrastructure:/MirrorCache/$releasever/') %}
mc:
  pkgrepo.managed:
    - baseurl: {{ repourl }}
    - gpgautoimport: True
{%- endif -%}
