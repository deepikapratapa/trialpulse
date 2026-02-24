%include "%sysfunc(pathname(HOME))/trialpulse_sas/programs/00_setup.sas";

/* Import CSV */
proc import datafile="&IN_CSV."
  out=tp.trials_raw
  dbms=csv
  replace;
  getnames=yes;
  datarow=2;
  guessingrows=max;
run;

/* Confirm imported rows */
proc sql;
  select count(*) as n_raw from tp.trials_raw;
quit;

/* If n_raw=0, stop here */
%macro stop_if_empty;
  %local n;
  proc sql noprint;
    select count(*) into :n trimmed from tp.trials_raw;
  quit;

  %if &n = 0 %then %do;
    %put ERROR: PROC IMPORT produced 0 rows. Import failed.;
    %abort cancel;
  %end;
%mend;
%stop_if_empty;

/* Derive reporting variables */
data tp.trials;
  set tp.trials_raw;

  length phase_std $10 sponsor_type_std $20 status_group_std $20;

  phase_std = strip(phase);
  if missing(phase_std) then phase_std = "Unknown";

  sponsor_type_std = strip(sponsor_type);
  if missing(sponsor_type_std) then sponsor_type_std = "Unknown";

  status_group_std = strip(status_group);
  if missing(status_group_std) then status_group_std = "Unknown";

  discontinued = (status_group_std in ("Terminated","Withdrawn"));
  completed    = (status_group_std = "Completed");

  duration_days = duration_start_to_completion_days;
  if missing(duration_days) then duration_days = duration_start_to_primary_days;

  enroll_n = enrollment_count;

  multi_country = (n_countries >= 2);
  if missing(n_countries) then multi_country = .;

  length enroll_bucket $20;
  if missing(enroll_n) then enroll_bucket = "Missing";
  else if enroll_n < 50 then enroll_bucket = "<50";
  else if enroll_n < 100 then enroll_bucket = "50-99";
  else if enroll_n < 250 then enroll_bucket = "100-249";
  else if enroll_n < 500 then enroll_bucket = "250-499";
  else enroll_bucket = "500+";
run;

/* Row count + quick distributions */
title "TP.TRIALS row count";
proc sql;
  select count(*) as n_rows from tp.trials;
quit;

title "Phase distribution";
proc freq data=tp.trials;
  tables phase_std / missing;
run;

title;