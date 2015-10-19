FROM makinacorpus/makina-states-ubuntu-vivid-stable
RUN salt-call --local mc_project.init_project registry
ADD . /srv/projects/registry/project
RUN  cd /srv/projects/registry/project\
     && echo FORCE_REBUILD_ID=$(git log -n1 --pretty=format:"%h") \
     && /srv/projects/registry/project/bin/build.sh
EXPOSE 80 443
VOLUME ["/srv/projects/registry/data"]
CMD ["/srv/projects/registry/project/bin/launch.sh", "indocker", "re_configure=True""]
