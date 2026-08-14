# Docker SOLR Example

Based on the guidance here: https://github.com/docker-solr/docker-solr

Using docker compose to do the set up and configure volumes.

Mapping local data folder to to /var/solr so that we can manage config files
outside of the container.

## Binary Distribution Image

This repository now includes a multi-stage Dockerfile that downloads the Apache
Solr binary distribution on top of Debian Trixie and produces a runtime image
that keeps the same `/var/solr` volume layout used by the official image.

The compose service builds that image locally and keeps the existing
`solr-precreate gettingstarted` startup command.

This is mainly useful for security patching. `SOLR_VERSION` and
`SOLR_PACKAGE` control the Solr distribution layer, while the base image
arguments control the underlying OS runtime. That lets you rebuild the same
Solr version on a newer patched Debian base without waiting for the upstream
Solr image to be refreshed.

To start it:

```sh
docker compose up --build
```

The default build arguments are `SOLR_VERSION=10.0.0`,
`SOLR_PACKAGE=slim`, `BUILDER_BASE_IMAGE=debian:trixie`, and
`RUNTIME_BASE_IMAGE=debian:trixie`. Change those in `docker-compose.yml` when
you need a different Solr release, want the full instead of slim distribution,
or want to rebuild on a newer patched base image.

## CI

The repository includes a GitHub Actions workflow at
`.github/workflows/solr-image-ci.yml` that rebuilds the image on pull requests,
on pushes to `main`, on manual dispatch, and every Monday at 05:00 UTC.

That workflow keeps the configured Solr package and version fixed, rebuilds the
image against the configured base-image arguments, and fails if Trivy finds
unfixed HIGH or CRITICAL vulnerabilities in the resulting image.
