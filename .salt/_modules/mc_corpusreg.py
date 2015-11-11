#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

from pprint import pprint
import json
import logging
import os
import re
import requests
import time
import salt.loader
from requests.auth import HTTPBasicAuth


PROJECT = 'registry'
log = logging.getLogger(__name__)


def create_or_get_release(u, release, gh_user, gh_password):
    tok = HTTPBasicAuth(gh_user, gh_password)
    releases = requests.get("{0}/releases".format(u), auth=tok)
    pub = releases.json()
    if release not in [a['tag_name'] for a in pub]:
        cret = requests.post(
            "{0}/releases".format(u),
            auth=tok,
            data=json.dumps({'tag_name': release,
                             'name': release,
                             'body': release}))
        if 'created_at' not in cret.json():
            pprint(cret)
            raise ValueError('error creating release')
        log.info('Created release {0}/{1}'.format(u, release))
        pub = requests.get("{0}/releases".format(u), auth=tok).json()
        if release not in [a['tag_name'] for a in pub]:
            raise ValueError('error getting release')
    release = [a for a in pub if a['tag_name'] == release][0]
    return releases, release


def upload_binaries(binaries,
                    gh_url,
                    gh_user,
                    gh_password,
                    release_name='attachedfiles'):
    '''
    '''
    orga = gh_url.replace('.git', '').split('github.com/')[1]
    u = "https://api.github.com/repos/" + orga
    releases, release = create_or_get_release(
        u, release_name, gh_user, gh_password)
    tok = HTTPBasicAuth(gh_user, gh_password)
    assets = requests.get("{0}/releases/{1}/assets".format(
        u, release['id']), auth=tok).json()
    for fpath in binaries:
        toup = os.path.basename(fpath)
        if not os.path.exists(fpath):
            raise Exception('Release file is not here: {0}'.format(fpath))
        if toup in [a['name'] for a in assets]:
            asset = [a for a in assets if a['name'] == toup][0]
            cret = requests.delete(asset['url'], auth=tok)
            if not cret.ok:
                raise ValueError('error deleting release')
        log.info('Upload of {0} started'.format(toup))
        size = os.stat(fpath).st_size
        with open(fpath) as fup:
            fcontent = fup.read()
            upurl = re.sub(
                '{.*', '', release['upload_url']
            )+'?name={0}&size={1}'.format(toup, size)
            if fpath.endswith('.md5'):
                headers = {'Content-Type': 'text/plain'}
            else:
                headers = {'Content-Type': 'application/octet-stream'}
            log.info('Uploading using {0}'.format(upurl))
            cret = requests.post(
                upurl, auth=tok, data=fcontent, headers=headers)
            jret = cret.json()
            if jret.get('size', '') != size:
                pprint(jret)
                raise ValueError('upload failed')
            log.info('{0} uploaded'.format(fpath))
    return requests.get("{0}/releases/{1}/assets".format(
        u, release['id']), auth=tok).json()


def release_binary(gh_url,
                   gh_user,
                   gh_password,
                   registry_changeset=None,
                   docker_changeset=None,
                   docker_auth_changeset=None,
                   make=True,
                   upload=True,
                   make_docker_binary=True,
                   make_auth_binary=True,
                   make_binary=True):
    cfg = __salt__['mc_utils.sls_load']('/project/.salt/PILLAR.sample')
    cfg = cfg[[a for a in cfg][0]]
    data = cfg['data']
    bins = data['binaries']
    if not registry_changeset:
        registry_changeset = bins['registry']['changeset']
    if not docker_auth_changeset:
        docker_auth_changeset = bins['auth_server']['changeset']
    if not docker_changeset:
        docker_changeset = data['docker']['changeset']
    if make and make_binary:
        cret = __salt__['cmd.run_all'](
            '/project/bin/build-binary.sh',
            env={'changeset': registry_changeset})
        if cret['retcode'] != 0:
            print(cret['stdout'])
            print(cret['stderr'])
            raise ValueError('registry build failed')
    if make and make_docker_binary:
        cret = __salt__['cmd.run_all'](
            '/project/bin/build-docker.sh',
            env={'changeset': registry_changeset})
        if cret['retcode'] != 0:
            print(cret['stdout'])
            print(cret['stderr'])
            raise ValueError('auth registry build failed')
    if make and make_auth_binary:
        cret = __salt__['cmd.run_all'](
            '/project/bin/build-auth-binary.sh',
            env={'changeset': registry_changeset})
        if cret['retcode'] != 0:
            print(cret['stdout'])
            print(cret['stderr'])
            raise ValueError('auth registry build failed')
    if upload:
        binaries = [
            '/project/binaries/docker-{0}.xz'.format(
                docker_changeset),
            '/project/binaries/docker-{0}.xz.md5'.format(
                docker_changeset),
            '/project/binaries/registry-{0}.xz'.format(
                registry_changeset),
            '/project/binaries/registry-{0}.xz.md5'.format(
                registry_changeset),
            '/project/binaries/auth_server-{0}.xz'.format(
                docker_auth_changeset),
            '/project/binaries/auth_server-{0}.xz.md5'.format(
                docker_auth_changeset)]
        upload_binaries(binaries, gh_url, gh_user, gh_password)
# vim:set et sts=4 ts=4 tw=80:
