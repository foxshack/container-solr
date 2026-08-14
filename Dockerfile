# syntax=docker/dockerfile:1.7

ARG SOLR_VERSION=10.0.0

FROM debian:trixie AS builder

ARG SOLR_VERSION
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gzip \
    openjdk-21-jdk-headless \
    perl \
    tar \
    unzip \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src

RUN curl -fsSL "https://archive.apache.org/dist/solr/solr/${SOLR_VERSION}/solr-${SOLR_VERSION}-src.tgz" -o solr-src.tgz \
 && tar -xzf solr-src.tgz \
 && mv "solr-${SOLR_VERSION}" solr \
 && rm solr-src.tgz

WORKDIR /usr/src/solr

RUN ./gradlew --no-daemon dev

FROM debian:trixie

ARG SOLR_VERSION
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/solr/bin:/opt/docker-solr/scripts:${PATH}"
ENV SOLR_INCLUDE=/etc/default/solr.in.sh
ENV SOLR_HOME=/var/solr/data
ENV SOLR_LOGS_DIR=/var/solr/logs
ENV SOLR_PID_DIR=/var/solr
ENV SOLR_PORT=8983
ENV SOLR_VERSION=${SOLR_VERSION}

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    lsof \
    openjdk-21-jre-headless \
    procps \
    tini \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --gid 8983 solr \
 && useradd --uid 8983 --gid 8983 --home-dir /var/solr --create-home --shell /bin/bash solr

COPY --from=builder /usr/src/solr/solr/packaging/build/dev/ /opt/solr/
COPY docker/solr.in.sh /etc/default/solr.in.sh
COPY docker/scripts/ /opt/docker-solr/scripts/

RUN mkdir -p /docker-entrypoint-initdb.d /var/solr/data /var/solr/logs \
 && chmod +x /opt/docker-solr/scripts/* \
 && chown -R solr:solr /docker-entrypoint-initdb.d /etc/default/solr.in.sh /opt/docker-solr /opt/solr /var/solr

VOLUME ["/var/solr"]
WORKDIR /opt/solr
EXPOSE 8983

USER solr

ENTRYPOINT ["tini", "--", "docker-entrypoint.sh"]
CMD ["solr-foreground"]