*EXAMPLE OF IMPORTING TABLE FOR CROSS SECTION
	*IMPORT 2SLSIV
	
local droppath /Users/jesseschreger/Dropbox
*local droppath C:/Users/Benjamin/Dropbox
*local droppath /Users/bhebert/Dropbox


*import excel "`dir_resultsb'/RS_CDS_IVHMLLocal_relative_noex_fixed.xlsx", sheet("Sheet1") clear
import excel "$mainpath/Results/BenH_3Sep2015/RS_CDS_IVLocalHML_relative_noex.xlsx", sheet("Sheet1") clear
* 90, 95, or 99
local CI_lvl 90
local HML 1

replace A="cds_se" if _n==5
drop if _n==1 | _n==3 | _n==6
sxpose, clear
foreach x of varlist _all { 
replace `x'=subinstr(`x',"-","_",.) if _n==1
replace `x'=subinstr(`x'," ","_",.) if _n==1

local temp=`x'[1]
rename `x' `temp'
}
drop if _n==1
replace cds_se=subinstr(cds_se,"(","",.)
replace cds_se=subinstr(cds_se,")","",.)
rename VAR Ticker

foreach x of varlist _all {
if "`x'"~="Ticker" {
destring `x',  replace 
}
}


sort Ticker
rename cds_ cds


su cds if Ticker == "EqIndex_AR"

local indval = `r(mean)'

gen betaest =  Index_Beta * `indval'
gen pointest = cds + betaest

gen ci_low = CI_1_`CI_lvl'_L + Index_Beta * `indval'
gen ci_high = CI_1_`CI_lvl'_H + Index_Beta * `indval'

keep Ticker  betaest pointest ci_low ci_high Index_Beta
gen n=_n
replace Ticker=subinstr(Ticker,"_AR","",.)
summ n if Ticker=="EqIndex"
local n_index=r(mean)
local index_alpha= pointest[`n_index']
gen capm_implied=`index_alpha'*Index_Beta
drop n

gen label=Ticker
replace label="Chemical" if Ticker=="Chems"
replace label="Energy" if Ticker=="Enrgy"
replace label="Manufacturing" if Ticker=="Manuf"
replace label="Non-Durables" if Ticker=="NoDur"
replace label="Real Estate" if Ticker=="RlEst"
replace label="Telecoms" if Ticker=="Telcm"
replace label="Utilities" if Ticker=="Utils"

if `HML'==0 {
replace label="Gov. Ownership" if Ticker=="High_Government"
replace label="No Gov. Ownership" if Ticker=="Low_Government"
replace label="Non-Importer" if Ticker=="Low_import_intensity"
replace label="Importer" if Ticker=="High_import_intensity"
replace label="Domestically-Owned" if Ticker=="Low_foreign_own"
replace label="Foreign-Owned" if Ticker=="High_foreign_own"
replace label="ADR" if Ticker=="High_indicator_adr"
replace label="No ADR" if Ticker=="Low_indicator_adr"
replace label="Non-Exporter" if Ticker=="Low_es_industry"
replace label="Exporter" if Ticker=="High_es_industry"
replace label="Blue Rate (Onshore)" if Ticker=="DSBlue"
replace label="Blue Rate (ADR)" if Ticker=="ADRBlue"
replace label="Official Rate" if Ticker=="OfficialRate"

gen compnum=.
replace compnum=1 if Ticker=="High_es_industry" | Ticker=="Low_es_industry"
replace compnum=2 if Ticker=="Low_import_intensity" | Ticker=="High_import_intensity"
replace compnum=3 if Ticker=="High_foreign_own" | Ticker=="Low_foreign_own"
replace compnum=4 if Ticker=="High_indicator_adr" | Ticker=="Low_indicator_adr"
}
else {
replace label="Gov. Ownership" if Ticker=="HML_Government"
replace label="Exporter" if Ticker=="HML_es_industry"
replace label="Exporter_old" if Ticker=="HML_export_share"
replace label="Importer" if Ticker=="HML_import_intensity"
replace label="Foreign-Owned" if Ticker=="HML_foreign_own"
replace label="ADR" if Ticker=="HML_indicator_adr"
replace label="Onshore-ADR FX" if Ticker=="DSMinusADR"
replace label="Financial" if Ticker=="HML_finvar" 

gen compnum=.
replace compnum=1 if Ticker=="HML_es_industry" 
replace compnum=2 if Ticker=="HML_import_intensity" 
replace compnum=3 if Ticker=="HML_finvar" 
replace compnum=4 if Ticker=="HML_foreign_own" 
replace compnum=5 if Ticker=="HML_indicator_adr" 
replace compnum=6 if Ticker=="DSMinusADR" 
}

local group1 Banks Chems Diverse Enrgy Manuf NoDur RlEst Telcm Utils
local group2 HML_Government HML_es_industry HML_finvar HML_foreign_own HML_import_intensity HML_indicator_adr
local group3 ADRBlue DSBlue OfficialRate

graph drop _all


	discard
	local group1a Banks Enrgy Manuf RlEst Utils	
	local group1b Chems Diverse Telcm	
local group1 Banks Chems Diverse Enrgy Manuf RlEst Telcm Utils
	*twoway (rcap ci_high ci_low  capm_implied if regexm("`group1'",Ticker), lcolor(navy) sort ) (lfit capm_implied capm_implied if regexm("`group1'",Ticker), sort range(-110 -30)) (scatter pointest capm_implied if regexm("`group1'",Ticker),  mcolor(navy) mlabcolor(navy) ) (scatter pointest capm_implied if regexm("`group1a'",Ticker),  mlabel(label) mcolor(forest_green) mlabcolor(forest_green) mlabsize(med)) (scatter pointest capm_implied if regexm("`group1b'",Ticker),  mcolor(forest_green)), ytitle("Estimated Industry Response, {&alpha}", size(med)) xtitle("Abnormal Return from Market Beta", size(med)) legend(off) graphregion(fcolor(white) lcolor(white))  name("Graph`x'") xlabel(-110(20)-30) ylabel(-100(20)0) 
	twoway (rcap ci_high ci_low  capm_implied if regexm("`group1'",Ticker), lcolor(navy) sort ) (lfit capm_implied capm_implied if regexm("`group1'",Ticker), sort) (scatter pointest capm_implied if regexm("`group1'",Ticker),  mcolor(navy) mlabcolor(navy) ) (scatter pointest capm_implied if regexm("`group1a'",Ticker),  mlabel(label) mcolor(forest_green) mlabcolor(forest_green) mlabsize(med)) (scatter pointest capm_implied if regexm("`group1b'",Ticker),  mcolor(forest_green)), ytitle("Estimated Abnormal Return", size(med)) xtitle("Abnormal Return from Market Beta", size(med)) legend(off) graphregion(fcolor(white) lcolor(white))  name("Graph`x'") xlabel(-80(20)-20) ylabel(-100(20)0) 
	graph export "$rpath/BK_Ind.eps", replace
	
discard
	 local group2 HML_es_industry HML_finvar HML_foreign_own HML_import_intensity HML_indicator_adr
	*forval x=1/5 {
	*twoway (rcap ci_high ci_low  capm_implied if regexm("`group2'",Ticker), lcolor(bluishgray) sort) (lfit capm_implied capm_implied if regexm("`group2'",Ticker), sort range(-30 40)) (scatter pointest capm_implied if regexm("`group2'",Ticker),  mcolor(bluishgray) mlabcolor(bluishgray)) (rcap ci_high ci_low  capm_implied if compnum==`x', lcolor(forest_green) sort ) (scatter pointest capm_implied if compnum==`x',  mlabel(label) mcolor(forest_green) mlabcolor(forest_green) mlabsize(med)), ytitle("Estimated Abnormal Return, {&alpha}", size(med)) xtitle("Abnormal Return from Market Beta", size(med)) legend(off) graphregion(fcolor(white) lcolor(white))  name("GraphHML_`x'")  xlabel(-30(10)40) ylabel(-60(20)40) 
	*twoway (rcap ci_high ci_low  capm_implied if regexm("`group2'",Ticker), lcolor(bluishgray) sort) (lfit capm_implied capm_implied if regexm("`group2'",Ticker), sort range(-30 40)) (scatter pointest capm_implied if regexm("`group2'",Ticker),  mcolor(bluishgray) mlabcolor(bluishgray)) (rcap ci_high ci_low  capm_implied if compnum==`x', lcolor(forest_green) sort ) (scatter pointest capm_implied if compnum==`x',  mlabel(label) mcolor(forest_green) mlabcolor(forest_green) mlabsize(med)), ytitle("Estimated Abnormal Return", size(med)) xtitle("Abnormal Return from Market Beta", size(med)) legend(off) graphregion(fcolor(white) lcolor(white))  name("GraphHML_`x'")  xlabel(-30(10)40) ylabel(-60(20)40) 
	*graph export "$rpath/BK_HML_`x'.eps", replace
	*}
	 local group2  HML_es_industry HML_finvar HML_foreign_own HML_import_intensity HML_indicator_adr
		*twoway (rcap ci_high ci_low  capm_implied if regexm("`group2'",Ticker), lcolor(navy) sort ) (lfit capm_implied capm_implied if regexm("`group2'",Ticker), sort range(-30 40))   (scatter pointest capm_implied if regexm("`group2'",Ticker),  mlabel(label) mcolor(forest_green) mlabcolor(forest_green) mlabsize(med)), ytitle("Estimated Abnormal Return, {&alpha}", size(medlarge)) xtitle("Abnormal Return from Market Beta") legend(off) graphregion(fcolor(white) lcolor(white))  name("GraphHML_All")  xlabel(-30(10)40) ylabel(-60(20)40) 
		twoway (rcap ci_high ci_low  capm_implied if regexm("`group2'",Ticker), lcolor(navy) sort ) (lfit capm_implied capm_implied if regexm("`group2'",Ticker), sort range(-40 40))   (scatter pointest capm_implied if regexm("`group2'",Ticker),  mlabel(label) mcolor(forest_green) mlabcolor(forest_green) mlabsize(med)), ytitle("Estimated Abnormal Return", size(med)) xtitle("Abnormal Return from Market Beta", size(med)) legend(off) graphregion(fcolor(white) lcolor(white))  name("GraphHML_All")  
graph export "$rpath/BK_HML_All.eps", replace
