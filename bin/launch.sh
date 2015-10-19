#!/usr/bin/env bash
cd "$(dirname "${0}")"
MS="${MS:-"https://github.com/makinacorpus/makina-states.git"}";MS_BR="stable"
name="registry"
W="$(pwd)"
DATA="$(pwd)_data"
FROM="${FROM:-"$(egrep ^FROM $W/Dockerfile|head -n1|awk '{print $2}')"}"
LEVEL="${LEVEL:-info}"
pillar="${pillar:-"${W}/../data/configuration/pillar.sls"}"
dpillar="${W}/../pillar/init.sls"
indocker="";devmode=""
for i in ${@};do
    if [ "x${i}" = "xindocker" ];then indocker="1";shift;fi
    if [ "x${i}" = "xdev" ];then dev="1";shift;fi
done
if [ "x${indocker}" = "x" ];then
    if [ -e "$pillar" ];then cp -fv "${pillar}" "${dpillar}";fi
    salt-call --retcode-passthrough -l${LEVEL} --local mc_launcher.launch "${@}"
    exit $?
fi
for i in\
 /srv/salt/makina-states /srv/mastersalt/makina-states $W/makina-states;do
    if [ -d $i ];then break;fi
done
if [ ! -d $ms ];then
    git clone "${MS}" "${ms}";cd "${ms}";git reset --hard "remotes/origin/${MS_BR}"
fi
set -x
docker run -ti\
    -v "${ms}":/srv/salt/makina-states\
    -v "${ms}":/srv/mastersalt/makina-states\
    -v "${DATA}":/srv/projects/${name}/data\
    -v "${W}":/srv/projects/${W}/project\
    "${FROM}" "${@}"
# vim:set et sts=4 ts=4 tw=80:
