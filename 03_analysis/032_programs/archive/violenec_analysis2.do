	clear 
	tempfile countrylevel
	save `countrylevel', replace emptyok

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
	
	drop if male == -9
	
	reshape wide bullying_index bullying_pv bullying_ev_all bullying_ev_online bullying_ev_trad bullying_any, i(year countrycode male) j(grade)
	
	reshape wide bullying_index4 bullying_pv4 bullying_ev_all4 bullying_ev_online4 bullying_ev_trad4 bullying_any4 bullying_index8 bullying_pv8 bullying_ev_all8 bullying_ev_online8 bullying_ev_trad8 bullying_any8, i(year countrycode ) j(male)

	ren *8* *_8_*
	ren *4* *_4_*
	
	reshape wide bullying_index_4_0 bullying_pv_4_0 bullying_ev_all_4_0 bullying_ev_online_4_0 bullying_ev_trad_4_0 bullying_any_4_0 bullying_index_8_0 bullying_pv_8_0 bullying_ev_all_8_0 bullying_ev_online_8_0 bullying_ev_trad_8_0 bullying_any_8_0 bullying_index_4_1 bullying_pv_4_1 bullying_ev_all_4_1 bullying_ev_online_4_1 bullying_ev_trad_4_1 bullying_any_4_1 bullying_index_8_1 bullying_pv_8_1 bullying_ev_all_8_1 bullying_ev_online_8_1 bullying_ev_trad_8_1 bullying_any_8_1, i(countrycode) j(year)
	
	ren *2019 *_2019
	ren *2023 *_2023

	drop if bullying_ev_all_4_0_2023 == .
	
	wbopendata, match(countrycode)
	drop if incomelevel == "HIC"
	drop region regionname adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename

	gen bullying_chg4 = ((bullying_any_4_1_2023-bullying_any_4_1_2019)/bullying_any_4_1_2019)*100
	gen bullying_chg8 = ((bullying_any_8_1_2023-bullying_any_8_1_2019)/bullying_any_8_1_2019)*100

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
		//expand 2, gen(dup)

		
		* get school level data
		keep if national_level == 1
		
		gen grade = .
		replace grade = 4 if idgrade <= 5 
		replace grade = 8 if idgrade >= 7
		//replace male = -9 if dup == 1		
		
		
		
		* Get country level mean
		collapse (mean) *_c* [w=school_weight], by(countrycode grade)
		
		gen year = 20`y'
		append using `countrylevel'
		save `countrylevel', replace
		
	
	}
	
	save "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_school.dta", replace
	
	
	wbopendata, indicator(ny.gdp.pcap.pp.kd) clear long latest 
	drop year
	merge 1:m countrycode using "${clone}/01_harmonization/013_outputs/WLD/TIMSS_analysis_school.dta", nogen keep(matched using)
	drop if incomelevel == "HIC"
	drop if countryname ==""
	
	drop countryname region regionname adminregion adminregionname incomelevelname lendingtype lendingtypename

	reshape wide bullying_c_all violence_c_all violence_c_cp violence_c_teach, i(countrycode year) j(grade)
	
	drop if inlist(countrycode, "EGY", "CIV", "MYS", "PAK", "RUS")
	drop if inlist(countrycode, "PSE", "LBN", "PHL")
	
	reshape wide bullying_c_all4 violence_c_all4 violence_c_cp4 violence_c_teach4 bullying_c_all8 violence_c_all8 violence_c_cp8 violence_c_teach8, i(countrycode) j(year)
	drop if bullying_c_all42019 == . 
	
	foreach var of varlist *_c* {
		replace `var' = `var'*100
	}
	
	*--------------------------------------------------------------*
	* T-Test 													   *
	*--------------------------------------------------------------*
	clear
	tempfile pvals 
	save `pvals', replace emptyok
	
	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/WLD_2023_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear

	gen grade = .
	replace grade = 4 if idgrade <= 5 
	replace grade = 8 if idgrade >= 7
		
	gen disad = 1 if inlist(ses_c, 3)
	replace disad = 0 if inlist(ses_c,1,2)
	
	levelsof countrycode, local(cnt)
	
	qui foreach g in 4 8 {
		foreach c in `cnt' {
			foreach y in bullying_pv bullying_ev_all bullying_ev_online bullying_ev_trad {
				foreach grp in disad urban {
					noi di "`c' grade `g' `y', `grp'"
	preserve
	
	cap ttest `y' if grade == `g' & countrycode == "`c'", by(`grp')
	
	* continue analysis if the combination exists for the country
	if _rc == 0 {
	mat p = r(p)
	mat e = r(mu_2)-r(mu_1)
	
	svmat double p
	svmat double e
	
	drop if p1 == . 
	keep p1 e1
	ren e1 effect_size
	
	gen grade = `g'
	gen countrycode = "`c'"
	gen y = "`y'"
	gen group = "`grp'"
	
	append using `pvals'
	save `pvals', replace
	* end skip case 
	}
	
	restore 
	
	* next group
	}
	* next outcome
	}
	* next country
	}
	* next grade
	}
	
	use `pvals', clear
	
	gen byte sig = p1 < 0.05
	
	save "${clone}/03_analysis/033_outputs/ttests_bulbygroup.dta", replace
	
	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/WLD_2023_TIMSS_v01_M_wrk_A_GLAD_ALL.dta", clear

	* warning: This takes a long time, just save this once and don't do it again.
	//wbopendata,match(countrycode)
	//save"${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/2023_GLAD_incomelvl.dta", replace
	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/2023_GLAD_incomelvl.dta", clear

		
	gen grade = .
	replace grade = 4 if idgrade <= 5 
	replace grade = 8 if idgrade >= 7
	

	drop if incomelevel == "HIC" | countryname == ""
	replace countryname = "Iran" if strpos(countryname, "Iran")>0
	replace countryname = "Palestine" if strpos(countryname, "West Bank")>0

	
	levelsof countryname, local(cnt)	
	global grphtitles ""
	
	//lab def exppv 0 "Did Not Experience" 1 "Experienced"
	lab val bullying_pv exppv
	lab val bullying_ev_all exppv

	foreach c in `cnt' {
		noi di "`c'"
	cap alorenz score_timss_math_01 if grade == 8 & countryname=="`c'", by(bullying_pv) gp points(100) ///
	title("`c'") ytitle("") xtitle("")  yline(475)
	
	if _rc == 0 {
	local cnt = substr("`c'", 1,3)
	graph save "`cnt'", replace
	
	global grphtitles = "${grphtitles}" + " `cnt'.gph"
	}
}

	grc1leg2 ${grphtitles}, ycommon xcommon graphregion(color(white)) b2title("Share of Students") l1title("TIMSS Score, Math") //  
