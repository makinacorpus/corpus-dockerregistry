#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
import time
import salt.loader
import os
import logging


log = logging.getLogger(__name__)
PROJECT = 'registry'


def sshconfig(name=PROJECT):
    '''
    Try to find ssh keys inside /ms_ssh and allow them to
    connect as the root user
    '''
    cfg = __salt__['mc_project.get_configuration'](name)
    for path in [
        os.path.join(cfg['data_root'], 'ssh'),
        os.path.join(cfg['data_root'], 'ms_ssh'),
        '/ms_ssh'
    ]:
        if not os.path.exists(path):
            continue
        for i in os.listdir(path):
            fp = os.path.join(path, i)
            if i.endswith('.pub'):
                ret = __salt__['ssh.set_auth_key_from_file']('root', fp)
                if ret in ['no change', 'new']:
                    log.info('{0} added to root ssh auth'.format(fp))


def reconfigure(name=PROJECT):
    '''
    Run everything here that needed to reconf
    your app based on discovery or new pillar
    configuration upon a container boot.
    '''
    _s = __salt__

    cfg = _s['mc_project.get_configuration'](name)
    ret = _s['mc_project.deploy'](name,
                                  only='install',
                                  only_steps=['050_conf.sls'])
    output = salt.loader.outputters(__opts__)
    print(output['nested'](ret))
    if not ret['result']:
        raise ValueError('configure failed')
    return ret


def launch(name=PROJECT, ssh_config=False, re_configure=False):
    '''
    Run what's needed and stop everything

    This means for example launching circus
    and stopping it and all that it can have left
    behind
    '''
    if ssh_config or re_configure:
        sshconfig()
    if re_configure:
        reconfigure(name=name)
    # this will block here, we launch circus, if this die
    # it means that the app died somehow
    ret = {'retcode': 1}
    try:
        cfg = __salt__['mc_project.get_configuration'](name)
        data = cfg['data']
        log.info('Registry is running at http://{0} - https://{0}'
                 ''.format(data['domain']))
        log.info('Auth server (token) is running at http://{0}/authserver/'
                 ' - https://{0}/authserver/'
                 ''.format(data['domain']))
        log.info('Static users:')
        for user, udata in data['users'].items():
            log.info('- {0} :: {1}'.format(user, udata['password']).strip())
        log.info('Circus is starting <C-C> to stop')
        ret = __salt__['cmd.run_all']('/usr/bin/circus.sh start')
    except (KeyboardInterrupt, IOError, OSError) as exc:
        # try to shutdown circus if possible
        now = time.time()
        log.info('graceful circus stop')
        for i in range(30):
            log.info('Circus stop try {0}/30'.format(i))
            time.sleep(0.04)
            cret = __salt__['cmd.run_all']('circusctl stop')
            for out in ['stdout', 'stderr']:
                if 'already' in cret[out]:
                    cret['retcode'] = 1
            if time.time() > (now + 10):
                log.info('Failed to stop')
                break
            if not cret['retcode']:
                break
        log.info('graceful circus quit')
        for i in range(30):
            log.info('Circus shutdown try {0}/30'.format(i))
            time.sleep(0.04)
            cret = __salt__['cmd.run_all']('circusctl quit --waiting')
            for out in ['stdout', 'stderr']:
                if 'already' in cret[out]:
                    cret['retcode'] = 1
            if time.time() > (now + 10):
                log.info('Failed to stop')
                break
            if not cret['retcode']:
                break
        # try to remove leftover processes
        for i in [
            'cron', 'nginx', 'sshd', 'rsyslogd', 'fail2ban-server',
            # try to remove leftover processes for this particular image
            'registry', 'auth_server', 'redis-server',
        ]:
            __salt__['cmd.run_all']('killall -9 {0}'.format(i))
    if ret['retcode'] != 0:
        raise Exception('died')
# vim:set et sts=4 ts=4 tw=80:
