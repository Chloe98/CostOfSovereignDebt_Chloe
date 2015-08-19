
* Setup paths-- in case it hasn't been done yet.
do ${csd_dir}/SetupPaths.do

global GDP_models  consensus consensus03 consensus6m consensus036m ipg24 ipg12 ipg3
// vecm var dols
*global GDP_models vecm 

*Make the Dividend VAR indices
//do "$csd_dir/VarRunner.do"

*Creates NGF and the different indices of Forecasts from the Consensus Data
do "$csd_dir/Long_Term.do"

*Make the forecast index weights
do "$csd_dir/Forecast_RS.do"

*Make the Industrial Production weights
do "$csd_dir/Industrial_Production.do"

*Run Regressions
do "$csd_dir/RigobonSack_v3.do"
