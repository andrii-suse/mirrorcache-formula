{% set dbuserhost = salt['pillar.get']('postgres:user:mirrorcache:host', {}) -%}
{% set dbuserpass = salt['pillar.get']('postgres:user:mirrorcache:password', {}) -%}

dbpkgs:
  pkg.installed:
    - pkgs:
      - postgresql
      - postgresql-server

rcpostgresql:
  service.running:
    - name: postgresql.service
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

