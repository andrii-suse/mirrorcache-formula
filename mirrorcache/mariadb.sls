{% set dbuserhost = salt['pillar.get']('mysql:user:mirrorcache:host', {}) -%}
{% set dbuserpass = salt['pillar.get']('mysql:user:mirrorcache:password', {}) -%}

mariadb:
  pkg.installed

rcmariadb:
  service.running:
    - name: mariadb
    - enable: true

db:
  mysql_user.present:
    - name: mirrorcache
    {% if dbuserpass -%}
    - password: {{ dbuserpass }}
    {% else -%}
    - allow_passwordless: True
    {% endif -%}
    {% if dbuserhost -%}
    - host: '{{ dbuserhost }}'
    {%- endif %}
  mysql_database.present:
    - name: mirrorcache
  mysql_grants.present:
    - grant: all privileges
    - database: mirrorcache.*
    - user: mirrorcache
    {% if dbuserhost -%}
    - host: '{{ dbuserhost }}'
    {% endif -%}
