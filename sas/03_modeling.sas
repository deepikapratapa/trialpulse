/*========================================================
  03_modeling.sas
  Advanced Clinical Analytics — Discontinuation Risk Model
========================================================*/

%include "%sysfunc(pathname(HOME))/trialpulse_sas/programs/00_setup.sas";
options obs=max;

/*---------------------------------------
  Prepare modeling dataset
---------------------------------------*/
data work.model;
  set tp.trials;

  /* Keep meaningful phases only */
  length phase2 $20 sponsor2 $20;
  phase2 = strip(phase);
  sponsor2 = strip(sponsor_type);

  if phase2 in ("Phase 2","Phase 3","Phase 2/3","Phase 2+");

  /* Recode sponsor */
  if sponsor2 in ("0","1","") then sponsor2="Other/Unknown";

  /* Ensure numeric conversions */
  enroll_n = input(strip(enrollment_count), best12.);
  dur_comp = input(strip(duration_start_to_completion_day), best12.);
  dur_prim = input(strip(duration_start_to_primary_days), best12.);
  duration_days = coalesce(dur_comp, dur_prim);

  start_year_n = input(strip(start_year), best12.);

  discontinued_flag = (status_group in ("Terminated","Withdrawn"));

  /* Remove missing key predictors */
  if missing(enroll_n) then delete;
run;

/*---------------------------------------
  Logistic Regression
---------------------------------------*/
ods output
  ParameterEstimates = work.logit_params
  OddsRatios         = work.logit_or
  FitStatistics      = work.logit_fit
  Association        = work.logit_assoc;

proc logistic data=work.model descending;
  class phase2 sponsor2 / param=ref ref=first;

  model discontinued_flag =
        phase2
        sponsor2
        multi_country
        enroll_n
        start_year_n
        / clodds=wald;

  units enroll_n=50 start_year_n=1;
  roc;
run;

/*---------------------------------------
  Clean Odds Ratio Table
---------------------------------------*/
data work.or_table;
  set work.logit_or;

  length predictor $100;

  predictor = catx(" ", Effect, Level);

  keep predictor OddsRatioEst LowerCL UpperCL;
run;

/*---------------------------------------
  Export Modeling Results
---------------------------------------*/
%let RUNDATE=%sysfunc(today(),yymmddn8.);

proc export data=work.or_table
  outfile="&OUTDIR./model_odds_ratios_&RUNDATE..csv"
  dbms=csv replace;
run;

proc export data=work.logit_fit
  outfile="&OUTDIR./model_fit_stats_&RUNDATE..csv"
  dbms=csv replace;
run;

/*---------------------------------------
  PDF Modeling Report
---------------------------------------*/
ods pdf file="&OUTDIR./modeling_report_&RUNDATE..pdf" style=journal;

title "TrialPulse — Discontinuation Risk Model";
proc print data=work.or_table label noobs; run;

title "Model Fit Statistics";
proc print data=work.logit_fit noobs; run;

title "ROC Association Statistics";
proc print data=work.logit_assoc noobs; run;

ods pdf close;

/*---------------------------------------
  Log location
---------------------------------------*/
%put NOTE: Modeling outputs written to &OUTDIR.;