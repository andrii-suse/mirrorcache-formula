{% set dbuserhost = salt['pillar.get']('mysql:user:mirrorcache:host', 'localhost') -%}
{% set dbuserpass = salt['pillar.get']('mysql:user:mirrorcache:password', {}) -%}

{% if not dbuserhost %}
  {% set dbuserhosts = ['localhost'] %}
{% elif dbuserhost is string %}
  {% set dbuserhosts = [dbuserhost] %}
{% elif dbuserhost is iterable %}
  {% set dbuserhosts = dbuserhost %}
{% else %}
  {% set dbuserhosts = ['localhost'] %}
{% endif %}

mariadb:
  pkg.installed

rcmariadb:
  service.running:
    - name: mariadb
    - enable: true

db_database:
  mysql_database.present:
    - name: mirrorcache

{% for host in dbuserhosts %}
db_user_{{ host }}:
  mysql_user.present:
    - name: mirrorcache
    {% if dbuserpass -%}
    - password: {{ dbuserpass }}
    {% else -%}
    - allow_passwordless: {{ salt['pillar.get']('mysql:user:mirrorcache:allow_passwordless', False) }}
    {% endif -%}
    - host: '{{ host }}'

db_grants_{{ host }}:
  mysql_grants.present:
    - grant: all privileges
    - database: mirrorcache.*
    - user: mirrorcache
    - host: '{{ host }}'
    - require:
      - mysql_user: db_user_{{ host }}
      - mysql_database: db_database
{% endfor %}
