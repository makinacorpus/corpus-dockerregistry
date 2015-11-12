#!/usr/bin/env bash
cd "$(dirname "${0}/..")"
W="$(pwd)"
DATA="${DATA:-"${W}_data"}"
LEVEL="${LEVEL:-info}"
pillar="${pillar:-"${W}/../data/configuration/pillar.sls"}"
dpillar="${W}/../pillar/init.sls"
MS_DEVMODE=""
if [ -e "$pillar" ];then cp -fv "${pillar}" "${dpillar}";fi
saltcall() { v_run salt-call --local -lall --retcode-passthrough "${@}"; }
v_run() { set -x;"${@}";"${@}";set +x; }
v_run saltcall mc_launcher.launch "${@}"
# vim:set et sts=4 ts=4 tw=80:
