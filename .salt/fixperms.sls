{% set cfg = opts['ms_project'] %}
{# export macro to callees #}
{% set ugs = salt['mc_usergroup.settings']() %}
{% set locs = salt['mc_locations.settings']() %}
{% set cfg = opts['ms_project'] %}
{{cfg.name}}-restricted-perms:
  file.managed:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - mode: 750
    - user: {% if not cfg.no_user%}{{cfg.user}}{% else -%}root{% endif %}
    - group: {{cfg.group}}
    - contents: |
            #!/usr/bin/env bash
            if [ -e "{{cfg.pillar_root}}" ];then
            "{{locs.resetperms}}" "${@}" \
              --dmode '0770' --fmode '0770' \
              --user root --group "{{ugs.group}}" \
              --users root \
              --groups "{{ugs.group}}" \
              --paths "{{cfg.pillar_root}}";
            fi
            if [ -e "{{cfg.project_root}}" ];then
              "{{locs.resetperms}}" "${@}" \
              --dmode '0770' --fmode '0770'  \
              --paths "{{cfg.project_root}}" \
              --users www-data:r-x \
              --users {{cfg.user}} \
              --groups {{cfg.group}}:r-x \
              --user {{cfg.user}} \
              --group {{cfg.group}};
              "{{locs.resetperms}}" "${@}" --no-recursive -k\
              --dmode '0770' --fmode '0770'  \
              --paths "{{cfg.data.www_dir}}" \
              --paths "{{cfg.data.images}}" \
              --paths "{{cfg.data_root}}" \
              --users www-data:r-x \
              --users {{cfg.user}}:rwx\
              --groups {{cfg.group}}:r-x \
              --user {{cfg.user}} \
              --group {{cfg.group}};
              "{{locs.resetperms}}" "${@}" -k\
              --dmode '0700' --fmode '0400'\
              --user "root" --group "root"\
              --paths "{{cfg.data_root}}/configuration";
              "{{locs.resetperms}}" "${@}" \
              --no-recursive -o -k\
              --dmode '0555' --fmode '0644'  \
              --paths "{{cfg.project_root}}" \
              --paths "{{cfg.project_dir}}" \
              --paths "{{cfg.project_dir}}"/.. \
              --paths "{{cfg.project_dir}}"/../.. \
              --users www-data:--x ;
            fi
  cmd.run:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - cwd: {{cfg.project_root}}
    - user: root
    - watch:
      - file: {{cfg.name}}-restricted-perms
