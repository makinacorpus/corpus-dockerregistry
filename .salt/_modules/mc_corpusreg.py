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


def create_or_get_release(rdvn gh_user, gh_password):
    tok = HTTPBasicAuth(gh_user, gh_password)
    releases = requests.get("{0}/releases".format(u), auth=tok)
    pub = releases.json()
    if fdv not in [a['tag_name'] for a in pub]:
        cret = requests.post(
            "{0}/releases".format(u),
            auth=tok,
            data=json.dumps({'tag_name': fdv,
                             'name': fdv,
                             'body': fdv}))
        if 'created_at' not in cret.json():
            pprint(cret)
            raise ValueError('error creating release')
        log.info('Created release {0}/{1}'.format(u, fdv))
        pub = requests.get("{0}/releases".format(u), auth=tok).json()
        if fdv not in [a['tag_name'] for a in pub]:
            raise ValueError('error getting release')
    release = [a for a in pub if a['tag_name'] == fdv][0]
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
    create_or_get_release(release_name, gh_user, gh_password)
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
            cret = requests.post(
                upurl, auth=tok,
                data=fcontent,
                headers={
                    'Content-Type':
                    'application/x-xz'})
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
                   docker_auth=_changeset=None,
                   registry_changeset=None,
                   upload=True,
                   make_auth_binary=True,
                   make_binary=True):
    cfg = __salt__['mc_dumper.sls_load']('/project/.salt/PILLAR.sample')
    import pdb;pdb.set_trace()  ## Breakpoint ##
    if make_binary:
        cret = __salt__['cmd.run_all'](
            '/project/bin/build-binary.sh',
            env={'changeset': registry_changeset})
        if cret['retcode'] != 0:
            print(cret['stdout'])
            print(cret['stderr'])
            raise ValueError('registry build failed')
    if upload:
        binaries = [
            '/project/registry-{0}'.format(registry_changeset),
            '/project/registry-{0}.md5'.format(registry_changeset),
        ]
        upload_binaries(binaries, gh_url, gh_user, gh_password)
# vim:set et sts=4 ts=4 tw=80:
