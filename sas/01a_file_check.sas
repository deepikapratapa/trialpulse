%include "%sysfunc(pathname(HOME))/trialpulse_sas/programs/00_setup.sas";

/* Confirm file exists */
%put NOTE: FILEEXIST=%sysfunc(fileexist("&IN_CSV.")) ;

/* Assign a fileref (<=8 chars) */
filename incsv "&IN_CSV.";

data _null_;
  length fid 8 infoname $32 infoval $256;
  fid = fopen("incsv","I",1,"B");
  if fid = 0 then do;
    put "ERROR: Could not open file via fileref incsv.";
    stop;
  end;

  infoname="File Size (bytes)"; infoval=finfo(fid,infoname); put infoname= infoval=;
  infoname="Last Modified";      infoval=finfo(fid,infoname); put infoname= infoval=;
  infoname="Filename";           infoval=finfo(fid,infoname); put infoname= infoval=;

  rc = fclose(fid);
run;

filename incsv clear;

/* Preview header + first 3 data rows */
data _null_;
  infile "&IN_CSV." lrecl=32767 obs=4 truncover;
  input;
  put _infile_;
run;



proc contents data=tp.trials_raw; run;

proc print data=tp.trials_raw(obs=5); run;

proc means data=tp.trials_raw n nmiss; run;