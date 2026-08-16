#!/bin/bash
set -e

# This is the entrypoint script for the Solr Docker container.
# It handles initialization and then starts Solr.

# Source the Solr environment if it exists
if [ -f "/etc/default/solr.in.sh" ]; then
  . /etc/default/solr.in.sh
fi

# Run any init scripts in /docker-entrypoint-initdb.d
if [ -d "/docker-entrypoint-initdb.d" ]; then
  echo "Running initialization scripts..."
  for f in /docker-entrypoint-initdb.d/*.sh; do
    if [ -f "$f" ] && [ -x "$f" ]; then
      echo "Executing $f"
      "$f"
    fi
  done
fi

# If no command was provided, start Solr in the foreground
if [ $# -eq 0 ] || [ "$1" = "solr-foreground" ]; then
  echo "Starting Solr..."
  # Set JVM options to bind Jetty to all interfaces for Docker
  export SOLR_OPTS="${SOLR_OPTS} -Dsolr.jetty.host=0.0.0.0"
  exec /opt/solr/bin/solr start -f
else
  exec "$@"
fi
