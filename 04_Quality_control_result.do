////////////////////////////////
///// Generate Time Series /////
////////////////////////////////

version 14.0
clear all
set matsize 3956, permanent
set more off, permanent
set maxvar 32767, permanent
capture log close
sca drop _all
matrix drop _all
macro drop _all

******************************
*** Define main root paths ***
******************************

//NOTE FOR WINDOWS USERS : use "/" instead of "\" in your paths

* Define root depend on the stata user. 
if "`c(username)'" == "xweng"     local pc = 1
if `pc' == 1 global root "C:/Users/XWeng/OneDrive - WBG/MEASURE UHC DATA - Sven Neelsen's files"

* Define path for data sources
global SOURCE "${root}/STATA/DATA/SC/ADePT READY/MICS"

* Define path for INTERMEDIATE
global INTER "${SOURCE}/INTER"

* Define path for output data
global OUT "${SOURCE}/Time_Series/FINAL"

*****************************************
*** Combine the quality control result **
*****************************************
//ssc install fs

cd "${INTER}"	
fs  quality_control*.dta
local firstfile: word 1 of `r(files)'
use `firstfile', clear
foreach f in `r(files)' {
 if "`f'" ~= "`firstfile'" append using `f'
}

//keep if flag_dhs == 1| flag_hefpi == 1
//br if flag_dhs == 1

*for some variable adjust the unit to keep consistency
replace flag_hefpi = 0 if inlist(varname_my,"w_height_1549","w_bmi_1549","a_bp_sys","a_bp_dial") & flag_dhs == 0
//drop if flag_hefpi == 0 & flag_dhs == 0

*save data in dta.
save "${OUT}/quality_control.dta",replace