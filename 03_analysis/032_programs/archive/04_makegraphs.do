	*------------------------------------------------*
	* graph 1 for datawrapper: overall prevalence    *
	*------------------------------------------------*
	global clone "C:/Users/YiNingWong/Github/GLAD"
	use "${clone}/03_analysis/033_outputs/TIMSS_analysis_all.dta", clear
	keep if group == "all" & male == -9
	
	drop *_c_*
	drop bullying_index bullying_any
	
	
	foreach v of varlist bullying* {
		replace `v' = `v'*100
	}
	
	reshape wide bullying_pv bullying_ev_all bullying_ev_online bullying_ev_trad, i(countrycode male subgroup grade group) j(year)
	
	br if grade == 4
	
	* we don't care about countries without 2023 data
	drop if bullying_ev_all2023 == .
	
	wbopendata, match(countrycode)
	drop if incomelevel == "HIC"
	drop countrycode region adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename
	
	* romania countrcode is coded wrong but drop if anyway cause it's hic
	drop if countryname ==""
	
	replace countryname = "Iran" if strpos(countryname, "Iran")>0
	replace countryname = "Palestine" if strpos(countryname, "West Bank")>0
	
	*------------------------------------------------*
	* graph 2 for datawrapper: prevalence by sex	 *
	*------------------------------------------------*
	use "${clone}/03_analysis/033_outputs/TIMSS_analysis_all.dta", clear

	keep if group == "all" & male != -9
	keep if year == 2023
	
	drop *_c_*
	drop bullying_index bullying_any bullying_ev_online bullying_ev_trad bullying_any 
	
	reshape wide bullying_pv bullying_ev_all, i(countrycode subgroup grade group year) j(male)
	
	foreach v of varlist bullying* {
		replace `v' = `v'*100
	}
	
	wbopendata,match(countrycode)
	drop if incomelevel == "HIC"
	drop countrycode region adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename
	
	* romania countrcode is coded wrong but drop if anyway cause it's hic
	drop if countryname ==""
	
	replace countryname = "Iran" if strpos(countryname, "Iran")>0
	replace countryname = "Palestine" if strpos(countryname, "West Bank")>0
	
	br if grade == 8
	
	*------------------------------------------------*
	* graph 3 bmp by bullying by sex:                *
	*------------------------------------------------*
	use "${clone}/03_analysis/033_outputs/WLD_2023_TIMSS_v01_M_wrk_A_GLAD_CLO.dta", clear
	
//	keep if year == 2023
	
	keep countrycode grade male subgroup m_sdg411_math m_sdg411_scie
	
	foreach v of varlist m_* {
		replace `v'=`v'*100
	}
	
	replace subgroup = subinstr(subgroup,"=","_",.)
	
	* keep pv and ev
	drop if strpos(subgroup,"_c_")>0 | subgroup =="all" | strpos(subgroup,"_o_")>0 | strpos(subgroup,"any")>0 | strpos(subgroup,"trad")>0
	
	reshape wide m_sdg411_scie m_sdg411_math, i(countrycode grade) j(subgroup, string) 
	
	* temp, don't distinguish between male/female
	collapse (mean) m_* , by(grade countrycode)
	wbopendata,match(countrycode)
	drop if incomelevel == "HIC"
	drop countrycode region adminregion adminregionname incomelevel incomelevelname lendingtype lendingtypename
	
	* romania countrcode is coded wrong but drop if anyway cause it's hic
	drop if countryname ==""
	
	replace countryname = "Iran" if strpos(countryname, "Iran")>0
	replace countryname = "Palestine" if strpos(countryname, "West Bank")>0
	
	* change to "not reaching"
	foreach v of varlist m_* {
		replace `v'=100-`v'
	}
		
	ren *sdg411* *ld*
	/*
	reshape wide m_ld_sciebul_ev_all_0 m_ld_mathbul_ev_all_0 m_ld_sciebul_ev_all_1 m_ld_mathbul_ev_all_1 m_ld_sciebul_pv_0 m_ld_mathbul_pv_0 m_ld_sciebul_pv_1 m_ld_mathbul_pv_1, i(regionname grade countryname) j(male)
	
	ren *0 *f 
	ren *1 *m
	ren m_* *
	
	br if grade == 4
	*/
	*----------------------------*
	* graph 3 v2:                *
	*----------------------------*
	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/2023_GLAD_incomelvl.dta", clear

		
	//gen grade = .
	//replace grade = 4 if idgrade <= 5 
	///replace grade = 8 if idgrade >= 7
	

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
	title("`c'") ytitle("") xtitle("")  yline(400)
	
	if _rc == 0 {
	local cnt = substr("`c'", 1,3)
	graph save "`cnt'", replace
	
	global grphtitles = "${grphtitles}" + " `cnt'.gph"
	}
}

	grc1leg2 ${grphtitles}, ycommon xcommon graphregion(color(white)) b2title("Share of Students") l1title("TIMSS Score, Math") //  
	
	*-------------------------------*
	* graph 4 b/w within inequality *
	*-------------------------------*
	* see "${clone}/01_harmonization/013_outputs/ineqdeco.dta" from violence_analysis.do
	
	*-----------------------------------------------------------*
	* graph 5 - schools share of students experiencing bullying *
	*-----------------------------------------------------------*
	* Get the country level means
	local y 23
	use "${clone}/01_harmonization/013_outputs/WLD/WLD_2023_TIMSS/2023_GLAD_incomelvl.dta", clear
	drop bullying_any
	gen byte bullying_any = bullying_pv == 1 | bullying_ev_all ==1
	tabstat bullying_any, by(countrycode)

		
		* get school level data
		keep if national_level == 1
		
		* Get country level mean
		collapse (mean) bullying_*  [w=learner_weight], by(countrycode grade idschool)
		
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
	
	wbopendata, match(countrycode)
	keep if incomelevel != "HIC" & countryname != ""
	
		keep countryname grade *ev_all* *pv* bullying_any* regionname 
		
		foreach v of varlist bullying* {
			replace `v' = `v'*100
		}
		
		gen bullying_any0 = 100-bullying_any25-bullying_any50-bullying_any75
		gen bullying_pv0 = 100-bullying_pv25-bullying_pv50-bullying_pv75
		gen bullying_ev_all0 = 100-bullying_ev_all25-bullying_ev_all50-bullying_ev_all75
		
		order countryname regionname bullying_pv0 bullying_pv* bullying_ev* bullying_ev* bullying_any0 bullying_any*

		br if grade ==8
		
	*-----------------------------------------------------------*
	* graph 6 - schools share of students experiencing bullying *
	*-----------------------------------------------------------*
	use "${clone}/03_analysis/033_outputs/timss_analysis_school.dta", clear

	wbopendata, match(countrycode)
	
	drop if incomelevel =="HIC" | countryname ==""
	
	keep countryname regionname grade bullying_c_all violence_c_cp year
	
	reshape wide bullying_c_all violence_c_cp, i(countryname regionname grade) j(year)
	drop if bullying_c_all2023 == .
	br if grade == 8
	
	foreach var of varlist *_c* {
		replace `var' = `var'*100
	}
	
	
	*-----------------------------------------------------------*
	* graph 7 - ttests *
	*-----------------------------------------------------------*
	use "${clone}/03_analysis/033_outputs/ttests_bulbygroup.dta", clear
	
	wbopendata, match(countrycode)
	
	drop if incomelevel == "HIC" | countryname == ""