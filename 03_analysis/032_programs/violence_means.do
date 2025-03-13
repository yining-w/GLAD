*----------------------------------------------------------------------------*
* Get country level bullying means 
*----------------------------------------------------------------------------*
	clear 
	tempfile countrylevel
	save `countrylevel', replace emptyok

	* 1. Bullying by type and group/male
	* Get the country level means
	foreach y in 19 23 {
		//local y 23
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
