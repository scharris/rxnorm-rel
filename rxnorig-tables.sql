-- Derived from RxNorm Oracle ddl as follows:
--   Set search path to rxno at top.
--   Remove DROP statements.
--   Concatenate RXNormDDL.sql, rxn_index.sql, and add extra indexes section at bottom.

set search_path to rxno;

CREATE TABLE RXNATOMARCHIVE
(
   RXAUI VARCHAR(8) NOT NULL,
   AUI VARCHAR(10),
   STR VARCHAR(4000) NOT NULL,
   ARCHIVE_TIMESTAMP VARCHAR(280) NOT NULL,
   CREATED_TIMESTAMP VARCHAR(280) NOT NULL,
   UPDATED_TIMESTAMP VARCHAR(280) NOT NULL,
   CODE VARCHAR(50),
   IS_BRAND VARCHAR(1),
   LAT VARCHAR(3),
   LAST_RELEASED VARCHAR(30),
   SAUI VARCHAR(50),
   VSAB VARCHAR(40),
   RXCUI VARCHAR(8),
   SAB VARCHAR(20),
   TTY VARCHAR(20),
   MERGED_TO_RXCUI VARCHAR(8)
)
;

CREATE TABLE RXNCONSO
(
   RXCUI VARCHAR(8) NOT NULL,
   LAT VARCHAR (3) DEFAULT 'ENG' NOT NULL,
   TS VARCHAR (1),
   LUI VARCHAR(8),
   STT VARCHAR (3),
   SUI VARCHAR (8),
   ISPREF VARCHAR (1),
   RXAUI  VARCHAR(8) NOT NULL,
   SAUI VARCHAR (50),
   SCUI VARCHAR (50),
   SDUI VARCHAR (50),
   SAB VARCHAR (20) NOT NULL,
   TTY VARCHAR (20) NOT NULL,
   CODE VARCHAR (50) NOT NULL,
   STR VARCHAR (3000) NOT NULL,
   SRL VARCHAR (10),
   SUPPRESS VARCHAR (1),
   CVF VARCHAR(50)
)
;

CREATE TABLE RXNREL
(
   RXCUI1    VARCHAR(8) ,
   RXAUI1    VARCHAR(8), 
   STYPE1    VARCHAR(50),
   REL       VARCHAR(4) ,
   RXCUI2    VARCHAR(8) ,
   RXAUI2    VARCHAR(8),
   STYPE2    VARCHAR(50),
   RELA      VARCHAR(100) ,
   RUI       VARCHAR(10),
   SRUI      VARCHAR(50),
   SAB       VARCHAR(20) NOT NULL,
   SL        VARCHAR(1000),
   DIR       VARCHAR(1),
   RG        VARCHAR(10),
   SUPPRESS  VARCHAR(1),
   CVF       VARCHAR(50)
)
;

CREATE TABLE RXNSAB
(
   VCUI VARCHAR (8),
   RCUI VARCHAR (8),
   VSAB VARCHAR (40),
   RSAB VARCHAR (20) NOT NULL,
   SON VARCHAR (3000),
   SF VARCHAR (20),
   SVER VARCHAR (20),
   VSTART VARCHAR (10),
   VEND VARCHAR (10),
   IMETA VARCHAR (10),
   RMETA VARCHAR (10),
   SLC VARCHAR (1000),
   SCC VARCHAR (1000),
   SRL INTEGER,
   TFR INTEGER,
   CFR INTEGER,
   CXTY VARCHAR (50),
   TTYL VARCHAR (300),
   ATNL VARCHAR (1000),
   LAT VARCHAR (3),
   CENC VARCHAR (20),
   CURVER VARCHAR (1),
   SABIN VARCHAR (1),
   SSN VARCHAR (3000),
   SCIT VARCHAR (4000)
)
;

CREATE TABLE RXNSAT
(
   RXCUI VARCHAR(8),
   LUI VARCHAR(8),
   SUI VARCHAR(8),
   RXAUI VARCHAR(9),
   STYPE VARCHAR (50),
   CODE VARCHAR (50),
   ATUI VARCHAR(11),
   SATUI VARCHAR (50),
   ATN VARCHAR (1000) NOT NULL,
   SAB VARCHAR (20) NOT NULL,
   ATV VARCHAR (4000),
   SUPPRESS VARCHAR (1),
   CVF VARCHAR (50)
)
;

CREATE TABLE RXNSTY
(
   RXCUI VARCHAR(8) NOT NULL,
   TUI VARCHAR (4),
   STN VARCHAR (100),
   STY VARCHAR (50),
   ATUI VARCHAR (11),
   CVF VARCHAR (50)
)
;

CREATE TABLE RXNDOC (
    DOCKEY	VARCHAR(50) NOT NULL,
    VALUE	VARCHAR(1000),
    TYPE	VARCHAR(50) NOT NULL,
    EXPL	VARCHAR(1000)
)
;

CREATE TABLE RXNCUICHANGES
(
      RXAUI VARCHAR(8),
      CODE VARCHAR(50),
      SAB  VARCHAR(20),
      TTY  VARCHAR(20),
      STR  VARCHAR(3000),
      OLD_RXCUI VARCHAR(8) NOT NULL,
      NEW_RXCUI VARCHAR(8) NOT NULL
)
;


CREATE TABLE rxncui (
 cui1 VARCHAR(8),
 ver_start VARCHAR(40),
 ver_end   VARCHAR(40),
 cardinality VARCHAR(8),
 cui2        VARCHAR(8)
)
;


create index x_rxnconso_str on rxnconso(str);
create index x_rxnconso_rxcui on rxnconso(rxcui);
create index x_rxnconso_tty on rxnconso(tty);
create index x_rxnconso_code on rxnconso(code);
create index x_rxnsat_rxcui on rxnsat(rxcui);
create index x_rxnsat_atv on rxnsat(atv);
create index x_rxnsat_atn on rxnsat(atn);
create index x_rxnrel_rxcui1 on rxnrel(rxcui1);
create index x_rxnrel_rxcui2 on rxnrel(rxcui2);
create index x_rxnrel_rela on rxnrel(rela);
create index x_rxnatomarchive_rxaui on rxnatomarchive(rxaui);
create index x_rxnatomarchive_rxcui on rxnatomarchive(rxcui);
create index x_rxnatomarchive_merged_to on rxnatomarchive(merged_to_rxcui);

-- These extra indexes are added in addition to those provided by RXNORM to facilitate common queries.
create index rxnsat_sabaui_ix on rxnsat(sab, rxaui);
create index rxnsat_aui_ix on rxnsat(rxaui);
create index rxnconso_sabaui_ix on rxnconso(sab, rxaui);
create index rxnrel_sab_ix on rxnrel(sab);
