*=========================================================================*
* GLOBAL LEARNING ASSESSMENT DATABASE (GLAD)
* Project information at: https://github.com/worldbank/GLAD
*
* Metadata to be stored as 'char' in the resulting dataset (do NOT use ";" here)
local region      = "WLD"
local year        = "2023"
local assessment  = "TIMSS"
local master      = "v01_M"
local adaptation  = "wrk_A_GLAD"
local module      = "ALL"
local ttl_info    = "Joao Pedro de Azevedo [eduanalytics@worldbank.org]"
local dofile_info = "last modified by Ahmed Raza in January 29, 2021"

  // Set up folders in clone and define locals to be used in this do-file
  glad_local_folder_setup , r("`region'") y("`year'") as("`assessment'") ma("`master'") ad("`adaptation'")
  local temp_dir     "`r(temp_dir)'"
  local output_dir   "`r(output_dir)'"
  local surveyid     "`r(surveyid)'"
  local output_file  "`surveyid'_`adaptation'_`module'"

  // If user does not have access to datalibweb, point to raw microdata location
    local input_dir	= "C:/Users/`c(username)'/CGD Education Dropbox/Education Team Files/Research/Household Survey Datasets/TIMSS/raw"
  
  
*
* Steps:
* 0) Program setup (identical for all assessments)
* 1) Open all rawdata, lower case vars, save in temp_dir
* 2) Combine all rawdata into a single file (merge and append)
* 3) Standardize variable names across all assessments
* 4) ESCS and other calculations (by Aroob, from Feb 2019)
* REPEAT 1-4 TWICE: once for lower grade (L), once for upper grade (U)
* 5) Bring WB countrycode & harmonization thresholds, and save dtas
*=========================================================================*


	//cap confirm file "${clone}/01_harmonization/011_rawdata/TEMP23.dta"
	
	//if _rc == 0 {

	* Loop over grade
	foreach g in 4 8 {
		
		* File prefix changes per grde
		if `g' == 4 {
			local fils "a"
		}
		else if `g' == 8 {
			local fils "b"
		}
		
	  //  local input_dir	= "C:/Users/`c(username)'/CGD Education Dropbox/Education Team Files/Research/Household Survey Datasets/TIMSS/raw"
//local g 4
	* Get all the files that exist 
	cd "`input_dir'/TIMSS2023_IDB_SPSS_G`g'/2_Data Files/SPSS Data"
	fs *m8*
	
	//		import spss using "`input_dir'/TIMSS2023_IDB_SPSS_G`g'/2_Data Files/SPSS Data/asamkdm8.sav",  clear

	
	local fil `r(files)'
	
	* Loop get a full list of countries
	local cnts ""
    foreach f in `r(files)' {
		local cnt = strupper(substr("`f'",4,3)) // unique by iso3
		local cnts = "`cnts'" + " `cnt'" // add each available country to the loop
	}
	local uniqcnt: list uniq cnts // extract to unique
	noi di "`uniqcnt'"
     
	 * Loop over each country
     foreach c in `uniqcnt' {
	 	noi di "`c' grade `g'"
		   
        // Temporary copies of the 4 rawdatasets needed for each country (new section)
        foreach prefix in `fils'sa `fils'sg `fils'sh `fils'cg {   //
		
		* 8th graders dont have home questionnaire
		if "`prefix'" == "bsh" {
			noi di "skip 8th grade home"
		}
		else {

		import spss using "`input_dir'/TIMSS2023_IDB_SPSS_G`g'/2_Data Files/SPSS Data/`prefix'`c'm8.sav",  clear
		noi di "loading `prefix'"
		
        rename *, lower

        compress
		
        save "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/`prefix'.dta", replace
		noi di "`c' `prefix' saved"
		
		* end skip case, 8th grade home
		}
	* next prefix 
	}

		
        // Merge the 4 rawdatasets into a single TEMP country file
		
		if `g' == 4 {
			local bulvar 14 
			local princvar 14
		}
		else if `g' == 8 {
			local bulvar 17
			local princvar 15
		}
		
		* Scores dataset
        use "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/`fils'sa.dta", clear
		
		* Just keep the main scores and not individual questions
		keep cty idcntry idpop idgrader idgrade itassess idbook idschool idclass idstud itsex *sdage *sssci0* *smmat0*

        merge 1:1 idschool idstud using "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/`fils'sg.dta", keep(master match) nogen //keepusing(*sbg01 *sbgssb *sbgsb *sdgssb *sdgsb jkzone jkrep idschool *sbg`bulvar'*)


		// only merge home questionnaire for grade 4		
		if `g' == 4 {
        merge 1:1 idschool idstud using "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/`fils'sh.dta", keep(master match) nogen //keepusing(*sbhela *sdhela *sbhena *sdhena *sbheln *sdheln *sbhelt *sdhelt *sbhent *sdhent *sbhlnt *sdhlnt *sbhpsp *sdhpsp idschool )
	}
		

        merge m:1 idschool using "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/`fils'cg.dta", keep(master match) //keepusing(idschool schwgt stotwgtu wgtadj1 wgtfac1 jkcrep jkczone *cbg`princvar'* *cdgdas *cbgdas *cbg05* *cdgsbc) nogen //  acdgdas acbgdas

		gen grade = `g'
		if `g' == 8 {
			drop *sbg14*
			drop *cbg14*
			ren *sbg17* *sbg14* 
			ren *cbg15* *cbg14*
		}

		//cap ren b* a*
        save "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/TEMP_l_`c'`g'.dta", replace
		
		// next country
      }	  

	// next grade
  }
  
 

    *---------------------------------------------------------------------------
    * L.2) Combine all rawdata into a single file (merge and append)
    *---------------------------------------------------------------------------
	cd "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023"
	fs 	TEMP*4*

    local firstfile: word 1 of `r(files)'
    use "`firstfile'", clear
    foreach f in `r(files)' {
      if "`f'" != "`firstfile'" append using "`f'"
    }
	
    save "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/TEMP23_G4.dta", replace

//	tempfile g4
//	save `g4', replace
	
	cd "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/T23_G8_SPSS Data"
	fs 	TEMP*8*

    local firstfile: word 1 of `r(files)'
    use "`firstfile'", clear
    foreach f in `r(files)' {
      if "`f'" != "`firstfile'" append using "`f'"
    }

	    save "${clone}/01_harmonization/011_rawdata/WLD/TIMSS 2023/TEMP23_G8.dta", replace

	//append using `g4'

	//drop me* se* mn* sp*
e
    save "${clone}/01_harmonization/011_rawdata/TEMP23.dta", replace

    noi disp as res "{phang}Step L.1 completed {p_end}"	 
	//}

    *---------------------------------------------------------------------------
    * L.3) Standardize variable names across all assessments
    *---------------------------------------------------------------------------
    // For each variable class, we create a local with the variables in that class
    //     so that the final step of saving the GLAD dta  knows which vars to save
	
    use "${clone}/01_harmonization/011_rawdata/TEMP23.dta", clear

    // ID Vars:
    local idvars "idcntry_raw idschool idgrade idclass idlearner"

    *<_idcntry_raw_>
    clonevar idcntry_raw = idcntry
    label var idcntry_raw "Country ID, as coded in rawdata"
    *</_idcntry_raw_>

    *<_idschool_>
    label var idschool "School ID"
    *</_idschool_>

    *<_idgrade_>
    label var idgrade "Grade ID"
    *</_idgrade_>

    *<_idclass_>
    label var idclass "Class ID"
    *</_idclass_>

    *<_idlearner_>
    clonevar idlearner = idstud
    label var idlearner "Learner ID"
    *</_idlearner_>

    // Drop any value labels of idvars, to be okay to append multiple surveys
    foreach var of local idvars {
      label values `var' .
    }


    // VALUE Vars:
    local valuevars	"score_timss* level_timss*"

    *<_score_assessment_subject_pv_>
    foreach pv in 01 02 03 04 05 {
      clonevar  score_timss_math_`pv' = asmmat`pv'
      label var score_timss_math_`pv' "Plausible value `pv': `assessment' score for math"
      char      score_timss_math_`pv'[clo_marker] "number"
      clonevar  score_timss_scie_`pv' = asssci`pv'
      label var score_timss_scie_`pv' "Plausible value `pv': `assessment' score for science"
      char      score_timss_scie_`pv'[clo_marker] "number"
    }
    *</_score_assessment_subject_pv_>

    *<_level_assessment_subject_pv_>
    foreach pv in 01 02 03 04 05 {
      clonevar  level_timss_math_`pv' = asmibm`pv'
      label var level_timss_math_`pv' "Plausible value `pv': `assessment' level for math"
      char      level_timss_math_`pv'[clo_marker] "factor"
      clonevar  level_timss_scie_`pv' = assibm`pv'
      label var level_timss_scie_`pv' "Plausible value `pv': `assessment' level for science"
      char      level_timss_scie_`pv'[clo_marker] "factor"
    }
    *</_level_assessment_subject_pv_>


	//comment_AR: check values and codebook for variables to see if anything has changed between years ///
    
	
    // TRAIT Vars:
    local traitvars	"age male bullying_* violence_* urba* ses* " // urban* 

    *<_age_>
    gen int age = asdage  if  !missing(asdage)  &  asdage != 99    
	
	label var age "Learner age at time of assessment"
    *</_age_>

    *<_urban_>
    gen byte urban = (inlist(acbg05a,1, 2, 3, 4, 5))  if  !missing(acbg05a)  &  acbg05a != 9
    label var urban "School is located in urban/rural area"
    *</_urban_>

    *<_urban_o_>
    decode acbg05a, g(urban_o1)
    label var urban_o1 "Original variable of urban: population size of the school area"
    decode acbg05b, g(urban_o2)
    label var urban_o2 "Original variable of urban: school is located in urban/rural area"
    *</_urban_o_>
	
	*<_ses_c_>*
	clonevar ses_c = acdgsbc
	*</_ses_c_>*


    *<_male_>
    gen byte male = (itsex == 2)  &  !missing(itsex)
    label var male "Learner gender is male/female"
    *</_male_>
	
	* Bullying *
    *<_bullying_index_>
	clonevar bullying_index = asbgsb
    *</_bullying_index_>
	
	*<_bullying_pv_>*
	gen bullying_pv = . 
	foreach v in e f g l n {
		replace bullying_pv = 1 if asbg14`v' <= 2
		replace bullying_pv = 0 if asbg14`v' > 2 & bullying_pv == . 
	}
	
	*</_bullying_pv_>*
	
	*<_bullying_ev_all_>*
	gen bullying_ev_all = . 
	foreach v in a b c d e f g h i j k m {
		replace bullying_ev_all = 1 if asbg14`v' <= 2
		replace bullying_ev_all = 0 if asbg14`v' > 2 & bullying_ev_all == . 
	}
	*</_bullying_ev_all_>*
	
	*<_bullying_ev_online_>*
	gen bullying_ev_online = . 
	foreach v in h i j {
		replace bullying_ev_online = 1 if asbg14`v' <= 2
		replace bullying_ev_online = 0 if asbg14`v' > 2 & bullying_ev_online == . 
	}
	*</_bullying_ev_online_>*
	
	*<_bullying_ev_trad_>*
	gen bullying_ev_trad = . 
	foreach v in a b c d e f k m {
		replace bullying_ev_trad = 1 if asbg14`v' <= 2
		replace bullying_ev_trad = 0 if asbg14`v' > 2 & bullying_ev_trad == . 
	}
	*</_bullying_ev_trad_>*
	
	*<_bullying_any_>*
	gen bullying_any = 1 if bullying_pv == 1 | bullying_ev_all == 1
	replace bullying_any = 1 if bullying_pv == 1 & bullying_ev_all == 1
	*</_bullying_any_>*
	
	* Principal perception of bullying problems at school
	
	* Bullying is a problem
	*<_bullying_c_all_>*
	gen bullying_c_all = .
	foreach v in h i {
		replace bullying_c_all = 1 if acbg14`v' >= 3 
		replace bullying_c_all = 0 if acbg14`v' < 3 & bullying_c_all == .
	}
	* Grade 4 question is not exact (physical fights vs physical injury)
	* So we exlcude this
	replace bullying_c_all = . if grade == 4 
	*</_bullying_c_all_>*
	

	* Violence to teachers is a moderate to severe problem 
	*<_violence_c_teach_>*
	gen byte violence_c_teach = (acbg14j>=3 | acbg14k>=3)
	*</_violence_c_teach_>*
	

    // SAMPLE Vars:
    local samplevars "learner_weight jkzone jkrep school_weight jkcrep jkczone"

    *<_school_weight_>
    clonevar school_weight = schwgt
    label var school_weight "Total school weight"
    *</_school_weight_>
	
    *<_learner_weight_>
    clonevar learner_weight = totwgt
    label var learner_weight "Total learner weight"
    *</_learner_weight_>

    *<_jkzone_>
    label var jkzone "Jackknife zone"
    *</_jkzone_>
	
    *<_jkczone_>
    label var jkczone "Jackknife school zone"
    *</_jkczone_>


    *<_jkrep_>
    label var jkrep "Jackknife replicate code"
    *</_jkrep_>
	
    *<_jkczone_>
    label var jkczone "Jackknife school zone"
    *</_jkczone_>


    noi disp as res "{phang}Step L.3 completed (`output_file'){p_end}"

    *---------------------------------------------------------------------------
    * 5) Bring WB countrycode & harmonization thresholds, and save dtas
    *---------------------------------------------------------------------------

    // Brings World Bank countrycode from ccc_list
    // NOTE: the *assert* is intentional, please do not remove it.
    // if you run into an assert error, edit the 011_rawdata/master_countrycode_list.csv
	
	* one inconsistency with wb countrycode
	ren cty countrycode
	replace countrycode = "ROU" if countrycode == "ROM"
	
    //merge m:1 idcntry_raw using "`temp_dir'/countrycode_list.dta", keep(match) assert(match using) nogen

    // Surveyid is needed to merge harmonization proficiency thresholds
    gen str surveyid = "`region'_`year'_`assessment'"
    label var surveyid "Survey ID (Region_Year_Assessment)"
	
	gen byte national_level = !inlist(countrycode, "AAD", "ADU", "ASH", "BFL", "BFR", "COT", "CQU", "ENG")
	

    // New variable class: keyvars (not IDs, but rather key to describe the dataset)
    local keyvars "surveyid countrycode national_level"

    ****************************************************************************
 
   
    // This function compresses the dataset, adds metadata passed in the arguments as chars, save GLAD_BASE.dta
    // which contains all variables, then keep only specified vars and saves GLAD.dta, and delete files in temp_dir
    edukit_save, filename("`output_file'") path("`output_dir'") dir2delete("`temp_dir'") ///
                 idvars("`idvars'") varc("key `keyvars';value `valuevars';trait `traitvars';sample `samplevars'") ///
                 metadata("`metadata'") collection("GLAD")

    noi disp as res "Creation of `output_file'.dta completed"

  

  else {
    noi disp as txt "Skipped creation of `output_file'.dta (already found in clone)"
  }
