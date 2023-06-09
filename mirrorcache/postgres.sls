{% set dbuserhost = salt['pillar.get']('postgres:user:mirrorcache:host', {}) -%}
{% set dbuserpass = salt['pillar.get']('postgres:user:mirrorcache:password', {}) -%}

dbpkgs:
  pkg.installed:
    - pkgs:
      - postgresql
      - postgresql-server

postgresql:
  pkg.installed

rcpostgresql:
  service.running:
    - name: postgresql
    - enable: true

mirrorcache.database:
  postgres_user.present:
    - name: mirrorcache
    {% if dbuserpass -%}
    - password: {{ dbuserpass }}
    {% endif -%}
    {% if dbuserhost -%}
    - host: '{{ dbuserhost }}'
    {%- endif %}
  postgres_database.present:
    - name: mirrorcache
    - owner: mirrorcache

