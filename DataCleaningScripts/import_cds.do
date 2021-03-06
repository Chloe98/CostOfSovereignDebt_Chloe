import excel "$csd_data/Datastream/CDS_Indices.xlsx", sheet("Import") firstrow clear
label var MCCEM10 "MARKIT CDX-EM 10Y OTR INDEX"
label var MCCEM5Y "MARKIT CDX-EM 5Y OTR INDEX"
label var MCCED5Y "MARKIT CDX-EMDIV 5Y OTR INDEX"
label var MCCED10 "MARKIT CDX-EMDIV 10Y OTR INDEX"
label var MCCED7Y "MARKIT CDX-EMDIV 7Y OTR INDEX"
label var MCCED3Y "MARKIT CDX-EMDIV 3Y OTR INDEX"
label var MCCIG1Y "MARKIT CDX-NAIG 1Y OTR INDEX"
label var MCCIG2Y "MARKIT CDX-NAIG 2Y OTR INDEX"
label var MCCIG3Y "MARKIT CDX-NAIG 3Y OTR INDEX"
label var MCCIG5Y "MARKIT CDX-NAIG 5Y OTR INDEX"
label var MCCIG7Y "MARKIT CDX-NAIG 7Y OTR INDEX"
label var MCCIG10 "MARKIT CDX-NAIG 10Y OTR INDEX"
label var MCCNH10 "MARKIT CDX-NAHY 10Y OTR INDEX"
label var MCCNH3Y "MARKIT CDX-NAHY 3Y OTR INDEX"
label var MCCNH5Y "MARKIT CDX-NAHY 5Y OTR INDEX"
label var MCCNH7Y "MARKIT CDX-NAHY 7Y OTR INDEX"

foreach x in varlist M* {
destring M*, replace force
}

twoway (line MCCED5Y date) (line MCCIG5Y date) (line MCCNH5Y date)
save "$apath/CDS_Indices.dta", replace
