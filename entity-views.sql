create view ent_scd_v as
select
  scd.rxcui "rxcui",
  scd.name "name",
  scd.prescribable_name "prescribableName",
  scd.rxterm_form "rxtermForm",
  df.name "dosageForm",
  scd.ingrset_rxcui "ingrSetRxcui",
  scd.available_strengths "availableStrengths",
  scd.qual_distinct "qualDistinct",
  scd.quantity "quantity",
  scd.human_drug "humanDrug",
  scd.vet_drug "vetDrug",
  scd.unquantified_form_rxcui "unquantifiedFormRxcui",
  scd.suppress "suppress"
from scd
join df on df.rxcui = scd.df_rxcui
;

create view ent_sbd_v as
select
  sbd.rxcui                   "rxcui",
  sbd.name                    "name",
  sbd.prescribable_name       "prescribableName",
  sbd.rxterm_form             "rxtermForm",
  df.name                     "dosageForm",
  sbd.available_strengths     "availableStrengths",
  sbd.qual_distinct           "qualDistinct",
  sbd.quantity                "quantity",
  sbd.human_drug              "humanDrug",
  sbd.vet_drug                "vetDrug",
  sbd.unquantified_form_rxcui "unquantifiedFormRxcui",
  sbd.suppress                "suppress"
from sbd
join df on df.rxcui = sbd.df_rxcui
;

create materialized view ndc_scd_mv as
select distinct pc.two_part_ndc, d.rxcui scd_rxcui
from mthspl_prod_ndc pc
join mthspl_prod p on p.rxaui = pc.prod_rxaui
join scd d on d.rxcui = p.rxcui
;
create unique index ix_ndcscdmv_ndccui on ndc_scd_mv (two_part_ndc, scd_rxcui);
create index ix_ndcscdmv_cui on ndc_scd_mv (scd_rxcui);

create materialized view ndc_sbd_mv as
select distinct pc.two_part_ndc, d.rxcui sbd_rxcui
from mthspl_prod_ndc pc
join mthspl_prod p on p.rxaui = pc.prod_rxaui
join sbd d on d.rxcui = p.rxcui
;
create unique index ix_ndcsbdmv_ndccui on ndc_sbd_mv (two_part_ndc, sbd_rxcui);
create index ix_ndcsbdmv_cui on ndc_sbd_mv (sbd_rxcui);

-- TODO: Define more drug related isolated entities above, then include in ndc_isoents_mv below.

create materialized view relents_ndc_mv as
select
  pc.two_part_ndc ndc,
  (select coalesce(json_agg(d.*), '[]'::json)
   from ent_scd_v d
   where d.rxcui in (select scd_rxcui from ndc_scd_mv where two_part_ndc = pc.two_part_ndc)
  ) scds,
  (select coalesce(json_agg(d.*), '[]'::json)
   from ent_sbd_v d
   where d.rxcui in (select sbd_rxcui from ndc_sbd_mv where two_part_ndc = pc.two_part_ndc)
  ) sbds
from mthspl_prod_ndc pc
join mthspl_prod p on p.rxaui = pc.prod_rxaui
group by pc.two_part_ndc
;
create unique index ix_relentsndc_ndc on relents_ndc_mv (ndc);
