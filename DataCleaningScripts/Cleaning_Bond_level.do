*Bond level data
*Cleaning Bloomberg data
global dir_inter "~/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate"
global dir_datasets "~/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets"
tempfile Gov_time_series

set more off
local stale_thresh=.2
import excel "$mainpath/Bloomberg/Data/Debt_Securities.xlsx", sheet("Gov_all") firstrow clear
foreach x in Bond Name ISSUE_DT maturity market_issue ID_ISIN currency COLLECTIVE_ACTION_CLAUSE GOVERNING_LAW Defaulted cpn_typ CREDIT_EVENT_RESTRUCTURING AMT_OUTSTANDING AMT_ISSUED INFLATION_LINKED_INDICATOR security_typ CNTRY_ISSUE_ISO {
local temp=lower("`x'")
rename `x' `temp'
}

drop credit_eve governing security_t cntry
destring amt_issued, replace force
gen issue_date=date(issue_dt,"MDY")
format issue_date %td
gen mat_date=date(maturity,"MDY")
format mat_date %td
replace issue_dt="9/30/2009" if id_isin=="XS0501195993"
*http://www.boerse-frankfurt.de/en/bonds/argentina+10+38+pars+XS0501195993
replace issue_dt="9/24/2009" if id_isin=="XS0501196025"
*http://www.bondpdf.com/bonds/XS0501196025
replace issue_dt="4/1/2005" if id_isin=="ARARGE03E659"
*http://isin1.findex.com/ARARGE03E659-ARGENTINA-2005-G-R-31-12-38-S-8.php
replace issue_dt="4/1/2005" if id_isin=="ARARGE03E667"
*http://isin1.findex.com/ARARGE03E667-ARGENTINA-2005-G-R-31-12-33-S-9.php
replace issue_dt="6/25/2010" if id_isin=="XS0501195720"
*http://em.cbonds.com/emissions/issue/88549
replace issue_dt="" if id_isin=="ARARGE03E642"
*http://em.cbonds.com/emissions/issue/95707
replace issue_dt="4/15/2010" if id_isin=="ARARGE03G712"
*http://em.cbonds.com/emissions/issue/95799
replace issue_dt="1/20/2005" if id_isin=="ARARGE03E634"
*http://em.cbonds.com/emissions/issue/95771
*replace issue_dt="" if id_isin=="ARP04981AA75"
drop if issue_dt==""
drop issue_dt maturity
gen ticker=subinstr(bond," Corp","",.)
order ticker
save "$apath/Gov_bonds_static.dta", replace

import excel "$mainpath/Bloomberg/Data/Debt_Securities.xlsx", sheet("Gov_Prices_Value")  allstring clear
foreach x of varlist _all {
tostring `x', replace
	if `x'[3]=="" | `x'[3]=="#N/A N/A" {
		drop `x'
		}
		}
local i=1
foreach x of varlist _all {		
	rename `x' v`i'
	local i=`i'+1
	}		
local ii=`i'-2		
save "`Gov_time_series'", replace

*STOPPED HERE
forvalues i=1(3)`ii' {
use "`Gov_time_series'", clear
local y=`i'+1
local z=`i'+2
keep v`i' v`y' v`z'
local temp=v`i'[1]
gen bb_ticker="`temp'"
replace v`i'=subinstr(v`i'," Corp","",.)
replace v`i'=subinstr(v`i'," ","_",.) if _n==1
local temp=v`i'[1]
gen ticker= "`temp'"
rename v`i' date
rename v`y' ytm_mid
rename v`z' px_last
drop if _n==1 | _n==2
local x=`z'/3
save "$mainpath/Bloomberg/intermediate/govbond_`x'.dta", replace
}	



use "$mainpath/Bloomberg/intermediate/govbond_1.dta", clear
forvalues i=2/131 {
append using "$mainpath/Bloomberg/intermediate/govbond_`i'.dta"
}
rename date datestr
gen date=date(datestr,"MDY")
format date %td
order date
drop datestr
destring ytm_mid, replace force
destring px_last, replace force
drop if date==.
mmerge ticker using "$apath/Gov_bonds_static.dta"
keep if _merge==3

gen exchange_bond=0
replace exchange_bond=1 if issue_date==td(29nov2005)
replace exchange_bond=1 if issue_date==td(02jun2010)

bysort ticker: egen obscount=count(px_last)
drop if id_isin=="#N/A Field Not Applicable"

gen bdate = bofd("basic",date)
format bdate %tbbasic
encode ticker, gen(tid)
tsset tid bdate
sort tid bdate

gen stale_ind=0
replace stale_ind=1 if px_last==l.px_last
bysort tid: egen stale_ratio=sum(stale_ind)
replace stale_ratio=stale_ratio/obscount
keep if stale_ratio<.2

sort tid bdate
gen px_change=100*log(px_last/l.px_last)
gen px_change2=100*log(px_last/l2.px_last)


tostring exchange_bond, replace
gen stale_ratio_str=round(stale_ratio*1000)
tostring stale_ratio_str, replace
gen ticker_exch=ticker+"_"+exchange_bond+"_"+curr+"_"+stale_ratio_str
sort ticker date

*KEEP EURO AND DOLLAR BONDS with at least 500 days
drop if obscount<500
levelsof(ticker_exch), local(tickid)
discard
/*foreach x of local tickid {
	twoway (line px_last date) if ticker_exch=="`x'" & date>=td(01jan2011) & date<=td(30jul2014), title("`x'") name("`x'")
	graph export "$rpath/`x'.png", replace
	}
*/	
	*usable restructured bond is EI233619
	*most frequently traded defaulted is EC131761 
	keep if ticker=="EI233619" | ticker=="EC131761" | id_isin=="US040114GK09"
	replace ticker="rsbond_usd_disc" if ticker=="EI233619"
	replace ticker="defbond_eur" if ticker=="EC131761"
	replace ticker="rsbond_usd_par" if id_isin=="US040114GK09"
	
	twoway (line ytm_mid date if ticker=="rsbond_usd_disc") (line ytm_mid date if ticker=="defbond_eur"), legend(order(1 "Restructured" 2 "Holdout")) ytitle("YTM")
	graph export "$rpath/bond_ytm_compare.png", replace
	twoway (line px_last date if ticker=="rsbond_usd_disc") (line px_last date if ticker=="defbond_eur"), legend(order(1 "Restructured" 2 "Holdout")) ytitle("Price")
	graph export "$rpath/bond_px_compare.png", replace
	
	
	keep date px_last ticker
	rename px_last px_close
	gen px_open=.
	gen total_return=px_close
	gen market="Index"
	gen industry_sector=ticker
	rename ticker Ticker
	save "$apath/bondlevel.dta", replace
	
	
/*
*LOCAL GOVT AND CORP
import excel "$dir_home/Data/Debt_Securities.xlsx", sheet("Gov") firstrow clear
foreach x in Bond Name ISSUE_DT maturity market_issue ID_ISIN currency COLLECTIVE_ACTION_CLAUSE GOVERNING_LAW Defaulted cpn_typ CREDIT_EVENT_RESTRUCTURING AMT_OUTSTANDING AMT_ISSUED INFLATION_LINKED_INDICATOR security_typ CNTRY_ISSUE_ISO {
local temp=lower("`x'")
rename `x' `temp'
}

drop credit_eve governing 
destring amt_issued, replace force
gen issue_date=date(issue_dt,"MDY")
format issue_date %td
gen mat_date=date(maturity,"MDY")
format mat_date %td
drop if name=="REPUBLIC OF ARGENTINA" | name=="ARGENTINA PRESTAMOS GARA"
sort issue_date
save "$dir_datasets/Loc_Gov_bonds_static.dta", replace


*CORP
import excel "$dir_home/Data/Debt_Securities.xlsx", sheet("Corp") firstrow clear
foreach x in Bond Name ISSUE_DT maturity market_issue ID_ISIN currency COLLECTIVE_ACTION_CLAUSE  Defaulted cpn_typ CREDIT_EVENT_RESTRUCTURING AMT_OUTSTANDING AMT_ISSUED INFLATION_LINKED_INDICATOR   {
local temp=lower("`x'")
rename `x' `temp'
}

drop credit_eve  
destring amt_issued, replace force
gen issue_date=date(issue_dt,"MDY")
format issue_date %td
gen mat_date=date(maturity,"MDY")
format mat_date %td
drop issue_dt maturity
order issue_date mat_date
sort issue_date
rename O equity_name
rename bond_to equity_ticker
replace equity_ticker=trim(equity_ticker)
replace equity_ticker=subinstr(equity_ticker,"  "," ",.)
replace equity_ticker=subinstr(equity_ticker,"  "," ",.)
replace equity_ticker=subinstr(equity_ticker,"  "," ",.)
replace equity_ticker=subinstr(equity_ticker,"  "," ",.)
replace equity_ticker=subinstr(equity_ticker,"  "," ",.)
order equity_ticker equity_name, after(bond)
save "$dir_datasets/Corp_bonds_static.dta", replace


*LOCAL GOVT AND CORP
import excel "$dir_home/Data/Debt_Securities.xlsx", sheet("Gov") firstrow clear
foreach x in Bond Name ISSUE_DT maturity market_issue ID_ISIN currency COLLECTIVE_ACTION_CLAUSE GOVERNING_LAW Defaulted cpn_typ CREDIT_EVENT_RESTRUCTURING AMT_OUTSTANDING AMT_ISSUED INFLATION_LINKED_INDICATOR security_typ CNTRY_ISSUE_ISO {
local temp=lower("`x'")
rename `x' `temp'
}

drop credit_eve governing 
destring amt_issued, replace force
gen issue_date=date(issue_dt,"MDY")
format issue_date %td
gen mat_date=date(maturity,"MDY")
format mat_date %td
drop if name=="REPUBLIC OF ARGENTINA" | name=="ARGENTINA PRESTAMOS GARA"
sort issue_date
save "$dir_datasets/Loc_Gov_bonds_static.dta", replace



*Bond level data
*Cleaning Bloomberg data
global dir_home "~/Dropbox/Cost of Sovereign Default/Bloomberg"
global dir_inter "~/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate"
global dir_datasets "~/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets"

import excel "$dir_home/Data/Debt_Securities.xlsx", sheet("Gov_all") firstrow clear
foreach x in Bond Name ISSUE_DT maturity market_issue ID_ISIN currency COLLECTIVE_ACTION_CLAUSE GOVERNING_LAW Defaulted cpn_typ CREDIT_EVENT_RESTRUCTURING AMT_OUTSTANDING AMT_ISSUED INFLATION_LINKED_INDICATOR security_typ CNTRY_ISSUE_ISO {
local temp=lower("`x'")
rename `x' `temp'
}

drop credit_eve governing security_t cntry
destring amt_issued, replace force
gen issue_date=date(issue_dt,"MDY")
format issue_date %td
gen mat_date=date(maturity,"MDY")
format mat_date %td
replace issue_dt="9/30/2009" if id_isin=="XS0501195993"
*http://www.boerse-frankfurt.de/en/bonds/argentina+10+38+pars+XS0501195993
replace issue_dt="9/24/2009" if id_isin=="XS0501196025"
*http://www.bondpdf.com/bonds/XS0501196025

replace issue_dt="4/1/2005" if id_isin=="ARARGE03E659"
*http://isin1.findex.com/ARARGE03E659-ARGENTINA-2005-G-R-31-12-38-S-8.php
replace issue_dt="4/1/2005" if id_isin=="ARARGE03E667"
*http://isin1.findex.com/ARARGE03E667-ARGENTINA-2005-G-R-31-12-33-S-9.php
replace issue_dt="6/25/2010" if id_isin=="XS0501195720"
*http://em.cbonds.com/emissions/issue/88549
replace issue_dt="" if id_isin=="ARARGE03E642"
*http://em.cbonds.com/emissions/issue/95707
replace issue_dt="4/15/2010" if id_isin=="ARARGE03G712"
*http://em.cbonds.com/emissions/issue/95799
replace issue_dt="1/20/2005" if id_isin=="ARARGE03E634"
*http://em.cbonds.com/emissions/issue/95771
*replace issue_dt="" if id_isin=="ARP04981AA75"
drop if issue_dt==""
drop issue_dt maturity
gen ticker=subinstr(bond," Corp","",.)
order ticker
save "$dir_datasets/Gov_bonds_static.dta", replace

import excel "$dir_home/Data/Debt_Securities.xlsx", sheet("Gov_Prices_Value")  allstring clear
sxpose, clear

gen n=_n
order n
gen mod4=mod(n,4)
drop if mod4==0
drop mod4 n

gen n=_n
order n
tsset n
carryforward _var1, replace
encode _var1, gen(bond_id)
order bond_id
drop n
save "$dir_inter/Gov_time_series.dta", replace




*Corp level data
*Cleaning Bloomberg data
global dir_home "~/Dropbox/Cost of Sovereign Default/Bloomberg"
global dir_inter "~/Dropbox/Cost of Sovereign Default/Bloomberg/intermediate"
global dir_datasets "~/Dropbox/Cost of Sovereign Default/Bloomberg/Datasets"

import excel "$dir_home/Data/Debt_Securities.xlsx", sheet("Corp_price_value2") firstrow clear
foreach x in Bond Name ISSUE_DT maturity market_issue ID_ISIN currency COLLECTIVE_ACTION_CLAUSE GOVERNING_LAW Defaulted cpn_typ CREDIT_EVENT_RESTRUCTURING AMT_OUTSTANDING AMT_ISSUED INFLATION_LINKED_INDICATOR security_typ CNTRY_ISSUE_ISO {
local temp=lower("`x'")
rename `x' `temp'
}

drop credit_eve governing security_t cntry
destring amt_issued, replace force
gen issue_date=date(issue_dt,"MDY")
format issue_date %td
gen mat_date=date(maturity,"MDY")
format mat_date %td
replace issue_dt="9/30/2009" if id_isin=="XS0501195993"
*http://www.boerse-frankfurt.de/en/bonds/argentina+10+38+pars+XS0501195993
replace issue_dt="9/24/2009" if id_isin=="XS0501196025"
*http://www.bondpdf.com/bonds/XS0501196025

replace issue_dt="4/1/2005" if id_isin=="ARARGE03E659"
*http://isin1.findex.com/ARARGE03E659-ARGENTINA-2005-G-R-31-12-38-S-8.php
replace issue_dt="4/1/2005" if id_isin=="ARARGE03E667"
*http://isin1.findex.com/ARARGE03E667-ARGENTINA-2005-G-R-31-12-33-S-9.php
replace issue_dt="6/25/2010" if id_isin=="XS0501195720"
*http://em.cbonds.com/emissions/issue/88549
replace issue_dt="" if id_isin=="ARARGE03E642"
*http://em.cbonds.com/emissions/issue/95707
replace issue_dt="4/15/2010" if id_isin=="ARARGE03G712"
*http://em.cbonds.com/emissions/issue/95799
replace issue_dt="1/20/2005" if id_isin=="ARARGE03E634"
*http://em.cbonds.com/emissions/issue/95771
*replace issue_dt="" if id_isin=="ARP04981AA75"
drop if issue_dt==""
drop issue_dt maturity
gen ticker=subinstr(bond," Corp","",.)
order ticker
save "$dir_datasets/Gov_bonds_static.dta", replace

import excel "$dir_home/Data/Debt_Securities.xlsx", sheet("Gov_Prices_Value")  allstring clear
sxpose, clear

gen n=_n
order n
gen mod4=mod(n,4)
drop if mod4==0
drop mod4 n

gen n=_n
order n
tsset n
carryforward _var1, replace
encode _var1, gen(bond_id)
order bond_id
drop n
save "$dir_inter/Gov_time_series.dta", replace
