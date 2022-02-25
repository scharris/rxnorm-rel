#!/bin/sh
set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR"/..

psql -U rxnorm -f general-views.sql
psql -U rxnorm -f entity-views.sql
psql -U rxnorm -f report-views.sql
