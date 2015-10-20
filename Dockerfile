FROM makinacorpus/makina-states-ubuntu-vivid-stable
ADD .git /srv/projects/registry/project/.git
RUN  cd /srv/projects/registry/project\
     && git reset --hard\
     && echo FORCE_REBUILD_ID=$(git log -n1 --pretty=format:"%h")\
     && /srv/projects/registry/project/bin/build.sh
EXPOSE 80 443
VOLUME ["/srv/projects/registry/data"]
CMD ["/srv/projects/registry/project/bin/launch.sh", "indocker", "re_configure=True"]
