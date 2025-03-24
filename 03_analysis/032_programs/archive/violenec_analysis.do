		
	clear 
	tempfile countrylevel
	save `countrylevel', replace emptyok

	* Get the country level means
	foreach y in 19 23 {
		foreach agg in all ses_c urban {

		use "${clone}/01_harmonization/013_outputs/WLD/WLD_20`y'_TIMSS/WLD_20`y'_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear
		gen all = 1
		expand 2, gen(dup)

		keep if national_level == 1
		
		gen grade = .
		replace grade = 4 if idgrade <= 5 
		replace grade = 8 if idgrade >= 7
		
		replace male = -9 if dup == 1
		
			
		
		* Get country level mean
		collapse (mean) bullying_* violence_* [w=learner_weight], by(countrycode grade male `agg')
		
		gen group = "`agg'"
		ren `agg' subgroup 
		
		gen year = 20`y'
		append using `countrylevel`v''
		save `countrylevel`v'', replace
		
		save "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.dta", replace
	
	}
	}
	e
	*-----------------------------------*
	* Get country mean from school vars *
	*-----------------------------------*
	clear 
	tempfile countrylevel
	save `countrylevel', replace emptyok

	* Get the country level means
	foreach y in 19 23 {

		use "${clone}/01_harmonization/013_outputs/WLD/WLD_20`y'_TIMSS/WLD_20`y'_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear
		expand 2, gen(dup)

		
		* get school level data
		keep if national_level == 1
		
		gen grade = .
		replace grade = 4 if idgrade <= 5 
		replace grade = 8 if idgrade >= 7
		replace male = -9 if dup == 1		
		
		* Get country level mean
		collapse (mean) bullying_* violence_* [w=school_weight], by(countrycode grade male)
		
		gen year = 20`y'
		append using `countrylevel'
		save `countrylevel', replace
		
		//save "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.dta", replace
	
	}
	
	keep countrycode male grade year *_c_*
	
	* Combine the school questions and student questions 
	merge 1:1 countrycode male grade year using "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.dta", nogen

	save "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.dta", replace

	*-----------------------------------*
	* School level means			    *
	*-----------------------------------*
	clear 
	tempfile countrylevel
	save `countrylevel', replace emptyok

	* Get the country level means
	foreach y in 19 23 {
		//local y 19
		use "${clone}/01_harmonization/013_outputs/WLD/WLD_20`y'_TIMSS/WLD_20`y'_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear

		
		* get school level data
		keep if national_level == 1
		
		gen grade = .
		replace grade = 4 if idgrade <= 5 
		replace grade = 8 if idgrade >= 7
		
		* Get country level mean
		collapse (mean) bullying_* violence_* [w=learner_weight], by(countrycode grade idschool)
		
		drop *_c_*
		
		foreach v of varlist bullying_* {
			gen byte `v'25 = (`v' >= .25 & `v' < .5)
			gen byte `v'50 = (`v' >= .5 & `v' < .75)
			gen byte `v'75 = (`v' >= .75)
			drop `v'
		}
		
		collapse (mean) bullying_*, by(countrycode grade)
		
		gen year = 20`y'
		gen male = -9
		append using `countrylevel'
		save `countrylevel', replace
		
		//save "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.dta", replace
	
	}
	
	keep countrycode grade *25 *50 *75 year male
	
	
	merge 1:1 countrycode male grade year using "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.dta", nogen
	
	lab var bullying_c_all "% schools identify bullying as a moderate/severe problem"
	lab var violence_c_all "% schools identify violence as a moderate/severe problem"
	lab var violence_c_cp "% schools identify violence from teachers as moderate/severe problem"
	lab var violence_c_teach "% schools identify violence to teachers as a moderate/severe problem"
	
	drop *index25 *index50 *index75
	foreach p in 25 50 75 {
		lab var bullying_pv`p' "% schools where `p'% students reported bullying"
		lab var bullying_ev_all`p' "% schools where `p'% students reported emotional bullying"
		lab var bullying_pv`p' "% schools where `p'% students reported physical bullying"
		lab var bullying_ev_online`p' "% schools where `p'% students reported online bullying"
		lab var bullying_ev_trad`p' "% schools where `p'% students reported traditional forms of bullying"

	}
	
	sort countrycode year grade male 
	order countrycode year grade male 
	wbopendata, match(countrycode)
	save "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.dta", replace
	export delimited "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_all.csv", replace
	
	*-----------------------------------*
	* Between/within inequality		    *
	*-----------------------------------*
	clear 
	tempfile ineq
	save `ineq', replace emptyok 

	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2019_TIMSS/WLD_2019_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear
	gen year = 2019

	append using "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/WLD_2023_TIMSS_v01_M_wrk_A_GLAD_ALL.dta"
	
	replace year = 2023 if year == .
	
	keep if national_level == 1
		
	gen grade = .
	replace grade = 4 if idgrade <= 5 
	replace grade = 8 if idgrade >= 7
	
	egen id = group(countrycode idschool)
	encode countrycode, gen(cty)
	
	//preserve 

	keep if year == 2023
	wbopendata, match(countrycode)
	drop if incomelevel == "HIC" | national_level == 0 | countrycode == "ROM"
	
	levelsof countrycode, local(cnt)
	foreach c in `cnt' {
		preserve
		noi di "`c'"
		//local c "ZAF"
		cap qui ineqdeco bullying_index [aw = learner_weight] if grade == 8 & countrycode == "`c'", by(idschool)

		if _rc == 0 {
		mat b = r(between_ge0)
		mat w = r(within_ge0)
		
		svmat double b, names(col)
		cap ren c1 b
		cap svmat double w, names(col)
		cap ren c1 w
		
		keep w b 
		drop if w == . 
		gen countrycode = "`c'"
		
		append using `ineq'
		save `ineq', replace
		}
		else {
			noi di "skipping, no data"
		}
		restore 
	}
	use `ineq', clear
	
	gen n = 1
	reshape wide b w, i(countrycode) j(n)

	
//	ren *w w_*
//	ren *b b_*
	gen n = _n
	
	* between pct 
	gen b_pct = (b1/(b1+w1))*100
	gen w_pct = (w1/(b1+w1))*100
	
	gen bw_total = b1 + w1
	
	order countrycode b1 w1 bw_total

	reshape long b_ w_, i(n) j(countrycode, string)
	
	save "${clone}/01_harmonization/013_outputs/ineqdeco.dta", replace
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
	
