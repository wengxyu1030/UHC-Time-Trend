*$newMICS2countries $newMICS3countries 
global newMICScountries   $newMICS4countries $newMICS5countries $newMICS6countries

foreach c in $newMICScountries {

	* open micro-dataset
		clear
		cap use "${OUT}/ADePT READY/MICS/New/MICS2-`c'Adept.dta", clear
		cap use "${OUT}/ADePT READY/MICS/New/MICS3-`c'Adept.dta", clear
		cap use "${OUT}/ADePT READY/MICS/New/MICS4-`c'Adept.dta", clear
		cap use "${OUT}/ADePT READY/MICS/New/MICS5-`c'Adept.dta", clear
		cap use "${OUT}/ADePT READY/MICS/New/MICS6-`c'Adept.dta", clear
		
	* Create empty variables for outcomes which are missing from specific survey
		foreach y in $newMICSvars {
			cap gen `y' = . 
		}

	* Create empty meso-outcome variables
		foreach y in $newMICSvars {
			ge pop`y' = . 
			ge CI`y' = . 
			ge stderror_CI`y' = . 
			ge N`y' = . 
			ge urb`y' = .
			gen rur`y'=.
			ge Nurb`y' = .
			gen Nrur`y'=.
			gen med1`y' = .
			gen med2`y' = .
			gen med3`y' = .
			gen Nmed1`y' = .
			gen Nmed2`y' = .
			gen Nmed3`y' = .
		}

		forval j=1/5 {
			foreach y in $newMICSvars {
				ge Q`j'`y' = . 
				ge N`j'`y' = .
			}
		}
		gen gl_adm1_lab = hh_region_lab
		*tabulate gl_adm1_code
		tabulate hh_region_num
		local numreg = r(r)
		forval j=1/`numreg' {
			foreach y in $newMICSvars {
				gen Rp`j'`y' = .
				gen Rn`j'`y' = .
				gen Rc`j'`y' = .
				gen Rl`j'`y' = ""
			}
		}
	* line is needed for countries without regional var
		foreach y in $newMICSvars {
			cap gen Rp1`y' = .
			cap gen Rn1`y' = .
			cap gen Rc1`y' = .
			cap gen Rl1`y' = ""
		}

	* Populate population mean and N variables as well as region-specific ones
				foreach y in $newMICSvars {
					sum `y' [aw=ind_sampleweight], de
					if r(N)~=0 & r(mean)~=0 {
						sum `y' [aw=ind_sampleweight] , de 
						replace N`y' = r(N)  
						replace pop`y' = r(mean)
						sum `y' if c_mateduc == 1 [aw=ind_sampleweight]
						replace med1`y' = r(mean)
						replace Nmed1`y' = r(N) 
						sum `y' if c_mateduc == 2 [aw=ind_sampleweight]
						replace med2`y' = r(mean)
						replace Nmed2`y' = r(N) 
						sum `y' if c_mateduc == 3 [aw=ind_sampleweight]
						replace med3`y' = r(mean)
						replace Nmed3`y' = r(N) 
						sum `y' if hh_urban == 1 [aw=ind_sampleweight]
						replace urb`y' = r(mean)
						replace Nurb`y' = r(N) 
						sum `y' if hh_urban == 0 [aw=ind_sampleweight]
						replace rur`y' = r(mean)
						replace Nrur`y' = r(N) 
						/*
						tabulate gl_adm1_code
						local numreg = r(r)
						levelsof gl_adm1_code, local(levels)
						local j = 1
						foreach l of local levels {
						if `l'!=-9 {
								levelsof gl_adm1_lab if gl_adm1_c == `l', local(name)
								sum `y' [aw=ind_sampleweight] if gl_adm1_code == `l', de
								replace Rp`j'`y' = r(mean) if Rp`j'`y' == .
								replace Rn`j'`y' = r(N) if Rn`j'`y' == . 
								replace Rc`j'`y' = `l' if Rc`j'`y' == . 
								replace Rl`j'`y' =  `name'  
								local ++j
							}
						}
						*/
						tabulate hh_region_num
						local numreg = r(r)
						replace hh_region_num =-9 if hh_region_num == .
						levelsof hh_region_num, local(levels)
						local j = 1
						foreach l of local levels {
						if `l'!=-9 {
								levelsof hh_region_lab if hh_region_num == `l', local(name)
								sum `y' [aw=ind_sampleweight] if hh_region_num == `l', de
								replace Rp`j'`y' = r(mean) if Rp`j'`y' == .
								replace Rn`j'`y' = r(N) if Rn`j'`y' == . 
								replace Rc`j'`y' = `l' if Rc`j'`y' == . 
								replace Rl`j'`y' =  `name'  
								local ++j
							}
						}
						sum `y' if hh_wealthscore!=. [aw=ind_sampleweight] , de
						if r(N)>1 & r(mean)~=0 {
							conindex `y' [aw=ind_sampleweight], rankvar(hh_wealthscore) robust truezero/* CI HHs ranked by pc income  */ 
							replace CI`y' = r(CI)
							replace stderror_CI`y' = r(CIse) 
							tabstat `y' [aw=ind_sampleweight], stat(mean n) by(hh_wealth_quintile) save 
							forval j=1/5 {
								matrix a = r(Stat`j') 
								replace Q`j'`y' = a[1,1]
								replace N`j'`y' = a[2,1]
							}
						}
					}
				}

	* Keep first observation and meso variablwsa
		ge id=_n
		keep if id==1 
		keep country survey iso* year N* pop* Q* CI* stderror_CI* R* urb* rur* med*
		local stublist
		ds R*
		foreach v of varlist `r(varlist)' {
			local vv = substr("`v'", 1, strpos("`v'","_")-2)
			local stublist `stublist' `vv'
		}
		local stublist: list uniq stublist
		display "`stublist'"
		
	* reshape long
		reshape long N pop N1 N2 N3 N4 N5 Q1 Q2 Q3 Q4 Q5 CI stderror_CI `stublist' Nurb urb Nrur rur Nmed1 Nmed2 Nmed3 med1 med2 med3, i(country) j(indic) string 
		
	* Drop empty variables
		drop if pop == .
	
	* save survey-specific meso-data
		saveold "${OUT}/TEMP/MICS/MICSnew-`c'Adept.dta", replace
}

	* Append survey-specific meso-data
		clear
		set obs 1
		foreach c in $newMICS2countries $newMICS3countries $newMICS4countries  $newMICS5countries  $newMICS6countries {
			append using "${OUT}/TEMP/MICS/MICSnew-`c'Adept.dta"
			*erase "${OUT}/TEMP/MICS/MICSnew-`c'Adept.dta"
		}
		drop in 1
		
	* Create NewMICS identifier
		gen newMICS = 2020
		saveold "${OUT}/NewMICS_2020.dta", replace
		
		
		
		
		** checker against previous dataset by Maxime
		use "${OUT}/NewMICS_2020.dta", clear
		rename pop pop2
		merge 1:1 country year indic using "D:/MEASURE UHC DATA/STATA/DATA/SC/NewMICS.dta", keepusing(pop)
		drop if inlist(indic,"h_drinkwater","h_san_facilities")
		drop if strmatch(indic, "*pnc*") & _ == 2
		drop if _ == 2 & pop == 0
		gen diff = pop - pop2
		replace diff = . if inlist(indic,"c_diarrheaact","c_sevdiarrheatreat","c_diarrheaact_q","c_sevdiarrheatreat_q") 
		sort diff 
		order diff pop pop2
		 rename pop popMAX
		 rename pop2 popHAO
		should pull in HEFPI here to compare now for paper.
		
		
		** checker against previous HEFPI dataset
		use "C:\Users\wb493196\Desktop\hefpi_full_database.dta", clear
		gen survey  = "MICS" if strmatch(referenceid,"*MICS*") 
		rename pop pop2
		merge 1:1 country year survey indic using "${OUT}/NewMICS_2020.dta", keepusing(pop)
		keep if _ == 3
		gen diff = pop2 - pop
		sort diff 
		order diff pop pop2 indic country year
		 rename pop popHAO
		 rename pop2 popHEFPI

		should pull in HEFPI here to compare now for paper.