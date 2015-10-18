#!/usr/bin/env bash
cd "$(dirname ${0})/.."
set -x
saltcall() {
    salt-call --local -lall --retcode-passthrough "${@}"
}

run_do() {
    set -ex
    for i in /project/.salt/_modules/*py;do
        ln -sv "${i}" /srv/salt/_modules
    done
    saltcall mc_corpusreg.release_binary\
        "$GH_URL" "$GH_USER" "$GH_PASSWORD" "$@"
}

if [ "x${1}" = "xDO" ];then
    shift
    run_do $@
else
    docker rm -f mcdockerregistrywrapper || /bin/true
    docker run -ti --rm --name="mcdockerregistrywrapper"\
        -e GH_URL="${GH_URL:-https://github.com/makinacorpus/corpus-dockerregistry.git}"\
        -e GH_USER="${GH_USER}"\
        -e GH_PASSWORD="${GH_PASSWORD}"\
        -v $PWD:/project\
        -v /usr/bin/docker:/usr/bin/docker:ro\
        -v /var/lib/docker:/var/lib/docker\
        -v /var/run/docker:/var/run/docker\
        -v /var/run/docker.sock:/var/run/docker.sock\
        makinacorpus/makina-states-ubuntu-vivid-stable:latest\
        /project/bin/release_registry.sh DO $@
fi
# vim:set et sts=4 ts=4 tw=80:
