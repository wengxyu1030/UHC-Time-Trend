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
***** Prepare the Region Data *****
***********************************

import delimited using "${OUT}/iso3c_region.csv", varnames(1) clear
rename alpha3 iso3c
keep iso3c region subregion
save "${OUT}/iso3c_region.dta",replace 

//source: https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/blob/master/all/all.csv


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

replace iso3c = "SWZ" if country == "Eswatini" //add the missing iso code in the microdata. 

merge m:1 iso3c using "${OUT}/iso3c_region.dta"

tab country if _merge == 1 //please check if there's not-matched country
drop _merge

gen missing = (pop == .)

save "${OUT}/DHS_Time_Series.dta",replace
export excel "${OUT}/DHS_Time_Series.xlsx",firstrow(var) replace

***********************************
****** Generate the figures *******
***********************************