Components
------------
Shell scripts:
- a Release module in .salt to release two binaries (see: bin/release_registry.sh)

	-  one for cesanta/docker_auth (see also: bin/build-auth-binary.sh)
	-  one for the docker distribution binary (see also: bin/build-binary.sh)

Salt modules:
- mc_corpusreg.py: helper to release the two go binaries (registry & docker_auth)
- mc_launcher.py: helper to start the circus daemon which launch all other processes:

    - nginx reverse proxy to:

        - /docker_auth_service: cesanta/docker_auth
        - /.*: passthrough to docker registry

	- sshd
	- cron
	- logrotate
	- registry
	- docker_auth




Release the go binaries
--------------------------
- Maybe udpate .salt/PILLAR.sample to upgrade/edit the versions of the registry & docker_auth
- launch the release helper which will spawn a docker container, build the binaries into two others and finally upon completness upload binaries to github.
<pre>
$EDITOR .salt/PILLAR.sample
export GH_USER="<github_username>"
# notice the initial space to avoid this going into your bash history
 export GH_PASSWORD="<github_password>"
./bin/release_registry.sh
</pre>

Develop the code of this image
--------------------------------
First, you will have to add your user to a special **editor** group  for the sole purpose
of editing the files of a running container.
<pre>
groupadd -u 65753 editor
gpasswd -a $(whoami) editor
</pre>

Secondly, you will need to have a first sucessful complete build to have a "cache" image to stage your new developements on.
<pre>
docker build -t mydevtag .
</pre>

Last but not least, now you can launch a container based on this image to hapilly hack the image
<pre>
</pre>
