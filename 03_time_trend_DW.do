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
if `pc' == 1 global root "C:/Users/XWeng/OneDrive - WBG/MEASURE UHC DATA - Sven Neelsen's files"

* Define path for dofiles
global DO "${root}/STATA/DO/SC/UHC-Time-Trend/UHC-Time-Trend"

* Define path for data sources
global SOURCE "${root}/STATA/DATA/SC/ADePT READY/MICS"

* Define path for INTERMEDIATE
global INTER "${SOURCE}/Time_Series/INTER"

* Define path for output data
global OUT "${SOURCE}/Time_Series/FINAL"

* Define path for external data 
global EXTERNAL "${root}/STATA/DO/SC/UHC-Time-Trend/UHC-Time-Trend/external"

*******************************************
*** Generate Quality Control Indicators ***
*******************************************

*combine both DHS and MICS time-series data. 
use "${OUT}/DHS_Time_Series_QC.dta",replace 
append using  "${OUT}/MICS_Time_Series_QC.dta" 

*rename for consistency 
replace country = "CotedIvoire" if country == "Cote d'Ivoire"
replace country = "SaoTomePrincipe" if country == "Sao Tome and Principe"
replace country = subinstr(country," ","",.)
replace country = "Congodr" if iso2c == "CD" //aligning the naming of Congo,Congodr and Dem. Rep. Congo

*identify abnormal data
destring(value_my value_hefpi),replace
gen gap_hefpi = (value_my-value_hefpi)/value_hefpi*100
replace gap_hefpi = value_my-value_hefpi if value_hefpi>20

gen flag_hefpi = ((gap_hefpi > 10 | gap_hefpi < -10 )& value_hefpi<=20) | ((gap_hefpi>2|gap_hefpi<-2)&value_hefpi>20)
replace flag_hefpi=0 if value_my==. & value_hefpi==.
replace flag_hefpi=2 if value_my!=. & value_hefpi==.
tab varname_my if flag_hefpi == 1
br varname_my value* flag_hefpi if flag_hefpi == 1

*identify missing data points 
gen gap_mis = cond(missing(value_my)& !missing(value_hefpi),1,0)

*reshape to have source of data as column
reshape long value_ ,i(survey country year varname_my) j(source) string
rename value_ value

*housekeeping
replace value = . if value == 0 

rename varname_my varname

split survey,p(-) l(1)
replace survey = survey1
drop survey1

keep binary survey country year varname source iso3c iso2c value region subregion surveyid missing gap_mis gap_hefpi flag_hefpi

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

*generate quality control indicator required by Sven (Don't average the standard deviation, but to identify the outliers -> Difference divide by year -> Maximum annualized point change between the close points between each other -> Show the time-series. )
destring year, replace
sort country varname source year
bysort country varname source: gen growth_rate_my = (value - value[_n-1])/(year - year[_n-1]) if source == "my"

gen temp_gr_abs = abs(growth_rate) //take the absolute value in case there's big negative number
bysort country varname: egen temp_growth_rate = max(temp_gr_abs)

replace growth_rate_my = temp_growth_rate
replace growth_rate_my = . if multi != 1 
drop temp_* 

br country varname source growth_rate_my if multi == 1

*save data in dta and excel (feed to tableau dashboard)
save "${OUT}/Time_Series.dta",replace
export excel "${OUT}/Time_Series.xlsx",firstrow(var) replace
