## Build the image

```
docker build -t rxnorm-pg .
```

## Run

Download RxNorm data and make a reference to its `rrf` subdirectory:

```
DATA_DIR="$HOME/Downloads/RxNorm_full_02072022/rrf"
```

Then start the container, mapping the `rrf` data directory into the container:

```
docker run --name rxnorm-pg -d -v "$DATA_DIR":/rxnorm-rrf -p 127.0.0.1:5432:5432 --shm-size=256MB  rxnorm-pg -c "max_wal_size=3GB"
```

It may take several minutes for the container to initialize the database and to
finish populating tables from the RxNorm data. You can follow progress by
watching the container's log:

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
