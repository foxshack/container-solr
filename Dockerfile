# syntax=docker/dockerfile:1.7

ARG BUILDER_BASE_IMAGE=debian:trixie
ARG JAVA_RUNTIME_PACKAGE=openjdk-21-jre-headless
ARG RUNTIME_BASE_IMAGE=debian:trixie
ARG SOLR_PACKAGE=slim
ARG SOLR_VERSION=9.8.1

FROM ${BUILDER_BASE_IMAGE} AS downloader

ARG SOLR_PACKAGE
ARG SOLR_VERSION
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gzip \
    tar \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN case "${SOLR_PACKAGE}" in \
      full) archive="solr-${SOLR_VERSION}.tgz" && extracted_dir="solr-${SOLR_VERSION}" ;; \
      slim) archive="solr-${SOLR_VERSION}-slim.tgz" && extracted_dir="solr-${SOLR_VERSION}-slim" ;; \
      *) echo "Unsupported SOLR_PACKAGE: ${SOLR_PACKAGE}" >&2 && exit 1 ;; \
    esac \
 && curl -fsSL "https://archive.apache.org/dist/solr/solr/${SOLR_VERSION}/${archive}" -o solr.tgz \
 && tar -xzf solr.tgz \
 && mv "${extracted_dir}" solr \
 && rm solr.tgz

FROM ${RUNTIME_BASE_IMAGE}

ARG JAVA_RUNTIME_PACKAGE
ARG SOLR_PACKAGE
ARG SOLR_VERSION
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/solr/bin:/opt/docker-solr/scripts:${PATH}"
ENV JAVA_RUNTIME_PACKAGE=${JAVA_RUNTIME_PACKAGE}
ENV SOLR_INCLUDE=/etc/default/solr.in.sh
ENV SOLR_HOME=/var/solr/data
ENV SOLR_LOGS_DIR=/var/solr/logs
ENV SOLR_PID_DIR=/var/solr
ENV SOLR_PACKAGE=${SOLR_PACKAGE}
ENV SOLR_PORT=8983
ENV SOLR_VERSION=${SOLR_VERSION}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    lsof \
   ${JAVA_RUNTIME_PACKAGE} \
    procps \
    tini \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --gid 8983 solr \
 && useradd --uid 8983 --gid 8983 --home-dir /var/solr --create-home --shell /bin/bash solr

COPY --from=downloader /opt/solr/ /opt/solr/
COPY docker/solr.in.sh /etc/default/solr.in.sh
COPY docker/scripts/ /opt/docker-solr/scripts/
COPY docker/initdb.d/ /docker-entrypoint-initdb.d/
COPY docker/solr.xml /opt/solr-config/solr.xml
COPY docker/log4j2.xml /var/solr/log4j2.xml

RUN mkdir -p /docker-entrypoint-initdb.d /var/solr/data /var/solr/logs /opt/solr/server/solr/configsets \
 && chmod +x /opt/docker-solr/scripts/* /docker-entrypoint-initdb.d/* \
 && chown -R solr:solr /docker-entrypoint-initdb.d /etc/default/solr.in.sh /opt/docker-solr /opt/solr /opt/solr-config /opt/solr/server/solr/configsets /var/solr

VOLUME ["/var/solr/data"]
WORKDIR /opt/solr
EXPOSE 8983

USER solr

ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]
CMD ["solr-foreground"]