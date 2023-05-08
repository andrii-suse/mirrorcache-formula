{%- set repositories = salt['pillar.get']('zypper:repositories', {}) -%}
{%- set already = { 'defined': False } -%}

{# repository might be already defined in zypper pillar, so need to detect it #}
{%- if not repositories -%}
  {%- set repositories = salt['pillar.get']('zypp:repositories', {}) -%}
{%- endif -%}

{%- if repositories -%}
  {%- for repo, data in repositories.items() -%}
    {%- if data.baseurl and 'MirrorCache' in data.baseurl -%}
      {%- do already.update({ 'defined': True }) -%}
    {%- endif -%}
  {%- endfor -%}
{%- endif -%}

{%- if already.defined != True -%}
  {% set repourl = salt['pillar.get']('mirrorcache:repourl', 'http://download.opensuse.org/repositories/openSUSE:/infrastructure:/MirrorCache/$releasever/') %}
mc:
  pkgrepo.managed:
    - baseurl: {{ repourl }}
    - gpgautoimport: True
{%- endif -%}
