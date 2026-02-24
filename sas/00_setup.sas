/*========================================================
  TrialPulse SAS Reporting Pack (OnDemand)
  00_setup.sas
========================================================*/

options nodate nonumber;
options validvarname=v7;

/* Root folder in SAS OnDemand (your Home folder) */
%let ROOT=%sysfunc(pathname(HOME))/trialpulse_sas;

/* Input CSV uploaded to HOME/trialpulse_sas */
%let IN_CSV=&ROOT./trialpulse_analysis.csv;

/* Output directories under HOME/trialpulse_sas */
%let OUTDIR=&ROOT./output;
%let QCDIR=&ROOT./qc;

/* Library for project datasets */
libname tp "&ROOT.";

/* Ensure output folders exist */
options dlcreatedir;
libname out "&OUTDIR.";
libname qc "&QCDIR.";
libname out clear;
libname qc clear;
options nodlcreatedir;

/* Log checks */
%put NOTE: ROOT=&ROOT.;
%put NOTE: IN_CSV=&IN_CSV.;
%put NOTE: OUTDIR=&OUTDIR.;
%put NOTE: QCDIR=&QCDIR.;