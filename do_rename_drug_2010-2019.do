
cd /Users/sooa/Documents/boxwarning

import excel "/Users/sooa/Documents/boxwarning/drug_names/drug_names_2016.xlsx", sheet("List-up_2015-2019_prep") cellrange(A1:C419) firstrow clear

replace year = substr(year,-4,.)
destring year, replace

replace gnrc_name =ustrtrim(lower(gnrc_name))

** Drop opioid and opioid related warnings
*drop if opioid == 1

duplicates drop

** 1. Replace drug names containig any relevant keyword first

gen namelength = strlen(gnrc_name)

levelsof namelength, local(length)

local names_ordered
foreach i in `length'{
	levelsof gnrc_name if namelength == `i' & strpos(gnrc_name, "/") == 0
	local names = r(levels)
	local names_ordered `"`names_ordered' `names'"'
}

gen gnrc_name2 = ""
foreach i of local names_ordered {
    replace gnrc_name2 = "`i'" if strpos(gnrc_name, "`i'")
}

** 2. Preplace drug names containing two or more keywords

levelsof gnrc_name if strpos(gnrc_name, "/"), local(names)
foreach i in `names'{
	replace gnrc_name2 = "`i'" if strpos(gnrc_name, "`i'")
}

** 3. Remove unnecessary parts of drug name

foreach i in "25% " "30% " "50% " "70% " "75% " "extended-release" "extended release" "injection" "hydrochloride" "antibiotic"{
	replace gnrc_name2 = ustrtrim(subinstr(gnrc_name2,"`i'","",.))
}

** Miscellaneous: same order with Medicare Part D
replace gnrc_name2 = "carbidopa/levodopa/entacapone" if gnrc_name2 == "entacapone/carbidopa/levodopa"
replace gnrc_name2 = "empagliflozin/linagliptin" if gnrc_name2 == "linagliptin/empagliflozin"

*** 4. Keep first treatment or second treatment in 5 years (Therefore, only treatments since 2015 are valid)
sort gnrc_name2 year
by gnrc_name2: gen count = _n
by gnrc_name2: gen count_1 = year[_n-1]

keep if count == 1 | (count == 2 & year-count_1 >= 5)
by gnrc_name2: gen count_2 = _N
drop if count_2 == 2 & count == 1

gen group = cond(year>=2015, 1, 0)


** Export
keep gnrc_name2 year group opioid
rename gnrc_name2 gnrc_name

export delimited "./drug_names/drug_names_241229", replace


****
** Complete Python fuzzy match
****

import delimited "/Users/sooa/Documents/boxwarning/drug_names/drug_match.csv", clear

gen matched_name_2 = ""
** In general, score >= 90 are reliable. Below that, it needs manual matching, comparing to Medicare Part D. Exceptions are below.
replace matched_name_2 = "Alemtuzumab" if gnrc_name =="alemtuzumab"
replace matched_name_2 = "Aliskiren Hemifumarate" if gnrc_name =="aliskiren"
replace matched_name_2 = "Alogliptin Benzoate" if gnrc_name =="alogliptin"
replace matched_name_2 = "Daclatasvir Dihydrochloride" if gnrc_name =="daclatasvir"
replace matched_name_2 = "Dapagliflozin Propanediol" if gnrc_name =="dapagliflozin"
replace matched_name_2 = "Darbepoetin Alfa In Polysorbat" if gnrc_name =="darbepoetin alfa"
replace matched_name_2 = "Dolutegravir Sodium" if gnrc_name =="dolutegravir"
replace matched_name_2 = "Ertugliflozin Pidolate" if gnrc_name =="ertugliflozin"
replace matched_name_2 = "Fenoprofen Calcium" if gnrc_name =="fenoprofen"
replace matched_name_2 = "Heparin Sodium,porcine" if gnrc_name =="heparin sodium"
replace matched_name_2 = "Ketorolac Tromethamine" if gnrc_name =="ketorolac"
replace matched_name_2 = "Olmesartan Medoxomil" if gnrc_name =="olmesartan"
replace matched_name_2 = "Ribociclib Succinate" if gnrc_name =="ribociclib"
replace matched_name_2 = "Risedronate Sodium" if gnrc_name =="risedronate delayed release"
replace matched_name_2 = "Sitagliptin Phosphate" if gnrc_name =="sitagliptin"
replace matched_name_2 = "Tofacitinib Citrate" if gnrc_name =="tofacitinib"
replace matched_name_2 = "Tolmetin Sodium" if gnrc_name =="tolmetin"
replace matched_name_2 = "Zolpidem Tartrate" if gnrc_name =="zolpidem"
replace matched_name_2 = "Azithromycin" if gnrc_name =="antibiotic azithromycin"
replace matched_name_2 = "Clopidogrel Bisulfate" if gnrc_name =="clopidogrel"
replace matched_name_2 = "Salmeterol Xinafoate" if gnrc_name =="salmeterol"
replace matched_name_2 = "Saquinavir Mesylate" if gnrc_name =="saquinavir"
replace matched_name_2 = "Flurazepam Hcl" if gnrc_name == "flurazepam"
replace matched_name_2 = "Formoterol Fumarate" if gnrc_name == "formoterol"
replace matched_name_2 = "Lithium Carbonate" if gnrc_name == "llthium"
replace matched_name_2 = "Almotriptan Malate" if gnrc_name == "almotriptan"
replace matched_name_2 = "Rizatriptan Benzoate" if gnrc_name == "rizatriptan"
replace matched_name_2 = "Pentazocine Hcl/Naloxone Hcl" if gnrc_name == "pentazocine"
replace matched_name_2 = "Dolasetron Mesylate" if gnrc_name == "dolasetron"

gen gnrc_name2 = matched_name
replace gnrc_name2 = matched_name_2 if matched_name_2 != ""
replace gnrc_name2 = "" if match_score < 70 & matched_name_2 == ""

replace gnrc_name2 = "" if gnrc_name == "adenosine"
replace gnrc_name2 = "" if gnrc_name == "quazepam"

drop if gnrc_name2 == ""
collapse (max) opioid (min) group (max) year, by(gnrc_name2)
rename gnrc_name2 gnrc_name
rename year ytreat

save drug_matched_list, replace

***
** Match start
*****
grstyle init
grstyle set plain

use "/Users/sooa/Downloads/drug_provider_output_allyears.dta", clear

merge m:1 gnrc_name using drug_matched_list
drop _merge

*drop if opioid == 1
drop if group == 0
  
gen type = .
replace type = 1 if inlist(prscrbr_type, "Family Practice", "Internal Medicine", "General Practice", "Obstetrics & Gynecology", "Geriatric Medicine")
replace type = 2 if inlist(prscrbr_type, "Nurse Practitioner", "Certified Clinical Nurse Specialist")
replace type = 3 if inlist(prscrbr_type, "Physician Assistant")

label define type 1 "Physician" 2 "NP" 3 "PA", replace
label val type type

destring prscrbr_state_fips, gen(state_fips) force
drop if state_fips == .
drop if state_fips > 56

local opioidflag = 1

***
** Specification1: All states
***

**** Drop opioid flag - No longer used
/*
if `opioidflag' == 1{
	import excel "/Users/sooa/Documents/boxwarning/drug_names/MUP_DPR_RY24_P06_V10_DYT22_DLSum.xlsx", sheet("Medicare Part D Drug Lists") cellrange(A4:G470) firstrow case(lower) clear
	keep genericname opioidflag
	duplicates drop
	tempfile temp
	save `temp'
	restore
	preserve	
}
*/
****

collapse (sum) tot_clms tot_30day_fills (first) ytreat opioid, by(type gnrc_name year)
merge m:1 gnrc_name using ./drug_names/partd_class_ver250107, gen(_class)

*** Redefine Gabapentin (In the order of best working) id_class== 131, id_cat== 25
* Switch to separate
replace id_class = 1000 if gnrc_name == "Gabapentin"
replace id_cat = 100 if gnrc_name == "Gabapentin"

* Switch to SSRIs/SNRIs (Selective Serotonin Reuptake Inhibitors/ Serotonin and Norepinephrine Reuptake Inhibitors)
replace id_class = 33 if gnrc_name == "Gabapentin"
replace id_cat = 7 if gnrc_name == "Gabapentin"

* Switch to Non-opioid Pain medicine
replace id_class = 2 if gnrc_name == "Gabapentin"
replace id_cat = 1 if gnrc_name == "Gabapentin"

* Switch to Opioid pain medicine - No change
replace id_class = 3 if gnrc_name == "Gabapentin"
replace id_cat = 1 if gnrc_name == "Gabapentin"


** Drop opioid by matching (No longer used)
/*
gen genericname = upper(gnrc_name)
capture merge m:1 genericname using `temp'
capture drop if opioidflag== "Y"
*/

encode gnrc_name, gen(gnrc_cd)

gen timeto = year-ytreat
replace timeto = -1 if ytreat == .

summ timeto, detail
local min=r(min)
gen timeto2 = timeto - `min'
summ timeto2 if timeto == -1
local base = r(min)

summ timeto2, detail
local max=r(max)
local timeto2
forvalues i=0/`max'{
	local val=`i'+`min'
	local timeto2 `timeto2' `i' "`val'"
	label define timeto2 `timeto2', replace
}
label val timeto2 timeto2

preserve
keep if id_class != .
keep if ytreat != .
hist timeto, by(type) freq
graph export "./graph_coef/hist_evnt.jpg", as(jpg) name("Graph") quality(100) replace
restore

** All observations
eststo md1: reghdfe tot_clms ib`base'.timeto2 if type == 1, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo np1: reghdfe tot_clms ib`base'.timeto2 if type == 2, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo pa1: reghdfe tot_clms ib`base'.timeto2 if type == 3, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
coefplot md1 np1 pa1, keep(*timeto2) vertical
graph export "./graph_coef/event_1_allp_250107.jpg", as(jpg) name("Graph") quality(100) replace
coefplot md1 np1 pa1, keep(3.timeto2 4.timeto2 5.timeto2 6.timeto2 7.timeto2 8.timeto2 9.timeto2 10.timeto2 11.timeto2) vertical
graph export "./graph_coef/event_1_250107.jpg", as(jpg) name("Graph") quality(100) replace

** Is pre-trend cohort-specific?: Why class#year FE does not capture?
eststo np_g1: reghdfe tot_clms ib`base'.timeto2 if type == 2 & (ytreat == 2015 | ytreat == .), absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo np_g2: reghdfe tot_clms ib`base'.timeto2 if type == 2 & (ytreat == 2016 | ytreat == .), absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo np_g3: reghdfe tot_clms ib`base'.timeto2 if type == 2 & (ytreat == 2017 | ytreat == .), absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo np_g4: reghdfe tot_clms ib`base'.timeto2 if type == 2 & (ytreat == 2018 | ytreat == .), absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo np_g5: reghdfe tot_clms ib`base'.timeto2 if type == 2 & (ytreat == 2019 | ytreat == .), absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
coefplot np_g1 np_g2 np_g3 np_g4 np_g5, keep(*timeto2) order(0.timeto2 1.timeto2 2.timeto2 3.timeto2 4.timeto2) vertical
** A drug named "Gabapentin", treated in 2019, is the 4th most prescribed medication by nurse practitioners. (7th by physicians)
*** It was also fastest growing medications within anticonvulsant class, mostly because of off-label use as an alternative to opioids. This is because clinicians believe it's a safe alternative to opioids in terms of cost, familiarity, noncontrolled status. It took 30% of total anticonvulsants in 2013 and 47% of in 2022. But up to 95% of these prescriptions are off-label use.

** Balanced sample
eststo md1: reghdfe tot_clms ib`base'.timeto2 if type == 1 & timeto >=-3 & timeto <= 6, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo np1: reghdfe tot_clms ib`base'.timeto2 if type == 2 & timeto >=-3 & timeto <= 6, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo pa1: reghdfe tot_clms ib`base'.timeto2 if type == 3 & timeto >=-3 & timeto <= 6, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
coefplot md1 np1 pa1, keep(*timeto2) vertical
graph export "./graph_coef/event_1_bl_250101.jpg", as(jpg) name("Graph") quality(100) replace

preserve
replace timeto2 = `base' if ytreat == 2019
eststo md1: reghdfe tot_clms ib`base'.timeto2 if type == 1 & year<=2019, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo np1: reghdfe tot_clms ib`base'.timeto2 if type == 2 & year<=2019, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo pa1: reghdfe tot_clms ib`base'.timeto2 if type == 3 & year<=2019, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
coefplot md1 np1 pa1, keep(*timeto2) vertical
graph export "./graph_coef/event_1_nocovid_250101.jpg", as(jpg) name("Graph") quality(100) replace
restore

if `opioidflag' == 1{
** Drop opioid by keywords: more reliable 
	drop if strpos(gnrc_name, "Hydrocodone")
	drop if strpos(gnrc_name, "Dihydrocod")
	drop if strpos(gnrc_name, "Codeine")
	drop if strpos(gnrc_name, "Fentanyl")
	drop if strpos(gnrc_name, "Morphine")
	drop if strpos(gnrc_name, "Buprenorphine")
	drop if strpos(gnrc_name, "Opium")
	drop if strpos(gnrc_name, "Butorphanol")
	drop if strpos(gnrc_name, "Tramadol")
	drop if strpos(gnrc_name, "Hydromorphone")
	drop if strpos(gnrc_name, "Methadone")
	drop if strpos(gnrc_name, "Oxycodone")
	drop if strpos(gnrc_name, "Levorphanol")
	drop if strpos(gnrc_name, "Tapentadol")
	drop if strpos(gnrc_name, "Oxymorphone")
	drop if strpos(gnrc_name, "Pentazocine")
	drop if strpos(gnrc_name, "Topiramate")
}

eststo md2: reghdfe tot_clms ib`base'.timeto2 if type == 1, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo np2: reghdfe tot_clms ib`base'.timeto2 if type == 2, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)
eststo pa2: reghdfe tot_clms ib`base'.timeto2 if type == 3, absorb(i.gnrc_cd i.year i.id_class#i.year) vce(robust)

coefplot md2 np2 pa2, keep(3.timeto2 4.timeto2 5.timeto2 6.timeto2 7.timeto2 8.timeto2 9.timeto2 10.timeto2 11.timeto2) vertical
graph export "./graph_coef/event_2_250101.jpg", as(jpg) name("Graph") quality(100) replace


*eststo all: reghdfe tot_clms ib`base'.timeto2 ib`base'.timeto2#ib1.type, absorb(i.gnrc_cd i.year i.id_class#i.year i.type#i.year) vce(robust)

** Rising trend in NP is due to a drug treated in 2019. If omitted, trend disappears. 
eststo np1: qui reg tot_clms ib`base'.timeto2 i.gnrc_cd i.year i.id_class#i.year if type == 2 & timeto >=-3 & (ytreat == 2015 | ytreat == .)
eststo np2: qui reg tot_clms ib`base'.timeto2 i.gnrc_cd i.year i.id_class#i.year if type == 2 & timeto >=-3 & (ytreat == 2016 | ytreat == .)
eststo np3: qui reg tot_clms ib`base'.timeto2 i.gnrc_cd i.year i.id_class#i.year if type == 2 & timeto >=-3 & (ytreat == 2017 | ytreat == .)
eststo np4: qui reg tot_clms ib`base'.timeto2 i.gnrc_cd i.year i.id_class#i.year if type == 2 & timeto >=-3 & (ytreat == 2018 | ytreat == .)
eststo np5: qui reg tot_clms ib`base'.timeto2 i.gnrc_cd i.year i.id_class#i.year if type == 2 & timeto >=-3 & (ytreat == 2019 | ytreat == .)


***
** Specification 2: State-year FE
***
preserve
**
* Drug classification
**
merge m:1 gnrc_name using ./drug_names/partd_class_ver241230, gen(_class)
merge m:1 state_fips using scopechange_data, keepusing(NP_year) gen(_sop)
gen sop_status = NP_year <= year

collapse (sum) tot_clms tot_30day_fills (first) ytreat id_class (mean) sop_status, by(type gnrc_name year state_fips)
gen genericname = upper(gnrc_name)
if `opioidflag' == 1{
	capture merge m:1 genericname using `temp'
	capture drop if opioidflag== "Y"
}
encode gnrc_name, gen(gnrc_cd)

gen timeto = year-ytreat
replace timeto = -1 if ytreat == .

summ timeto, detail
local min=r(min)
gen timeto2 = timeto - `min'
summ timeto2 if timeto == -1
local base = r(min)

summ timeto2, detail
local max=r(max)
local timeto2
forvalues i=0/`max'{
	local val=`i'+`min'
	local timeto2 `timeto2' `i' "`val'"
	label define timeto2 `timeto2', replace
}
label val timeto2 timeto2

gen l_tot_clms = log(tot_clms)
eststo md: qui reg l_tot_clms i.state_fips#i.year i.state_fips#i.id_class i.id_class#i.year ib`base'.timeto2 ib`base'.timeto2#i.sop_status i.id_class i.year if type == 1
eststo np: qui reg l_tot_clms i.state_fips#i.year i.state_fips#i.id_class i.id_class#i.year ib`base'.timeto2 ib`base'.timeto2#i.sop_status i.id_class i.year if type == 2
eststo pa: qui reg l_tot_clms i.state_fips#i.year i.state_fips#i.id_class i.id_class#i.year ib`base'.timeto2 ib`base'.timeto2#i.sop_status i.id_class i.year if type == 3

gen l_tot_30day = log(tot_30day_fills)
eststo md: qui reg l_tot_30day i.state_fips#i.year i.state_fips#i.id_class i.id_class#i.year ib`base'.timeto2 ib`base'.timeto2#i.sop_status i.id_class i.year if type == 1
eststo np: qui reg l_tot_30day i.state_fips#i.year i.state_fips#i.id_class i.id_class#i.year ib`base'.timeto2 ib`base'.timeto2#i.sop_status i.id_class i.year if type == 2
eststo pa: qui reg l_tot_30day i.state_fips#i.year i.state_fips#i.id_class i.id_class#i.year ib`base'.timeto2 ib`base'.timeto2#i.sop_status i.id_class i.year if type == 3

esttab md np pa, keep(*timeto2 *sop_status)
coefplot md np pa, keep(*timeto2#1.sop_status) rename(0.timeto2#1.sop_status = "-6" 1.timeto2#1.sop_status = "-5" 2.timeto2#1.sop_status = "-4" 3.timeto2#1.sop_status = "-3" 4.timeto2#1.sop_status = "-2" 5.timeto2#1.sop_status = "-1" 6.timeto2#1.sop_status = "0" 7.timeto2#1.sop_status = "1" 8.timeto2#1.sop_status = "2" 9.timeto2#1.sop_status = "3" 10.timeto2#1.sop_status = "4" 11.timeto2#1.sop_status = "5" 12.timeto2#1.sop_status = "6" 13.timeto2#1.sop_status = "7")  vertical
