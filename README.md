Makina-States bases docker registry
===================================

This provides a docker distribution (registry v2) docker image based on
makina-states.

The registry wont allow any anonymous configuration

Volumes
-----------
You need to add a volume that will contains those subdirs:

  - ./configuration: contains the configuration
    - ./configuration/cert.pem: certificate in PERM format
    - ./configuration/key.pem: certificate in PERM format
  - ./data/images: where the images are stored
  - ./data/www_dir: reverse proxy docroot

Allow users to connect to the registry
--------------------------------------
<pre>
  docker run -ti -d -v /path/to/volume_on_host:/srv/projects/registry/data makinacorpus/registry bash
  cd /srv/projects/registry/data/configuration
  htpasswd -cm configuration/registry.webaccess <USER> <PASSWORD>
</pre>

Configure the SSL certificate
------------------------------
By default we run with a non secured selfsigned certificate which is always rebuilt
upon configuration.

You may provide a trusted cert by adding:

- configuration/cert.pem:
   Put here your certificate (including all the trust chain) in PEM format
- configuration/key.pem:
   Put here your certificate key in PEM format

Run
---
<pre>
  docker run -d -v /path/to/volume_on_host:/srv/projects/registry/data\
    makinacorpus/registry
</pre>
