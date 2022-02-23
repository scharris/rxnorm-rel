-- These indexes are added in addition to those provided by RXNORM to facilitate common queries.
create index rxnsat_sabaui_ix on rxnsat(sab, rxaui);
create index rxnsat_aui_ix on rxnsat(rxaui);
create index rxnconso_sabaui_ix on rxnconso(sab, rxaui);
create index rxnrel_sab_ix on rxnrel(sab);

