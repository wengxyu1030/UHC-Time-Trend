
import delimited "C:\Users\wb500886\WBG\Sven Neelsen - World Bank\MEASURE UHC DATA\RAW DATA\Recode VII\external\tableconvert_2020-03-09_112615.csv", varnames(1) clear 
rename ïcountry country 
gen iso2c = regexs(0) if regexm(alpha2code,"([a-zA-Z]+)")
gen iso3c = regexs(0) if regexm(alpha3code,"([a-zA-Z]+)")
keep country iso2c iso3c
save "C:\Users\wb500886\WBG\Sven Neelsen - World Bank\MEASURE UHC DATA\RAW DATA\Recode VII\external\iso.dta",replace

