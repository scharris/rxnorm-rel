#!/bin/sh
set -e

createuser -U postgres --echo rxnorm
createdb -U postgres --owner rxnorm rxnorm
psql -d rxnorm -U rxnorm --echo-all -c "create schema rxno authorization rxnorm;"
psql -d rxnorm -U rxnorm --echo-all -c "create schema rxnr authorization rxnorm;" -c "alter role rxnorm set search_path to rxnr;"
