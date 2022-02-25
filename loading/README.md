# RxNorm database setup

## Initial setup

We assume a running Postgres server is listening on localhost:5432, that a superuser "postgres" exists,
and that local trust authentication is being used. For other cases, define PG* environment variables (such
as PGHOST, PGPORT) appropriately before running the scripts below.

Open a bash shell in directory `loading` for the following commands.

Create the rxnorm user, database, and schema:
```
./01-create-db.sh
```

## Create schema tables

To create schema tables for the original RxNorm tables and those
of the derived/augmented relational schema:

```
./02-create-tables.sh
```

## Populate tables

Copy the "rrf" directory contents from the RxNorm data files distribution into directory
`rxnorm-orig/rrf`. Then load this data into the RxNorm database tables and the derived tables via:

```
./03-populate-tables.sh
```

## Create views

```
./04-create-views.sh
```
