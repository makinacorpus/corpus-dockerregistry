Components
------------
Shell scripts:
- a Release module in .salt to release two binaries (see: bin/release_registry.sh)

	-  one for cesanta/docker_auth (see also: bin/build-auth-binary.sh)
	-  one for the docker distribution binary (see also: bin/build-binary.sh)

Salt modules:
- mc_corpusreg.py: helper to release the two go binaries (registry & docker_auth)
- mc_launcher.py: helper to start the circus daemon which launch all other processes:

	- nginx
	- sshd
	- cron
	- logrotate
	- registry
	- docker_auth

The image consists in
-----------------------
- an nginx reverse proxy to:

	- /docker_auth_service: cesanta/docker_auth
	- /.*: passthrough to docker registry

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
