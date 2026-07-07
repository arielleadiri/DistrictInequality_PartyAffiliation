*******************************************************************************
******** main_project.do
******** District Inequality and Party Affiliation Effects on Votes
******** for Majority Sponsored Bills in the 115th Congress
******** By Arielle Adiri and Martie Ehly
******** 4/13
******** Regressions and tests
*******************************************************************************

cls
clear all
set more off


*** Set the correct path here
cd "/Users/Owner/OneDrive/Desktop/bu_s26/metrics/research_project"


*** code
use "data/made/analysis_df.dta"

/*******************************************************************************
                choosing specific bills having to do with poverty
*******************************************************************************/
*or change to just HR1628 -> medicare bill along party lines -> need probit (switala said no)
replace bill_number = subinstr(bill_number, char(34), "", .)
*keep if bill_number == "HR1628"
keep if bill_number == "HR1" && VoteIndex == "C115V699"


* Confirm sample size and composition
count
tab bill_number
tab Party Dummy_Yes

* generating interaction term
gen ratio_x_party = ratio_90_10 * repub_dummy

gen mean_x_party = mean_inc * repub_dummy

*descriptive stats
estpost summarize Dummy_Yes ratio_90_10 mean_inc pct_nonwhite pct_poverty repub_dummy, detail

* Export to LaTeX
/* unhide to run on HR1626
esttab using "output/descriptives.tex", replace ///
    cells("count(fmt(0) label(Obs.)) mean(fmt(3) label(Mean)) sd(fmt(3) label(Std. Dev.)) min(fmt(3) label(Min)) max(fmt(3) label(Max))") ///
    title("Descriptive Statistics HR1628") ///
    nonumber ///
    booktabs ///
    fragment ///
    prehead("\begin{table}[htbp]" "\centering" "\caption{Descriptive Statistics}" "\label{tab:descriptives}" "\begin{tabular}{lccccc}" "\toprule") ///
    postfoot("\bottomrule" "\end{tabular}" "\end{table}")
*/
	
* unhide to run on HR1
esttab using "output/descriptives1.tex", replace ///
    cells("count(fmt(0) label(Obs.)) mean(fmt(3) label(Mean)) sd(fmt(3) label(Std. Dev.)) min(fmt(3) label(Min)) max(fmt(3) label(Max))") ///
    title("Descriptive Statistics HR1") ///
    nonumber ///
    booktabs ///
    fragment ///
    prehead("\begin{table}[htbp]" "\centering" "\caption{Descriptive Statistics}" "\label{tab:descriptives}" "\begin{tabular}{lccccc}" "\toprule") ///
    postfoot("\bottomrule" "\end{tabular}" "\end{table}")
*/ 

********************************************************************************
* MODEL 1: Simple — inequality only, no controls
********************************************************************************

reg Dummy_Yes ratio_90_10,  
estimates store m1
*estat hettest -> none found Prob > chi2 = 0.4447

********************************************************************************
* MODEL 2: Add controls (no party dummy)
********************************************************************************

reg Dummy_Yes ratio_90_10 mean_inc pct_nonwhite pct_poverty,  
estimates store m2
*estat hettest -> none found Prob > chi2 = 0.6438

* Models 1-2: hettest insignificant (p=0.44, p=0.64) so plain OLS reported
 
********************************************************************************
* MODEL 3: Add party dummy
********************************************************************************

reg Dummy_Yes ratio_90_10 mean_inc pct_nonwhite pct_poverty repub_dummy, 
estimates store m3
estat hettest //-> yep Prob > chi2 = 0.0000

reg Dummy_Yes ratio_90_10 mean_inc pct_nonwhite pct_poverty repub_dummy, vce (robust) 
estimates store m3_1


********************************************************************************
* MODEL 4: Add interaction term
********************************************************************************

reg Dummy_Yes ratio_90_10 mean_inc pct_nonwhite pct_poverty  ///
     repub_dummy ratio_x_party 
estimates store m4
estat hettest //-> yep Prob > chi2 = 0.0000


reg Dummy_Yes ratio_90_10 mean_inc pct_nonwhite pct_poverty  ///
     repub_dummy ratio_x_party , vce(robust) 
estimates store m4_1
vif
*ofc repub_dummy and interaction term have high VIFs, they are mechanically correlated

********************************************************************************
* MODEL 5: Centering the 90/10 ratio to lower VIFs?
********************************************************************************
egen ratio_mean = mean(ratio_90_10)
gen ratio_centered = ratio_90_10 - ratio_mean
gen ratio_x_party_new = ratio_centered * repub_dummy

reg Dummy_Yes ratio_centered mean_inc pct_nonwhite pct_poverty ///
    repub_dummy ratio_x_party_new, vce(robust)
estimates store m5_1
vif


********************************************************************************
*checks for multicollinearity	
*vif 
*checks for heteroskedasticity
*estat hettest
*VIF Interpretation
*1–5 No problem
*5–10 Moderate, worth noting
*>10 Serious multicollinearity


********************************************************************************
* LPM OUT-OF-BOUNDS CHECK (to see if you need to fix)
********************************************************************************

quietly reg Dummy_Yes ratio_90_10 mean_inc pct_nonwhite pct_poverty ///
    repub_dummy ratio_x_party,  
predict yhat, xb
count if yhat < 0 | yhat > 1
di "Share out of bounds: " r(N)/_N

********************************************************************************
*                     Unhide to run on HR1628
********************************************************************************
/*

* Table 1: Main specification (models 1-3)
esttab m1 m2 m3_1 using "output/results_main.tex", replace ///
    label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "Controls" "Party") ///
    scalars("r2 R-squared") ///
    addnotes("Robust standard errors in parentheses from Model 3 onwards." ///
             "Dependent variable: Vote Yes on HR1628.") ///
    booktabs fragment ///
    prehead("\begin{tabular}{lccc}" "\toprule") ///
    postfoot("\bottomrule" "\end{tabular}")

* Table 2: Interaction only (drop centered column)
esttab m5_1 using "output/results_interaction.tex", replace ///
    label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Interaction") ///
    scalars("r2 R-squared") ///
    addnotes("Robust standard errors in parentheses." ///
             "Dependent variable: Vote Yes on HR1628.") ///
    booktabs fragment ///
    prehead("\begin{tabular}{lc}" "\toprule") ///
    postfoot("\bottomrule" "\end{tabular}")

* Table 3: Full appendix table
esttab m1 m2 m3_1 m4_1 using "output/results_full.tex", replace ///
    label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "Controls" "Party" "Interaction") ///
    scalars("r2 R-squared") ///
    addnotes("Robust standard errors in parentheses from Model 3 onwards." ///
             "Dependent variable: Vote Yes on HR1628.") ///
    booktabs fragment ///
    prehead("\begin{tabular}{lcccc}" "\toprule") ///
    postfoot("\bottomrule" "\end{tabular}")
	
*/	

********************************************************************************
*                     Unhide to run on HR1
********************************************************************************
*

* Table 1: Main specification (models 1-3)
esttab m1 m2 m3_1 using "output/results_main1.tex", replace ///
    label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "Controls" "Party") ///
    scalars("r2 R-squared") ///
    addnotes("Robust standard errors in parentheses from Model 3 onwards." ///
             "Dependent variable: Vote Yes on HR1.") ///
    booktabs fragment ///
    prehead("\begin{tabular}{lccc}" "\toprule") ///
    postfoot("\bottomrule" "\end{tabular}")

* Table 2: Interaction only (drop centered column)
esttab m5_1 using "output/results_interaction1.tex", replace ///
    label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Interaction") ///
    scalars("r2 R-squared") ///
    addnotes("Robust standard errors in parentheses." ///
             "Dependent variable: Vote Yes on HR1.") ///
    booktabs fragment ///
    prehead("\begin{tabular}{lc}" "\toprule") ///
    postfoot("\bottomrule" "\end{tabular}")

* Table 3: Full appendix table
esttab m1 m2 m3_1 m4_1 using "output/results_full1.tex", replace ///
    label b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    mtitles("Baseline" "Controls" "Party" "Interaction") ///
    scalars("r2 R-squared") ///
    addnotes("Robust standard errors in parentheses from Model 3 onwards." ///
             "Dependent variable: Vote Yes on HR1.") ///
    booktabs fragment ///
    prehead("\begin{tabular}{lcccc}" "\toprule") ///
    postfoot("\bottomrule" "\end{tabular}")


