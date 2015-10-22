#!/usr/bin/env bash
# build all mak;ina-states based projects in the image
cd /srv/projects
set -ex
find -type d -maxdepth 1 -mindepth 1 | while read project;do
    salt-call --retcode-passthrough --local -lall mc_project.deploy "${project}" "$@"
done
# vim:set et sts=4 ts=4 tw=80:
