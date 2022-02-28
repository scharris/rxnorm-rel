create schema rxno authorization rxnorm
;
create schema rxnr authorization rxnorm
;
alter role rxnorm set search_path to rxnr
;
