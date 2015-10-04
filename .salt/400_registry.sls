{% set cfg = opts.ms_project %}
{% set data = cfg.data %}
download:
  file.managed:
    - name: "{{cfg.project_root}}/registry.xz"
    - source: "https://github.com/makinacorpus/corpus-dockerregistry/releases/download/bins/registry-{{data.changeset}}.xz"
    - source_hash: "https://github.com/makinacorpus/corpus-dockerregistry/releases/download/bins/registry-{{data.changeset}}.xz.md5"
    - user: {{cfg.user}}
    - group: {{cfg.group}}
    - mode: 750 
extract:
  cmd.wait:
  - name: "xz -k -d -c registry.xz > registry.tmp && mv -f registry.tmp registry && chmod 755 registry"
  - cwd: "{{cfg.project_root}}"
  - user: root
  - watch:
    - file: download
extract-fallback:
  cmd.run:
  - name: "xz -k -d -c registry.xz > registry.tmp && mv -f registry.tmp registry && chmod 755 registry"
  - onlyif: test ! -e registry
  - cwd: "{{cfg.project_root}}"
  - user: root
  - watch:
    - cmd: extract
   
