packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - MirrorCache
      - perl-Mojo-mysql
      - perl-Minion-Backend-mysql
      - perl-DateTime-Format-MySQL

packages-geofeature:
  pkg.installed:
    - refresh: False
    - unless: test ! -f /var/lib/GeoIP/GeoLite2-City.mmdb
    - pkgs:
      - perl-Mojolicious-Plugin-ClientIP
      - perl-MaxMind-DB-Reader
    - require:
      - packages

/etc/mirrorcache:
  file.directory:
    - user:  mirrorcache
    - group: root
    - mode:  740
    - require:
      - packages

/etc/mirrorcache/conf.env:
  file.prepend:
    - require:
      - /etc/mirrorcache
    - text: |
        # managed by salt - do not edit!

