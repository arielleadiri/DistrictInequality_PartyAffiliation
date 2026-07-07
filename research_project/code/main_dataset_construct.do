*******************************************************************************
******** main_dataset_construct.do
******** By Arielle Adiri and Martie Ehly
******** 4/1
******** Cleaning the IPUMS dataset
*******************************************************************************

cls
clear all
set more off


*** Set the correct path here
cd "/Users/Owner/OneDrive/Desktop/bu_s26/metrics/research_project"


*** code
/*******************************************************************************
				compute percentiles in a loop by puma 
*******************************************************************************/
use "data/made/hh_clean.dta", clear

levelsof puma_id, local(pumas)
 
tempfile puma_results
postfile phandle str7 puma_id double p10 p90 mean_inc double hh_count ///
                 double pct_nonwhite double pct_poverty using `puma_results'
 
foreach p of local pumas {
    quietly {
		preserve
        * subset to this puma
        keep if puma_id == "`p'"
 
        * weighted percentiles
        _pctile hhincome [pw=hhwt], percentiles(10 90)
        local p10 = r(r1)
        local p90 = r(r2)
 
        * weighted mean income
        summarize hhincome [aw=hhwt]
        local meaninc = r(mean)
 
        * total household weight (for crosswalk)
        summarize hhwt
        local hhcount = r(sum)
 
        * percent nonwhite (weighted)
        summarize nonwhite [aw=hhwt]
        local pct_nw = r(mean)
		
		*percent below poverty line (2017)
		summarize below_poverty [aw=hhwt]
		local pct_pov = r(mean)
		restore
 
    }
    post phandle ("`p'") (`p10') (`p90') (`meaninc') (`hhcount') (`pct_nw') (`pct_pov')
}
 
postclose phandle

 
* load results and compute ratio 
use `puma_results', clear
 
gen ratio_90_10 = p90 / p10

 
* flag any infinite ratios (p10 == 0) 
count if ratio_90_10 == . | ratio_90_10 > 1000
list puma_id p10 p90 ratio_90_10 if p10 == 0
drop if p10 == 0
 
* check distribution
sum ratio_90_10, detail

 
save "data/made/puma_stats.dta", replace


/*******************************************************************************
load and standardise crosswalk -> matching households in congressional districts
*******************************************************************************/

import delimited "data/raw/geocorr_puma_cd115_full.csv", clear varnames(1)
 
* build matching puma_id (state 2-digit + puma 5-digit)
drop in 1
destring state puma12 cd115 pop10 afact, replace
gen puma_id = string(state, "%02.0f") + string(puma12, "%05.0f")
 
* build cd_key to match your vote dataset (e.g. "FL-7", "NC-3")
gen district_num = cd115   // numeric district number from geocorr
 
keep puma_id state district_num afact

 
* state fips to abbreviation lookup 
gen state_abbrev = ""
replace state_abbrev = "AL" if state == 1
replace state_abbrev = "AR" if state == 5
replace state_abbrev = "CT" if state == 9
replace state_abbrev = "DE" if state == 10
replace state_abbrev = "DC" if state == 11
replace state_abbrev = "FL" if state == 12
replace state_abbrev = "GA" if state == 13
replace state_abbrev = "LA" if state == 22
replace state_abbrev = "ME" if state == 23
replace state_abbrev = "MD" if state == 24
replace state_abbrev = "MA" if state == 25
replace state_abbrev = "MS" if state == 28
replace state_abbrev = "NH" if state == 33
replace state_abbrev = "NJ" if state == 34
replace state_abbrev = "NY" if state == 36
replace state_abbrev = "NC" if state == 37
replace state_abbrev = "PA" if state == 42
replace state_abbrev = "RI" if state == 44
replace state_abbrev = "SC" if state == 45
replace state_abbrev = "TN" if state == 47
replace state_abbrev = "VT" if state == 50
replace state_abbrev = "VA" if state == 51
replace state_abbrev = "WV" if state == 54
 
* build cd_key to match vote dataset format
gen cd_key = state_abbrev + "-" + string(district_num)
 
save "data/made/crosswalk.dta", replace
 
* merging data
use "data/made/puma_stats.dta", clear
merge 1:m puma_id using "data/made/crosswalk.dta"
drop if _merge != 3   // drop unmatched 
drop _merge
 
* allocate puma stats to congressional districts
* weight each puma's contribution by afact * hh_count
gen alloc_wt = afact * hh_count
 
* collapse to congressional district level using weighted means
collapse (mean) ratio_90_10 mean_inc pct_nonwhite pct_poverty ///
         [aw=alloc_wt], by(cd_key)

save "data/made/cd_stats.dta", replace

/*******************************************************************************
			now we merge with our congressional data
*******************************************************************************/
use "data/made/southeast_congress.dta", clear
 
* merge district stats
* many-to-one: many vote rows per district, one stats row per district
merge m:1 cd_key using "data/made/cd_stats.dta"
tab _merge
drop if _merge == 2   // cd stats rows with no vote data
drop _merge
 
* create variables for analysis -> do i need to standardise continuous predictors (mean 0, sd 1)?
egen ratio_z    = std(ratio_90_10)
egen inc_z      = std(mean_inc)
egen nonwhite_z = std(pct_nonwhite)
egen pov_z 		= std(pct_poverty)
 
* checks
count if ratio_z == .
count if Dummy_Yes == .
sum ratio_z inc_z nonwhite_z party_dummy Dummy_Yes 
rename party_dummy repub_dummy

 
save "data/made/analysis_df.dta", replace

