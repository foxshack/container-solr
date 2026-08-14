# Docker SOLR Example

Based on the guidance here: https://github.com/docker-solr/docker-solr

Using docker compose to do the set up and configure volumes.

Mapping local data folder to to /var/solr so that we can manage config files
outside of the container.

## Binary Distribution Image

This repository now includes a multi-stage Dockerfile that downloads the Apache
Solr binary distribution on top of Debian Trixie and produces a runtime image
that keeps the same `/var/solr` volume layout used by the official image.

To stay drop-in compatible with projects currently using `solr:9.8`, the image
uses the upstream Docker helper scripts from the Solr distribution itself (the
same script family used by the official image), including commands like
`solr-precreate`.

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

This 9.x branch is pinned to Solr `9.8.1` and uses Java 21 by default on
Debian Trixie (the Java version available in that base image).

The default build arguments are `SOLR_VERSION=9.8.1`,
`SOLR_PACKAGE=slim`, `JAVA_RUNTIME_PACKAGE=openjdk-21-jre-headless`,
`BUILDER_BASE_IMAGE=debian:trixie`, and `RUNTIME_BASE_IMAGE=debian:trixie`.
Change those in `docker-compose.yml` when you need a different 9.x Solr
release, want the full instead of slim distribution, or want to rebuild on a
newer patched base image.

## CI

The repository includes a GitHub Actions workflow at
`.github/workflows/solr-image-ci.yml` that rebuilds the image on pull requests,
on pushes to `main`, on manual dispatch, and every Monday at 05:00 UTC.

That workflow keeps the configured Solr package and version fixed, rebuilds the
image against the configured base-image arguments, and fails if Trivy finds
unfixed HIGH or CRITICAL vulnerabilities in the resulting image.
