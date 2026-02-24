%include "%sysfunc(pathname(HOME))/trialpulse_sas/programs/00_setup.sas";

/* Check OBS setting */
proc options option=obs; run;

/* Reset it (critical) */
options obs=max;
proc options option=obs; run;

/* Rebuild TP.TRIALS safely (no filtering) */
proc datasets lib=tp nolist;
  delete trials;
quit;

data tp.trials;
  set tp.trials_raw;
run;

proc sql;
  select count(*) as n_rows from tp.trials;
quit;