packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - MirrorCache

/etc/mirrorcache:
  file.directory:
    - user:  root
    - group: mirrorcache
    - mode:  750
    - require:
      - packages

/etc/mirrorcache/conf.env:
  file.prepend:
    - require:
      - /etc/mirrorcache
    - text: |
        # managed by salt - do not edit!

/etc/mirrorcache/conf.ini:
  file.prepend:
    - require:
      - /etc/mirrorcache
    - text: |
        # managed by salt - do not edit!

