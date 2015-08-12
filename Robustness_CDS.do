******************
*Robustness Table*
******************

do ${csd_dir}/SetupPaths.do

do ${csd_dir}/StaticTable.do

do ${csd_dir}/ADR_Value.do

do ${csd_dir}/BlueRateMaker.do

do ${csd_dir}/GlobalFactors.do

forvalues cdsii=10/15 {
if `cdsii'==1 {
	global cds_app "_3y"
	global cds_e "def3y_europe"
	global cds_n "def3y"

}	
else if `cdsii'==2 {
	global cds_app "_7y"
	global cds_e "def7y_europe"
	global cds_n "def7y"
}

else if `cdsii'==3 {
	global cds_app "_3yConR"
	global cds_e "conh_def3y_europe"
	global cds_n "conh_def3y"

}

else if `cdsii'==4 {
	global cds_app "_5yConR"
	global cds_e "conh_def5y_europe"
	global cds_n "conh_def5y"
}

else if `cdsii'==5 {
	global cds_app "_7yConR"
	global cds_e "conh_def7y_europe"
	global cds_n "conh_def7y"

}

else if `cdsii'==6 {
	global cds_app "_3yTri"
	global cds_e "tri_def3y_europe"
	global cds_n "tri_def3y"

}

else if `cdsii'==7 {
	global cds_app "_5yTri"
	global cds_e "tri_def5y_europe"
	global cds_n "tri_def5y"
}

else if `cdsii'==8 {
	global cds_app "_7yTri"
	global cds_e "tri_def7y_europe"
	global cds_n "tri_def7y"
}

else if `cdsii'==9 {
	global cds_app "_3yUST"
	global cds_e "ust_def3y_europe"
	global cds_n "ust_def3y"

}

else if `cdsii'==10 {
	global cds_app "_5yUST"
	global cds_e "ust_def5y_europe"
	global cds_n "ust_def5y"
}

else if `cdsii'==11 {
	global cds_app "_7yUST"
	global cds_e "ust_def7y_europe"
	global cds_n "ust_def7y"
}


else if `cdsii'==12 {
	global cds_app "_3yNY"
	global cds_e "def3y_europe"
	global cds_n "def3y_newyork"
}

else if `cdsii'==13 {
	global cds_app "_5yNY"
	global cds_e "def5y_europe"
	global cds_n "def5y_newyork"
}

else if `cdsii'==14 {
	global cds_app "_7yNY"
	global cds_e "def7y_europe"
	global cds_n "def7y_newyork"
}

else if `cdsii'==15 {
	*TEMP
	global cds_app "_PUFNY"
	global cds_e "Upfront5Y"
	global cds_n "Upfront4Y"
}
do ${csd_dir}/CDSMaker.do
do ${csd_dir}/ThirdAnalysis.do
do ${csd_dir}/RunAnalysis.do

}

*ORGANIZE RESULTS

import excel "$rpath/RS_CDS_IV_reshapeADRs_3y.xls", sheet("Sheet1") firstrow clear
gen cds_type="3y"
keep if variables=="cds2" | variables=="Robust_SE" | variables=="Full_SE" | variables=="CI_95"
save "$rpath/temp.dta", replace
foreach x in "ConR" "Tri" "UST" "NY" {
foreach y in "3y" "5y" "7y" {
	cap{
	import excel "$rpath/RS_CDS_IV_reshapeADRs_`y'`x'.xls", sheet("Sheet1") firstrow clear
	keep if variables=="cds2" | variables=="Robust_SE" | variables=="Full_SE" | variables=="CI_95"
	gen cds_type="`x'`y'"
	append using "$rpath/temp.dta"
	save "$rpath/temp.dta", replace
	}
}	
}	
import excel "$rpath/RS_CDS_IV_reshapeADRs_7y.xls", sheet("Sheet1") firstrow clear
	keep if variables=="cds2" | variables=="Robust_SE" | variables=="Full_SE" | variables=="CI_95"
	gen cds_type="7y"
	append using "$rpath/temp.dta"
	order cds_type
	save "$rpath/temp.dta", replace
	
	import excel "$rpath/RS_CDS_IV_reshapeADRs_PUFNY.xls", sheet("Sheet1") firstrow clear
	keep if variables=="cds2" | variables=="Robust_SE" | variables=="Full_SE" | variables=="CI_95"
	gen cds_type="PUFNY"
	append using "$rpath/temp.dta"
	order cds_type
	save "$rpath/temp.dta", replace
	
	
	foreach var of varlist _all {
		rename `var' x_`var'
	}
	rename x_cds_type cds_type
	rename x_variables variables
	reshape long x_, i(cds var) j(temp) str
	bysort cds_type: gen se_temp=x_ if variables=="Full_SE"
	destring se_temp, replace force
	bysort cds: egen se_temp2=max(se_temp)
	tostring se_temp2, replace force
	replace x_="("+se_temp2+")" if variables=="Robust_SE" & (temp=="consensus" | temp=="consensus03" | temp=="consensus036m" | temp=="consensus6m" | temp=="vecm")
	drop if var=="Full_SE"
	drop se*
	reshape wide x_, i(cds var) j(temp) str
	renpfix x_
	drop est_type
	gen varnum=2
	replace varnum=1 if vari=="cds2"
	replace varnum=3 if vari=="Robust_SE"
	foreach x of varlist con* vec* {
	
		replace `x'=subinstr(`x',"(","",.) if varnum==3
		replace `x'=subinstr(`x',")","",.) if varnum==3
		replace `x'=substr(`x',1,4) if varnum==3
		replace `x'="("+`x'+")" if varnum==3
		}
	sort cds_type varnum
	save "$rpath/Robustness_Table.dta", replace
	export excel using "$rpath/Robustness_Table.xls", firstrow(variables)
