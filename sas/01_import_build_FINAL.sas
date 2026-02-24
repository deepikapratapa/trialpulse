%include "%sysfunc(pathname(HOME))/trialpulse_sas/programs/00_setup.sas";

/* Always reset OBS in case it was changed earlier */
options obs=max;

/* (Re)import using PROC IMPORT (works with quotes/commas in titles) */
proc import datafile="&IN_CSV."
  out=tp.trials_raw
  dbms=csv
  replace;
  guessingrows=max;
run;

/* Confirm import count */
proc sql;
  select count(*) as n_raw from tp.trials_raw;
quit;

/* Build analysis-ready SAS dataset */
data tp.trials;
  set tp.trials_raw;

  length enroll_bucket $20;

  /* Convert numeric-like character fields safely */
  enroll_n = input(strip(enrollment_count), best12.);
  dur_comp = input(strip(duration_start_to_completion_day), best12.);
  dur_prim = input(strip(duration_start_to_primary_days), best12.);

  /* Duration preference */
  duration_days = dur_comp;
  if missing(duration_days) then duration_days = dur_prim;

  /* Flags */
  discontinued = (status_group in ("Terminated","Withdrawn"));
  completed    = (status_group = "Completed");
  multi_country = (n_countries >= 2);

  /* Enrollment bucket */
  if missing(enroll_n) then enroll_bucket = "Missing";
  else if enroll_n < 50 then enroll_bucket = "<50";
  else if enroll_n < 100 then enroll_bucket = "50-99";
  else if enroll_n < 250 then enroll_bucket = "100-249";
  else if enroll_n < 500 then enroll_bucket = "250-499";
  else enroll_bucket = "500+";
run;

/* Final checks */
title "TP.TRIALS row count";
proc sql;
  select count(*) as n_rows from tp.trials;
quit;

title "Phase distribution";
proc freq data=tp.trials;
  tables phase status_group sponsor_type / missing;
run;

title;