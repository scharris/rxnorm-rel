DROP TABLE RXNATOMARCHIVE;
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

DROP  TABLE RXNCONSO;
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

DROP TABLE RXNREL;
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

DROP TABLE RXNSAB;
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

DROP TABLE RXNSAT;
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

DROP TABLE RXNSTY;
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

DROP TABLE RXNDOC;
CREATE TABLE RXNDOC (
    DOCKEY	VARCHAR(50) NOT NULL,
    VALUE	VARCHAR(1000),
    TYPE	VARCHAR(50) NOT NULL,
    EXPL	VARCHAR(1000)
)
;

DROP  TABLE RXNCUICHANGES;
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

DROP TABLE rxncui;
 
 CREATE TABLE rxncui (
 cui1 VARCHAR(8),
 ver_start VARCHAR(40),
 ver_end   VARCHAR(40),
 cardinality VARCHAR(8),
 cui2        VARCHAR(8)
)
;

 
