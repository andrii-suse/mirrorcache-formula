{% from "mirrorcache/macros.jinja" import var_if_pillar with context -%}
{% from "mirrorcache/macros.jinja" import ini_if_pillar with context -%}

include:
  - .common

webui.conf.env:
  file.keyvalue:
    - name: /etc/mirrorcache/conf.env
    - separator: '='
    - append_if_not_found: True
    - key_values:
        MIRRORCACHE_INI: /etc/mirrorcache/conf.ini
        MIRRORCACHE_MATALINK_GREEDY: '3'
        MOJO_LISTEN: 'http://*:3000'
        MOJO_REVERSE_PROXY: '1'
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

# historically al variables were in conf.env,
# but conf.ini was introduced to change parameters without service restart
webui.conf.ini:
  file.keyvalue:
    - name: /etc/mirrorcache/conf.ini
    - separator: '='
    - append_if_not_found: True
    - key_values:
        {{ ini_if_pillar('root',     'http://download.opensuse.org') -}}
        {{ ini_if_pillar('root_nfs', '')  -}}
        {{ ini_if_pillar('city_mmdb', '') -}}
        {{ ini_if_pillar('redirect',     '') }}
        {{ ini_if_pillar('redirect_huge','') }}
        {{ ini_if_pillar('huge_file_size','') }}
        {{ ini_if_pillar('small_file_size','') }}
        {{ ini_if_pillar('city_mmdb','') }}
        {{ ini_if_pillar('ip2location','') }}

# temporary workaround to make ini work, will add variables later
webui.conf.ini.db:
  file.append:
    - name: /etc/mirrorcache/conf.ini
    - require:
      - /etc/mirrorcache/conf.env
    - text: |
        [db]
