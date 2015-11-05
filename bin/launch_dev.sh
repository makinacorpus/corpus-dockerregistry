#!/usr/bin/env bash
cd "$(dirname "${0}/..")"
W="$(pwd)"
name="$(egrep "ADD.*srv.*project\s*$" Dockerfile|sed -re "s,.*/srv/projects/([^/]+)/project,\1,g")"
DATA="${DATA:-"${W}_data"}"
VOLUME="${DATA:-"${W}_data"}"
FROM="${FROM:-"$(egrep ^FROM $W/Dockerfile|head -n1|awk '{print $2}')"}"
docker run -ti \
    -e MS_DEVMODE="${MS_DEVMODE:-1}" \
    -v ~/.ssh:/ms_ssh \
    -v "${VOLUME}":/srv/projects/${name}/data \
    -v "${W}":/srv/projects/${W}/project \
    ${DOCKER_RUN_ARGS} "${FROM}" "${@}"
# vim:set et sts=4 ts=4 tw=80:
