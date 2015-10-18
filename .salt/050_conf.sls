{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}
{% import "makina-states/services/http/nginx/init.sls" as nginx %}
{% import "makina-states/services/monitoring/circus/macros.jinja" as circus with context %}

{# scramble the redis password upon each reconfiguration to avoid
   multiple docker images sharing the same root password, when
   we restart, the password change #}
{% do salt['mc_utils.purge_memoize_cache']() %}
{% do salt['mc_redis.change_password']() %}

include:
  - makina-states.services.http.nginx.hooks
  - makina-states.services.monitoring.circus.hooks
  # reconfigure password
  - makina-states.services.db.redis.configuration

{{ nginx.virtualhost(domain=data.domain,
                     doc_root=data.www_dir,
                     server_aliases=data.server_aliases,
                     vhost_basename='corpus-'+cfg.name,
                     loglevel=data.nginx_loglevel,
                     ssl_cert=data.get('ssl_cert', None),
                     ssl_key=data.get('ssl_key', None),
                     vh_top_source=data.nginx_upstreams,
                     vh_content_source=data.nginx_vhost,
                     project=cfg.name)}}

{% set circus_data = {
  'cmd': '{cfg[project_root]}/bin/registry {cfg[data_root]}/configuration/registry.yml'.format(cfg=cfg, data=cfg.data),
  'environment': {},
  'uid': cfg.user,
  'gid': cfg.group,
  'copy_env': True,
  'working_dir': cfg.project_root,
  'warmup_delay': "10",
  'max_age': 24*60*60} %}
{{ circus.circusAddWatcher(cfg.name+'-registry', **circus_data) }}

{{cfg.name}}-dirs:
  file.directory:
    - makedirs: true
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - names:
      - {{cfg.data.conf}}
      - {{cfg.data.images}}
      - {{cfg.data.www_dir}}

{{cfg.name}}-configs-before:
  mc_proxy.hook:
    - watch:
      - file: {{cfg.name}}-dirs
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-pre

{{cfg.name}}-configs-pre:
  mc_proxy.hook:
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-post

{{cfg.name}}-htaccess:
  file.managed:
    - name: "{{data.htaccess}}"
    - source: ''
    - user: www-data
    - group: www-data
    - mode: 770
    - watch:
      - mc_proxy: {{cfg.name}}-configs-pre
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-post

{% if data.get('http_users', {}) %}
{% for userrow in data.http_users %}
{% for user, passwd in userrow.items() %}
{{cfg.name}}-{{user}}-htaccess:
  webutil.user_exists:
    - name: "{{user}}"
    - password: "{{passwd}}"
    - htpasswd_file: "{{data.htaccess}}"
    - options: m
    - force: true
    - watch:
      - file: {{cfg.name}}-htaccess
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-post
{% endfor %}
{% endfor %}
{% endif %}
{% for config, tdata in data.configs.items() %}
{{cfg.name}}-{{config}}-conf:
  file.managed:
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-post
    - watch:
      - mc_proxy: redis-post-conf
      - mc_proxy: {{cfg.name}}-configs-pre
    - defaults:
        project: "{{cfg.name}}"
        cfg: "{{cfg.name}}"
    - source: {{ tdata.get(
          'source',
          'salt://makina-projects/{0}/files/{1}'.format(
           cfg.name, config))}}
    - makedirs: {{tdata.get('makedirs', True)}}
    - name: {{ tdata.get('target', '{0}/{1}'.format(
                    cfg.project_root, config))}}
    - user: {{tdata.get('user', cfg.user)}}
    - group: {{tdata.get('group', cfg.group)}}
    - mode: {{tdata.get('mode', 750)}}
    {% if  data.get('template', 'jinja') %}
    - template: {{ data.get('template', 'jinja') }}
    {% else %}
    - template: false
    {% endif %}
{% endfor %}

{{cfg.name}}-configs-post:
  mc_proxy.hook:
    - watch_in:
      - mc_proxy: {{cfg.name}}-configs-after

{{cfg.name}}-configs-after:
  mc_proxy.hook: []

{{cfg.name}}-www-data:
  user.present:
    - name: www-data
    - optional_groups:
      - {{cfg.group}}
    - remove_groups: false
