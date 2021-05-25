
global path1 "C:\Users\wb63803\WBG\Patrick Hoang-Vu Eozenou - MEASURE UHC DATA\ADAM\Adam sandbox\HEFPI database assembly\HE\Full mesodata database"
global path2 "C:\Users\wb63803\WBG\Patrick Hoang-Vu Eozenou - MEASURE UHC DATA\ADAM\Adam sandbox\UHC Index paper #3"

cd "$path2"

use "${path1}\\2018 UHC_precoll.dta" ,clear

replace country="Kosovo" if iso3c=="XKX" 

do "C:\Users\wb63803\WBG\Patrick Hoang-Vu Eozenou - MEASURE UHC DATA\ADAM\Adam sandbox\HEFPI database assembly\HE\Full mesodata database\hefpi sc keep decisions.do" 

/*
sort iso3c year
merge iso3c year using "C:\Users\wb63803\WBG\Patrick Hoang-Vu Eozenou - MEASURE UHC DATA\ADAM\Adam sandbox\UHC Index paper #3\income groups.dta"
tabstat pop , by(indic) stat(min max mean p50 p75 p90 iqr) 
table indic regioncode , c(p95 pop) format(%3.2f) 
table indic income if keep==1 , c(p90 pop N pop) format(%3.2f) 
*/

replace coll="DHS" if strmatch(referenceid,"*DHS*")
replace coll="MICS" if strmatch(referenceid,"*MICS*")
replace coll="WHS" if strmatch(referenceid,"*WHS*")
replace coll="STEPS" if strmatch(referenceid,"*STEPS*")
replace coll="LSMS" if strmatch(referenceid,"*LSMS*") | strmatch(referenceid,"*SLC*") | strmatch(referenceid,"*VHLSS*") | strmatch(referenceid,"*VLSS*") 
replace coll="RHS" if strmatch(referenceid,"*RHS*")
replace coll="MCSS" if strmatch(referenceid,"*MCSS*")
replace coll="EHIS" if strmatch(referenceid,"*EHIS*")
replace coll="ISSP" if strmatch(referenceid,"*ISSP*")
replace coll="WB Household Health Survey 2011" if strmatch(referenceid,"*WBHHS*")
replace coll="OECD Hlth Stats" if strmatch(referenceid,"*OECD*")
replace coll="US Hlth Intrv Survey" if strmatch(referenceid,"*NHIS*") & iso3c=="USA" 
replace coll="Eurobarometer" if strmatch(referenceid,"*EUBM*")
replace coll="SAGE" if strmatch(referenceid,"*SAGE*")
replace coll="Other" if coll==""

egen groupid=group(coll)
tab coll groupid 
label define groupid 1 "DHS" 2 "ECHP" 3 "EHIS" 4 "Eurobarometer" 5 "ISSP" 6 "LSMS" 7 "MCSS" 8 "MICS"  9 "OECD"  10 "Other"  11 "RHS"  12 "SAGE" 13 "STEPS"  14 "UK-GHS"  15 "US-HIS"  16 "WB-HHS"  17 "WHS" 
label values groupid groupid 

rename country orig_country 
egen country = sieve(orig_country) , omit(,.)
replace country="Korea Dem People's Rep" if country=="Korea Dem People’s Rep" 

replace pop=pop*100 
rename a_rep old_a_rep
ge a_rep="Month(s)" if old_a_rep==3
drop old_a_rep

codebook country
sort country
bysort country: gen r = _n
sort r country
forval i = 1/201{
	local a`i' = country[`i']
}

foreach m in c_anc c_fullimm w_mam_2y w_pap_3y  c_sba c_treatARI c_treatdiarrhea { // IP code now appears below  

	global indicator "`m'"

	rtfopen graphsfile using "2018 UHC trends - ${indicator}.rtf" , paper(us) margins(720 720 720 720) template(fnmono2) replace
	file write graphsfile "{\pard\b TRENDS IN ${indicator}\par}" _n
	rtfsect graphsfile 
	rtfclose graphsfile

	forval i = 1/201 {
		local x  "`a`i''"
		di "`x'"

		preserve

			keep if country=="`x'" & indic=="${indicator}" & pop~=. 
			sum pop
			
			graph twoway ///
			(scatter pop year if groupid==1 , m(Oh) mc(gs6) lc(gs6) connect(l) sort(year) ) ///
			(scatter pop year if groupid==2 , m(Oh) mc(orange) lc(orange) connect(l) sort(year) ) ///
			(scatter pop year if groupid==3 , m(Oh) mc("153 204 0") lc("153 204 0") connect(l) sort(year) ) ///
			(scatter pop year if groupid==4 , m(Oh) mc(eltgreen) lc(eltgreen) connect(l) sort(year) ) ///
			(scatter pop year if groupid==5 , m(Oh) mc(gold) lc(gold) connect(l) sort(year) ) ///
			(scatter pop year if groupid==6 , m(Oh) mc(ebblue) lc(ebblue) connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==7 , m(Oh) mc("128 0 0") lc("128 0 0") connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==8 , m(Oh) mc(eltblue) lc(eltblue) connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==9 , m(Oh) mc("255 51 153") lc("255 51 153") connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==10 , m(Oh) mc(cyan) lc(cyan) connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==11 , m(Oh) mc(red) lc(red) connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==12 , m(Oh) mc(erose) lc(erose) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==13 , m(Oh) mc(brown) lc(brown) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==14 , m(Oh) mc(purple) lc(purple) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==15 , m(Oh) mc(olive_teal) lc(olive_teal) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==16 , m(Oh) mc(ltblue) lc(ltblue) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==17 , m(Oh) mc(dkgreen) lc(dkgreen) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if keep==1 , m(smx) mc(cranberry) sort(year) yti("Population rate (%)", si(*.7)) xti("") xlabel(1980(5)2017, labsize(*.6)) ylabel(0(20)100, labsize(*.6)) legend(rows(5)) legend(size(small)) legend(order(1 "DHS" 2 "ECHP" 3 "EHIS" 4 "Eurobarometer" 5 "ISSP" 6 "LSMS" 7 "MCSS" 8 "MICS"  9 "OECD"  10 "Other"  11 "RHS"  12 "SAGE" 13 "STEPS"  14 "UK-GHS"  15 "US-HIS"  16 "WB-HHS"  17 "WHS" 18 "Kept")) ti("`x' - ${indicator}"))  , saving("`x'_${indicator}",replace) 
			graph export "`x'_${indicator}.emf" , replace				  
				
			keep year collection referenceid pop a_ren a_rep N keep 
			order year collection referenceid pop a_ren a_rep N keep 
			sort year 
			tostring year , replace
			format year %5s
			tostring a_ren , replace
			format a_ren %3s
			tostring N , replace
			format N %10s
			format a_rep %10s
			format pop %4.2f
			format collection %10s
			tostring keep , replace
			format keep %3s


			sdecode pop, replace prefix("\qc{") suffix("}")
																		
			rtfappend graphsfile using "2018 UHC trends - ${indicator}.rtf" , replace
			file write graphsfile "{\pard \b\f3\fs30 `x' \par}"
			file write graphsfile "\line"
			rtflink graphsfile using "`x'_${indicator}.emf" 
			file write graphsfile "\line"
			file write graphsfile "{\pard\i Note: see note to data table for explanation of legend. \par}" _n
			file write graphsfile "\line"
			file write graphsfile "\line"

			capture noisily {
				file write graphsfile "{\pard\b Surveys for `x'\par}" _n
				rtfrstyle year collection referenceid a_ren a_rep N keep pop , cwidths(550 1800 3500 800 1300 800 800 1000) local(b d e)
				listtab year collection referenceid a_ren a_rep N keep pop , handle(graphsfile) begin("`b'") delim("`d'") end("`e'") head("`b'\ql{\i Year}`d'\ql{\i Coll.}`d'\ql{\i Ref ID.}`d'\ql{\i Recall}`d'\ql{\i period}`d'\ql{\i N}`d'\ql{\i Kept}`d'\qc{\i Pop}`e'")
				file write graphsfile "\line"
				file write graphsfile "{\pard\i Note: A note. \par}" _n
				rtfsect graphsfile 
			}

			rtfclose graphsfile

		restore

	}

}

/*

foreach m in a_inpatient_1yr {

	global indicator "`m'"

	rtfappend graphsfile using "2018 UHC trends - ${indicator}.rtf" , replace
	rtfsect graphsfile 
	rtfclose graphsfile

	forval i = 1/201 {
		local x  "`a`i''"
		di "`x'"

		preserve

			keep if country=="`x'" & indic=="${indicator}" & pop~=. 
			sum pop
			
			graph twoway ///
			(scatter pop year if groupid==1 , m(Oh) mc(gs6) lc(gs6) connect(l) sort(year) ) ///
			(scatter pop year if groupid==2 , m(Oh) mc(orange) lc(orange) connect(l) sort(year) ) ///
			(scatter pop year if groupid==3 , m(Oh) mc("153 204 0") lc("153 204 0") connect(l) sort(year) ) ///
			(scatter pop year if groupid==4 , m(Oh) mc(eltgreen) lc(eltgreen) connect(l) sort(year) ) ///
			(scatter pop year if groupid==5 , m(Oh) mc(gold) lc(gold) connect(l) sort(year) ) ///
			(scatter pop year if groupid==6 , m(Oh) mc(ebblue) lc(ebblue) connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==7 , m(Oh) mc("128 0 0") lc("128 0 0") connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==8 , m(Oh) mc(eltblue) lc(eltblue) connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==9 , m(Oh) mc("255 51 153") lc("255 51 153") connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==10 , m(Oh) mc(cyan) lc(cyan) connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==11 , m(Oh) mc(red) lc(red) connect(l) lp(longdash) sort(year) ) ///
			(scatter pop year if groupid==12 , m(Oh) mc(erose) lc(erose) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==13 , m(Oh) mc(brown) lc(brown) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==14 , m(Oh) mc(purple) lc(purple) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==15 , m(Oh) mc(olive_teal) lc(olive_teal) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==16 , m(Oh) mc(ltblue) lc(ltblue) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if groupid==17 , m(Oh) mc(dkgreen) lc(dkgreen) connect(l) lp(shortdash) sort(year) ) ///
			(scatter pop year if keep==1 , m(smx) mc(cranberry) sort(year) yti("Population rate (%)", si(*.7)) xti("") xlabel(1980(5)2017, labsize(*.6)) ylabel(0(5)20, labsize(*.6)) legend(rows(5)) legend(size(small)) legend(order(1 "DHS" 2 "ECHP" 3 "EHIS" 4 "Eurobarometer" 5 "ISSP" 6 "LSMS" 7 "MCSS" 8 "MICS"  9 "OECD"  10 "Other"  11 "RHS"  12 "SAGE" 13 "STEPS"  14 "UK-GHS"  15 "US-HIS"  16 "WB-HHS"  17 "WHS" 18 "Kept")) ti("`x' - ${indicator}"))  , saving("`x'_${indicator}",replace) 
			graph export "`x'_${indicator}.emf" , replace				  
				
			keep year collection referenceid pop a_ren a_rep N keep 
			order year collection referenceid pop a_ren a_rep N keep 
			sort year 
			tostring year , replace
			format year %5s
			tostring a_ren , replace
			format a_ren %3s
			tostring N , replace
			format N %10s
			format a_rep %10s
			format pop %4.2f
			format collection %10s
			tostring keep , replace
			format keep %3s


			sdecode pop, replace prefix("\qc{") suffix("}")
																		
			rtfappend graphsfile using "2018 UHC trends - ${indicator}.rtf" , replace
			file write graphsfile "{\pard \b\f3\fs30 `x' \par}"
			file write graphsfile "\line"
			rtflink graphsfile using "`x'_${indicator}.emf" 
			file write graphsfile "\line"
			file write graphsfile "{\pard\i Note: see note to data table for explanation of legend. \par}" _n
			file write graphsfile "\line"
			file write graphsfile "\line"

			capture noisily {
				file write graphsfile "{\pard\b Surveys for `x'\par}" _n
				rtfrstyle year collection referenceid a_ren a_rep N keep pop , cwidths(550 1800 3500 800 1300 800 800 1000) local(b d e)
				listtab year collection referenceid a_ren a_rep N keep pop , handle(graphsfile) begin("`b'") delim("`d'") end("`e'") head("`b'\ql{\i Year}`d'\ql{\i Coll.}`d'\ql{\i Ref ID.}`d'\ql{\i Recall}`d'\ql{\i period}`d'\ql{\i N}`d'\ql{\i Kept}`d'\qc{\i Pop}`e'")
				file write graphsfile "\line"
				file write graphsfile "{\pard\i Note: A note. \par}" _n
				rtfsect graphsfile 
			}

			rtfclose graphsfile

		restore

	}

}

*/

*winexec C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE "2018 UHC trends - ${indicator}.rtf"
