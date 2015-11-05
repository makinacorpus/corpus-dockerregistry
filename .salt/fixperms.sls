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
            setfacl -P -R -b -k "{{cfg.project_dir}}"
            # layout directories belongs to {{cfg.user}}:{{cfg.group}}
            "{{locs.resetperms}}" --no-acls --no-recursive \
               --paths="{{cfg.project_dir}}" \
               --paths="{{cfg.project_dir}}"/.. \
               --paths="{{cfg.project_dir}}"/../.. \
               --dmode '0751' --fmode '0770' \
               --user {{cfg.user}} --group {{cfg.group}};
            # pillar layout directories belongs to {{cfg.user}}:root
            "{{locs.resetperms}}" --no-acls\
               --paths "{{cfg.pillar_root}}" \
               --dmode '0770' --fmode '0770'  \
               --user {{cfg.user}} --group root;
            # read only for group: editor
            # Other is not authorized to access any file
            find \
              "{{cfg.data_root}}/ssh" \
              "{{cfg.data_root}}/configuration" \
              -type f -or -type d | while read i;do
                if [ ! -h "${i}" ];then
                  if [ -d "${i}" ];then
                    chmod g-s "${i}"
                    chown {{cfg.user}}:{{cfg.group}} "${i}"
                    chmod g+rxs-w,o-rwx "${i}"
                  elif [ -f "${i}" ];then
                    chown {{cfg.user}}:{{cfg.group}} "${i}"
                  fi
                fi
              done
            # read/write for group: editor
            # Other is not authorized to access any file
            find \
              "{{cfg.data_root}}/data" \
              "{{cfg.data.www_dir}}" \
              "{{cfg.data.images}}" \
              -type f -or -type d | while read i;do
                if [ ! -h "${i}" ];then
                  if [ -d "${i}" ];then
                    chmod g-s "${i}"
                    chown {{cfg.user}}:{{cfg.group}} "${i}"
                    chmod g+rwxs,o-rwx "${i}"
                  elif [ -f "${i}" ];then
                    chown {{cfg.user}}:{{cfg.group}} "${i}"
                  fi
                fi
              done
            "{{locs.resetperms}}" --no-acls \
               --paths "{{cfg.data_root}}/configuration" \
               --dmode '2750' --fmode '0440' \
               --user "{{cfg.user}}" --group {{cfg.group}}
  cmd.run:
    - name: {{cfg.project_dir}}/global-reset-perms.sh
    - cwd: {{cfg.project_root}}
    - user: root
    - watch:
      - file: {{cfg.name}}-restricted-perms
