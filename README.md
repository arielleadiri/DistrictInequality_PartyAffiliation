# District Inequality and Party Affiliation Effects on Congressional Voting

**Authors:** Arielle Adiri and Martie Ehly

## Overview
This project investigates whether district-level income inequality predicts how 
members of the U.S. House of Representatives vote on major legislation, and 
whether that relationship differs by party affiliation. Using data from the 
115th Congress, we analyze roll-call votes on two bills, HR1628 (ACA repeal) 
and HR1 (tax reform), against district-level income inequality (90/10 ratio), 
mean income, racial composition, and poverty rate.

## Motivation
Modern political science broadly treats partisanship as the dominant driver 
of congressional voting behavior, often at the expense of constituent-level 
economic factors. This project asks a narrower question: even within a 
strongly partisan sorting, does district inequality retain any independent 
explanatory power, particularly for bills with direct redistributive 
consequences?

**Hypothesis 1:** District income inequality (90/10 ratio) predicts roll-call 
voting behavior.

**Hypothesis 2:** The effect of inequality on voting behavior differs by 
representative's party affiliation.

## Data
This project uses:
- Congressional roll-call vote data for the 115th Congress, originally 
  scraped from congress.org and shared by a research contact at Indiana 
  University
- District-level income and demographic data (90/10 ratio, mean income, 
  percent nonwhite, percent below poverty line) constructed from PUMA-level 
  data
- A crosswalk from Geocorr 2018 (Geographic Correspondence Engine) to map 
  PUMA-level data to congressional districts

**Data is not included in this repository.** Some source data was shared 
informally by a research contact and is not ours to redistribute; other 
components (PUMA-level income data, Geocorr crosswalks) are publicly 
available but require separate access. To reproduce this analysis:
1. Congressional roll-call data: available via [congress.org](https://www.congress.org) 
   or the official Congress.gov records for the 115th Congress
2. District demographic and income data: derived from PUMA-level American 
   Community Survey data (available via [IPUMS USA](https://usa.ipums.org/usa/))
3. Geographic crosswalk: [Geocorr 2018](https://mcdc.missouri.edu/applications/geocorr2018.html)

## Methodology
- Restricted analysis to House members from northeastern and southeastern 
  states in the 115th Congress
- Constructed a linear probability model regressing `Dummy_Yes` (1 = voted 
  Yea) on the district 90/10 income ratio, adding controls incrementally: 
  mean income, percent nonwhite, percent below poverty line, then party 
  affiliation
- Tested for heteroskedasticity (Breusch-Pagan/hettest) and applied robust 
  standard errors from Model 3 onward
- Added an interaction term between the 90/10 ratio and party affiliation to 
  test whether inequality's effect on voting differs by party
- Diagnosed and corrected multicollinearity between the party dummy and the 
  interaction term (VIF > 18) by centering the 90/10 ratio at its sample mean 
  before constructing the interaction
- Checked linear probability model validity by confirming the share of 
  predicted values falling outside the [0,1] bound

## Key Findings

| Variable | Baseline | Controls | Party |
|---|---|---|---|
| 90/10 ratio | -0.038*** | -0.014 | -0.001 |
| Mean income | | -0.000*** | -0.000** |
| Percent nonwhite | | -1.125*** | -0.166 |
| Percent below poverty line | | 0.145 | -0.281 |
| Party (1 = Republican) | | | 0.770*** |
| Constant | 0.950*** | 1.727*** | 0.508*** |
| Observations | 178 | 178 | 178 |
| R-squared | 0.089 | 0.411 | 0.773 |

*Table: HR1628 (ACA repeal). Robust standard errors omitted here for readability; 
see full regression output in `output/`. \*p<0.10, \*\*p<0.05, \*\*\*p<0.01*

- District income inequality (90/10 ratio) is a significant negative predictor 
  of Yea votes in the baseline model, but loses significance once income and 
  demographic controls are added
- Party affiliation dominates the explanation of voting behavior once 
  introduced, R-squared jumps from 0.411 to 0.773 for HR1628 alone

**Key result:** For HR1628, district inequality's effect on voting differs 
significantly by party (interaction coefficient = -0.037, p<0.10). Republican 
representatives from more unequal districts were slightly less likely to vote 
Yea, even after accounting for near-total partisan sorting. For HR1 (tax 
reform), no such interaction effect exists, party affiliation perfectly 
predicts the vote regardless of district inequality.

This contrast suggests that bills with more direct, visible impact on 
low-income constituents may create small but measurable cross-pressure on 
representatives, even amid strong partisan sorting, while bills without that 
direct visibility see purely partisan voting.

## Repository Structure
```
district_inequality_votes/
├── code/
│   ├── main_dataset_construct.do
│   ├── cleaning_IPUMSdata.do
│   ├── cleaning_allmembersstacked.do
│   └── main_project.do
├── data/
│   ├── raw/          # Not tracked; see Data section above
│   └── made/          # Not tracked; see Data section above
├── output/             # Regression tables (.tex) and descriptive statistics
├── .gitignore
└── README.md
```
## Requirements
Stata (used: version 17+). No additional packages required beyond base Stata 
and `estout`/`esttab` for table export.

## Limitations
- Sample restricted to northeastern and southeastern states; effects may 
  differ in western districts
- Geocorr-based crosswalk introduces measurement error when mapping PUMA 
  data to congressional districts
- Analysis reflects a single Congress (115th); a panel extension across 
  multiple sessions with member fixed effects would strengthen causal claims

## Next Steps
- Extend to a panel dataset across multiple congressional sessions with 
  member fixed effects
- Incorporate DW-NOMINATE ideology scores to separate party affiliation from 
  individual ideological positioning
- Expand geographic scope beyond northeastern/southeastern states

## Authors
Arielle Adiri and Martie Ehly