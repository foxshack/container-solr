#!/bin/bash
# Create a Solr core from a mounted configset.
# Usage: scripts/create-core.sh <core-name> [configset-name]
# If configset-name is not provided, defaults to core-name.

set -euo pipefail

core_name="${1:?usage: create-core.sh <core-name> [configset-name]}"
configset_name="${2:-$core_name}"

echo "Creating core '$core_name' from configset '$configset_name'..."
docker compose exec solr solr create -c "$core_name" -d "$configset_name"
echo "Done. Access at http://localhost:8983/solr/#/~cores/$core_name"
