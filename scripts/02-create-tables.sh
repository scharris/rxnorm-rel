#!/bin/sh
set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR"/..

# Create dummy tables so the table drop statements in RxNormDDL.sql (from RxNorm) won't generate errors.
PGOPTIONS="--search_path=rxno" psql -U rxnorm <<EOF
create table rxnatomarchive(x int);
create table rxnconso(x int);
create table rxnrel(x int);
create table rxnsab(x int);
create table rxnsat(x int);
create table rxnsty(x int);
create table rxndoc(x int);
create table rxncuichanges(x int);
create table rxncui(x int);
EOF

PGOPTIONS="--search_path=rxno" psql -U rxnorm -f rxnorm-orig/RxNormDDL.sql
PGOPTIONS="--search_path=rxno" psql -U rxnorm -f rxnorm-orig/rxn_index.sql
PGOPTIONS="--search_path=rxno" psql -U rxnorm -f rxnorm-orig/rxn_index_extra.sql

psql -U rxnorm -f derived-tables.sql
