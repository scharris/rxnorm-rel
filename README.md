## Build the image

```
docker build -t rxnorm-pg .
```

## Run

Download RxNorm data and make a reference to its `rrf` subdirectory:

Bash/Zsh:
```
DATA_DIR="$HOME/Downloads/RxNorm_full_02072022/rrf"
```
PowerShell:
```
$DATA_DIR="$HOME/Downloads/RxNorm_full_02072022/rrf"
```

(Change the location to suite your download path and file name).

Then start the container, mapping the `rrf` data directory into the container:

Bash/Zsh:
```
docker run -d --name rxnorm-pg -p 127.0.0.1:5432:5432 \
 -v "$DATA_DIR":/rxnorm-rrf  -v rxnorm-pg-data:/var/lib/postgresql/data \
 rxnorm-pg -c "max_wal_size=3GB"
```

PowerShell:
```
docker run -d --name rxnorm-pg -p 127.0.0.1:5432:5432 `
  -v "$($DATA_DIR):/rxnorm-rrf" -v "rxnorm-pg-data:/var/lib/postgresql/data" `
  rxnorm-pg -c "max_wal_size=3GB"
```

For the initial loading, it will take several minutes for the container to
populate tables from the RxNorm data. Subsequent startups will avoid data
loading, at least so long as the `rxnorm-pg-data` Docker volume is not deleted.
The bind mount to `rxnorm-rrf` is also not necessary for container startup once
the `rxnorm-pg-data` volume has been successfully populated by a previous run.

You can follow progress by watching the container's log:

```
docker logs rxnorm-pg -f
```

## Connect

To start psql within the container:

```
docker exec -it rxnorm-pg psql -U rxnorm
```

To connect to the database via jdbc, use connection string:

```
jdbc:postgresql://localhost:5432/rxnorm
```
with username `rxnorm` and any password.

## Stop the container

```
docker rm -vf rxnorm-pg
```
