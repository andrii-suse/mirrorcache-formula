{% set db_provider = 'mariadb' %}
{% set db_provider_from_conf = salt['cmd.run_stdout']('(( grep MIRRORCACHE_DB_PROVIDER= /etc/mirrorcache/conf.env | tail -n 1 | grep -Eo "[^=]*$" ) 2> /dev/null || : )', python_shell=True) %}
{% if db_provider_from_conf %}
  {% set db_provider = db_provider_from_conf %}
{% else %}
  {% set db_provider_from_pillar = salt['pillar.get']('mirrorcache:db_provider') %}
  {% if db_provider_from_pillar %}
    {% set db_provider = db_provider_from_pillar %}
  {% else %}
    {% set db_provider_from_env = salt['environ.get']('MIRRORCACHE_DB_PROVIDER') %}
    {% if db_provider_from_env %}
      {% set db_provider = db_provider_from_env %}
    {% endif %}
  {% endif %}
{% endif %}

{% if db_provider == 'mariadb' %}
packages-extra:
  pkg.installed:
    - refresh: False
    - pkgs:
      - perl-Mojo-mysql
      - perl-Minion-Backend-mysql
      - perl-DateTime-Format-MySQL
{% endif %}

packages-geofeature:
  pkg.installed:
    - refresh: False
    - unless: test ! -f /var/lib/GeoIP/GeoLite2-City.mmdb
    - pkgs:
      - perl-Mojolicious-Plugin-ClientIP
      - perl-MaxMind-DB-Reader
    - require:
      - packages

