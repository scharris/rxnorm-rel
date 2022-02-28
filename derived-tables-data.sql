create table tmp_mthspl_sub as
select
  c.rxaui,
  c.rxcui,
  case when length(c.code) = 10 then c.code end unii,
  case when length(c.code) >= 17 then c.code end biologic_code,
  c.str as name,
  c.suppress
from rxno.rxnconso c
where c.sab = 'MTHSPL' and c.tty = 'SU'
;
create index ix_tmpmthsplsub_aui on tmp_mthspl_sub (rxaui);
create index ix_tmpmthsplsub_cui on tmp_mthspl_sub (rxcui);
create index ix_tmpmthsplsub_unii on tmp_mthspl_sub (unii);

create table tmp_scd_ingrset (
  drug_rxcui varchar(12) not null,
  ingrset_rxcui varchar(12) not null,
  ingrset_rxaui varchar(12) not null,
  ingrset_name varchar(4000) not null,
  ingrset_suppress varchar(1) not null,
  ingrset_tty varchar(100) not null,
  constraint pk_tmpscdingrset primary key (drug_rxcui, ingrset_rxcui)
);
create index ix_tmpsingletoningrset on tmp_scd_ingrset (ingrset_rxcui);


-- Load tables derived from sab=RXNORM subset of RxNorm.

insert into df (rxcui, rxaui, name, origin, code)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.atn = 'ORIG_SOURCE' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.atn = 'ORIG_CODE' and s.rxcui = c.rxcui)
from rxno.rxnconso c
where c.sab = 'RXNORM'
and c.tty = 'DF'
;

insert into dfg (rxcui, rxaui, name)
select c.rxcui, c.rxaui, c.str
from rxno.rxnconso c
where c.sab = 'RXNORM'
and c.tty = 'DFG'
;

insert into df_dfg (df_rxcui, dfg_rxcui)
select df.rxcui, dfg.rxcui
from rxno.rxnrel r
join df on df.rxcui = r.rxcui1
join dfg on dfg.rxcui = r.rxcui2
where r.sab = 'RXNORM'
and r.rela = 'inverse_isa'
;

insert into et (rxcui, rxaui, name)
select c.rxcui, c.rxaui, c.str
from rxno.rxnconso c
where c.sab = 'RXNORM'
and c.tty = 'ET'
;

insert into "in" (rxcui, rxaui, name, suppress)
select distinct c.rxcui, c.rxaui, c.str as name, c.suppress
from rxno.rxnconso c
where sab='RXNORM'
and tty = 'IN'
;

insert into pin (rxcui, rxaui, name, in_rxcui, suppress)
select distinct
  c.rxcui,
  c.rxaui,
  c.str as name,
  (select i.rxcui
   from rxno.rxnrel r
   join "in" i on i.rxcui = r.rxcui1
   where r.sab = 'RXNORM' and r.rela = 'form_of'
     and r.rxcui2 = c.rxcui) in_rxcui,
  c.suppress
from rxno.rxnconso c
where sab='RXNORM'
and tty = 'PIN'
;

insert into tmp_scd_ingrset (drug_rxcui, ingrset_rxcui, ingrset_rxaui, ingrset_name, ingrset_suppress, ingrset_tty)
with scd_nomin as ( -- SCDs with no multi-ingredient
  select scd.rxcui
  from rxno.rxnconso scd
  where scd.sab = 'RXNORM' and scd.tty = 'SCD' and scd.rxcui not in (
    select scd.rxcui
    from rxno.rxnrel r
    join rxno.rxnconso scd on scd.rxcui = r.rxcui1 and scd.sab = 'RXNORM' and scd.tty = 'SCD'
    join rxno.rxnconso min on min.rxcui = r.rxcui2 and min.sab = 'RXNORM' and min.tty = 'MIN'
    where r.sab = 'RXNORM' and r.rela = 'ingredients_of'
  )
),
scdc_nomins as ( -- SCDCs that have no multi-ingredient
  select scdc.rxcui scdc_rxcui, scdc.str scdc_str, r.rela, scd.rxcui scd_rxcui, scd.str scd_str
  from rxno.rxnrel r
  join rxno.rxnconso scd on scd.rxcui = r.rxcui1
  join rxno.rxnconso scdc on scdc.rxcui = r.rxcui2
  join scd_nomin sn on sn.rxcui = scd.rxcui
  where r.sab = 'RXNORM' and r.rela = 'constitutes'
  and scd.sab = 'RXNORM' and scd.tty = 'SCD'
  and scdc.sab = 'RXNORM' and scdc.tty = 'SCDC'
)
select distinct scd.*, i.*
from scd_nomin scd,
lateral (
  select ingr.rxcui, ingr.rxaui, ingr.str, ingr.suppress, ingr.tty
  from rxno.rxnrel r
  join scdc_nomins on scdc_nomins.scdc_rxcui = r.rxcui1
  join rxno.rxnconso ingr on ingr.rxcui = r.rxcui2
  where r.sab = 'RXNORM' and r.rela in ('ingredient_of', 'precise_ingredient_of')
  and ingr.sab = 'RXNORM' and ingr.tty in ('IN', 'PIN')
  and scd.rxcui = scdc_nomins.scd_rxcui
  order by ingr.tty desc --prefer PIN over IN
  limit 1
) i
;

insert into tmp_scd_ingrset (drug_rxcui, ingrset_rxcui, ingrset_rxaui, ingrset_name, ingrset_suppress, ingrset_tty)
select scd.rxcui, m.rxcui, m.rxaui, m.name, m.suppress, 'MIN'
from rxno.rxnrel r
join (
  select c.rxcui, c.rxaui, c.str as name, c.suppress
  from rxno.rxnconso c where sab='RXNORM' and tty = 'MIN'
) m on m.rxcui = r.rxcui2
join rxno.rxnconso scd on scd.rxcui = r.rxcui1
where r.rela = 'ingredients_of' and r.sab = 'RXNORM'
and scd.tty = 'SCD' and scd.sab = 'RXNORM'
;

insert into ingrset (rxcui, rxaui, name, suppress, tty)
select distinct ingrset_rxcui, ingrset_rxaui, ingrset_name, ingrset_suppress, ingrset_tty
from tmp_scd_ingrset
;

insert into scdf (rxcui, rxaui, name, df_rxcui)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select df.rxcui from rxno.rxnrel r join df on df.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'dose_form_of' and c.rxcui = r.rxcui1) df_rxcui
from rxno.rxnconso c
where c.sab = 'RXNORM' and c.tty = 'SCDF'
;

insert into scd (rxcui, rxaui, name, prescribable_name, rxterm_form, df_rxcui, scdf_rxcui, ingrset_rxcui, available_strengths, qual_distinct, suppress, quantity, human_drug, vet_drug, unquantified_form_rxcui)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select psn.str from rxno.rxnconso psn where psn.tty = 'PSN' and psn.rxcui = c.rxcui) psn,
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXTERM_FORM'),
  (select df.rxcui from rxno.rxnrel r join df on df.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'dose_form_of' and r.rxcui1 = c.rxcui) df_rxcui,
  (select scdf.rxcui from rxno.rxnrel r join scdf on scdf.rxcui = r.rxcui1
   where r.rxcui2 = c.rxcui and r.sab = 'RXNORM' and r.rela = 'isa') scdf_rxcui,
  (select ingrset_rxcui from tmp_scd_ingrset where drug_rxcui = c.rxcui) ingrset_rxcui,
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_AVAILABLE_STRENGTH'),
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_QUALITATIVE_DISTINCTION'),
  c.suppress,
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_QUANTITY'),
  exists (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_HUMAN_DRUG'),
  exists (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_VET_DRUG'),
  (select scd2.rxcui from rxno.rxnrel r join rxno.rxnconso scd2 on scd2.rxcui = r.rxcui1
   where r.sab = 'RXNORM' and r.rela = 'quantified_form_of' and r.rxcui2 = c.rxcui
     and scd2.sab = 'RXNORM' and scd2.tty = 'SCD') uqform
from rxno.rxnconso c
where c.sab='RXNORM'
and c.tty = 'SCD'
;

insert into bn (rxcui, rxaui, name, rxn_cardinality, reformulated_to_rxcui)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_BN_CARDINALITY' and s.rxcui = c.rxcui),
  (select c2.rxcui
   from rxno.rxnrel r
   join rxno.rxnconso c2 on c2.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'reformulated_to'
     and c2.sab = 'RXNORM' and c2.tty = 'BN'
     and c.rxcui = r.rxcui1)
from rxno.rxnconso c
where c.tty = 'BN'
and sab = 'RXNORM'
;

insert into sbdf (rxcui, rxaui, name, df_rxcui, bn_rxcui, scdf_rxcui)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select df.rxcui from rxno.rxnrel r join df on df.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'dose_form_of' and c.rxcui = r.rxcui1) df_rxcui,
  (select bn.rxcui from rxno.rxnrel r join bn on bn.rxcui = r.rxcui2
   where c.rxcui = r.rxcui1 and r.sab = 'RXNORM' and r.rela = 'ingredient_of') bn_rxcui,
  (select scdf.rxcui from rxno.rxnrel r join scdf on scdf.rxcui = r.rxcui1
   where r.rxcui2 = c.rxcui and r.sab = 'RXNORM' and r.rela = 'tradename_of') scdf_rxcui
from rxno.rxnconso c
where c.sab = 'RXNORM' and c.tty = 'SBDF'
;

insert into sbdc (rxcui, rxaui, name)
select c.rxcui, c.rxaui, c.str
from rxno.rxnconso c
where c.sab = 'RXNORM' and c.tty = 'SBDC'
;

insert into sbd (rxcui, rxaui, name, scd_rxcui, bn_rxcui, sbdf_rxcui, sbdc_rxcui, prescribable_name, rxterm_form, df_rxcui, available_strengths, qual_distinct, suppress, quantity, human_drug, vet_drug, unquantified_form_rxcui)
select
  c.rxcui,
  c.rxaui,
  c.str as name,
  (select r.rxcui2 from rxno.rxnrel r where r.rxcui1 = c.rxcui and r.rela = 'has_tradename') scd_rxcui,
  (select bn.rxcui from rxno.rxnrel r join bn on bn.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'ingredient_of' and r.rxcui1 = c.rxcui) bn_rxcui,
  (select f.rxcui from rxno.rxnrel r join sbdf f on f.rxcui = r.rxcui1
   where r.rxcui2 = c.rxcui and r.sab = 'RXNORM' and r.rela = 'isa') sbdf_rxcui,
  (select sbdc.rxcui from rxno.rxnrel r join sbdc on sbdc.rxcui = r.rxcui1
   where r.sab = 'RXNORM' and r.rela = 'consists_of' and r.rxcui2 = c.rxcui) sbdc_rxcui,
  (select psn.str from rxno.rxnconso psn where psn.tty = 'PSN' and psn.rxcui = c.rxcui) psn,
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXTERM_FORM') rxterm_form,
  (select r.rxcui2 from rxno.rxnrel r where r.sab = 'RXNORM' and r.rela = 'dose_form_of' and r.rxcui1 = c.rxcui) df,
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_AVAILABLE_STRENGTH') strengths,
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_QUALITATIVE_DISTINCTION') qual_distinct,
  c.suppress,
  (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_QUANTITY') quantity,
  exists (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_HUMAN_DRUG') human,
  exists (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_VET_DRUG') vet,
  (select sbd2.rxcui
   from rxno.rxnrel r
   join rxno.rxnconso sbd2 on sbd2.rxcui = r.rxcui1
   where r.sab = 'RXNORM' and r.rela = 'quantified_form_of'
   and sbd2.sab = 'RXNORM' and sbd2.tty = 'SBD'
   and c.rxcui = r.rxcui2) unquant_form
from rxno.rxnconso c
where c.sab='RXNORM' and c.tty = 'SBD'
;

insert into gpck (rxcui, rxaui, name, prescribable_name, df_rxcui, suppress, human_drug)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select psn.str from rxno.rxnconso psn where psn.tty = 'PSN' and psn.rxcui = c.rxcui) psn,
  (select df.rxcui from rxno.rxnrel r join df on df.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'dose_form_of' and c.rxcui = r.rxcui1) df_rxcui,
  c.suppress,
  exists (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_HUMAN_DRUG')
from rxno.rxnconso c
where c.sab='RXNORM' and c.tty = 'GPCK'
;

insert into bpck (rxcui, rxaui, name, gpck_rxcui, prescribable_name, df_rxcui, suppress, human_drug)
select
  c.rxcui,
  c.rxaui,
  c.str as name,
  (select g.rxcui from rxno.rxnrel r join gpck g on g.rxcui = r.rxcui1
   where r.rxcui2 = c.rxcui and r.sab = 'RXNORM' and r.rela = 'tradename_of') gpck_rxcui,
  (select psn.str from rxno.rxnconso psn where psn.tty = 'PSN' and psn.rxcui = c.rxcui) psn,
  (select df.rxcui from rxno.rxnrel r join df on df.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'dose_form_of' and c.rxcui = r.rxcui1) df_rxcui,
  c.suppress,
  exists (select s.atv from rxno.rxnsat s where s.sab = 'RXNORM' and s.rxcui = c.rxcui and s.atn = 'RXN_HUMAN_DRUG')
from rxno.rxnconso c
where c.sab='RXNORM' and c.tty = 'BPCK'
;

insert into scdc (rxcui, rxaui, name, boss_active_ingr_name, boss_active_moi_name, boss_source, rxn_in_expressed_flag, strength, boss_str_num_unit, boss_str_num_val, boss_str_denom_unit, boss_str_denom_val, in_rxcui, pin_rxcui)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_BOSS_AI' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_BOSS_AM' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_BOSS_FROM' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_IN_EXPRESSED_FLAG' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_STRENGTH' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_BOSS_STRENGTH_NUM_UNIT' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_BOSS_STRENGTH_NUM_VALUE' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_BOSS_STRENGTH_DENOM_UNIT' and s.rxcui = c.rxcui),
  (select s.atv from rxno.rxnsat s where s.atn = 'RXN_BOSS_STRENGTH_DENOM_VALUE' and s.rxcui = c.rxcui),
  (select i.rxcui from rxno.rxnrel r join "in" i on i.rxcui = r.rxcui2
   where r.rela = 'ingredient_of' and r.sab = 'RXNORM' and r.rxcui1 = c.rxcui) in_rxcui,
  (select pin.rxcui from rxno.rxnrel r join pin on pin.rxcui = r.rxcui2
   where r.rela = 'precise_ingredient_of' and r.sab = 'RXNORM' and r.rxcui1 = c.rxcui) pin_rxcui
from rxno.rxnconso c
where c.tty = 'SCDC' and c.sab = 'RXNORM'
;

insert into sbdc_scdc (sbdc_rxcui, scdc_rxcui)
select sbdc.rxcui, scdc.rxcui
from rxno.rxnrel r
join scdc on scdc.rxcui = r.rxcui1
join sbdc on sbdc.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'tradename_of'
;

insert into scdg (rxcui, rxaui, name, dfg_rxcui)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select dfg.rxcui from rxno.rxnrel r join dfg on dfg.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'doseformgroup_of' and c.rxcui = r.rxcui1) dfg_rxcui
from rxno.rxnconso c
where c.sab = 'RXNORM' and c.tty = 'SCDG'
;

insert into sbdg (rxcui, rxaui, name, dfg_rxcui, bn_rxcui, scdg_rxcui)
select
  c.rxcui,
  c.rxaui,
  c.str,
  (select dfg.rxcui from rxno.rxnrel r join dfg on dfg.rxcui = r.rxcui2
   where r.sab = 'RXNORM' and r.rela = 'doseformgroup_of' and c.rxcui = r.rxcui1) dfg_rxcui,
  (select r.rxcui2 from rxno.rxnrel r
   where r.rxcui1 = c.rxcui and r.sab = 'RXNORM' and r.rela = 'ingredient_of') bn,
  (select scdg.rxcui from rxno.rxnrel r join scdg on scdg.rxcui = r.rxcui1
   where r.rxcui2 = c.rxcui and r.sab = 'RXNORM' and r.rela = 'tradename_of') scdg
from rxno.rxnconso c
where c.sab = 'RXNORM' and c.tty = 'SBDG'
;

insert into sbdf_sbdg (sbdf_rxcui, sbdg_rxcui)
select f.rxcui, g.rxcui
from rxno.rxnrel r
join sbdf f on f.rxcui = r.rxcui1
join sbdg g on g.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'inverse_isa'
;

insert into sbdg_sbd (sbdg_rxcui, sbd_rxcui)
select g.rxcui, d.rxcui
from rxno.rxnrel r
join sbdg g on g.rxcui = r.rxcui1
join sbd d on d.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'isa'
;

insert into scd_sy (scd_rxcui, synonym, sy_rxaui)
select cd.rxcui, c1.str, c1.rxaui
from rxno.rxnrel r
join rxno.rxnconso c1 on c1.rxaui = r.rxaui1
join scd cd on cd.rxaui = r.rxaui2
where rxcui1 is null
and r.sab = 'RXNORM' and c1.sab = 'RXNORM' and c1.tty = 'SY'
;

insert into sbd_sy (sbd_rxcui, synonym, sy_rxaui)
select bd.rxcui, c1.str, c1.rxaui
from rxno.rxnrel r
join rxno.rxnconso c1 on c1.rxaui = r.rxaui1
join sbd bd on bd.rxaui = r.rxaui2
where rxcui1 is null
and r.sab = 'RXNORM' and c1.sab = 'RXNORM' and c1.tty = 'SY'
;

insert into scdc_scd (scdc_rxcui, scd_rxcui)
select scdc.rxcui, scd.rxcui
from rxno.rxnrel r
join scdc on scdc.rxcui = r.rxcui1
join scd on scd.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'consists_of'
;

insert into scdf_scdg (scdf_rxcui, scdg_rxcui)
select scdf.rxcui, scdg.rxcui
from rxno.rxnrel r
join scdf on scdf.rxcui = r.rxcui1
join scdg on scdg.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'inverse_isa'
;

insert into scdg_scd (scdg_rxcui, scd_rxcui)
select scdg.rxcui, scd.rxcui
from rxno.rxnrel r
join scdg on scdg.rxcui = r.rxcui1
join scd on scd.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'isa'
;

insert into gpck_scd (gpck_rxcui, scd_rxcui)
select g.rxcui, s.rxcui
from rxno.rxnrel r
join gpck g on g.rxcui = r.rxcui1
join scd s on s.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'contained_in'
;

insert into bpck_scd (bpck_rxcui, scd_rxcui)
select b.rxcui, s.rxcui
from rxno.rxnrel r
join bpck b on b.rxcui = r.rxcui1
join scd s on s.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'contained_in'
;

insert into bpck_sbd (bpck_rxcui, sbd_rxcui)
select b.rxcui, s.rxcui
from rxno.rxnrel r
join bpck b on b.rxcui = r.rxcui1
join sbd s on s.rxcui = r.rxcui2
where r.sab = 'RXNORM' and r.rela = 'contained_in'
;

insert into atc_drug_class(rxcui, rxaui, atc_code, drug_class, drug_class_level)
select distinct
  c.rxcui,
  c.rxaui,
  c.code,
  c.str,
  (select s.atv from rxno.rxnsat s where s.rxaui = c.rxaui and s.atn = 'ATC_LEVEL')
from rxno.rxnconso c
join rxno.rxnsat s on s.rxaui = c.rxaui
where s.sab = 'ATC' and s.atn = 'IS_DRUG_CLASS'
;

-- Load tables derived from sab=MTHSPL subset of RxNorm.

insert into mthspl_sub (rxaui, rxcui, unii, biologic_code, name, in_rxcui, pin_rxcui, suppress)
select
  s.rxaui,
  s.rxcui,
  s.unii,
  s.biologic_code,
  s.name,
  (select i.rxcui from "in" i where i.rxcui = s.rxcui) in_rxcui,
  (select i.rxcui from pin i where i.rxcui = s.rxcui) pin_rxcui,
  s.suppress
from tmp_mthspl_sub s
;

insert into mthspl_prod (rxaui, rxcui, code, rxnorm_created, name, scd_rxcui, sbd_rxcui, gpck_rxcui, bpck_rxcui, suppress, ambiguity_flag)
select
  c.rxaui,
  c.rxcui,
  case when c.code <> 'NOCODE' then c.code end,
  c.tty = 'MTH_RXN_DP',
  c.str as name,
  (select d.rxcui from scd d where d.rxcui = c.rxcui) scd_rxcui,
  (select d.rxcui from sbd d where d.rxcui = c.rxcui) sbd_rxcui,
  (select d.rxcui from gpck d where d.rxcui = c.rxcui) gpck_rxcui,
  (select d.rxcui from bpck d where d.rxcui = c.rxcui) bpck_rxcui,
  c.suppress,
  (select a.atv from rxno.rxnsat a where a.rxaui = c.rxaui and a.atn = 'AMBIGUITY_FLAG') ambiguity_flag
from rxno.rxnconso c
where c.sab='MTHSPL' and c.tty in ('DP','MTH_RXN_DP')
;

insert into mthspl_sub_setid (sub_rxaui, set_id, suppress)
select a.rxaui, a.atv, a.suppress
from mthspl_sub s
join rxno.rxnsat a on a.rxaui = s.rxaui and a.atn = 'SPL_SET_ID'
;

insert into mthspl_ingr_type (ingr_type, description) values
  ('I', 'inactive ingredient'),
  ('A', 'active ingredient'),
  ('M', 'active moiety')
;

insert into mthspl_prod_sub (prod_rxaui, ingr_type, sub_rxaui)
select
  r.rxaui2 prod_rxaui,
  case when r.rela='has_active_ingredient' then 'A'
       when r.rela='has_active_moiety' then 'M'
       else 'I' end ingr_type,
  r.rxaui1 sub_rxaui
from rxno.rxnrel r
where
  r.sab='MTHSPL' and
  r.rela IN ('has_active_ingredient','has_inactive_ingredient','has_active_moiety')
;

insert into mthspl_prod_dmspl
select distinct p.rxaui, a.atv dm_spl_id
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'DM_SPL_ID'
;

insert into mthspl_prod_setid
select distinct p.rxaui, a.atv dm_spl_id
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'SPL_SET_ID'
;

insert into mthspl_prod_ndc
select p.rxaui, a.atv full_ndc, regexp_replace(a.atv , '-[0-9]+$', '') two_part_ndc
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'NDC'
;

insert into mthspl_prod_labeler
select p.rxaui, a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'LABELER'
;

insert into mthspl_prod_labeltype
select p.rxaui, a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'LABEL_TYPE'
;

insert into mthspl_mktcat (name)
select distinct a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'MARKETING_CATEGORY'
;

insert into mthspl_prod_mktcat (prod_rxaui, mkt_cat)
select p.rxaui, a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'MARKETING_CATEGORY'
;

insert into mthspl_prod_mktcat_code(prod_rxaui, mkt_cat, code, num)
select pa.rxaui, mc.name, pa.atv, regexp_replace(pa.atv, '^[A-Za-z]+', '')
from (
  select p.rxaui, a.atn, a.atv
  from mthspl_prod p
  join rxno.rxnsat a on a.rxaui = p.rxaui
) pa
join mthspl_mktcat mc on mc.name = pa.atn
;

insert into mthspl_prod_mktstat
select p.rxaui, a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'MARKETING_STATUS'
;

insert into mthspl_prod_mkteffth
select p.rxaui, a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'MARKETING_EFFECTIVE_TIME_HIGH'
;

insert into mthspl_prod_mktefftl
select p.rxaui, a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'MARKETING_EFFECTIVE_TIME_LOW'
;

insert into mthspl_prod_dcsa
select p.rxaui, a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'DCSA'
;

insert into mthspl_prod_nhric
select p.rxaui, a.atv
from mthspl_prod p
join rxno.rxnsat a on a.rxaui = p.rxaui and a.atn = 'NHRIC'
;

insert into mthspl_pillattr (attr) values
  ('IMPRINT_CODE'),
  ('COATING'),
  ('COLOR'),
  ('COLORTEXT'),
  ('SCORE'),
  ('SHAPE'),
  ('SHAPETEXT'),
  ('SIZE'),
  ('SYMBOL')
;

insert into mthspl_prod_pillattr(prod_rxaui, attr, attr_val)
select pa.rxaui, a.attr, pa.atv
from (
  select p.rxaui, a.atn, a.atv
  from mthspl_prod p
  join rxno.rxnsat a on a.rxaui = p.rxaui
) pa
join mthspl_pillattr a on a.attr = pa.atn
;

drop table tmp_mthspl_sub;
drop table tmp_scd_ingrset;
