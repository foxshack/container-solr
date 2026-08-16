#!/bin/bash
# Seeds solr.xml into SOLR_HOME on first start. Configsets are mounted from the host,
# and cores are created via web UI or solr create_core command (see README).

set -euo pipefail

mkdir -p "${SOLR_HOME}"

if [[ ! -f "${SOLR_HOME}/solr.xml" ]]; then
  cp /opt/solr-config/solr.xml "${SOLR_HOME}/solr.xml"
fi
