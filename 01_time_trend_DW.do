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
if `pc' == 1 global root "C:/Users/XWeng/OneDrive - WBG/MEASURE UHC DATA"

* Define path for data sources
global SOURCE "${root}/STATA/DATA/SC"

* Define path for INTERMEDIATE
global INTER "${SOURCE}/Time_Series/INTER"

* Define path for output data
global OUT "${SOURCE}/Time_Series/FINAL"

***************************
*** Combine the Microdata**
***************************
//ssc install fs
global DATA "${SOURCE}/FINAL/Time_series_working" //this directory is temporary for monitor use, later to finalize
cd "${DATA}"
fs  *.dta
local firstfile: word 1 of `r(files)'

***************************
*** Caculate Indicators ***
***************************
foreach survey in `r(files)' {

use "${DATA}/`survey'",clear

    ***for variables generated from 1_antenatal_care 2_delivery_care 3_postnatal_care
	foreach var of var c_anc	c_anc_any	c_anc_bp	c_anc_bp_q	c_anc_bs	c_anc_bs_q ///
	c_anc_ear	c_anc_ear_q	c_anc_eff	c_anc_eff_q	c_anc_eff2	c_anc_eff2_q ///
	c_anc_eff3	c_anc_eff3_q	c_anc_ir	c_anc_ir_q	c_anc_ski	c_anc_ski_q ///
	c_anc_tet	c_anc_tet_q	c_anc_ur	c_anc_ur_q	c_caesarean	c_earlybreast ///
	c_facdel	c_hospdel	c_sba	c_sba_eff1	c_sba_eff1_q	c_sba_eff2 ///
	c_sba_eff2_q	c_sba_q	c_skin2skin	c_pnc_any	c_pnc_eff	c_pnc_eff_q c_pnc_eff2	c_pnc_eff2_q {
    egen pop_`var' = wtmean(`var'), weight(w_sampleweight)
    }
	
	***for variables generated from 4_sexual_health 5_woman_anthropometrics
	foreach var of var w_CPR w_unmet_fp	w_need_fp w_metany_fp	w_metmod_fp w_metany_fp_q  w_bmi_1549 w_height_1549 w_obese_1549 w_overweight_1549 {
	egen pop_`var' = wtmean(`var'), weight(w_sampleweight)
	}
	
	***for variables generated from 7_child_vaccination
	foreach var of var c_bcg c_dpt1 c_dpt2 c_dpt3 c_fullimm c_measles ///
	c_polio1 c_polio2 c_polio3{
    egen pop_`var' = wtmean(`var'), weight(w_sampleweight)
    }
	
	***for variables generated from 8_child_illness	
	foreach var of var c_ari* c_diarrhea 	c_diarrhea_hmf	c_diarrhea_medfor	c_diarrhea_mof	c_diarrhea_pro	c_diarrheaact ///
	c_diarrheaact_q	c_fever	c_fevertreat c_illness* c_illtreat* c_sevdiarrhea	c_sevdiarrheatreat ///
	c_sevdiarrheatreat_q	c_treatAR* c_treatdiarrhea	c_diarrhea_med {
    egen pop_`var' = wtmean(`var'), weight(w_sampleweight)
    }
	
	***for variables generated from 9_child_anthropometrics
	foreach var of var c_underweight c_stunted	hc70 hc71 ant_sampleweight{
    egen pop_`var' = wtmean(`var'),weight(ant_sampleweight)
    }
	
	***for variables generated from 10_child_mortality
	foreach var of var mor_ali {
    egen pop_`var' = wtmean(`var'), weight(w_sampleweight)
    }
	
	***for variables generated from 11_child_other
	foreach var of var w_mateduc c_ITN{
	egen pop_`var' = wtmean(`var'),weight(hh_sampleweight)
	}
	
	***for hiv indicators from 12_hiv
    foreach var of var a_hiv {
    egen pop_`var' = wtmean(`var'),weight(a_hiv_sampleweight)
    }
              
	***for adult indicators from 13_adult
    foreach var of var a_diab_treat  a_inpatient_1y a_bp_treat a_bp_sys a_bp_dial a_hi_bp140_or_on_med a_bp_meas {
	egen pop_`var' = wtmean(`var'),weight(hh_sampleweight)
	}
	
	***for hm related indicators 
	foreach var of var hm_live hm_male hm_age_yrs hm_age_mon hm_headrel hm_stay {
	egen pop_`var' = wtmean(`var'),weight(w_sampleweight)    
	}


*Please add the sample size for the variables too.

keep pop_* survey country iso3c iso2c year
keep if _n == 1

save "${INTER}/Indicator_`survey'", replace  

}