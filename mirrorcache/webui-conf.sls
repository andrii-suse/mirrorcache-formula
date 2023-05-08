{% from "mirrorcache/macros.jinja" import var_if_pillar with context -%}

include:
  - .common

webui.conf.env:
  file.keyvalue:
    - name: /etc/mirrorcache/conf.env
    - separator: '='
    - append_if_not_found: True
    - key_values:
        MIRRORCACHE_MATALINK_GREEDY: '3'
        MOJO_LISTEN: 'http://*:3000'
        MOJO_REVERSE_PROXY: '1'
        {{ var_if_pillar('redirect',     '') }}
        {{ var_if_pillar('redirect_huge','') }}
        {{ var_if_pillar('workers',      '') }}
        {{ var_if_pillar('proxy_url',    '') }}
        {{ var_if_pillar('root_country', '') }}
        {{ var_if_pillar('branding',     'openSUSE') }}
        {{ var_if_pillar('top_folders',  '"debug distribution factory history ports repositories source tumbleweed update"') }}
        {{ var_if_pillar('vpn_prefix',   '') }}
        {{ var_if_pillar('stat_flush_count',  300) }}
        {{ var_if_pillar('root_longitude',    '') }}
        {{ var_if_pillar('metalink_publisher',     '') }}
        {{ var_if_pillar('metalink_publisher_url', '') }}
