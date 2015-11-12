#!/usr/bin/env bash
cd "$(dirname ${0})/.."
NAME="$(egrep "ADD.*srv.*project\s*$" Dockerfile|sed -re "s,.*/srv/projects/([^/]+)/project,\1,g")"
W="$(pwd)"
DATA="${DATA:-"${W}_data"}"
dname="mc${NAME}wrapper"
GH_URL="${GH_URL:-$(git remote show origin|grep 'URL push'|awk '{print $4}')}"
v_run() { set -x;echo "${@}";"${@}";ret=${?};set +x;return ${ret}; }
saltcall() { v_run salt-call --local -ldebug --retcode-passthrough "${@}"; }
if  [ "x${1}" = "x--help" ] ||\
    [ "x${GH_USER}" = "x"  ] ||\
    [ "x${GH_PASSWORD}" = "x" ];then
    printf "usage:\nGH_USER=x GH_PASSWORD=y $0 ARGS\n";exit 1;
elif [ "x${1}" = "xDO" ];then
    # code running inside the container
    shift
    cd /srv/salt/makina-states;git pull origin stable
    saltcall mc_project.init_project ${NAME} \
     && saltcall mc_project.sync_modules ${NAME} \
     && saltcall mc_corpusreg.release_binary \
        "$GH_URL" "$GH_USER" "$GH_PASSWORD" "$@"
    exit ${?}
fi
# code to spawn a container running our release script
set -x
sudo docker rm -f "$dname" || /bin/true
if [ "x${SKIP_BUILD}" = "x" ];then
    ${W}/bin/build-auth-binary.sh
    ${W}/bin/build-binary.sh
    ${W}/bin/build-docker.sh
fi
sudo docker run -ti --rm --name="$dname"\
    --privileged\
    -e GH_URL="${GH_URL}"\
    -e GH_USER="${GH_USER}"\
    -e GH_PASSWORD="${GH_PASSWORD}"\
    -v "${W}":/srv/projects/${NAME}/project\
    -v "${DATA}":/srv/projects/${NAME}/project_data\
    -v "${DATA}":/srv/projects/${NAME}/data\
    -v /usr/bin/docker:/usr/bin/docker:ro\
    -v /var/lib/docker:/var/lib/docker\
    -v /var/run/docker:/var/run/docker\
    -v /var/run/docker.sock:/var/run/docker.sock\
    makinacorpus/makina-states-ubuntu-vivid-stable:latest \
$(\
if [ "x${DOCKER_DEBUG}" != "x" ];then echo bash;\
else echo /srv/projects/${NAME}/project/bin/release_registry.sh DO "$@";fi)
ret=$?
exit $ret
# vim:set et sts=4 ts=4 tw=80:
