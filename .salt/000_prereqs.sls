{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
include:
  - makina-states.services.monitoring.circus
  - makina-states.services.http.nginx
  - makina-states.services.db.redis

prepreqs-{{cfg.name}}:
  pkg.installed:
    - pkgs:
      - apache2-utils
      - librados-dev

conf-redis:
  file.managed:
    - name: /srv/pillar/redis.sls
    - contents: |
                makina-states.services.db.redis.redis.bind: 127.0.0.1
    - user: root
    - group: root
    - reload_pillar: true
    - mode: 750

add-custom-pillar:
  file.append:
    - name: /srv/pillar/top.sls
    - text: "    - redis"
    - onlyif: grep -v redis /srv/pillar/top.sls
    - reload_pillar: true
    - watch:
      - file: conf-redis
    - watch_in:
      - mc_proxy: redis-pre-conf
