packages:
  pkg.installed:
    - refresh: False
    - pkgs:
      - MirrorCache

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

