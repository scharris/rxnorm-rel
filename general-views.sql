create view in_unii_v as
select distinct s.in_rxcui, s.unii
from mthspl_sub s
join "in" i on i.rxcui = s.in_rxcui
;

create view pin_unii_v as
select distinct s.pin_rxcui, s.unii
from mthspl_sub s
join pin i on i.rxcui = s.pin_rxcui
;

create view scd_unii_v as
select scd.rxcui as scd_rxcui, iu.unii as unii
from scdc_scd
join scd on scdc_scd.scd_rxcui = scd.rxcui
join scdc on scdc_scd.scdc_rxcui = scdc.rxcui
join "in" i on i.rxcui = scdc.in_rxcui
join in_unii_v iu on iu.in_rxcui = i.rxcui
union
select scd.rxcui as scd_rxcui, piu.unii as unii
from scdc_scd
join scd on scdc_scd.scd_rxcui = scd.rxcui
join scdc on scdc_scd.scdc_rxcui = scdc.rxcui
join pin i on i.rxcui = scdc.pin_rxcui
join pin_unii_v piu on piu.pin_rxcui = i.rxcui
;
comment on view scd_unii_v is 'Pairs of SCD/UNII-CUI for both IN and PIN ingredients.';

create view scdf_in_v as
select distinct scd.scdf_rxcui, scdc.in_rxcui
from scd
join scdc_scd on scdc_scd.scd_rxcui = scd.rxcui
join scdc on scdc.rxcui = scdc_scd.scdc_rxcui
;
/* Above view verified to yield same results as rxrel query:
select count(*) from scdf_in_v; -- 23059
select count(*) from (
select scdf.rxcui, i.rxcui
from rxno.rxnrel r
join scdf on scdf.rxcui = r.rxcui1
join "in" i on i.rxcui = r.rxcui2
where r.rela = 'ingredient_of' and r.sab = 'RXNORM'
) q; -- 23059
*/

create view scdg_in_v as
select distinct scdg.rxcui scdg_rxcui, i.rxcui in_rxcui
from scdg
join scdg_scd on scdg_scd.scdg_rxcui = scdg.rxcui
join scdc_scd on scdc_scd.scd_rxcui = scdg_scd.scd_rxcui
join scdc on scdc.rxcui = scdc_scd.scdc_rxcui
join "in" i on scdc.in_rxcui = i.rxcui
;
/* View above has equivalent content to ingredient_of records from rxnrel between scdg and in tty's:
select count(*) from scdg_in_v; -- 27000
select count(*) from (
select scdg.rxcui, i.rxcui
from rxno.rxnrel r
join scdg on scdg.rxcui = r.rxcui1
join "in" i on i.rxcui = r.rxcui2
where r.rela = 'ingredient_of' and r.sab = 'RXNORM'
) q
; -- 27000 rows
*/

-- Remaining views could replace equivalent tables, but would leave fk relationship gaps.

/*
create view sbdf_sbdg_v as
select distinct sbdf.rxcui sbdf_rxcui, sbdg.rxcui sbdg_rxcui
from sbdf
join df_dfg fg on fg.df_rxcui = sbdf.df_rxcui
join sbdg on sbdg.bn_rxcui = sbdf.bn_rxcui and sbdg.dfg_rxcui = fg.dfg_rxcui
;
-- The above is equivalent (checked by count) to rxnrel relationship data for sbdf/sbdg:
select count(*) from sbdf_sbdg_v;  -- 21541
select count(*) from (
select f.rxcui, g.rxcui
from rxno.rxnrel r
join sbdf f on f.rxcui = r.rxcui1
join sbdg g on g.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'inverse_isa'
) q;
-- 21541
*/

/*
create view sbdc_scdc_v as
select distinct scdc_scd.scdc_rxcui, sbdc.rxcui
from sbdc
join sbd on sbd.sbdc_rxcui = sbdc.rxcui
join scdc_scd on scdc_scd.scd_rxcui = sbd.scd_rxcui
;

-- Above view produces the same count as the data tradename_of records from rxnrel:
select count(*) from sbdc_scdc_v; -- 26051
select count(*) from (
select scdc.rxcui, sbdc.rxcui
from rxno.rxnrel r
join scdc on scdc.rxcui = r.rxcui1
join sbdc on sbdc.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'tradename_of'
) q; -- 26051
*/

/*
create view sbdg_sbd_v as
select sbdg.rxcui sbdg_rxcui, sbd.rxcui sbd_rxcui
from sbdg
join df_dfg on df_dfg.dfg_rxcui = sbdg.dfg_rxcui
join sbd on sbd.bn_rxcui = sbdg.bn_rxcui and sbd.df_rxcui = df_dfg.df_rxcui
;
--  Equivalent by count to query of 'isa' relationship in rxnrel between the involved entities:
select count(*) from sbdg_sbd_v; --35068
select count(*) from (
select g.rxcui, d.rxcui
from rxno.rxnrel r
join sbdg g on g.rxcui = r.rxcui1
join sbd d on d.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'isa'
) q; -- 35068
*/

/* Non-existence of view sbdg_strength_v to replace table sbdg_strength:
The available strengths of an sbdg are NOT derivable via the strengths from related scdc's:
select distinct sbdg_sbd_v.sbdg_rxcui, scdc.strength
from sbdg_sbd_v
join sbd on sbd.rxcui = sbdg_sbd_v.sbd_rxcui
join scdc_scd on scdc_scd.scd_rxcui = sbd.scd_rxcui
join scdc on scdc_scd.scdc_rxcui = scdc.rxcui
; -- 40147
select count(*) from sbdg_strength; -- 11742
*/

