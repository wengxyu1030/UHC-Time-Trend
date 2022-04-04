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

*identify abnormal data (the thresholds to be decided)
destring(value_my value_hefpi),replace
gen gap_hefpi = (value_my-value_hefpi)/value_hefpi*100
replace gap_hefpi = value_my-value_hefpi if value_hefpi>20

/*
//previous discussion on flagged data points
gen flag_hefpi = ((gap_hefpi > 10 | gap_hefpi < -10 )& value_hefpi<=20) | ((gap_hefpi>2|gap_hefpi<-2)&value_hefpi>20) //the previous definition of flaged datapoints. 
*/

*identify abnormal data (updated threshold per discussion with WB team)
gen flag_hefpi = 0 
replace flag_hefpi = 1 if ((gap_hefpi >20 | gap_hefpi < -20 )& value_hefpi<=5)
replace flag_hefpi = 1 if ((gap_hefpi >15 | gap_hefpi < -15 )& inrange(value_hefpi,5,10))
replace flag_hefpi = 1 if ((gap_hefpi >12 | gap_hefpi < -12 )& inrange(value_hefpi,10,20))
replace flag_hefpi = 1 if ((gap_hefpi >10 | gap_hefpi < -10 )& inrange(value_hefpi,20,40))
replace flag_hefpi = 1 if ((gap_hefpi >8 | gap_hefpi < -8 )& inrange(value_hefpi,40,50))
replace flag_hefpi = 1 if ((gap_hefpi >7 | gap_hefpi < -7 )& inrange(value_hefpi,50,60))
replace flag_hefpi = 1 if ((gap_hefpi >6 | gap_hefpi < -6 )& inrange(value_hefpi,60,70))
replace flag_hefpi = 1 if ((gap_hefpi >5 | gap_hefpi < -5 )& inrange(value_hefpi,70,80))
replace flag_hefpi = 1 if ((gap_hefpi >4 | gap_hefpi < -4 )& inrange(value_hefpi,80,100))

//codify the falg status
replace flag_hefpi=1 if value_my==. & value_hefpi!=. //if there's benchmark available while the value is not coded in the template
replace flag_hefpi=0 if value_my==. & value_hefpi==. //if both of the value and the benchmarks are missing
replace flag_hefpi=0 if value_my!=. & value_hefpi==. //if the value is not missing while the benchmarks are missing. 
tab varname_my if flag_hefpi == 1

*reshape to have source of data as column
reshape long value_ ,i(survey country year varname_my) j(source) string
rename value_ value

*housekeeping
replace value = . if value == 0 

rename varname_my varname

split survey,p(-) l(1)
replace survey = survey1
drop survey1

keep binary survey country year varname source iso3c iso2c value region subregion surveyid missing gap_hefpi flag_hefpi
drop if value == . 

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
bysort country varname source: gen my_gr = (value - value[_n-1]) /(year- year[_n-1]) if source == "my"

gen temp_gr_abs = abs(my_gr) //take the absolute value in case there's big negative number
bysort country varname: egen temp_growth_rate = max(temp_gr_abs)

replace my_gr = temp_growth_rate
replace my_gr = . if multi != 1 
drop temp_* 


//br country varname source my_gr if multi == 1

*find the outlier for the growth rate and standard deviation when it's time series
foreach var in my_gr my_sd {
	//find the IQR and define the outliers
    egen iqr_`var' = iqr(`var') if source == "my",by(varname)
	egen qrt_`var' = pctile(`var') if source == "my",p(75) by(varname)  //3rd quartile
	
	local r = 1 //name using category as varname don't support dots (0.5 is not allowed)
	forval i = 0.5(0.5)2 {
		gen iqr_`var'_`r' = qrt_`var'  + `i'*iqr_`var' if source == "my" 
		gen outlier_`var'_`r' = (`var' > iqr_`var'_`r') if source == "my" & !mi(`var')
		label var outlier_`var'_`r'  "Outlier: 3Q + `i'IQR"
		local r = `r' +1
		display `r'
	}
	drop iqr*
}


foreach var of varlist outlier* {
	//apply the same value to all the country-indicator level for different benchmark source (easier to filter and compare)
	bysort country varname: egen temp_`var' = max(`var')
	replace `var' = temp_`var'
	drop temp*
	replace `var' = . if multi != 1
}

br country varname my_gr my_sd source outlier*

*specify the quality checking scope:
gen varname_focus = 0
replace varname_focus = 1 if inlist(varname,"c_anc","c_anc_any","c_anc_ear","c_anc_eff","c_facdel","c_hospdel","c_sba","c_sba_q","c_pnc_any")
replace varname_focus = 1 if inlist(varname,"w_CPR","w_unmet_fp","w_metmod_fp","w_condom_conc","c_fullimm","c_measles","c_treatARI","c_treatdiarrhea","c_underweight")
replace varname_focus = 1 if inlist(varname,"c_stunted","c_wasted",	"c_ITN","a_hiv","c_vaczero","c_fevertreat","c_diarrhea_pro")


*save data in dta and excel (feed to tableau dashboard)
save "${OUT}/Time_Series.dta",replace
export excel "${OUT}/Time_Series.xlsx",firstrow(var) replace
