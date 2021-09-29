/////////////////////////////////
///// Generate Time Series_3/////
/////////////////////////////////

/*This file is to generate the variables for quality control, for example, standard deviation, identify variables with time-series.
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

*******************************************
*** Generate Quality Control Indicators ***
*******************************************

use "${OUT}/DHS_Time_Series_QC.dta",replace 

*reshape to have source of data as column
reshape long value_ ,i(survey country year varname_my) j(source) string
rename value_ value

*housekeeping
replace value = . if value == 0 

rename varname_my varname

keep binary survey country year varname source iso3c iso2c value region subregion surveyid missing

*generate standard deviation data with benchmarks (considering limited time-series, the sd only applies to survey-variable level comparing difference between source)
egen hefpi_sd = sd(value) if inlist(source,"hefpi","my"),by(surveyid varname)
egen dhs_sd = sd(value) if inlist(source,"dhs","my"),by(surveyid varname)
egen sd_min = rowmin(hefpi_sd dhs_sd)

*identify variables with time-series. (any source)
gen n_missing = (value != .)
bysort country varname source: egen t_n = total(n_missing) //calculate the number data point for each variable by country and source
gen multi = (t_n > 1) 

bysort country varname: egen temp_multi_any = mean(multi)
replace multi = (temp_multi_any > 0) //as long as any source contain more them two time stamps, to identify as multi-time stampes for same variable for other sources as well.

*generate standard deviation data among itselfs
egen my_sd = sd(value) if source == "my",by(country varname) //for each country, calculate the sd along the time. 
bysort country varname: egen temp_sd_my = mean(my_sd)
replace my_sd = temp_sd_my
replace my_sd = . if multi != 1 //only apply to datapoints where multiple time stamp exists. 

drop temp_* 

*save data in dta and excel (feed to tableau dashboard)
save "${OUT}/DHS_Time_Series.dta",replace
export excel "${OUT}/DHS_Time_Series.xlsx",firstrow(var) replace
