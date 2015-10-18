{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
{% for binary in ['registry', 'docker_auth'] %}
{{binary}}-download:
  file.managed:
    - name: "{{cfg.project_root}}/{{binary}}.xz"
    - source: "https://github.com/makinacorpus/corpus-dockerregistry/releases/download/binaries/{{binary}}-{{data.changeset}}.xz"
    - source_hash: "https://github.com/makinacorpus/corpus-dockerregistry/releases/download/binaries/{{binary}}-{{data.changeset}}.xz.md5"
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - mode: 750
{{binary}}-container:
  cmd.directory:
    - name: "{{cfg.project_root}}/bin"
    - user: root
    - mode: 755
    - makedirs: true
{{binary}}-extract:
  cmd.wait:
    - name: "xz -k -d -c {{binary}}.xz > {{binary}}.tmp && mv -f {{binary}}.tmp bin/{{binary}} && chmod 755 bin/{{binary}}"
    - cwd: "{{cfg.project_root}}"
    - user: root
    - watch:
      - file: {{binary}}-download
      - file: {{binary}}-container
extract-fallback:
  cmd.run:
    - name: "xz -k -d -c {{binary}}.xz > {{binary}}.tmp && mv -f {{binary}}.tmp bin/{{binary}} && chmod 755 bin/{{binary}}"
    - onlyif: test ! -e bin/{{binary}}
    - cwd: "{{cfg.project_root}}"
    - user: root
    - watch:
      - cmd: {{binary}}-extract
      - file: {{binary}}-container
{% endfor %}
