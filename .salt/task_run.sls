{% set cfg = opts['ms_project'] %}
{% set data = cfg.data %}
# reconfigure if anything has changed in $volume/configuration
include:
  - makina-projects.{{cfg.name}}.050_conf
boot:
  cmd.run:
    - use_vt: true
    - user: root
    - name: /usr/bin/circus.sh start
