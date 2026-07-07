*******************************************************************************
******** cleaning_allmembersstacked.do
******** By Arielle Adiri and Martie Ehly
******** 2/10, 4/1
******** Cleaning the Congress dataset we have curtesy of ???
*******************************************************************************

cls 
clear all
set more off

*** Set the correct path here
cd "/Users/Owner/OneDrive/Desktop/bu_s26/metrics/research_project"



*** Open up the dataset
use "data/raw/all_members_stacked.dta", clear

***code

**cleaning all_members_stacked

keep if Congress == 115
describe

* How many unique members?
codebook Rep_Number

* What does VoteIndex look like — are these all votes or filtered?
tab VoteIndex in 1/20

* Check party coding
tab Party

list Names Codes Party in 1/10

replace vote_result = subinstr(vote_result, char(34), "", .) // Remove all quotes
gen vote_result_dummy = (vote_result == "Passed")
gen party_dummy = (Party == "R")

gen party_clean  = regexs(1) if regexm(Names, "\(([DR])-[A-Z]+-[0-9]+\)")
gen state_abbrev = regexs(1) if regexm(Names, "\([DR]-([A-Z]+)-[0-9]+\)")
gen district_num = real(regexs(1)) if regexm(Names, "\([DR]-[A-Z]+-([0-9]+)\)")

* Check it worked
list Names state_abbrev district_num party_clean in 1/5

* Check for any failed parses (at-large or independents)
list Names state_abbrev district_num if district_num == . in 1/20

* Filter to Southeast minus Texas
keep if inlist(state_abbrev, "AL", "AR", "CT", "DE", "DC", "FL", "GA") | ///
        inlist(state_abbrev, "LA","ME", "MD", "MA", "MS""NH", "NJ", "NY") | ///
		inlist(state_abbrev, "NC","PA", "RI", "SC", "TN","VT", "VA", "WV")
* How many districts per state?
tab state_abbrev

* How many unique members?
codebook district_num

* True district count = unique state x district combinations
egen cd_key = concat(state_abbrev district_num), punct("-")
codebook cd_key

* Also useful for the eventual merge with IPUMS
tab cd_key

* label variables

la var Names          "Member name and district"
la var Codes          "Member bioguide/ICPSR ID"
la var Party          "Party affiliation (R/D)"
la var VoteIndex      "Roll call vote identifier"
la var Vote           "Raw vote cast (Yea/Nay/Present/Not Voting)"
la var Dummy_Yes      "1 = voted Yea, 0 = otherwise"
la var Congress       "Congress number"
la var Rep_Dim_1       "Member DW-NOMINATE score, 1st dimension"
la var Bill_Dim_1      "Vote policy location, DW-NOMINATE 1st dimension"
la var bill_number    "Bill identifier (e.g. HR1367)"
la var Rep_Number     "Unique member ID (use for clustering SEs)"
la var AbsDist        "Absolute ideological distance, member from vote"
la var party_dummy 	  "1 = Republican, 0 = Democrat"
la var Agg_Index 		"Numeric roll call vote identifier (101 obs per vote)"

sum Agg_Index
duplicates report Agg_Index
duplicates report VoteIndex


drop Freedom*Tea*
drop Squad
drop Dummy_No
drop vote_desc

* party dummy
count if Party != party_clean
count if party_dummy != GOP
drop party_clean 
drop GOP
tab Party party_dummy, miss   

order Congress Names Codes Rep_Number Party party_dummy bill_number VoteIndex Agg_Index Vote Dummy_Yes ///
		vote_result vote_result_dummy state_abbrev district_num cd_key  Rep_Dim_1 Bill_Dim_1 ///
		AbsDist Dim_1_Diff ToLeft ToRight

save "data/made/east_congress.dta", replace




