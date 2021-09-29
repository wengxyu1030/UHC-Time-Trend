
///////////////////////////////////////
///// Identify Missing Datapoints /////
///////////////////////////////////////

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

* Define root 
global root "C:/Users/wu_jn/OneDrive/MEASURE UHC DATA/QCR"

* Define path for data sources
global SOURCE "${root}/SC"

* Define path for INTERMEDIATE
global INTER "${root}/INTER"

* Define path for output data
global OUT "${root}/FINAL"


*******************************
*** Keep missing datapoints ***
*******************************

use "${SOURCE}/quality_control.dta", clear
keep if value_my == . & (value_dhs != . | value_hefpi != .) //identify the missing datapoints that exist in DHS or HEFPI public data (variable value_dhs value_hefpi) but not in the DW team generated indicator (variable value_my)

save "${INTER}/missing_datapoints.dta"

***************************
*** Match characteristics**
***************************

use "${SOURCE}/DHS_Time_Series.dta", clear
keep surveyid country year surveytype
duplicates drop
save "${INTER}/survey_characteristics.dta",replace

use "${INTER}/missing_datapoints.dta",clear
merge m:m surveyid using "${INTER}/survey_characteristics.dta",update
keep if _merge==1 | _merge==3
drop _merge

replace country = "Liberia" if surveyid == "LB2016MIS"
replace year = "2016" if surveyid == "LB2016MIS"
replace surveytype = "MIS" if surveyid == "LB2016MIS"
replace surveytype = "DHS" if surveyid == "CO2015DHS"
replace surveytype = "DHS" if surveyid == "DO2007DHS"
//manually add characteristics

save "${OUT}/quality_control_missing.dta"





