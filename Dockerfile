FROM makinacorpus/makina-states-ubuntu-vivid-stable
RUN salt-call --local mc_project.init_project registry
ADD . /srv/projects/registry/project
RUN  cd /srv/projects/registry/project\
     && echo FORCE_REBUILD_ID=$(git log -n1|head -n1|awk '{print $2}')\
     && salt-call --local -lall mc_project.deploy registry only=fixperms,sync_modules\
     && salt-call --local -lall mc_project.deploy registry only=install,fixperms
EXPOSE 80 443
VOLUME ["/srv/projects/registry/data"]
CMD [salt-call --local -lall mc_launcher.launch reconfigure=True]
