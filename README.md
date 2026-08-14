# Docker SOLR Example

Based on the guidance here: https://github.com/docker-solr/docker-solr

Using docker compose to do the set up and configure volumes.

Mapping local data folder to to /var/solr so that we can manage config files
outside of the container.

## Source-Built Image

This repository now includes a multi-stage Dockerfile that builds Apache Solr
from the source release on top of Debian Trixie and produces a runtime image
that keeps the same `/var/solr` volume layout used by the official image.

The compose service builds that image locally and keeps the existing
`solr-precreate gettingstarted` startup command.

To start it:

```sh
docker compose up --build
```

The default build argument is `SOLR_VERSION=10.0.0`. Change that in
`docker-compose.yml` if you need a different source release.
