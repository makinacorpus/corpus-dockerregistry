#!/usr/bin/env bash
cd "$(dirname ${0})/.."
W="${PWD}";DATA="${DATA:-"${W}_data"}";dname="mcdockerregistrywrapper"
GH_URL="${GH_URL:-$(git remote show origin|grep 'URL push'|awk '{print $4}')}"
v_run() { set -x;"${@}";"${@}";set +x; }
saltcall() { v_run salt-call --local -lall --retcode-passthrough "${@}"; }
if  [ "x${1}" = "x--help" ] ||\
    [ "x${GH_USER}" = "x"  ] ||\
    [ "x${GH_PASSWORD}" = "x" ];then
    printf "usage:\nGH_USER=x GH_PASSWORD=y $0 ARGS\n";exit 1;
elif [ "x${1}" = "xDO" ];then
    # code running inside the container
    shift
    saltcall mc_project.init_project registry \
     && saltcall mc_corpusreg.release_binary \
        "$GH_URL" "$GH_USER" "$GH_PASSWORD" "$@"
    exit ${?}
fi
# code to spawn a container running our release script
sudo docker rm -f "$dname" || /bin/true
sudo docker run --rm --name="$dname"\
    -e GH_URL="${GH_URL}"\
    -e GH_USER="${GH_USER}"\
    -e GH_PASSWORD="${GH_PASSWORD}"\
    -v "${W}":/srv/projects/registry/project\
    -v "${DATA}":/data\
    -v /usr/bin/docker:/usr/bin/docker:ro\
    -v /var/lib/docker:/var/lib/docker\
    -v /var/run/docker:/var/run/docker\
    -v /var/run/docker.sock:/var/run/docker.sock\
    makinacorpus/makina-states-ubuntu-vivid-stable:latest\
    /srv/projects/registry/project/bin/release_registry.sh DO "$@"
ret=$?
exit $ret
# vim:set et sts=4 ts=4 tw=80:
