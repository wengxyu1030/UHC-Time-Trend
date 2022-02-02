////////////////////////////////////
///// Run Time Series Do Files /////
///////////////////////////////////


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

*************************************
*** run all the time series files ***
*************************************

do "${DO}/01_time_trend_DW_DHS.do"
do "${DO}/01_time_trend_DW_MICS.do"
do "${DO}/02_time_trend_DW_DHS.do"
do "${DO}/02_time_trend_DW_MICS.do"
do "${DO}/03_time_trend_DW.do"

