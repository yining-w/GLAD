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