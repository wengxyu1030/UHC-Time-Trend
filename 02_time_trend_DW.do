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
if "`c(username)'" == "sunyining" local pc = 0
if "`c(username)'" == "xweng"     local pc = 1
if `pc' == 0 global root "/Users/sunyining/OneDrive/MEASURE UHC DATA"
if `pc' == 1 global root "C:/Users/XWeng/WBG/Sven Neelsen - World Bank/MEASURE UHC DATA"

* Define path for data sources
global SOURCE "${root}/STATA/DATA/SC"

* Define path for INTERMEDIATE
global INTER "${SOURCE}/Time_Series/INTER"

* Define path for output data
global OUT "${SOURCE}/Time_Series/FINAL"

***********************************
*** Combine the indicator result **
***********************************
//ssc install fs

cd "${INTER}"	
fs  *.dta
local firstfile: word 1 of `r(files)'
use `firstfile', clear
foreach f in `r(files)' {
 if "`f'" ~= "`firstfile'" append using `f'
}

reshape long pop_,i(survey country iso3c year) j(varname) string
rename pop_ pop

save "${OUT}/DHS_Time_Series.dta",replace
