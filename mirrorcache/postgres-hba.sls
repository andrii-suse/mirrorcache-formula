{% set hba_file = salt['pillar.get']('postgres:hba_file', '') %}

{% if not hba_file %}
{% set candidate_paths = [
  '/var/lib/pgsql/data/pg_hba.conf',
  '/var/lib/pgsql/custom_dir/pg_hba.conf',
  '/var/lib/pgsql/custom_dir/custom_pg_hba.conf',
  '/var/lib/postgresql/data/pg_hba.conf',
  '/etc/postgresql/18/main/pg_hba.conf',
  '/etc/postgresql/17/main/pg_hba.conf',
  '/etc/postgresql/16/main/pg_hba.conf',
  '/etc/postgresql/15/main/pg_hba.conf',
  '/etc/postgresql/14/main/pg_hba.conf',
  '/etc/postgresql/13/main/pg_hba.conf',
  '/etc/postgresql/12/main/pg_hba.conf'
] %}
{% set ns_found = [] %}
{% for path in candidate_paths %}
{% if not ns_found and salt['file.file_exists'](path) %}
{% set _ = ns_found.append(path) %}
{% endif %}
{% endfor %}
{% if ns_found %}
{% set hba_file = ns_found[0] %}
{% endif %}
{% endif %}

{% if not hba_file %}
{% set hba_file = '/var/lib/pgsql/data/pg_hba.conf' %}
{% endif %}

{% set local_auth = salt['pillar.get']('postgres:local_auth', 'md5') %}
{% set remote_host = salt['pillar.get']('postgres:remote_host', '') %}
{% set remote_auth = salt['pillar.get']('postgres:remote_auth', 'md5') %}

include:
  - .postgres

pg_hba_local_socket:
  file.replace:
    - name: {{ hba_file }}
    - pattern: '^(local\s+all\s+all\s+)(ident|trust|peer)'
    - repl: '\1{{ local_auth }}'
    - append_if_not_found: False
    - require:
      - service: rcpostgresql

pg_hba_local_ipv4:
  file.replace:
    - name: {{ hba_file }}
    - pattern: '^(host\s+all\s+all\s+127\.0\.0\.1\/32\s+)(ident|trust|peer)'
    - repl: '\1{{ local_auth }}'
    - append_if_not_found: False
    - require:
      - service: rcpostgresql

pg_hba_local_ipv6:
  file.replace:
    - name: {{ hba_file }}
    - pattern: '^(host\s+all\s+all\s+::1\/128\s+)(ident|trust|peer)'
    - repl: '\1{{ local_auth }}'
    - append_if_not_found: False
    - require:
      - service: rcpostgresql

{% if remote_host %}
pg_hba_remote_host:
  file.replace:
    - name: {{ hba_file }}
    - pattern: '^host\s+all\s+all\s+{{ remote_host | replace(".", "\\.") | replace("/", "\\/") }}\s+.*$'
    - repl: 'host    all             all             {{ remote_host }}            {{ remote_auth }}'
    - append_if_not_found: True
    - require:
      - service: rcpostgresql
{% endif %}

postgresql_reload:
  cmd.run:
    - name: systemctl reload postgresql.service
    - onchanges:
      - file: pg_hba_local_socket
      - file: pg_hba_local_ipv4
      - file: pg_hba_local_ipv6
      {% if remote_host %}
      - file: pg_hba_remote_host
      {% endif %}
