Hacking notes
================

## Table of Contents
  * [Develop the code of this image](#develop-the-code-of-this-image)
    * [The editor group](#the-editor-group)
    * [Building the image](#building-the-image)
    * [Debugging your container, AKA live edit](#debugging-your-container-aka-live-edit)
      * [Method 1: Manual edit (recommended)](#method-1-manual-edit-recommended)
        * [What to do if the container crashed](#what-to-do-if-the-container-crashed)
      * [Method 2: Edit a running container](#method-2-edit-a-running-container)
    * [commiting the result back](#commiting-the-result-back)
  * [Maintenance routine](#maintenance-routine)
  * [Specific notes for this image](#specific-notes-for-this-image)
    * [Components](#components)
    * [Release the go binaries](#release-the-go-binaries)

## A note on makina-states images
Mostly all makina-states based images:
  - use [circus](https://circus.readthedocs.org/en/latest/) to manage the processes inside the containers
  - logrotate to rotate most system logs
  - vixie-cron, logrotate & sshd are launched alongside the app processes
  - sshd do not allow connections by default (no user password, & no keys in authorized_keys)

## Develop the code of this image

### The editor group
To allow file cooperation from inside/out or the container, we use a special editor group that has access to the most important files of your container.

Those files are shared via a docker volumes.

This allows you to:
 * develop from outside the container, use your IDE, etc, when the container is running.
 * do any git operation from outside

The editor group must exists on your local machine, and if **editor** already exists, just choose another name.<br/>
The important thing is to share the **gid** (65753).
```bash
sudo groupadd -u 65753 editor
sudo gpasswd -a $(whoami) editor
newgrp editor # in any opened shell, or reboot(reconnect to a new) your session
```
Although the editor group is automatically created in makina-states based images,<br/>
it's up to the image maintainer to **allow this group to access files** in development mode (via ``.salt/fixperms.sls``).

### Building the image
The main thing you want to do with a docker image is to build it.<br/>
When you feels the build enoughtly stable, you can tag it to speed up future container spawns.<br/>
This will allows you to hack your code without having to rebuild each time you change a single letter.<br/>
```bash
sudo docker build -t mydevtag .
```

### Debugging your container, AKA live edit
#### Method 1: Manual edit (recommended)
The idea will have to find a "parent" image to test your changes on.<br/>
In other words, you ll be mostly playing by hand the Dockerfile in your docker shell.<br/>
This parent image can be either:
    - The image in the **FROM** Dockerfile statement (eg: makinacorpus/makina-states-ubuntu-vivid-stable)
    - An image produced by a previous build that you can stage you changes on (eg: mydevtag)

When you replayed the Dockerfile statements, you can go on with any command of your will including launching your app.
When you are happy of the result, you can then commit your code and test a build from scratch.
```bash
cat Dockerfile # see what's the hell how the image is constructed
               # to copy/paste the steps in your further shell
docker run $args -ti mydevtag bash
# do something that's needed to make your code deployment procedure happy
# from the "mydevtag" checkpoint
# in makina-states, this is trivial
salt-call --local -lall mc_project.deploy yourproject
# The next command is supposed to launch manually your app
/srv/projects/*/bin/launch.sh
# Wash, Since, Repeat, Enjoy
```
***NOTE***: the "salt-call" dance is only needed when you changed something to the deployment, you may not have to run it.

#### Get your container IP address
```bash
docker ps -a # Get the container IP
docker inspect -f '{{ .NetworkSettings.IPAddress }}' $id
```

##### What to do if the container crashed
If the container crashed and you want to bring it back to life, it can be tedious as bash is not a daemon<br/>
The trick is to commit back the container to a tempary image and relaunch it<br/>
```bash
# find your container ID
docker ps -a
# commit it to an image
docker commit $ID adevtag
# run again your container
docker run $args -ti adevtag bash
# in another shell window, untag to save space at next image pruning
docker rmi adevtag
```

#### Method 2: Edit a running container
This is mostly to inspect the running processes and stuff, but you won't be able to kill circus<br/>
as this would kill your container away.
```bash
# find your container ID
docker ps -a
# attach a shell to it
docker run $args -ti $id bash
# from there you can do all what was indicated in the previous steps
```

### commiting the result back
When you have finished your work, it's time to test a final rebuild<br/>
And eventually, you certainly want to commit back the changes to your code repository from within your host
```bash
sudo docker build -t myfinaltag .
git st && git add . .salt && git commit -am "Finished work" && git push
```
## Maintenance routine
To cleanup your containers & images from your busy development work, you must often do:
```bash
# if you do not have dockviz yet
alias dockviz="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock nate/dockviz"
dockviz images -t -> remove unused tags with docker rmi $image_id
wget https://raw.githubusercontent.com/makinacorpus/makina-states/master/docker/cleanup.sh
chmod +x cleanup.sh # remove dangling images, failed & stopped containers, READ ONCE THE SCRIPT !!!
sudo ./cleanup.sh
```
This will cleanup things and give your again some precious free space.


<!--
TOC created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)
-->
