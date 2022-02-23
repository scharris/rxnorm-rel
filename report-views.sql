-- FUNCTIONS
create function uniis_str(p_prod_rxaui varchar) returns varchar as $$
select string_agg(distinct s.unii, '|' order by s.unii)
from mthspl_prod_sub ps
       join mthspl_sub s on s.rxaui = ps.sub_rxaui
where ps.prod_rxaui = p_prod_rxaui and ps.ingr_type <> 'I'
$$ language sql;

create function drug_name(p_drug_rxcui varchar) returns varchar as $$
select d.str
from rxno.rxnconso d
where d.rxcui = p_drug_rxcui and d.tty in ('SBD','SCD') and d.sab='RXNORM';
$$ language sql;

create or replace view drug_v as
select
  d.rxcui,
  d.rxaui,
  d.tty,
  d.str as name,
  (select psn.str from rxno.rxnconso psn where psn.tty = 'PSN' and psn.rxcui = d.rxcui) prescribable_name,
  d.suppress,
  case
    when exists(select 1 from rxno.rxnrel where rela = 'has_quantified_form' and rxcui1 = d.rxcui) then 'Q'
    when exists(select 1 from rxno.rxnrel where rela = 'quantified_form_of' and rxcui1 = d.rxcui) then 'UQ'
  end quantification
from rxno.rxnconso d
where d.sab='RXNORM' and d.tty in ('SBD','SCD')
;

create or replace view mthspl_prod_sub_v as
select
  ps.prod_rxaui,
  p.rxcui          prod_rxcui,
  p.code           prod_code,
  p.rxnorm_created prod_rxnorm_created,
  p.name           prod_name,
  p.suppress       prod_suppress,
  p.ambiguity_flag prod_ambiguity_flag,
  ps.ingr_type,
  ps.sub_rxaui,
  s.rxcui          sub_rxcui,
  s.unii           sub_unii,
  s.biologic_code  sub_biologic_code,
  s.name           sub_name,
  s.suppress       sub_suppress
from mthspl_prod_sub ps
join mthspl_prod p on ps.prod_rxaui = p.rxaui
join mthspl_sub s on s.rxaui = ps.sub_rxaui
;

create or replace view drug_generalized_v as
select
  d.rxcui,
  (
    select rxcui1
    from rxno.rxnrel rel
    where rel.rela = 'quantified_form_of'
    and rel.rxcui2 = d.rxcui
  ) non_quantified_rxcui,
  case when d.tty = 'SCD'
    then d.rxcui
    else (select sbd.scd_rxcui from sbd where sbd.rxcui = d.rxcui)
  end generic_rxcui,
  case when d.tty = 'SCD'
    then (
      select rxcui1
      from rxno.rxnrel rel
      where rel.rela = 'quantified_form_of'
      and rel.rxcui2 = d.rxcui
    )
    else (
      select rxcui1
      from rxno.rxnrel rel
      where rel.rela = 'quantified_form_of'
      and rel.rxcui2 in (select sbd.scd_rxcui from sbd where sbd.rxcui = d.rxcui)
    )
  end generic_unquantified_rxcui
from drug_v d
;
comment on view drug_generalized_v is 'drugs with non-quantified, generic, and non-quantified generic variants';

create materialized view drug_generalized_mv as
select * from drug_generalized_v
;
create unique index ix_druggeneral_rxcui on drug_generalized_mv(rxcui);


create or replace view mthspl_prod_v as
select
  p.rxaui,
  p.rxcui,
  p.code,
  p.rxnorm_created,
  p.name,
  p.suppress,
  p.ambiguity_flag,
  (select coalesce(jsonb_agg(distinct uniis_str(mp.rxaui)), '[]'::jsonb) from mthspl_prod mp where mp.rxaui = p.rxaui) prod_uniis,
  (select coalesce(jsonb_agg(distinct spl_set_id), '[]'::jsonb) from mthspl_prod_setid mps where mps.prod_rxaui = p.rxaui) set_ids,
  (select coalesce(jsonb_agg(distinct label_type), '[]'::jsonb) from mthspl_prod_labeltype where prod_rxaui = p.rxaui) label_types,
  (select coalesce(jsonb_agg(distinct labeler), '[]'::jsonb) from mthspl_prod_labeler where prod_rxaui = p.rxaui) labelers,
  (select coalesce(jsonb_agg(distinct mkt_cat), '[]'::jsonb) from mthspl_prod_mktcat where prod_rxaui = p.rxaui) mkt_cats,
  (select coalesce(jsonb_agg(distinct code), '[]'::jsonb) from mthspl_prod_mktcat_code where prod_rxaui = p.rxaui) mkt_cat_codes,
  (select coalesce(jsonb_agg(distinct full_ndc), '[]'::jsonb) from mthspl_prod_ndc where prod_rxaui = p.rxaui) full_ndc_codes,
  (select coalesce(jsonb_agg(distinct two_part_ndc), '[]'::jsonb) from mthspl_prod_ndc where prod_rxaui = p.rxaui) short_ndc_codes,
  (select
    coalesce(jsonb_agg(jsonb_build_object(
      'ingrType', ingr_type,
      'rxaui', sub_rxaui,
      'rxcui', sub_rxcui,
      'unii', sub_unii,
      'biologicCode', sub_biologic_code,
      'name', sub_name,
      'suppress', sub_suppress)), '[]'::jsonb)
   from mthspl_prod_sub_v ps
   where p.rxaui = ps.prod_rxaui) substances
from mthspl_prod p
;

create or replace view mthspl_rxprod_v as
select p.*
from mthspl_prod_v p
where p.rxaui in (
  select plt.prod_rxaui
  from mthspl_prod_labeltype plt
  where plt.label_type = 'HUMAN PRESCRIPTION DRUG LABEL' or plt.label_type = 'HUMAN PRESCRIPTION DRUG LABEL WITH HIGHLIGHTS'
)
;

create or replace view mthspl_mktcode_prod_drug_v as
select
  pmcc.code                                                     application_code,
  pmcc.mkt_cat                                                  market_catergory,
  coalesce(jsonb_agg(distinct p.name), '[]'::jsonb)             product_name,
  coalesce(jsonb_agg(distinct p.code), '[]'::jsonb)             product_code,
  (select coalesce(jsonb_agg(distinct pn.two_part_ndc), '[]'::jsonb)
   from mthspl_prod_ndc pn
   where pn.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           ndcs,
  (select coalesce(jsonb_agg(distinct spl_set_id), '[]'::jsonb)
   from mthspl_prod_setid ps
   where ps.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           set_ids,
  (select coalesce(jsonb_agg(distinct label_type), '[]'::jsonb)
   from mthspl_prod_labeltype plt
   where plt.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           label_types,
  (select coalesce(jsonb_agg(distinct labeler), '[]'::jsonb)
   from mthspl_prod_labeler pl
   where pl.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           labelers,
  coalesce(jsonb_agg(distinct uniis_str(pmcc.prod_rxaui)), '[]'::jsonb) prod_uniis,
  (select coalesce(jsonb_agg(distinct jsonb_build_object(
       'ingrType', s.ingr_type,
       'rxaui', s.sub_rxaui,
       'rxcui', s.sub_rxcui,
       'unii', s.sub_unii,
       'biologicCode', s.sub_biologic_code,
       'name', s.sub_name,
       'suppress', s.sub_suppress)), '[]'::jsonb)
   from mthspl_prod_sub_v s
   where s.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           product_substances,
  coalesce(jsonb_agg(distinct d.rxcui)
    filter (where d.rxcui is not null), '[]'::jsonb)                        rxnorm_cuis,
  coalesce(jsonb_agg(distinct d.tty)
    filter (where d.tty is not null), '[]'::jsonb)                          rxnorm_term_types,
  coalesce(jsonb_agg(distinct d.name)
    filter (where d.name is not null), '[]'::jsonb)                         rxnorm_drug_names,
  coalesce(jsonb_agg(distinct d.prescribable_name)
    filter (where d.prescribable_name is not null), '[]'::jsonb)             rxnorm_prescribable_names,
  coalesce(jsonb_agg(distinct dgm.non_quantified_rxcui)
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)       rxnorm_unquantified_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.non_quantified_rxcui))
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)      unquantified_names,
  coalesce(jsonb_agg(distinct dgm.generic_rxcui)
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)              rxnorm_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_rxcui))
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)      generic_names,
  coalesce(jsonb_agg(distinct dgm.generic_unquantified_rxcui)
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) rxnorm_unquantified_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_unquantified_rxcui))
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) generic_unqualified_names
from mthspl_prod_mktcat_code pmcc
join mthspl_prod p on p.rxaui = pmcc.prod_rxaui
left join drug_v d on d.rxcui = p.rxcui
left join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
group by pmcc.code, pmcc.mkt_cat
;

create or replace view mthspl_mktcode_rxprod_drug_v as
select
  pmcc.code                                                     application_code,
  pmcc.mkt_cat                                                  market_catergory,
  coalesce(jsonb_agg(distinct p.name), '[]'::jsonb)             product_name,
  coalesce(jsonb_agg(distinct p.code), '[]'::jsonb)             product_code,
  (select coalesce(jsonb_agg(distinct pn.two_part_ndc), '[]'::jsonb)
   from mthspl_prod_ndc pn
   where pn.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           ndcs,
  (select coalesce(jsonb_agg(distinct spl_set_id), '[]'::jsonb)
   from mthspl_prod_setid ps
   where ps.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           set_ids,
  (select coalesce(jsonb_agg(distinct label_type), '[]'::jsonb)
   from mthspl_prod_labeltype plt
   where plt.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           label_types,
  (select coalesce(jsonb_agg(distinct labeler), '[]'::jsonb)
   from mthspl_prod_labeler pl
   where pl.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           labelers,
  coalesce(jsonb_agg(distinct uniis_str(pmcc.prod_rxaui)), '[]'::jsonb) prod_uniis,
  (select coalesce(jsonb_agg(distinct jsonb_build_object(
       'ingrType', s.ingr_type,
       'rxaui', s.sub_rxaui,
       'rxcui', s.sub_rxcui,
       'unii', s.sub_unii,
       'biologicCode', s.sub_biologic_code,
       'name', s.sub_name,
       'suppress', s.sub_suppress)), '[]'::jsonb)
   from mthspl_prod_sub_v s
   where s.prod_rxaui in (
     select pmc.prod_rxaui
     from mthspl_prod_mktcat_code pmc
     where pmc.code = pmcc.code
   ))                                                           product_substances,
  coalesce(jsonb_agg(distinct d.rxcui)
    filter (where d.rxcui is not null), '[]'::jsonb)                        rxnorm_cuis,
  coalesce(jsonb_agg(distinct d.tty)
    filter (where d.tty is not null), '[]'::jsonb)                          rxnorm_term_types,
  coalesce(jsonb_agg(distinct d.name)
    filter (where d.name is not null), '[]'::jsonb)                         rxnorm_drug_names,
  coalesce(jsonb_agg(distinct d.prescribable_name)
    filter (where d.prescribable_name is not null), '[]'::jsonb)             rxnorm_prescribable_names,
  coalesce(jsonb_agg(distinct dgm.non_quantified_rxcui)
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)       rxnorm_unquantified_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.non_quantified_rxcui))
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)      unquantified_names,
  coalesce(jsonb_agg(distinct dgm.generic_rxcui)
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)              rxnorm_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_rxcui))
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)      generic_names,
  coalesce(jsonb_agg(distinct dgm.generic_unquantified_rxcui)
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) rxnorm_unquantified_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_unquantified_rxcui))
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) generic_unqualified_names
from mthspl_prod_mktcat_code pmcc
join mthspl_prod p on p.rxaui = pmcc.prod_rxaui
left join drug_v d on d.rxcui = p.rxcui
left join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
where p.rxaui in (
    select mpl.prod_rxaui
    from mthspl_prod_labeltype mpl
    where mpl.label_type = 'HUMAN PRESCRIPTION DRUG LABEL' or mpl.label_type = 'HUMAN PRESCRIPTION DRUG LABEL WITH HIGHLIGHTS'
)
group by pmcc.code, pmcc.mkt_cat
;

create or replace view mthspl_prod_setid_v as
select
  ps.spl_set_id                                                 set_id,
  coalesce(jsonb_agg(distinct ps.prod_rxaui), '[]'::jsonb)      prod_atom_id,
  coalesce(jsonb_agg(distinct p.name), '[]'::jsonb)             product_name,
  coalesce(jsonb_agg(distinct p.code), '[]'::jsonb)             product_code,
  (select
     coalesce(jsonb_agg(distinct label_type), '[]'::jsonb)
   from mthspl_prod_labeltype plt
   where plt.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           label_types,
  (select
     coalesce(jsonb_agg(distinct labeler), '[]'::jsonb)
   from mthspl_prod_labeler pl
   where pl.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           labelers,
  (select
     coalesce(jsonb_agg(distinct code), '[]'::jsonb)
   from mthspl_prod_mktcat_code pmcc
   where pmcc.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           application_codes,
  (select
     coalesce(jsonb_agg(distinct mkt_cat), '[]'::jsonb)
   from mthspl_prod_mktcat pmc
   where pmc.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           market_categories,
  coalesce(jsonb_agg(distinct uniis_str(ps.prod_rxaui)), '[]'::jsonb) prod_uniis,
  (select
     coalesce(jsonb_agg(distinct jsonb_build_object(
       'ingrType', s.ingr_type,
       'rxaui', s.sub_rxaui,
       'rxcui', s.sub_rxcui,
       'unii', s.sub_unii,
       'biologicCode', s.sub_biologic_code,
       'name', s.sub_name,
       'suppress', s.sub_suppress)), '[]'::jsonb)
   from mthspl_prod_sub_v s
   where s.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           product_substances,
  coalesce(jsonb_agg(distinct d.rxcui)
    filter (where d.rxcui is not null), '[]'::jsonb)                        rxnorm_cuis,
  coalesce(jsonb_agg(distinct d.tty)
    filter (where d.tty is not null), '[]'::jsonb)                          rxnorm_term_types,
  coalesce(jsonb_agg(distinct d.name)
    filter (where d.name is not null), '[]'::jsonb)                         rxnorm_drug_names,
  coalesce(jsonb_agg(distinct d.prescribable_name)
    filter (where d.prescribable_name is not null), '[]'::jsonb)             rxnorm_prescribable_names,
  coalesce(jsonb_agg(distinct dgm.non_quantified_rxcui)
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)       rxnorm_unquantified_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.non_quantified_rxcui))
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)      unquantified_names,
  coalesce(jsonb_agg(distinct dgm.generic_rxcui)
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)              rxnorm_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_rxcui))
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)      generic_names,
  coalesce(jsonb_agg(distinct dgm.generic_unquantified_rxcui)
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) rxnorm_unquantified_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_unquantified_rxcui))
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) generic_unqualified_names
from mthspl_prod_setid ps
join mthspl_prod p on p.rxaui = ps.prod_rxaui
left join drug_v d on d.rxcui = p.rxcui
left join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
group by ps.spl_set_id
;

create or replace view mthspl_rxprod_setid_drug_v as
select
  ps.spl_set_id                                                 set_id,
  coalesce(jsonb_agg(distinct ps.prod_rxaui), '[]'::jsonb)      prod_atom_id,
  coalesce(jsonb_agg(distinct p.name), '[]'::jsonb)             product_name,
  coalesce(jsonb_agg(distinct p.code), '[]'::jsonb)             product_code,
  (select
     coalesce(jsonb_agg(distinct label_type), '[]'::jsonb)
   from mthspl_prod_labeltype plt
   where plt.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           label_types,
  (select
     coalesce(jsonb_agg(distinct labeler), '[]'::jsonb)
   from mthspl_prod_labeler pl
   where pl.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           labelers,
  (select
     coalesce(jsonb_agg(distinct code), '[]'::jsonb)
   from mthspl_prod_mktcat_code pmcc
   where pmcc.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           application_codes,
  (select
     coalesce(jsonb_agg(distinct mkt_cat), '[]'::jsonb)
   from mthspl_prod_mktcat pmc
   where pmc.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           market_categories,
  coalesce(jsonb_agg(distinct uniis_str(ps.prod_rxaui)), '[]'::jsonb) prod_uniis,
  (select
     coalesce(jsonb_agg(distinct jsonb_build_object(
       'ingrType', s.ingr_type,
       'rxaui', s.sub_rxaui,
       'rxcui', s.sub_rxcui,
       'unii', s.sub_unii,
       'biologicCode', s.sub_biologic_code,
       'name', s.sub_name,
       'suppress', s.sub_suppress)), '[]'::jsonb)
   from mthspl_prod_sub_v s
   where s.prod_rxaui in (
     select psi.prod_rxaui
     from mthspl_prod_setid psi
     where psi.spl_set_id = ps.spl_set_id
   ))                                                           product_substances,
  coalesce(jsonb_agg(distinct d.rxcui)
    filter (where d.rxcui is not null), '[]'::jsonb)                        rxnorm_cuis,
  coalesce(jsonb_agg(distinct d.tty)
    filter (where d.tty is not null), '[]'::jsonb)                          rxnorm_term_types,
  coalesce(jsonb_agg(distinct d.name)
    filter (where d.name is not null), '[]'::jsonb)                         rxnorm_drug_names,
  coalesce(jsonb_agg(distinct d.prescribable_name)
    filter (where d.prescribable_name is not null), '[]'::jsonb)             rxnorm_prescribable_names,
  coalesce(jsonb_agg(distinct dgm.non_quantified_rxcui)
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)       rxnorm_unquantified_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.non_quantified_rxcui))
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)      unquantified_names,
  coalesce(jsonb_agg(distinct dgm.generic_rxcui)
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)              rxnorm_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_rxcui))
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)      generic_names,
  coalesce(jsonb_agg(distinct dgm.generic_unquantified_rxcui)
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) rxnorm_unquantified_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_unquantified_rxcui))
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) generic_unqualified_names
from mthspl_prod_setid ps
join mthspl_prod p on p.rxaui = ps.prod_rxaui
left join drug_v d on d.rxcui = p.rxcui
left join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
where p.rxaui in (
  select mpl.prod_rxaui
  from mthspl_prod_labeltype mpl
  where mpl.label_type = 'HUMAN PRESCRIPTION DRUG LABEL' or mpl.label_type = 'HUMAN PRESCRIPTION DRUG LABEL WITH HIGHLIGHTS'
)
group by ps.spl_set_id
;

create or replace view mthspl_ndc_prod_drug_v as
select
  pn.two_part_ndc                                               short_ndc,
  coalesce(jsonb_agg(distinct pn.full_ndc), '[]'::jsonb)        full_ndcs,
  coalesce(jsonb_agg(distinct p.name), '[]'::jsonb)             product_name,
  coalesce(jsonb_agg(distinct p.code), '[]'::jsonb)             product_code,
  (select coalesce(jsonb_agg(distinct spl_set_id), '[]'::jsonb)
   from mthspl_prod_setid ps
   where ps.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           set_ids,
  (select coalesce(jsonb_agg(distinct label_type), '[]'::jsonb)
   from mthspl_prod_labeltype plt
   where plt.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           label_types,
  (select coalesce(jsonb_agg(distinct labeler), '[]'::jsonb)
   from mthspl_prod_labeler pl
   where pl.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           labelers,
  (select coalesce(jsonb_agg(distinct code), '[]'::jsonb)
   from mthspl_prod_mktcat_code pmcc
   where pmcc.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           application_codes,
  (select coalesce(jsonb_agg(distinct mkt_cat), '[]'::jsonb)
   from mthspl_prod_mktcat pmc
   where pmc.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           market_categories,
  coalesce(jsonb_agg(distinct uniis_str(pn.prod_rxaui)), '[]'::jsonb) prod_uniis,
  (select coalesce(jsonb_agg(distinct jsonb_build_object(
       'ingrType', s.ingr_type,
       'rxaui', s.sub_rxaui,
       'rxcui', s.sub_rxcui,
       'unii', s.sub_unii,
       'biologicCode', s.sub_biologic_code,
       'name', s.sub_name,
       'suppress', s.sub_suppress)), '[]'::jsonb)
   from mthspl_prod_sub_v s
   where s.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           product_substances,
  coalesce(jsonb_agg(distinct d.rxcui)
    filter (where d.rxcui is not null), '[]'::jsonb)                        rxnorm_cuis,
  coalesce(jsonb_agg(distinct d.tty)
    filter (where d.tty is not null), '[]'::jsonb)                          rxnorm_term_types,
  coalesce(jsonb_agg(distinct d.name)
    filter (where d.name is not null), '[]'::jsonb)                         rxnorm_drug_names,
  coalesce(jsonb_agg(distinct d.prescribable_name)
    filter (where d.prescribable_name is not null), '[]'::jsonb)             rxnorm_prescribable_names,
  coalesce(jsonb_agg(distinct dgm.non_quantified_rxcui)
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)       rxnorm_unquantified_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.non_quantified_rxcui))
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)      unquantified_names,
  coalesce(jsonb_agg(distinct dgm.generic_rxcui)
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)              rxnorm_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_rxcui))
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)      generic_names,
  coalesce(jsonb_agg(distinct dgm.generic_unquantified_rxcui)
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) rxnorm_unquantified_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_unquantified_rxcui))
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) generic_unqualified_names
from mthspl_prod_ndc pn
join mthspl_prod p on p.rxaui = pn.prod_rxaui
left join drug_v d on d.rxcui = p.rxcui
left join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
group by pn.two_part_ndc
;

create or replace view mthspl_ndc_rxprod_drug_v as
select
  pn.two_part_ndc                                               short_ndc,
  coalesce(jsonb_agg(distinct pn.full_ndc), '[]'::jsonb)        full_ndcs,
  coalesce(jsonb_agg(distinct p.name), '[]'::jsonb)             product_name,
  coalesce(jsonb_agg(distinct p.code), '[]'::jsonb)             product_code,
  (select coalesce(jsonb_agg(distinct spl_set_id), '[]'::jsonb)
   from mthspl_prod_setid ps
   where ps.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           set_ids,
  (select coalesce(jsonb_agg(distinct label_type), '[]'::jsonb)
   from mthspl_prod_labeltype plt
   where plt.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           label_types,
  (select coalesce(jsonb_agg(distinct labeler), '[]'::jsonb)
   from mthspl_prod_labeler pl
   where pl.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           labelers,
  (select coalesce(jsonb_agg(distinct code), '[]'::jsonb)
   from mthspl_prod_mktcat_code pmcc
   where pmcc.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           application_codes,
  (select coalesce(jsonb_agg(distinct mkt_cat), '[]'::jsonb)
   from mthspl_prod_mktcat pmc
   where pmc.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           market_categories,
  coalesce(jsonb_agg(distinct uniis_str(pn.prod_rxaui)), '[]'::jsonb) prod_uniis,
  (select coalesce(jsonb_agg(distinct jsonb_build_object(
       'ingrType', s.ingr_type,
       'rxaui', s.sub_rxaui,
       'rxcui', s.sub_rxcui,
       'unii', s.sub_unii,
       'biologicCode', s.sub_biologic_code,
       'name', s.sub_name,
       'suppress', s.sub_suppress)), '[]'::jsonb)
   from mthspl_prod_sub_v s
   where s.prod_rxaui in (
     select pnc.prod_rxaui
     from mthspl_prod_ndc pnc
     where pnc.two_part_ndc = pn.two_part_ndc
   ))                                                           product_substances,
  coalesce(jsonb_agg(distinct d.rxcui)
    filter (where d.rxcui is not null), '[]'::jsonb)                        rxnorm_cuis,
  coalesce(jsonb_agg(distinct d.tty)
    filter (where d.tty is not null), '[]'::jsonb)                          rxnorm_term_types,
  coalesce(jsonb_agg(distinct d.name)
    filter (where d.name is not null), '[]'::jsonb)                         rxnorm_drug_names,
  coalesce(jsonb_agg(distinct d.prescribable_name)
    filter (where d.prescribable_name is not null), '[]'::jsonb)             rxnorm_prescribable_names,
  coalesce(jsonb_agg(distinct dgm.non_quantified_rxcui)
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)       rxnorm_unquantified_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.non_quantified_rxcui))
    filter (where dgm.non_quantified_rxcui is not null), '[]'::jsonb)      unquantified_names,
  coalesce(jsonb_agg(distinct dgm.generic_rxcui)
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)              rxnorm_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_rxcui))
    filter (where dgm.generic_rxcui is not null), '[]'::jsonb)      generic_names,
  coalesce(jsonb_agg(distinct dgm.generic_unquantified_rxcui)
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) rxnorm_unquantified_generic_cuis,
  coalesce(jsonb_agg(distinct drug_name(dgm.generic_unquantified_rxcui))
    filter (where dgm.generic_unquantified_rxcui is not null), '[]'::jsonb) generic_unqualified_names
from mthspl_prod_ndc pn
join mthspl_prod p on p.rxaui = pn.prod_rxaui
left join drug_v d on d.rxcui = p.rxcui
left join drug_generalized_mv dgm on d.rxcui = dgm.rxcui
where p.rxaui in (
  select mpl.prod_rxaui
  from mthspl_prod_labeltype mpl
  where mpl.label_type = 'HUMAN PRESCRIPTION DRUG LABEL' or mpl.label_type = 'HUMAN PRESCRIPTION DRUG LABEL WITH HIGHLIGHTS'
)
group by pn.two_part_ndc
;
