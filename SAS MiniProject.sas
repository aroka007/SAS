* SAS MiniProject #1;

*1 - Read in files;
proc import datafile="C:\Users\mposner\OneDrive - Villanova University\Teaching\Statistical Programming\2019 Fall - Statistical Programming\SAS\Median Income by Zip Code in US.xlsx"
dbms=xlsx replace out=income;
getnames=yes;
run;


proc import datafile="C:\Users\mposner\OneDrive - Villanova University\Teaching\Statistical Programming\2019 Fall - Statistical Programming\SAS\PA College Graduation by Zip Code.xlsx"
dbms=xlsx replace out=grad;
getnames=yes;
run;

*2&3 - Merge files together;
data grad;
  set grad;
  rename __college_grad_ = CollGrad zip_code=zip;
run;

proc contents data=income;
proc contents data=grad;
run;

proc sort data=income; by zip;
proc sort data=grad; by zip;
data match noinc nograd;
  merge income (in=a) grad (in=b); by zip;
  if a and b then output match;
  else if a then output nograd;
  else output noinc;

proc contents data=match;
proc contents data=noinc;
proc contents data=nograd;
run;


proc print data=noinc (obs=20);
proc print data=nograd (obs=20);
run;


*4a - Quartiles of Coll Grad;
proc univariate data=match;
  var CollGrad;
run;

*4b - CollGradGroup;
proc format;
  value collgradf 1='low' 2='med-low' 3='med-high' 4='high';
data match;
  set match;
  if collgrad > 0.19150 then CollGradGrp = 4;
  else if collgrad > 0.12375 then CollGradGrp = 3;
  else if collgrad > 0.084 then CollGradGrp = 2;
  else if collgrad > . then CollGradGrp = 1;
  label CollGradGrp="College Graduation Group";
  format CollGradGrp collgradf.;

proc contents data=match;
run;

*4c - Median Income Graph;
proc univariate data=match noprint;
  histogram median;
run;

*4d - mean of median by CollGradGrp;
proc means data=match mean;
  var median pop;
  class collgradgrp;
  output out=myout;
proc print data=myout;
  where _type_=1 and _stat_='MEAN';
run;
