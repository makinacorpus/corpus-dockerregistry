FROM makinacorpus/makina-states-ubuntu-vivid-stable
ADD . /srv/projects/registry/project
RUN  cd /srv/projects/registry/project\
     && echo FORCE_REBUILD_ID=$(git log -n1 --pretty=format:"%h")\
     && /srv/projects/registry/project/bin/build.sh
EXPOSE 80 443
VOLUME ["/srv/projects/registry/data",
        "/var/log/nginx"]
        "/var/log/circus"]
CMD ["/srv/projects/registry/project/bin/launch.sh", "indocker", "re_configure=True"]
