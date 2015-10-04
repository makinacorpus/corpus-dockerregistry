{% set cfg = opts.ms_project %}
{% set data = cfg.data %}

include:
  - makina-states.services.http.nginx.services
# install & inconditionnaly reboot nginx upon deployments
/bin/true:
  cmd.run:
    - watch_in:
      - mc_proxy: nginx-pre-conf-hook
