/*========================================================
  02_tables.sas
  TrialPulse SAS Reporting Pack — Tables
  Outputs:
   - Excel workbook (multi-sheet)
   - PDF report
   - RTF report
========================================================*/

%include "%sysfunc(pathname(HOME))/trialpulse_sas/programs/00_setup.sas";
options obs=max;

/*-----------------------------
  Output file paths
-----------------------------*/
%let RUNDATE=%sysfunc(today(),yymmddn8.);
%let XLSX=&OUTDIR./trialpulse_tables_&RUNDATE..xlsx;
%let PDF =&OUTDIR./trialpulse_tables_&RUNDATE..pdf;
%let RTF =&OUTDIR./trialpulse_tables_&RUNDATE..rtf;

/*-----------------------------
  Helper formats
-----------------------------*/
proc format;
  value $phasef
    "Phase 2"  = "Phase II"
    "Phase 3"  = "Phase III"
    "Phase 2/3"= "Phase II/III"
    "Phase 2+" = "Phase I/II"
    other      = "Other/Unknown";
run;

/*-----------------------------
  Clean tiny noise categories
  - remove blank phase rows
  - remove weird phase like '2019.0'
-----------------------------*/
data work.tr;
  set tp.trials;
  length phase2 $20;
  phase2 = strip(phase);
  phase2 = put(phase2,$phasef.);

  /* keep operationally relevant phases only */
  if phase2 in ("Phase II","Phase III","Phase II/III","Phase I/II");

  /* standardize sponsor_type */
  length sponsor2 $20;
  sponsor2 = strip(sponsor_type);
  if sponsor2 in ("0","1","") then sponsor2="Other/Unknown";

  /* ensure numeric fields exist */
  /* duration_days, enroll_n, discontinued, completed should already exist */
run;

/*-----------------------------
  KPI Overview (Executive)
-----------------------------*/
proc sql;
  create table work.kpi_overview as
  select
    count(*)                                  as trials_n,
    sum(completed)                            as completed_n,
    sum(discontinued)                         as discontinued_n,
    calculated completed_n / calculated trials_n format=percent8.1 as completed_pct,
    calculated discontinued_n / calculated trials_n format=percent8.1 as discontinued_pct,
    median(duration_days)                     as median_duration_days format=comma12.,
    median(enroll_n)                          as median_enrollment format=comma12.,
    sum(multi_country)                        as multicountry_n,
    calculated multicountry_n / calculated trials_n format=percent8.1 as multicountry_pct
  from work.tr;
quit;

/*-----------------------------
  Table 1: Trial Characteristics by Phase
-----------------------------*/
proc sql;
  create table work.tbl_phase as
  select
    phase2                                     as phase label="Phase",
    count(*)                                   as trials_n format=comma12. label="Trials",
    median(duration_days)                      as median_duration format=comma12. label="Median duration (days)",
    median(enroll_n)                           as median_enrollment format=comma12. label="Median enrollment",
    sum(completed)                             as completed_n format=comma12. label="Completed",
    sum(discontinued)                          as discontinued_n format=comma12. label="Discontinued",
    calculated completed_n / calculated trials_n format=percent8.1 label="Completed (%)",
    calculated discontinued_n / calculated trials_n format=percent8.1 label="Discontinued (%)",
    sum(multi_country)                         as multicountry_n format=comma12. label="Multi-country",
    calculated multicountry_n / calculated trials_n format=percent8.1 label="Multi-country (%)"
  from work.tr
  group by phase2
  order by phase2;
quit;

/*-----------------------------
  Table 2: Outcomes by Sponsor Type x Phase
-----------------------------*/
proc sql;
  create table work.tbl_outcomes as
  select
    phase2                                    as phase label="Phase",
    sponsor2                                  as sponsor_type label="Sponsor type",
    count(*)                                  as trials_n format=comma12. label="Trials",
    sum(completed)                            as completed_n format=comma12. label="Completed",
    sum(discontinued)                         as discontinued_n format=comma12. label="Discontinued",
    calculated completed_n / calculated trials_n format=percent8.1 label="Completed (%)",
    calculated discontinued_n / calculated trials_n format=percent8.1 label="Discontinued (%)",
    median(duration_days)                     as median_duration format=comma12. label="Median duration (days)",
    median(enroll_n)                          as median_enrollment format=comma12. label="Median enrollment"
  from work.tr
  group by phase2, sponsor2
  order by phase2, sponsor2;
quit;

/*-----------------------------
  Table 3: Discontinuation Themes (reported)
-----------------------------*/
data work.disc;
  set work.tr;
  where status_group in ("Terminated","Withdrawn");
  length why_theme2 $40;
  why_theme2 = strip(why_theme);
  if missing(why_theme2) then why_theme2 = "Not reported";
run;

proc sql;
  create table work.tbl_themes as
  select
    why_theme2                                as theme label="Theme",
    count(*)                                  as n format=comma12. label="Trials",
    calculated n / (select count(*) from work.disc where theme ne "Not reported") format=percent8.1
                                             as pct label="Share (reported only)"
  from work.disc
  where why_theme2 ne "Not reported"
  group by why_theme2
  order by n desc;
quit;

/*-----------------------------
  Export CSVs as well (for portfolio)
-----------------------------*/
proc export data=work.kpi_overview
  outfile="&OUTDIR./kpi_overview_&RUNDATE..csv"
  dbms=csv replace;
run;

proc export data=work.tbl_phase
  outfile="&OUTDIR./table_phase_&RUNDATE..csv"
  dbms=csv replace;
run;

proc export data=work.tbl_outcomes
  outfile="&OUTDIR./table_outcomes_&RUNDATE..csv"
  dbms=csv replace;
run;

proc export data=work.tbl_themes
  outfile="&OUTDIR./table_discontinuation_themes_&RUNDATE..csv"
  dbms=csv replace;
run;

/*-----------------------------
  ODS Outputs: Excel + PDF + RTF
-----------------------------*/
ods listing close;

/* Excel workbook */
ods excel file="&XLSX." options(embedded_titles="yes" sheet_interval="now");

ods excel options(sheet_name="KPI Overview");
title "TrialPulse — KPI Overview (Phase II–III subset)";
proc print data=work.kpi_overview label noobs; run;

ods excel options(sheet_name="By Phase");
title "TrialPulse — Trial Characteristics by Phase";
proc report data=work.tbl_phase nowd headline headskip;
  columns phase trials_n median_duration median_enrollment completed_n discontinued_n;
  define phase / display;
  define trials_n / display;
  define median_duration / display;
  define median_enrollment / display;
  define completed_n / display;
  define discontinued_n / display;
run;

ods excel options(sheet_name="Outcomes x Sponsor");
title "TrialPulse — Outcomes by Sponsor Type and Phase";
proc report data=work.tbl_outcomes nowd headline headskip;
  columns phase sponsor_type trials_n completed_n discontinued_n median_duration median_enrollment;
  define phase / group;
  define sponsor_type / group;
run;

ods excel options(sheet_name="Discontinuation Themes");
title "TrialPulse — Discontinuation Themes (Reported Only)";
proc report data=work.tbl_themes nowd headline headskip;
  columns theme n pct;
  define theme / display;
  define n / display;
  define pct / display;
run;

ods excel close;

/* PDF report */
ods pdf file="&PDF." style=journal;
title "TrialPulse — Clinical Trial Operations Reporting (Tables)";
proc print data=work.kpi_overview label noobs; run;

title "Trial Characteristics by Phase";
proc report data=work.tbl_phase nowd headline headskip; run;

title "Outcomes by Sponsor Type and Phase";
proc report data=work.tbl_outcomes nowd headline headskip; run;

title "Discontinuation Themes (Reported Only)";
proc report data=work.tbl_themes nowd headline headskip; run;
ods pdf close;

/* RTF report */
ods rtf file="&RTF." style=journal;
title "TrialPulse — Clinical Trial Operations Reporting (Tables)";
proc print data=work.kpi_overview label noobs; run;

title "Trial Characteristics by Phase";
proc report data=work.tbl_phase nowd headline headskip; run;

title "Outcomes by Sponsor Type and Phase";
proc report data=work.tbl_outcomes nowd headline headskip; run;

title "Discontinuation Themes (Reported Only)";
proc report data=work.tbl_themes nowd headline headskip; run;
ods rtf close;

ods listing;

/* Tell you where files are */
%put NOTE: Wrote Excel -> &XLSX.;
%put NOTE: Wrote PDF  -> &PDF.;
%put NOTE: Wrote RTF  -> &RTF.;