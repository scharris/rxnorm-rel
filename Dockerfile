FROM postgres:14

COPY schemas.sql /docker-entrypoint-initdb.d/010-schemas.sql
COPY rxnorig-tables.sql /docker-entrypoint-initdb.d/020-rxnorig-tables.sql
COPY derived-tables.sql /docker-entrypoint-initdb.d/030-derived-tables.sql
COPY rxnorig-data.sql /docker-entrypoint-initdb.d/040-rxnorig-data.sql
COPY derived-tables-data.sql /docker-entrypoint-initdb.d/050-derived-tables-data.sql
COPY general-views.sql /docker-entrypoint-initdb.d/060-general-views.sql
COPY report-views.sql /docker-entrypoint-initdb.d/070-report-views.sql
COPY entity-views.sql /docker-entrypoint-initdb.d/080-entity-views.sql

RUN chmod a+r /docker-entrypoint-initdb.d/*

VOLUME /rxnorm-rrf

ENV POSTGRES_USER=rxnorm
ENV POSTGRES_PASSWORD=rxnorm
ENV POSTGRES_DB=rxnorm
