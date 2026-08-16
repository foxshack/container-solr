# Docker SOLR Example

Based on the guidance here: https://github.com/docker-solr/docker-solr

Using docker compose to manage Solr with live configsets and a
Docker-managed volume.

Configsets are mounted from the host (`./configsets`), so config changes are
immediate — no rebuild needed. Runtime data (indexes, transaction logs) lives
in a Docker-managed named volume (`solr_data`, mounted at `/var/solr/data`),
so it persists across container recreations and is managed by Docker.

## Quick start

```sh
docker compose up -d --build
```

Then visit http://localhost:8983 to access the Solr admin UI. To create cores,
see the "Cores and configsets" section below.

## Container Setup & Key Configuration

### Entry Point

The container uses a custom entry point script (`docker/scripts/docker-entrypoint.sh`)
that:
1. Sources the Solr environment configuration (`/etc/default/solr.in.sh`)
2. Runs initialization scripts from `/docker-entrypoint-initdb.d/` (e.g., core creation)
3. Starts Solr in foreground mode with proper Jetty host binding

### Network & Port Binding

**Critical:** Solr must bind to `0.0.0.0` (all interfaces) inside the container for
Docker port mapping to work correctly. This is configured via the JVM system property:

```
-Dsolr.jetty.host=0.0.0.0
```

This is set in the entry point script and allows external access to the container's
port 8983. Without this setting, Solr would bind to `127.0.0.1` (loopback only),
making it unreachable from the host machine.

### Global Configuration

Global Solr configuration files are baked into the image at build time and seeded
into the Docker volume on first start:

- **`docker/solr.xml`** — Root configuration, includes SolrCloud mode settings
  - Note: The `<solrcloud>` section requires `hostContext` for proper initialization
- **`docker/log4j2.xml`** — Logging configuration
- **`docker/solr.in.sh`** — Solr shell environment variables (JVM settings, paths)

To modify global config, edit these files and rebuild:

```sh
docker compose up -d --build
```

### Volumes

- **`solr_data`** (Docker-managed named volume) — Persists runtime data (indexes,
  transaction logs, core metadata) across container recreations
- **`./configsets/mnt`** (host mount) — Mounted at `/opt/solr/server/solr/configsets`
  for live configset management (no rebuild needed on config changes)



Each core's configuration template lives under `configsets/<core-name>/conf/`
(e.g. `configsets/gettingstarted/conf/` and `configsets/mhv/conf/`). The
`configsets/` directory is mounted into the running container at
`/opt/solr/server/solr/configsets`, making it live for Solr to use.

### Creating a new core

**Option 1: Via the web UI**
1. Visit http://localhost:8983
2. Click **Core Admin** → **Add Core**
3. Enter the core name and select the configset

**Option 2: Via convenience script**
```sh
./scripts/create-core.sh <core-name> [configset-name]
```

**Option 3: Via Solr CLI in the container**
```sh
docker compose exec solr solr create -c <core-name> -d <configset-name>
```

### Updating core configuration

Edit files directly in `configsets/<core-name>/conf/` (e.g.
`solrconfig.xml`, `managed-schema.xml`, `stopwords.txt`, etc.). Changes are
picked up by Solr immediately; no rebuild or container restart needed. Reload
the core via Core Admin → Reload if needed, or Solr will pick up changes on
the next request.

### Adding a new configset

1. Create a new directory: `mkdir -p configsets/<new-core>/conf`
2. Add configuration files (copy from an existing core or create from scratch):
   - `solrconfig.xml` (Solr behavior)
   - `managed-schema.xml` or `schema.xml` (index schema)
   - `stopwords.txt`, `synonyms.txt`, etc. (language resources)
   - Other config as needed
3. Create cores from this configset using one of the methods above

Global config (`docker/solr.xml`, `docker/log4j2.xml`) is baked into the image
at build time and seeded into the volume on first start. To change global
config, edit `docker/solr.xml` or `docker/log4j2.xml` and rebuild.

## Binary Distribution Image

This repository includes a multi-stage Dockerfile that downloads the Apache
Solr binary distribution on top of Debian Trixie and produces a runtime image.
The configsets are mounted (not baked in), so config changes are live.

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
Global config (`docker/solr.xml`, `docker/log4j2.xml`) is baked into the image
at build time. To change global config, edit those files and rebuild:

```sh
docker compose up -d --build
```

This 9.x branch is pinned to Solr `9.8.1` and uses Java 21 by default on
Debian Trixie (the Java version available in that base image).

The default build arguments are `SOLR_VERSION=9.8.1`,
`SOLR_PACKAGE=slim`, `JAVA_RUNTIME_PACKAGE=openjdk-21-jre-headless`,
`BUILDER_BASE_IMAGE=debian:trixie`, and `RUNTIME_BASE_IMAGE=debian:trixie`.
Change those in `docker-compose.yml` when you need a different 9.x Solr
release, want the full instead of slim distribution, or want to rebuild on a
newer patched base image.
### Build arguments

The default build arguments are:
- `SOLR_VERSION=9.8.1` — Solr release version
- `SOLR_PACKAGE=slim` — Use slim distribution (or `full` for complete)
- `BUILDER_BASE_IMAGE=debian:trixie` — Base image for download stage
- `RUNTIME_BASE_IMAGE=debian:trixie` — Base image for runtime

Change these in `docker-compose.yml` when you need a different Solr release,
want the full instead of slim distribution, or want to rebuild on a newer
patched base image.

### Reset data

To discard all index data and start fresh, run:
```sh
docker compose down -v
docker compose up -d --build
```

This removes the named volume, so it's recreated on startup (only `solr.xml` is
seeded; cores must be created manually).

## Troubleshooting

### Connection refused on localhost:8983

**Cause:** Solr is binding to `127.0.0.1` instead of `0.0.0.0` inside the container.

**Solution:** Ensure the entry point script sets `-Dsolr.jetty.host=0.0.0.0`. Check:
```sh
docker compose logs solr | grep "Started.*Connector"
```

Should show: `Started ServerConnector@...{0.0.0.0:8983}` (not `127.0.0.1:8983`)

### Container exits immediately

Check the logs for error messages:
```sh
docker compose logs solr
```

Common issues:
- Missing `hostContext` in `docker/solr.xml` → Solr fails to initialize
- Entry point script not found or not executable → Container cannot start
- Java/JVM issues → Check Java version compatibility

### Configuration changes not applied

**For configsets** (live mounts): Changes should be picked up immediately. Reload
the core via the web UI if needed.

**For global config** (baked into image): Rebuild the container:
```sh
docker compose up -d --build
```

### Check container health

```sh
# See if container is running
docker compose ps

# View all logs
docker compose logs solr

# Check last 20 lines
docker compose logs solr --tail=20

# Follow logs in real-time
docker compose logs -f solr
```

## Running Commands in the Container

Execute commands inside the running Solr container:

```sh
# Run Solr CLI commands
docker compose exec solr solr status
docker compose exec solr solr create -c <core-name> -d <configset-name>

# Access the bash shell
docker compose exec solr bash

# Check Solr version
docker compose exec solr solr --version
```

## Runtime Settings & Environment Variables

Key environment variables set in the container:

- `SOLR_HOME=/var/solr/data` — Solr data directory (contains cores, configs, indexes)
- `SOLR_LOGS_DIR=/var/solr/logs` — Log file directory
- `SOLR_PID_DIR=/var/solr` — Process ID directory
- `SOLR_PORT=8983` — HTTP port
- `SOLR_INCLUDE=/etc/default/solr.in.sh` — Shell environment file
- `SOLR_OPTS` — Additional JVM options (includes `-Dsolr.jetty.host=0.0.0.0`)

## CI

The repository includes a GitHub Actions workflow at
`.github/workflows/solr-image-ci.yml` that rebuilds the image on pull requests,
on pushes to `main`, on manual dispatch, and every Monday at 05:00 UTC.

That workflow keeps the configured Solr package and version fixed, rebuilds the
image against the configured base-image arguments, and fails if Trivy finds
unfixed HIGH or CRITICAL vulnerabilities in the resulting image.
