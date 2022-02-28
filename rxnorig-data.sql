set search_path to rxno;

-- RxNorm rrf data includes a spurious trailing '|', so add a dummy column to absorb the trailing ghost field.
alter table rxnconso add column dummy varchar(1);
alter table rxnsat add column dummy varchar(1);
alter table rxnrel add column dummy varchar(1);
alter table rxndoc add column dummy varchar(1);
alter table rxnsty add column dummy varchar(1);
alter table rxnsab add column dummy varchar(1);
alter table rxnatomarchive add column dummy varchar(1);
alter table rxncuichanges add column dummy varchar(1);
alter table rxncui add column dummy varchar(1);

\copy rxnconso from '/rxnorm-rrf/RXNCONSO.RRF' with delimiter '|' csv quote E'\b' null as '';
\copy rxnsat from '/rxnorm-rrf/RXNSAT.RRF' with delimiter '|' csv quote E'\b' null as '';
\copy rxnrel from '/rxnorm-rrf/RXNREL.RRF' with delimiter '|' csv quote E'\b' null as '';
\copy rxndoc from '/rxnorm-rrf/RXNDOC.RRF' with delimiter '|' csv quote E'\b' null as '';
\copy rxnsty from '/rxnorm-rrf/RXNSTY.RRF' with delimiter '|' csv quote E'\b' null as '';
\copy rxnsab from '/rxnorm-rrf/RXNSAB.RRF' with delimiter '|' csv quote E'\b' null as '';
\copy rxnatomarchive from '/rxnorm-rrf/RXNATOMARCHIVE.RRF' with delimiter '|' csv quote E'\b' null as '';
\copy rxncuichanges from '/rxnorm-rrf/RXNCUICHANGES.RRF' with delimiter '|' csv quote E'\b' null as '';
\copy rxncui from '/rxnorm-rrf/RXNCUI.RRF' with delimiter '|' csv quote E'\b' null as '';
