create table "in" (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null unique,
  suppress varchar(1) not null
);

create table pin (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null unique,
  in_rxcui varchar(12) not null references "in",
  suppress varchar(1) not null
);
create index ix_pin_in on pin(in_rxcui);

create table ingrset (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null unique,
  suppress varchar(1) not null,
  tty varchar(100) not null
);

create table df (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null,
  origin varchar(500),
  code varchar(500)
);

create table dfg (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null
);

create table df_dfg (
  df_rxcui varchar(12) not null references df,
  dfg_rxcui varchar(12) not null references dfg,
  constraint pk_dfdfg_cui primary key (df_rxcui, dfg_rxcui)
);
create index ix_dfdfg_dfg on df_dfg(dfg_rxcui);

create table scdf (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null unique,
  df_rxcui varchar(12) not null references df
);
create index ix_scdf_df on scdf(df_rxcui);

create table scd (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null unique,
  name varchar(2000) not null,
  prescribable_name varchar(2000),
  rxterm_form varchar(100),
  df_rxcui varchar(12) not null references df,
  scdf_rxcui varchar(12) not null references scdf,
  ingrset_rxcui varchar(12) not null references ingrset,
  available_strengths varchar(500),
  qual_distinct varchar(500),
  suppress varchar(1) not null,
  quantity varchar(100),
  human_drug boolean,
  vet_drug boolean,
  unquantified_form_rxcui varchar(12) references scd
);
create index ix_scd_df on scd(df_rxcui);
create index ix_scd_scdf on scd(scdf_rxcui);
create index ix_scd_ingrset on scd(ingrset_rxcui);
create index ix_scd_uqform on scd(unquantified_form_rxcui);

create table bn (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null unique,
  rxn_cardinality varchar(6),
  reformulated_to_rxcui varchar(12) references bn
);
comment on table bn is 'brand name';
create index ix_bn_reformbn on bn(reformulated_to_rxcui);

create table sbdf (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null,
  bn_rxcui varchar(12) not null references bn,
  df_rxcui varchar(12) not null references df,
  scdf_rxcui varchar(12) not null references scdf,
  constraint uq_sbdf_bn_df unique (bn_rxcui, df_rxcui)
);
create index ix_sbdf_bn on sbdf(bn_rxcui);
create index ix_sbdf_df on sbdf(df_rxcui);
create index ix_sbdf_scdf on sbdf(scdf_rxcui);

create table sbdc (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null
);

create table sbd (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null unique,
  name varchar(2000) not null,
  scd_rxcui varchar(12) not null references scd,
  bn_rxcui varchar(12) not null references bn,
  sbdf_rxcui varchar(12) not null references sbdf,
  sbdc_rxcui varchar(12) not null references sbdc,
  prescribable_name varchar(2000),
  rxterm_form varchar(100),
  df_rxcui varchar(12) not null references df,
  available_strengths varchar(500),
  qual_distinct varchar(500),
  suppress varchar(1) not null,
  quantity varchar(100),
  human_drug boolean,
  vet_drug boolean,
  unquantified_form_rxcui varchar(12) references sbd
);
create index ix_sbd_scd on sbd(scd_rxcui);
create index ix_sbd_bn on sbd(bn_rxcui);
create index ix_sbd_sbdf on sbd(sbdf_rxcui);
create index ix_sbd_sbdc on sbd(sbdc_rxcui);
create index ix_sbd_df on sbd(df_rxcui);
create index ix_sbd_uqsbd on sbd(unquantified_form_rxcui);

create table gpck (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null unique,
  name varchar(2000) not null,
  prescribable_name varchar(2000),
  df_rxcui varchar(12) not null references df,
  suppress varchar(1) not null,
  human_drug boolean
);
create index ix_gpck_df on gpck(df_rxcui);

create table bpck (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null unique,
  name varchar(2000) not null,
  gpck_rxcui varchar(12) not null references gpck,
  prescribable_name varchar(2000),
  df_rxcui varchar(12) not null references df,
  suppress varchar(1) not null,
  human_drug boolean
);
create index ix_bpck_gpck on bpck(gpck_rxcui);
create index ix_bpck_df on bpck(df_rxcui);

create table scdc (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null unique,
  in_rxcui varchar(12) not null references "in",
  pin_rxcui varchar(12) references pin,
  boss_active_ingr_name varchar(2000),
  boss_active_moi_name varchar(2000),
  boss_source varchar(10),
  rxn_in_expressed_flag varchar(10),
  strength varchar(500),
  boss_str_num_unit varchar(100),
  boss_str_num_val varchar(100),
  boss_str_denom_unit varchar(100),
  boss_str_denom_val varchar(100)
);
create index ix_scdc_in on scdc(in_rxcui);
create index ix_scdc_pin on scdc(pin_rxcui);

create table scdg (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null unique,
  dfg_rxcui varchar(12) not null references dfg
);
create index ix_scdg_dfg on scdg(dfg_rxcui);

create table scdf_scdg (
  scdf_rxcui varchar(12) not null references scdf,
  scdg_rxcui varchar(12) not null references scdg,
  constraint pk_scdfscdg_cui primary key (scdf_rxcui, scdg_rxcui)
);
create index ix_scdfscdg_scdg on scdf_scdg(scdg_rxcui);

create table sbdg (
  rxcui varchar(12) primary key,
  rxaui varchar(12) not null,
  name varchar(2000) not null,
  bn_rxcui varchar(12) references bn,
  dfg_rxcui varchar(12) not null references dfg,
  scdg_rxcui varchar(12) not null references scdg,
  constraint uq_sbdg_bn_dfg unique (bn_rxcui, dfg_rxcui)
);
create index ix_sbdg_bn on sbdg(bn_rxcui);
create index ix_sbdg_df on sbdg(dfg_rxcui);
create index ix_sbdg_scdg on sbdg(scdg_rxcui);

create table sbdf_sbdg (
  sbdf_rxcui varchar(12) not null references sbdf,
  sbdg_rxcui varchar(12) not null references sbdg,
  constraint pk_sbdfsbdg_cui primary key (sbdf_rxcui, sbdg_rxcui)
);
create index ix_sbdfsbdg_sbdg on sbdf_sbdg(sbdg_rxcui);

create table sbdg_sbd (
  sbdg_rxcui varchar(12) not null references sbdg,
  sbd_rxcui varchar(12) not null references sbd,
  constraint pk_sbdgsbd_cui primary key (sbdg_rxcui, sbd_rxcui)
);
create index ix_sbdgsbd_sbd on sbdg_sbd(sbd_rxcui);

create table sbdc_scdc (
  sbdc_rxcui varchar(12) not null references sbdc,
  scdc_rxcui varchar(12) not null references scdc,
  constraint pk_sbdcscdc primary key (sbdc_rxcui, scdc_rxcui)
);
create index ix_sbdcscdc_scdc on sbdc_scdc(scdc_rxcui);


create table et (
  rxcui varchar(12) not null,
  rxaui varchar(12) not null,
  name varchar(2000) not null unique,
  constraint pk_doseentrtrm_cuiname primary key (rxcui, name)
);

create table scd_sy (
  scd_rxcui varchar(12) not null references scd,
  synonym varchar(2000) not null,
  sy_rxaui varchar(12) not null,
  constraint pk_scdsy_cuisy primary key (scd_rxcui, synonym)
);
create index ix_scdsy_sy on scd_sy(synonym);

create table sbd_sy (
  sbd_rxcui varchar(12) not null references sbd,
  synonym varchar(2000) not null,
  sy_rxaui varchar(12) not null,
  constraint pk_sbdsy_cuisy primary key (sbd_rxcui, synonym)
);

create table scdc_scd (
  scdc_rxcui varchar(12) not null references scdc,
  scd_rxcui varchar(12) not null references scd,
  constraint pk_scdcscd primary key (scdc_rxcui, scd_rxcui)
);
create index ix_scdscdc_scd on scdc_scd(scd_rxcui);

create table scdg_scd (
  scdg_rxcui varchar(12) not null references scdg,
  scd_rxcui varchar(12) not null references scd,
  constraint pk_scdgscd_cui primary key (scdg_rxcui, scd_rxcui)
);
create index ix_scdgscd_scd on scdg_scd(scd_rxcui);

create table gpck_scd (
  gpck_rxcui varchar(12) not null references gpck,
  scd_rxcui varchar(12) not null references scd,
  constraint pk_gpckscd_cui primary key (gpck_rxcui, scd_rxcui)
);
create index ix_gpckscd_scd on gpck_scd(scd_rxcui);

create table bpck_scd (
  bpck_rxcui varchar(12) not null references bpck,
  scd_rxcui varchar(12) not null references scd,
  constraint pk_bpckscd_cui primary key (bpck_rxcui, scd_rxcui)
);
create index ix_bpckscd_scd on bpck_scd(scd_rxcui);

create table bpck_sbd (
  bpck_rxcui varchar(12) not null references bpck,
  sbd_rxcui varchar(12) not null references sbd,
  constraint pk_bpcksbd_cui primary key (bpck_rxcui, sbd_rxcui)
);
create index ix_bpcksbd_sbd on bpck_sbd(sbd_rxcui);

create table atc_drug_class (
  rxcui varchar(12) not null,
  rxaui varchar(12) not null,
  atc_code varchar(12) not null,
  drug_class varchar(3000) not null,
  drug_class_level varchar(2) not null,
  constraint pk_atcdrugcls_auiclass primary key (rxaui, drug_class)
);

create table mthspl_sub (
  rxaui varchar(12) not null primary key,
  rxcui varchar(12) not null,
  unii varchar(10),
  biologic_code varchar(18),
  name varchar(2000) not null,
  in_rxcui varchar(12) references "in",
  pin_rxcui varchar(12) references pin,
  suppress varchar(1) not null,
  constraint ck_mthspl_sub_notuniiandbiocode check (unii is null or biologic_code is null)
);
create index ix_mthsplsub_cui on mthspl_sub(rxcui);
create index ix_mthsplsub_unii on mthspl_sub(unii);
create index ix_mthsplsub_code on mthspl_sub(biologic_code);
create index ix_mthsplsub_in on mthspl_sub(in_rxcui);
create index ix_mthsplsub_pin on mthspl_sub(pin_rxcui);

create table mthspl_prod (
  rxaui varchar(12) not null primary key,
  rxcui varchar(12) not null,
  code varchar(13), -- Most of these are NDCs without packaging (3rd part), some are not NDCs at all.
  rxnorm_created boolean not null,
  name varchar(4000) not null,
  scd_rxcui varchar(12) references scd,   -- | mutually exclusive
  sbd_rxcui varchar(12) references sbd,   -- |
  gpck_rxcui varchar(12) references gpck, -- |
  bpck_rxcui varchar(12) references bpck, -- |
  suppress varchar(1) not null,
  ambiguity_flag varchar(9),
  constraint ck_mthsplprod_xor_drug_refs check (
    case when scd_rxcui is null then 0 else 1 end +
    case when sbd_rxcui is null then 0 else 1 end +
    case when gpck_rxcui is null then 0 else 1 end +
    case when bpck_rxcui  is null then 0 else 1 end <= 1
  )
);
create index ix_mthsplprod_cui on mthspl_prod(rxcui);
create index ix_mthsplprod_code on mthspl_prod(code);
create index ix_mthsplprod_scd on mthspl_prod(scd_rxcui);
create index ix_mthsplprod_sbd on mthspl_prod(sbd_rxcui);
create index ix_mthsplprod_gpck on mthspl_prod(gpck_rxcui);
create index ix_mthsplprod_bpck on mthspl_prod(bpck_rxcui);

create table mthspl_sub_setid (
  sub_rxaui varchar(12) not null references mthspl_sub,
  set_id varchar(46) not null,
  suppress varchar(1) not null,
  primary key (sub_rxaui, set_id)
);
create index ix_mthsplsubsetid_setid on mthspl_sub_setid(set_id);

create table mthspl_ingr_type (
  ingr_type varchar(1) not null primary key,
  description varchar(1000) not null
);

create table mthspl_prod_sub (
  prod_rxaui varchar(12) not null references mthspl_prod,
  ingr_type varchar(1) not null references mthspl_ingr_type,
  sub_rxaui varchar(12) not null references mthspl_sub,
  primary key (prod_rxaui, ingr_type, sub_rxaui)
);
create index ix_mthsplprodsub_ingrtype on mthspl_prod_sub(ingr_type);
create index ix_mthsplprodsub_subaui on mthspl_prod_sub(sub_rxaui);

create table mthspl_prod_dmspl (
  prod_rxaui varchar(12) not null references mthspl_prod,
  dm_spl_id varchar(46) not null,
  primary key (prod_rxaui, dm_spl_id)
);
create index ix_mthspl_proddmspl_dmsplid on mthspl_prod_dmspl(dm_spl_id);

create table mthspl_prod_setid (
  prod_rxaui varchar(12) not null references mthspl_prod,
  spl_set_id varchar(46) not null,
  primary key (prod_rxaui, spl_set_id)
);
create index ix_mthsplprodsetid_setid on mthspl_prod_setid(spl_set_id);

create table mthspl_prod_ndc (
  prod_rxaui varchar(12) not null references mthspl_prod,
  full_ndc varchar(12) not null,
  two_part_ndc varchar(12) not null,
  primary key (prod_rxaui, full_ndc)
);
create index ix_mthsplprodndc_fullndc on mthspl_prod_ndc(full_ndc);
create index ix_mthsplprodndc_twopartndc on mthspl_prod_ndc(two_part_ndc);

create table mthspl_prod_labeler (
  prod_rxaui varchar(12) not null references mthspl_prod,
  labeler varchar(2000) not null,
  primary key (prod_rxaui, labeler)
);

create table mthspl_prod_labeltype (
  prod_rxaui varchar(12) not null references mthspl_prod,
  label_type varchar(500) not null,
  primary key (prod_rxaui, label_type)
);
create index ix_mthsplprodlblt_lblt on mthspl_prod_labeltype(label_type);

create table mthspl_prod_mktstat (
  prod_rxaui varchar(12) not null references mthspl_prod,
  mkt_stat varchar(500) not null,
  primary key (prod_rxaui, mkt_stat)
);
create index ix_mthsplprodmktstat_mktstat on mthspl_prod_mktstat(mkt_stat);

create table mthspl_prod_mkteffth (
  prod_rxaui varchar(12) not null references mthspl_prod,
  mkt_eff_time_high varchar(8) not null,
  primary key (prod_rxaui, mkt_eff_time_high)
);
create index ix_mthsplprodmkteffth_mkteffth on mthspl_prod_mkteffth(mkt_eff_time_high);

create table mthspl_prod_mktefftl (
  prod_rxaui varchar(12) not null references mthspl_prod,
  mkt_eff_time_low varchar(8) not null,
  primary key (prod_rxaui, mkt_eff_time_low)
);
create index ix_mthsplprodmktefftl_mktetl on mthspl_prod_mktefftl(mkt_eff_time_low);

create table mthspl_mktcat (
  name varchar(500) primary key
);

create table mthspl_prod_mktcat (
  prod_rxaui varchar(12) not null references mthspl_prod,
  mkt_cat varchar(500) not null references mthspl_mktcat,
  primary key (prod_rxaui, mkt_cat)
);
create index ix_mthsplprodmktcat_mktcat on mthspl_prod_mktcat(mkt_cat);

create table mthspl_prod_mktcat_code (
  prod_rxaui varchar(12) not null references mthspl_prod,
  mkt_cat varchar(500) not null references mthspl_mktcat,
  code varchar(20) not null,
  num varchar(9) not null,
  primary key (prod_rxaui, mkt_cat, code)
);
create index ix_mthsplprodmktcatcode_mktcat on mthspl_prod_mktcat_code(mkt_cat);
create index ix_mthsplprodmktcatcode_code on mthspl_prod_mktcat_code(code);
create index ix_mthsplprodmktcatcode_num on mthspl_prod_mktcat_code(num);

create table mthspl_pillattr (
  attr varchar(500) primary key
);

create table mthspl_prod_pillattr (
  prod_rxaui varchar(12) not null references mthspl_prod,
  attr varchar(500) not null references mthspl_pillattr,
  attr_val varchar(1000) not null,
  primary key (prod_rxaui, attr, attr_val)
);
create index ix_mthsplprodpillattr_attr on mthspl_prod_pillattr(attr);
create index ix_mthsplprodpillattr_attrval on mthspl_prod_pillattr(attr_val);

create table mthspl_prod_dcsa (
  prod_rxaui varchar(12) not null references mthspl_prod,
  dcsa varchar(4) not null,
  primary key (prod_rxaui, dcsa)
);
create index ix_mthsplproddcsa_dcsa on mthspl_prod_dcsa(dcsa);

create table mthspl_prod_nhric (
  prod_rxaui varchar(12) not null references mthspl_prod,
  nhric varchar(13) not null,
  primary key (prod_rxaui, nhric)
);
create index ix_mthsplproddcsa_nhric on mthspl_prod_nhric(nhric);
