Makina-States bases docker registry
===================================
This provides a docker distribution (registry v2) docker image based on
makina-states.

The registry wont allow any anonymous configuration

Volumes
-----------
You need to add a volume that will contains those subdirs::
<pre>

   ./configuration:       <- contains the configuration
       pillar.sls:        <- extra registry saltstack configuration
       registry.webaccess <- htpasswd file               (created but empty)
   ./data/images          <- where the images are stored (autocreated)
   ./data/www_dir         <- reverse proxy docroot       (autocreated)

</pre>

For convenience, we name **./volume** such a volume in the next section

OPTIONAL: Generate a a certificate with a custom authority for test
----------------------------------------------------------------------------
<pre>
domain="yourdomain.tld"
mkdir -p volume/configuration
openssl genrsa -des3 -out sca-key.pem
openssl genrsa -des3 -out s${domain}-key.pem
openssl rsa -in sca-key.pem -out ca-key.pem
openssl rsa -in s${domain}-key.pem -out ${domain}-key.pem
openssl req -new -x509 -days $((365*30)) -key ca-key.pem -out ca.pem -subj "/C=FR/ST=dockerca/L=dockerca/O=dockerca/CN=dockerca/"
openssl req -new -key ${domain}-key.pem -out ${domain}.csr -subj "/C=FR/ST=dockerca/L=dockerca/O=dockerca/CN=*.${domain}/"
openssl x509 -CAcreateserial -req -days $((365*30)) -in ${domain}.csr -CA ca.pem -CAkey ca-key.pem -out ${domain}.crt
cat ${domain}.crt ca.pem > ${domain}.bundle.crt
</pre>

Register the certificate to the local openssl configuration
<pre>
cp ${domain}.bundle.crt /usr/local/share/ca-certificates && update-ca-certificates
</pre>

Configure the PILLAR
-------------------------
You need then to fill the pillar to setup a domain to serve for the registry (the virtualhost name) and the SSL certificate details
<pre>
mkdir -p volume/configuration
cp .salt/PILLAR.sample volume/configuration/pillar.sls
sed -re "s/makina-projects.projectname/makina-projects.registry/g" -i volume/configuration/pillar.sls
$EDITOR volume/configuration/pillar.sls
  -> edit at least:

    - domain
    - certificate key and bundle
    - list of http users and password to allow
    - You can remove what is not overriden if you want.
</pre>

Example configuration/pillar.sls
<pre>
makina-projects.registry:
  data:
    domain: "registryh.docker.tld"
    ssl_cert: |
        -----BEGIN CERTIFICATE-----
        MIIDMjCCAhoCCQDvVm1SttCzxTANBgkqhkiG9w0BAQsFADBZMQswCQYDVQQGEwJG
        ...
        ugItmnXoVCkHHrZvydXC/zxah21lfVtA05xB8zsieLyLmsy8lH2exftnpM3QgMAp
        G9S8ZWex
        -----END CERTIFICATE-----
        -----BEGIN CERTIFICATE-----
        MIIDhTCCAm2gAwIBAgIJAKWNQ8MgC28RMA0GCSqGSIb3DQEBCwUAMFkxCzAJBgNV
        ...
        S17wzmffRktued3rJ+efBUvegdnbJG1nxT51znLy5mlLAD37OCf2DgqlGyL1UcEr
        XhidyUpZcJ4Fr2koosQZ8z20j2tXDanhbSi1osJ6yQi8rjRdJZeCMwA=
        -----END CERTIFICATE----- 
    ssl_key: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpQIBAAKCAQEAzzBVPJvbMXFBN1mErd+T3QDUpvI6YvJt3JJjBptvcke1X9Si
      ...
      fFwSDE8arfpgbAfrtYgWjd0248GRV46iE1BuE4uuZ41XQ9J9DILzjMk=
      -----END RSA PRIVATE KEY-----
# vim:set ft=sls et : 
</pre>


Allow users to connect to the registry
--------------------------------------
<pre>
htpasswd -cm volume/configuration/registry.webaccess <USER> <PASSWORD>
</pre>

Run
---
<pre>
docker run -d -v $PWD/volume:/srv/projects/registry/data makinacorpus/registry
</pre>
