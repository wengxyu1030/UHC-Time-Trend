//////////////////////////////////
///// Generate Time Series_2 /////
/////////////////////////////////

/* This file is to collapse the survey-level indicators data to a final time series dataset. 
*/

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
if `pc' == 1 global root "C:/Users/XWeng/OneDrive - WBG/MEASURE UHC DATA"

* Define path for data sources
global SOURCE "${root}/STATA/DATA/SC"

* Define path for INTERMEDIATE
global INTER "${SOURCE}/Time_Series/INTER"

* Define path for output data
global OUT "${SOURCE}/Time_Series/FINAL"

* Define path for external data
global EXTERNAL "${root}/STATA/DO/SC/UHC-Time-Trend/external"

***********************************
***** Prepare the Region Data *****
***********************************

import delimited using "${EXTERNAL}/iso3c_region.csv", varnames(1) clear
rename alpha3 iso3c
keep iso3c region subregion
save "${EXTERNAL}/iso3c_region.dta",replace 

//source: https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/blob/master/all/all.csv


***********************************
*** Combine the indicator result **
***********************************
//ssc install fs

*consolidate the microdata produced indicators
cd "${INTER}"	
fs  *.dta
local firstfile: word 1 of `r(files)'
use `firstfile', clear
foreach f in `r(files)' {
 if "`f'" ~= "`firstfile'" append using `f'
}

reshape long pop_,i(survey country iso3c iso2c year) j(varname) string
rename pop_ pop

gen missing = (pop == .)

*identify the regions
replace iso2c = "CG"  if country == "Congorep" //there's issue on the iso2c for congorep and congo. 
replace iso3c = "COG"  if country == "Congorep"
replace iso2c = "CD"  if country == "Congo" //there's issue on the iso2c for congorep and congo. 
replace iso3c = "COD"  if country == "Congo"

replace iso3c = "SWZ" if country == "Eswatini" //add the missing iso code in the microdata. 
replace iso2c = "SZ" if country == "Eswatini" //add the missing iso code in the microdata. 

merge m:1 iso3c using "${EXTERNAL}/iso3c_region.dta"

tab country if _merge == 1 //please check if there's not-matched country
drop _merge

//HAVE THE COLUMN SEPARATE MISSING AS MISSING_URBAN MISSING_RURAL (need rural/urban level information)
gen surveyid = iso2c+year+"DHS"

tab country if mi(iso2c)
tab country if mi(iso3c)

*add the official DHS data and the HEFPI data (note only several indicators are overlapped)
rename pop value_my
rename varname varname_my
gen ispreferred = "1"
drop if survey == ""

merge 1:1 surveyid varname_my ispreferred using "${EXTERNAL}/DHS.dta"  //
drop _merge

drop if ispreferred  != "1"

merge 1:1 surveyid varname_my using "${EXTERNAL}/HEFPI_DHS"
drop _merge

destring(value_dhs),replace
drop if survey == ""

*identify the binary variables and change unit to %
egen temp_max = max(value_my), by(varname_my)
tab varname_my if temp_max <= 1
gen binary = (temp_max <= 1)

replace value_my = value_my*100 if binary == 1

drop temp_*

*for some variable adjust the unit to keep consistency
replace value_hefpi = value_hefpi/100 if inlist(varname_my,"w_height_1549","w_bmi_1549","a_bp_sys","a_bp_dial")

*save the intermediate output for quality checking use. 
keep varname* binary survey country year iso* value_* region subregion surveyid missing
save "${OUT}/DHS_Time_Series_QC.dta",replace 


***********************************
****** Generate the figures *******
***********************************