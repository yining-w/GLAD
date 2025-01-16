*=========================================================================*
* GLOBAL LEARNING ASSESSMENT DATABASE (GLAD)
* Project information at: https://github.com/worldbank/GLAD
*
* Metadata to be stored as 'char' in the resulting dataset (do NOT use ";" here)
local region      = "WLD"
local year        = "2019"
local assessment  = "TIMSS"
local master      = "v01_M"
local adaptation  = "wrk_A_GLAD"
local module      = "ALL"
local ttl_info    = "Joao Pedro de Azevedo [eduanalytics@worldbank.org]"
local dofile_info = "last modified by Ahmed Raza in January 29, 2021"


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

*Comment_AR: noisily or quietly use while debugging.

quietly {

  *---------------------------------------------------------------------------
  * 0) Program setup (identical for all assessments)
  *---------------------------------------------------------------------------

  // Parameters ***NEVER COMMIT CHANGES TO THOSE LINES!***
  //  - whether takes rawdata from datalibweb (==1) or from indir (!=1), global in 01_run.do
  local from_datalibweb = $from_datalibweb
  //  - whether checks first if file exists and attempts to skip this do file
  local overwrite_files = $overwrite_files
  //  - optional shortcut in datalibweb
  local shortcut = "$shortcut"
  //  - setting random seed at the beginning of each do for reproducibility
  set seed $master_seed

  // Set up folders in clone and define locals to be used in this do-file
  glad_local_folder_setup , r("`region'") y("`year'") as("`assessment'") ma("`master'") ad("`adaptation'")
  local temp_dir     "`r(temp_dir)'"
  local output_dir   "`r(output_dir)'"
  local surveyid     "`r(surveyid)'"
  local output_file  "`surveyid'_`adaptation'_`module'"

  // If user does not have access to datalibweb, point to raw microdata location
  if `from_datalibweb' == 0 {
    local input_dir	= "${input}/WLD/WLD_2019_TIMSS/WLD_2019_TIMSS_v01_M/Data/Stata"
  }
  // Confirm if the final GLAD file already exists in the local clone
  cap confirm file "`output_dir'/`output_file'.dta"
  // If the file does not exist or overwrite_files local is set to one, run the do
  if (_rc == 601) | (`overwrite_files') {

    // Filter the master country list to only this assessment-year
    use "${clone}/01_harmonization/011_rawdata/master_countrycode_list.dta", clear
    keep if (assessment == "`assessment'") & (year == `year')
    // Most assessments use the numeric idcntry_raw but a few (ie: PASEC 1996) have instead idcntry_raw_str
    if use_idcntry_raw_str[1] == 1 {
      drop   idcntry_raw
      rename idcntry_raw_str idcntry_raw
    }
    keep idcntry_raw national_level countrycode
    save "`temp_dir'/countrycode_list.dta", replace

    // Tokenized elements from the header to be passed as metadata
    local glad_description  "This dataset is part of the Global Learning Assessment Database (GLAD). It contains microdata from `assessment' `year'. Each observation corresponds to one learner (student or pupil), and the variables have been harmonized."
    local metadata          "region `region'; year `year'; assessment `assessment'; master `master'; adaptation `adaptation'; module `module'; ttl_info `ttl_info'; dofile_info `dofile_info'; description `glad_description'"
    
    *****************************************************************************
    * IMPORTANT!!!  THIS CODE BASICALLY BUILDS TWO DTAs (lower/upper idgrade)	  *
    * then append (could be a loop, pending more changes in the original pieces)*
    *****************************************************************************
    **********************   LOWER IDGRADE SECTION   ****************************

    *---------------------------------------------------------------------------
    * L.1) Open all rawdata, lower case vars, save in temp_dir
    *---------------------------------------------------------------------------
    // PLACEHOLDER: bring the list of countries as macro
    
	 
	 * foreach cnt in AAD ABA ADU ARE ARM AUS BFL BGR BHR CAN CHL COT CQU CYP CZE DEU DNK ENG ESP FIN FRA GEO HKG HRV HUN IDN IRL IRN ITA JPN KAZ KOR KWT  LTU MAR NIR NLD NO4 NOR NZL OMN POL PRT QAT RUS SAU SGP SRB SVK SVN SWE TUR TWN USA {

   * Comment_AR: figure out which countries go to b7 and which countries go to m7 global list and do the same for upper grade part of the code. 
   
   *  b7: can chl twn hrv cze dnk eng fin fra geo deu hkg hun ita kor ltu nld nor prt qat rus sgp svk esp swe are usa
   *  m7: aut alb arm aus aut aze bhr bfl bih bgr can chl twn hrv cyp cze dnk eng fin fra geo deu hkg hun irn irl ita jpn kaz kor xkx kwt lva ltu mlt mne mar nld nzl mkd nir nor omn pak phl pol prt qat rus sau srb sgp svk zaf esp swe tur are usa cot cqu rmo ema aad adu
   
   
     local countriesb7 "aut can chl twn hrv cze dnk eng fin fra geo deu hkg hun ita kor ltu nld nor prt qat rus sgp svk esp swe are usa" 
     
     local countriesm7 "are aut alb arm aus aut aze bhr bfl bih bgr can chl twn hrv cyp cze dnk eng fin fra geo deu hkg hun irn irl ita jpn kaz kor xkx kwt lva ltu mlt mne mar nld nzl mkd nir nor omn pak phl pol prt qat rus sau srb sgp svk zaf esp swe tur are usa cot cqu rmo ema aad adu"

     foreach ending in m7 b7{
     
      foreach cnt in `countries`ending'' {
    
        // Temporary copies of the 4 rawdatasets needed for each country (new section)
        foreach prefix in asa asg ash acg {   // comment_AR:  asr ast atg  - there are 3 other types of files which we are not currently using.        
          if `from_datalibweb'==1 {
            noi edukit_datalibweb, d(country(`region') year(`year') type(EDURAW) surveyid(`surveyid') filename(`prefix'`cnt'`ending'.dta) `shortcut')
          }
          else {
            
            use "`input_dir'/`prefix'`cnt'`ending'.dta", clear   
        
          }
          rename *, lower
          compress
          save "`temp_dir'/`prefix'.dta", replace
        }

        // Merge the 4 rawdatasets into a single TEMP country file
        use "`temp_dir'/asa.dta", clear
        merge 1:1 idcntry idschool idstud using "`temp_dir'/asg.dta", keep(master match) nogen
        merge 1:1 idcntry idschool idstud using "`temp_dir'/ash.dta", keep(master match) nogen
        merge m:1 idcntry idschool using "`temp_dir'/acg.dta", keep(master match) nogen
        save "`temp_dir'/TEMP_`surveyid'_l_`cnt'.dta", replace
      }
    }


    noi disp as res "{phang}Step L.1 completed (`output_file'){p_end}"


    *---------------------------------------------------------------------------
    * L.2) Combine all rawdata into a single file (merge and append)
    *---------------------------------------------------------------------------

    fs "`temp_dir'/TEMP_`surveyid'_l_*.dta"
    local firstfile: word 1 of `r(files)'
    use "`temp_dir'/`firstfile'", clear
    foreach f in `r(files)' {
      if "`f'" != "`firstfile'" append using "`temp_dir'/`f'"
    }

    noi disp as res "{phang}Step L.2 completed (`output_file'){p_end}"

	/// * Comment_AR: check this and compare with codebook ///

    *---------------------------------------------------------------------------
    * L.3) Standardize variable names across all assessments
    *---------------------------------------------------------------------------
    // For each variable class, we create a local with the variables in that class
    //     so that the final step of saving the GLAD dta  knows which vars to save

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
      clonevar  score_timss_science_`pv' = asssci`pv'
      label var score_timss_science_`pv' "Plausible value `pv': `assessment' score for science"
      char      score_timss_science_`pv'[clo_marker] "number"
    }
    *</_score_assessment_subject_pv_>

    *<_level_assessment_subject_pv_>
    foreach pv in 01 02 03 04 05 {
      clonevar  level_timss_math_`pv' = asmibm`pv'
      label var level_timss_math_`pv' "Plausible value `pv': `assessment' level for math"
      char      level_timss_math_`pv'[clo_marker] "factor"
      clonevar  level_timss_science_`pv' = assibm`pv'
      label var level_timss_science_`pv' "Plausible value `pv': `assessment' level for science"
      char      level_timss_science_`pv'[clo_marker] "factor"
    }
    *</_level_assessment_subject_pv_>


	//comment_AR: check values and codebook for variables to see if anything has changed between years ///
    
	
    // TRAIT Vars:
    local traitvars	"age urban* male escs qescs has_qescs"

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

    *<_male_>
    gen byte male = (itsex == 2)  &  !missing(itsex)
    label var male "Learner gender is male/female"
    *</_male_>


    // SAMPLE Vars:
    local samplevars "learner_weight jkzone jkrep"

    *<_learner_weight_>
    clonevar learner_weight = totwgt
    label var learner_weight "Total learner weight"
    *</_learner_weight_>

    *<_jkzone_>
    label var jkzone "Jackknife zone"
    *</_jkzone_>

    *<_jkrep_>
    label var jkrep "Jackknife replicate code"
    *</_jkrep_>


    noi disp as res "{phang}Step L.3 completed (`output_file'){p_end}"

	** Bullying by...
	
	** HOME **
	* 1) Early Numeracy / Literacy Activities Index, Before
	* as*hela, hena, heln, helt, hlnt

	* 2) What do you think of your child's school? Agree to disagree - b) safe environment
	lab var asbh09b "Agree to disagree: Child's school provides a safe environment"
	// asbh09a asbh09b asbh09c asbh09d asbh09e asbh09f asbh09g
	
	save "${clone}/03_output/TIMSS_2019_WLD.dta", replace
	
	** SCHOOL ** 
    *NOT replacing IDCNTRY for England and Scotland (original do file)
    *replace IDCNTRY = 826 if inlist(IDCNTRY,927,926,928)
    *replace IDCNTRY = 056 if inlist(IDCNTRY,956,957)
    *Identifying whether the datasets are nationally representative

	* h, i, j (intimidation, verbal abuse among students)
	* acbg15a acbg15b acbg15c acbg15d acbg15e acbg15f acbg15g acbg15h acbg15i acbg15j
	/*
	
	** 1. CDF distribution of math/science scores among those who were bullied versus not, 4th and 8th grade 
	** 2019 and 2023
	alorenz asssci01 [aw=learner_weight], gp points(300) by(asdgsb) 
	// add mpl line
	
//markvar(ctry) 
	** 2. Within / between school inequality on bullying, 4th and 8th grade
	ineqdeco asssci01 [aw = learner_weight] if cntry=="jpn", by(idschool)
	//asbgsb 
	* 
	/*
	       r(between_a2) =  .001075153902055
         r(between_a1) =  .0005050754898099
      r(between_ahalf) =  .0002461340258986
          r(within_a2) =  .0159525241243196
          r(within_a1) =  .0077432565902942

	*/
	/*
	*/
	** 3. Between 2019 and 2023 -- was the bullying among those who were 
	* most frequently bullied (change in distribution) or change in the mean?
	
	** 3. Bullying index on categorical home resources / earlier literacy (inequality is more stark among students along the lowest end of the specturm)
	local vars "acbgdas asbghrl asbheln"
	foreach xvar in `vars' {
	local label : variable label `xvar'
	twoway kdensity `xvar' if asdgsb==1, bwidth(1) || kdensity `xvar' if asdgsb==2, bwidth(1) || kdensity `xvar' if asdgsb==3, bwidth(1) title("`l'")
	//graph export "${clone}/`xvar'.jpg", replace
	}	

	
  
 
	
    noi disp as res "{phang}Step L.4 completed (`output_file'){p_end}"
    
    // FINISHED LOWER GRADE TEMP FILE
    save "`temp_dir'/TEMP_`surveyid'_l.dta", replace

    
	
    *****************************************************************************
    * IMPORTANT!!!  THIS CODE BASICALLY BUILDS TWO DTAs (lower/upper idgrade)	  *
    * then append (could be a loop, pending more changes in the original pieces)*
    *****************************************************************************
    **********************   UPPER IDGRADE SECTION   ****************************

	
	
    *---------------------------------------------------------------------------
    * U.1) Open all rawdata, lower case vars, save in temp_dir
    *---------------------------------------------------------------------------
    // PLACEHOLDER: bring the list of countries as macro
    
	
	*foreach cnt in AAD ABA ADU ARE ARM AUS BHR BWA CAN CHL COT CQU EGY ENG GEO HKG HUN IRL IRN ISR ITA JOR JPN KAZ KOR KWT LBN LTU MAR MLT MYS NO8 NOR NZL OMN QAT RUS SAU SGP SVN SWE THA TUR TWN USA ZAF {
	
  * Comment_AR: Do the same as 99-121.
  
  * b7: 
  * m7: bhr chl cyp egy eng fin fra geo hkg hun irn irl isr ita jpn jor kaz kor kwt lbn ltu mys mar nzl nor omn prt qat rom rus sau sgp zaf swe tur are usa cot cqu rmo zgt zwc aad adu
  
    local countriesb7 "chl eng geo hkg hun isr ita kor ltu mys nor qat rus sgp swe tur are usa" 
    local countriesm7 "aus bhr chl cyp egy eng fin fra geo hkg hun irn irl isr ita jpn jor kaz kor kwt lbn ltu mys mar nzl nor omn prt qat rom rus sau sgp zaf swe tur are usa cot cqu rmo zgt zwc aad adu"

     foreach ending in m7 b7{
  
     foreach cnt in `countries`ending'' {
	
      // Temporary copies of the 3 rawdatasets needed for each country (new section)
      foreach prefix in bsa bsg bcg  {
        if `from_datalibweb'==1 {
          noi edukit_datalibweb, d(country(`region') year(`year') type(EDURAW) surveyid(`surveyid') filename(`prefix'`cnt'`ending'.dta) `shortcut')
        }
        else {
          use "`input_dir'/`prefix'`cnt'`ending'.dta", clear    // Comment_AR (fixed): m7 or b7 , or both: change 506 line too //
        }
        rename *, lower
        compress
        save "`temp_dir'/`prefix'.dta", replace
      }

      // Merge the 3 rawdatasets into a single TEMP country file
      use "`temp_dir'/bsa.dta", clear
      merge 1:1 idcntry idschool idstud using "`temp_dir'/bsg.dta", keep(master match) nogen
      merge m:1 idcntry idschool using "`temp_dir'/bcg.dta", keep(master match) nogen
      save "`temp_dir'/TEMP_`surveyid'_u_`cnt'.dta", replace
    }
    }

    noi disp as res "{phang}Step U.1 completed (`output_file'){p_end}"


    *---------------------------------------------------------------------------
    * U.2) Combine all rawdata into a single file (merge and append)
    *---------------------------------------------------------------------------

    fs "`temp_dir'/TEMP_`surveyid'_u_*.dta"
    local firstfile: word 1 of `r(files)'
    use "`temp_dir'/`firstfile'", clear
    foreach f in `r(files)' {
      if "`f'" != "`firstfile'" append using "`temp_dir'/`f'"
    }

    noi disp as res "{phang}Step U.2 completed (`output_file'){p_end}"


    *---------------------------------------------------------------------------
    * U.3) Standardize variable names across all assessments
    *---------------------------------------------------------------------------
    // For each variable class, we create a local with the variables in that class
    //     so that the final step of saving the GLAD dta  knows which vars to save

    // ID Vars:
    local idvars "idcntry_raw idschool idgrade idclass idlearner"

    *<_idcntry_raw_>
    clonevar idcntry_raw = idcntry
    label var idcntry_raw "Country ID, as coded in rawdata"
    *</_idcntry_raw_>

    *<_idschool_>
    label var idschool "School ID"
    *</_idschool_>

	
	//Comment_AR: may need to check the cleaning for grade for the year 2019  //
	
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
      clonevar  score_timss_math_`pv' = bsmmat`pv'
      label var score_timss_math_`pv' "Plausible value `pv': `assessment' score for math"
      char      score_timss_math_`pv'[clo_marker] "number"
      clonevar  score_timss_science_`pv' = bsssci`pv'
      label var score_timss_science_`pv' "Plausible value `pv': `assessment' score for science"
      char      score_timss_science_`pv'[clo_marker] "number"
    }
    *</_score_assessment_subject_pv_>

    *<_level_assessment_subject_pv_>
    foreach pv in 01 02 03 04 05 {
      clonevar  level_timss_math_`pv' = bsmibm`pv'
      label var level_timss_math_`pv' "Plausible value `pv': `assessment' level for math"
      char      level_timss_math_`pv'[clo_marker] "factor"
      clonevar  level_timss_science_`pv' = bssibm`pv'
      label var level_timss_science_`pv' "Plausible value `pv': `assessment' level for science"
      char      level_timss_science_`pv'[clo_marker] "factor"
    }
    *</_level_assessment_subject_pv_>


    // TRAIT Vars:
    local traitvars	"age urban* male escs qescs has_qescs"

    *<_age_>
    gen int age = bsdage  if  !missing(bsdage)  &  bsdage!= 99
    label var age "Learner age at time of assessment"
    *</_age_>

    *<_urban_>
    gen byte urban = (inlist(bcbg05a,1, 2, 3, 4, 5))  if  !missing(bcbg05a)  &  bcbg05a != 9
    label var urban "School is located in urban/rural area"
    *</_urban_>

    *<_urban_o_>
    decode bcbg05a, g(urban_o1)
    label var urban_o1 "Original variable of urban: population size of the school area"
    decode bcbg05b, g(urban_o2)
    label var urban_o2 "Original variable of urban: school is located in urban/rural area"
    *</_urban_o_>

    *<_male_>
    gen byte male = (itsex == 2)  &  !missing(itsex)
    label var male "Learner gender is male/female"
    *</_male_>


    // SAMPLE Vars:
    local samplevars "learner_weight jkzone jkrep"

    *<_learner_weight_>
    clonevar learner_weight = totwgt
    label var learner_weight "Total learner weight"
    *</_learner_weight_>

    *<_jkzone_>
    label var jkzone "Jackknife zone"
    *</_jkzone_>

    *<_jkrep_>
    label var jkrep "Jackknife replicate code"
    *</_jkrep_>


    noi disp as res "{phang}Step U.3 completed (`output_file'){p_end}"

    
    
    *---------------------------------------------------------------------------
    * U.4) ESCS and other calculations (by Aroob, from Feb 2019)
    *---------------------------------------------------------------------------

    *NOT replacing IDCNTRY for England and Scotland (original do file)
    *replace IDCNTRY = 826 if inlist(IDCNTRY,927,926,928)
    *replace IDCNTRY = 056 if inlist(IDCNTRY,956,957)
    *Identifying whether the datasets are nationally representative
    gen n_res = 0 if inlist(idcntry,927,926,928,956,957)

    *** QUICK FIX ****
    rename *, upper
    ******************

    *Score and thresholds:
    foreach pv in 01 02 03 04 05 {
      clonevar SCORE_MATH`pv' = BSMMAT`pv'
      clonevar SCORE_SCIENCE`pv' = BSSSCI`pv'
      clonevar MATH_THRESHOLD`pv' = BSMIBM`pv'
      clonevar SCIENCE_THRESHOLD`pv' = BSSIBM`pv'
    }
    foreach var of varlist MATH_THRESHOLD* SCIENCE_THRESHOLD*{
      gen LOW_`var' = (`var' > 1) & !missing(`var')
      gen INT_`var' = (`var' > 2) & !missing(`var')
      gen HIGH_`var' = (`var' > 3) & !missing(`var')
      gen ADV_`var' = (`var' > 4) & !missing(`var')
    }

   
    // FINISHED UPPER GRADE TEMP FILE
    save "`temp_dir'/TEMP_`surveyid'_u.dta", replace

    *****************************************************************************
    * IMPORTANT!!!  THIS CODE BASICALLY BUILDS TWO DTAs (lower/upper idgrade)	  *
    * then append (could be a loop, pending more changes in the original pieces)*
    *****************************************************************************
    **********************   APPENDING BOTH FILES   ****************************

    // Opens up the file from the first loop (LOWER grade)
    // Appends with the file from second loop (UPPER grade)
    use "`temp_dir'/TEMP_`surveyid'_l", clear
    append using "`temp_dir'/TEMP_`surveyid'_u"

    *Comment_AR: Commenting out the ESCS part of the code so we need to gen an empty var called escs:
    
    * gen escs =. 
    
    
    * Adjustment after the append: rename science vars to scie so that ados don't break because of characterlimit. 
    
    ren score_timss_science_01 score_timss_scie_01
    ren score_timss_science_02 score_timss_scie_02
    ren score_timss_science_03 score_timss_scie_03
    ren score_timss_science_04 score_timss_scie_04
    ren score_timss_science_05 score_timss_scie_05
    
    ren level_timss_science_01 level_timss_scie_01
    ren level_timss_science_02 level_timss_scie_02
    ren level_timss_science_03 level_timss_scie_03
    ren level_timss_science_04 level_timss_scie_04
    ren level_timss_science_05 level_timss_scie_05
    
    
    
    
    *---------------------------------------------------------------------------
    * 5) Bring WB countrycode & harmonization thresholds, and save dtas
    *---------------------------------------------------------------------------

    // Brings World Bank countrycode from ccc_list
    // NOTE: the *assert* is intentional, please do not remove it.
    // if you run into an assert error, edit the 011_rawdata/master_countrycode_list.csv
    merge m:1 idcntry_raw using "`temp_dir'/countrycode_list.dta", keep(match) assert(match using) nogen

    // Surveyid is needed to merge harmonization proficiency thresholds
    gen str surveyid = "`region'_`year'_`assessment'"
    label var surveyid "Survey ID (Region_Year_Assessment)"

    // New variable class: keyvars (not IDs, but rather key to describe the dataset)
    local keyvars "surveyid countrycode national_level"

    ****************************************************************************
   /*
   * Comment_AR: Added from the PIRLS - take it out.
    
   // Harmonization of proficiency on-the-fly, based on thresholds as CPI
    glad_hpro_as_cpi
    local thresholdvars "`r(thresholdvars)'"
    local resultvars "`r(resultvars)'"

     // Update valuevars to include newly created harmonized vars (from the ado)
    local valuevars : list valuevars | resultvars
    
    */
   *****************************************************************************
   
    // This function compresses the dataset, adds metadata passed in the arguments as chars, save GLAD_BASE.dta
    // which contains all variables, then keep only specified vars and saves GLAD.dta, and delete files in temp_dir
    edukit_save, filename("`output_file'") path("`output_dir'") dir2delete("`temp_dir'") ///
                 idvars("`idvars'") varc("key `keyvars';value `valuevars';trait `traitvars';sample `samplevars'") ///
                 metadata("`metadata'") collection("GLAD")

    noi disp as res "Creation of `output_file'.dta completed"

  }

  else {
    noi disp as txt "Skipped creation of `output_file'.dta (already found in clone)"
    // Still loads it, to generate documentation
    use "`output_dir'/`output_file'.dta", clear
  }
}