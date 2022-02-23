#!/bin/sh
set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"

"$SCRIPT_DIR"/populate-rxnorm-tables.sh && "$SCRIPT_DIR"/populate-derived-tables.sh
