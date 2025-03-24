
	clear 
	tempfile countrylevel
	save `countrylevel', replace emptyok

*----------------------------------------------------------------------------*
* Get country level bullying means 
*----------------------------------------------------------------------------*	
	* 1. Bullying by type and group/male
	* Get the country level means
	foreach y in 19 23 {
	//	local y 23
		use "${clone}/01_harmonization/013_outputs/WLD/WLD_20`y'_TIMSS/WLD_20`y'_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear
		drop bullying_any 
		gen byte bullying_any =(bullying_pv==1 | bullying_ev_all ==1) if (bullying_ev_all != . | bullying_pv!=.)
		
		gen all = 1
		expand 2, gen(dup)

		keep if national_level == 1
		
		gen grade = .
		replace grade = 4 if idgrade <= 5 
		replace grade = 8 if idgrade >= 7
		
		replace male = -9 if dup == 1
		
		
		* Get country level mean
		collapse (mean) bullying_* violence_* [w=learner_weight], by(countrycode grade male)
		
		drop *_c_*
		gen year = 20`y'
		append using `countrylevel`v''
		save `countrylevel`v'', replace
		
		save "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.dta", replace
	
	}
	
	keep if male == -9
	* Wide by grade
	reshape wide bullying_index bullying_pv bullying_ev_all bullying_ev_online bullying_ev_trad bullying_any, i(year countrycode male) j(grade)
	
	* Wide by year
	reshape wide bullying_index4 bullying_pv4 bullying_ev_all4 bullying_ev_online4 bullying_ev_trad4 bullying_any4 bullying_index8 bullying_pv8 bullying_ev_all8 bullying_ev_online8 bullying_ev_trad8 bullying_any8, i(countrycode ) j(year )

	* Drop some stuff we don't need
	wbopendata, match(countrycode)
	drop if incomelevel== "HIC"
	
	// non - national HIC 
	drop if countryname == ""
	
	// non 2023 available
	drop if bullying_any82023 == . & bullying_any42023 == . 
	gen bullying_chg4 = ((bullying_any42023-bullying_any42019)/bullying_any42019)*100
	gen bullying_chg8 = ((bullying_any82023-bullying_any82019)/bullying_any82019)*100

	gen bullying_pp4 =(bullying_any42023-bullying_any42019)
	gen bullying_pp8 =(bullying_any82023-bullying_any82019)
	tabstat bullying_chg4 bullying_chg8 , stat(mean N)
	tabstat bullying_pp* , stat(mean N)

*----------------------------------------------------------------------------*
* Regressions 
*----------------------------------------------------------------------------*
	for g in 4 8 {
		
	* the data file is unique by student + subject 
	* pv01 scores in science/math are stored as "score", differentiated by "subject" variable
	* this data set only contains L/MIC countries 
	//local g 4
	use "${clone}/01_harmonization/013_outputs/WLD/G`g'_TIMSS.dta", clear
		
	* to z-score
	gen score_z=((score-r(mean))/r(sd))
	sum score
	replace score_z=((score-r(mean))/r(sd))
	
	* regular regression 
	eststo: reg score_z bullying_any, robust

	* school/country fixed effects
	eststo: reg score_z bullying_any i.idschool i.idcntry, robust
	
	* class/school fixed effects
	eststo: reg score_z bullying_any i.idclass i.idschool, robust
	
	* show table
	esttab, keep(bullying_any) se
	
	}
	
*----------------------------------------------------------------------------*
* Regressions 
*----------------------------------------------------------------------------*
	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/WLD_2023_TIMSS_v01_M_wrk_A_GLAD_CLO.dta", clear

drop se_* n_*
drop assessment
preserve
keep if year == 2023

//  male
replace subgroup = subinstr(subgroup,"=","_",.)
keep m_sdg* countrycode grade subgroup
reshape wide m_sdg411_math m_sdg411_scie, i(countrycode grade) j(subgroup,string)
reshape wide m_score_timss_mathbul_pv_0 m_score_timss_sciebul_pv_0 m_sdg411_sciebul_pv_0 m_sdg411_mathbul_pv_0 m_score_timss_mathbul_pv_1// m_score_timss_sciebul_pv_1 m_sdg411_sciebul_pv_1 m_sdg411_mathbul_pv_1 , i(countrycode grade) j(male)
foreach var of varlist m_sdg411* {
	replace `var'=(1-`var')*100
}

*----------------------------------------------------------------------------*
* INEQDECO 
*----------------------------------------------------------------------------*
	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/WLD_2023_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear

	gen grade = .
	replace grade = 4 if idgrade <= 5 
	replace grade = 8 if idgrade >= 7
	
	wbopendata, match(countrycode)
	drop if incomelevel == "HIC" | countrycode=="ROM" | national_level == 0
	encode countrycode, gen(cty)
	ineqdeco bullying_index [w=learner_weight] if grade==4, by(cty)
	
	*-----------------------------------*
	* Datt Ravallion				    *
	*-----------------------------------*
	clear 
	tempfile dr
	save `dr', replace emptyok 
	
	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2019_TIMSS/WLD_2019_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear
	gen year = 2019

	append using "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/WLD_2023_TIMSS_v01_M_wrk_A_GLAD_ALL.dta"
	
	replace year = 2023 if year == .
	
	keep if national_level == 1
		
	gen grade = .
	replace grade = 4 if idgrade <= 5 
	replace grade = 8 if idgrade >= 7
	
	
	* for this analysis, keep countries with both years available #	
	bysort countrycode year: gen index = _n
	bysort countrycode index (year): gen years = _N
	
	replace years = . if years == 1
	bysort countrycode: fillmissing years, with(any)
	drop if years == .
	
	gen pline = 9.2

	wbopendata, match(countrycode)
	drop if incomelevel == "HIC" | national_level == 0 | countrycode == "ROM"
	levelsof countrycode, local(cnt)
	foreach c in `cnt' { 
		noi di "`c'"
	preserve 
		
	cap qui drdecomp bullying_index if grade ==8 & countrycode == "`c'", by(year) varpl(pline) //mpl(9.2 7.4) // about monthly or about weekly
	if _rc != 0 {
		noi di "check `c' later"
	}
	else {
	mat b = r(shapley)
	svmat double b, names(col)
	
	keep Indicator Effect effect1 effect2 effect_avg
	gen countrycode = "`c'"
	drop if effect1 == .
	append using `dr'
	save `dr', replace
	}
	restore
		
	}
	use `dr', clear
	

	
*----------------------------------------------------------------------------*
* X% of principals with students  
*----------------------------------------------------------------------------*
	use "${clone}/01_harmonization/013_outputs/WLD/G8_TIMSS.dta", clear
	drop if subject== "math"

	collapse (mean) bullying_any bullying_c_all school_weight [w=learner_weight], by(countrycode idschool)
	//foreach b in 0 25 50 75 
	gen byte bullying_0 = bullying_any < .25 //>= .5
	gen byte bullying_25 = bullying_any >= .25 & bullying_any < .5 //>= .5
	gen byte bullying_50 = bullying_any >= .5 & bullying_any < .75 //>= .5
	gen byte bullying_75 = bullying_any >= .75 //>= .5
	
	collapse (mean) bullying_c_all  [w=school_weight], by(countrycode bullying_50)
	// bullying_0 bullying_25 bullying_50 bullying_75
	// tab bullying_any
		* Bullying is a problem
	*<_bullying_c_all_>*
	gen bullying_c_all = .
	foreach b in h i {
		replace bullying_c_all = 1 if bcbg14`b' >= 3 
		replace bullying_c_all = 0 if bcbg14`b' < 3 & bullying_c_all == .
	}