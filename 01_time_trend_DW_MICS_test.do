//////////////////////////////////////
///// Generate Time Series (MICS)/////
//////////////////////////////////////

/* This file is to calculate the indicators by mircordata
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

* Define path for data sources
global SOURCE "${root}/STATA/DATA/SC/ADePT READY/MICS"

* Define path for INTERMEDIATE
global INTER "${SOURCE}/Time_Series/INTER"

* Define path for output data
global OUT "${SOURCE}/Time_Series/FINAL"

***************************
*** Combine the Microdata**
***************************
//ssc install fs

foreach subfolder in MICS6-Oct2021 MICS3-Oct2021 MICS4-Oct2021 MICS5-Oct2021 MICS2-Oct2021 {
global DATA "${SOURCE}/`subfolder'" //this directory is temporary for monitor use, later to finalize 
cd "${DATA}"
fs  *.dta
local firstfile: word 1 of `r(files)'

***************************
*** Caculate Indicators ***
***************************
foreach survey in `r(files)' {

use "${DATA}/`survey'",clear

***rename the variables for non-DW-coded surveys for consistency 
capture confirm var c_del_eff1 //identify if this is microdata where variable name not changed yet (not coded by DW)
if !_rc{
    rename(c_del_eff1 c_del_eff1_q c_del_eff2 c_del_eff2_q w_unmet c_measles_vacc ind_sampleweight mor_wdob mor_doi hh1 hh2) ///
    (c_sba_eff1 c_sba_eff1_q c_sba_eff2 c_sba_eff2_q w_unmet_fp c_measles w_sampleweight hm_dob hm_doi hv001 hv002)
}

//generating weight info
egen pop_w_sampleweight = wtmean(w_sampleweight), weight(w_sampleweight)

***for variables generated from 1_antenatal_care 2_delivery_care 3_postnatal_care
	foreach var of var c_anc	c_anc_any	c_anc_bp	c_anc_bp_q	c_anc_bs	c_anc_bs_q ///
	c_anc_ear	c_anc_ear_q	c_anc_eff	c_anc_eff_q	c_anc_eff2	c_anc_eff2_q ///
	c_anc_eff3	c_anc_eff3_q	c_anc_ir	c_anc_ir_q	c_anc_ski	c_anc_ski_q ///
	c_anc_tet	c_anc_tet_q	c_anc_ur	c_anc_ur_q	c_caesarean	c_earlybreast ///
	c_facdel	c_hospdel	c_sba	c_sba_eff1	c_sba_eff1_q	c_sba_eff2 ///
	c_sba_eff2_q	c_sba_q	c_skin2skin	c_pnc_any	c_pnc_eff	c_pnc_eff_q c_pnc_eff2	c_pnc_eff2_q {
    egen pop_`var' = wtmean(`var'), weight(w_sampleweight)
    }
	
	***for variables generated from 4_sexual_health
	foreach var of var w_CPR w_unmet_fp	w_need_fp w_metany_fp w_metmod_fp w_metany_fp_q w_condom_conc w_married {
	egen pop_`var' = wtmean(`var'), weight(w_sampleweight)
	}
	
	***for variables generated from 7_child_vaccination
	foreach var of var c_bcg c_dpt1 c_dpt2 c_dpt3 c_fullimm c_measles ///
	c_polio1 c_polio2 c_polio3 c_vaczero {
    egen pop_`var' = wtmean(`var'), weight(c_sampleweight)
    }
	
	***for variables generated from 8_child_illness	
	foreach var of var c_ari* c_diarrhea 	c_diarrhea_hmf	c_diarrhea_medfor	c_diarrhea_mof	c_diarrhea_pro	c_diarrheaact ///
	c_diarrheaact_q	 c_illness* c_illtreat* c_sevdiarrhea	c_sevdiarrheatreat ///
	c_sevdiarrheatreat_q	c_treatAR* c_treatdiarrhea	c_diarrhea_med {
    egen pop_`var' = wtmean(`var'), weight(c_sampleweight)
    }
	
	***for variables generated from 9_child_anthropometrics
	foreach var of var c_underweight c_stunted c_height c_underweight_sev ///
	c_wasted c_wasted_sev c_weight c_hfa c_wfa c_wfh c_stunted_sev {
    egen pop_`var' = wtmean(`var'),weight(c_sampleweight)
    }
	
	***for variables generated from 10_child_mortality
	foreach var of var mor_ade mor_afl mor_ali mor_bord ///
	mor_int mor_male c_magebrt {
    egen pop_`var' = wtmean(`var'), weight(w_sampleweight)
    }
	
	***for variables generated from 11_child_other
	foreach var of var c_mateduc c_ITN{
	egen pop_`var' = wtmean(`var'),weight(hh_sampleweight)
	}


*Please add the sample size for the variables too.

keep pop_* survey country iso3c iso2c year
keep if _n == 1

save "${INTER}/Indicator_`survey'_MICS", replace  

}
}