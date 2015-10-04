{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
include:
  - makina-states.services.monitoring.circus.services
# install & inconditionnaly reboot circus  upon deployments
/bin/true:
  cmd.run:
    - watch_in:
      - mc_proxy: circus-pre-conf
