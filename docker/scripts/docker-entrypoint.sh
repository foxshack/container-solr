#!/bin/bash

set -euo pipefail

if [[ "${VERBOSE:-}" == "yes" ]]; then
  set -x
fi

if [[ "${1:-}" == -* ]]; then
  set -- solr-foreground "$@"
fi

if [[ -d /docker-entrypoint-initdb.d ]]; then
  for script in /docker-entrypoint-initdb.d/*; do
    if [[ ! -e "$script" ]]; then
      continue
    fi

    case "$script" in
      *.sh)
        . "$script"
        ;;
      *)
        ;;
    esac
  done
fi

exec "$@"