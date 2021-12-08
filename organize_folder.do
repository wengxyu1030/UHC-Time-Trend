
////////////////////////////////////////////////////
///// Generate Time Series (organize data folder) //
////////////////////////////////////////////////////

/*
Aline
date: 2021/12/08
verson: 1.0
*/

/*This code is to copy all latest files by folder to a consolidated folder, making it easier to generate time-series*/

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

* Define path for external data 
global EXTERNAL "${root}/STATA/DO/SC/UHC-Time-Trend/UHC-Time-Trend/external"


*****Move DHS

local dlist: dir "$SOURCE" dir "DHS*"

foreach d of local dlist {
    local file: dir "$SOURCE/`d'" files "*.dta"

    foreach f of local file {
       copy "$SOURCE/`d'/`f'"  "$SOURCE/DHS-Nov2021/`f'"
    }
}   


*****Move MICS

local dlist: dir "$SOURCE" dir "MICS*"

foreach d of local dlist {
    local file: dir "$SOURCE/`d'" files "*.dta"

    foreach f of local file {
       copy "$SOURCE/`d'/`f'"  "$SOURCE/MICS-Oct2021/`f'"
    }
}   

//!currently files copied to the folder are all labeled in small letters, it would be great if there's solution on it. 