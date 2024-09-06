/*
*filename	OX316_QPR_phase_3 + prioritisation
*author		AS_JH adapted
*date		21.11.2023

*------------------------------------------------------
****This code is for illustrative purposes only******
*------------------------------------------------------

*Identify the women with a pregnacy loss episode but no delivery record.
use "all pregnancy losses", clear

*identify pregnancies
cap noisily drop _merge
merge m:1 patid using "modified_datasets\patids_with_delivery_outcome.dta", keepusing(patid)
keep if _merge==1
drop _merge

*remove loss type/date/patid duplicates
duplicates drop patid pregloss_all date, force

duplicates tag patid date, gen(dup)
tab dup

*
tab pregloss_all
tab pregloss_all, nolabel

gen miscarriage=0
gen termination=0
gen ectopic=0
gen molar=0
gen blighted=0
gen probtop=0
gen unspecified=0


*preserve
*keep if dup > 0
replace miscarriage=1 if pregloss_all==1
replace termination=1 if pregloss_all==2
replace ectopic=1 if pregloss_all==3
replace molar=1 if pregloss_all==4
replace blighted=1 if pregloss_all==5
replace probtop=1 if pregloss_all==6
replace unspecified=1 if pregloss_all==7


*Identify records patid date duplicates with at least one miscarriage/termination recorded
bysort patid date: egen miscar_patid=max(miscarriage)
bysort patid date: egen termin_patid=max(termination)
bysort patid date: egen ectopic_patid=max(ectopic)
bysort patid date: egen molar_patid=max(molar)
bysort patid date: egen blighted_patid=max(blighted)
bysort patid date: egen probtop_patid=max(probtop)
bysort patid date: egen unspecified_patid=max(unspecified)

tab pregloss_all

*remove non-termnations from duplicate sets with at least one termination record for that day. Outcome prioritisation per episode: 1) Ectopic 2) termination 3) miscarriage 4) molar 5) blighted ovum
drop if (ectopic_patid==1 & ectopic==0 & dup > 0)
drop if (termin_patid==1 & termination==0 & ectopic==0 & dup > 0)
drop if (miscar_patid==1 & miscarriage==0 & termination==0 & ectopic==0 & dup > 0)
drop if (probtop_patid==1 & probtop==0 & miscarriage==0 & termination==0 & ectopic==0 & dup > 0)
drop if (molar_patid==1 & molar==0 & probtop==0 & miscarriage==0 & termination==0 & ectopic==0 & dup > 0)
drop if (unspecified_patid==1 & unspecified==0 & molar==0 & probtop==0 & miscarriage==0 & termination==0 & ectopic==0 & dup > 0)

tab pregloss_all

drop dup
duplicates tag patid date, gen(dup)
tab dup // shold be 0 duplicates
drop dup 

*sort by patid and event date
sort patid date

*count number of events by patient
by patid: gen eventcount=_n

drop miscarriage termination ectopic molar blighted probtop unspecified miscar_patid termin_patid ectopic_patid molar_patid blighted_patid probtop_patid unspecified_patid

gen eventcount_flag=1
bysort eventcount_flag: egen max_events=max(eventcount)
local max = max_events
di in red "There is a maximum of `max' events per patient"
drop eventcount_flag max_events

*reshape data to wide format
reshape wide date source pregloss_all numbaby, i(patid) j(eventcount)

gen episode_1=date1
format episode_1 %td

*calculate difference between each field and generate episode marker
forvalues x==2/`max' {
	
	local n = `x'-1
	gen dif`x'=.
	replace dif`x'=date`x'-date`n' if date`x' !=.
	
	count if dif`x' >= 56
	
	if `r(N)' !=0 {
		
	gen marker`x'=""
	replace marker`x'="Episode" if (dif`x' >= 56 & dif`x' !=.)
	
	}
	
}

reshape long marker date source pregloss_all dif numbaby, i(patid) j(eventcount)

drop if (source=="" & pregloss_all==. & dif==. & marker=="" & date==.)

replace marker="Episode" if eventcount==1


*temporarily remove all interim diagnoses from dataset and create seperate dataset
preserve

keep if marker==""

save "pregloss_toappend.dta", replace

restore


*remove all interim diagnoses
drop if marker==""

sort patid date

*generate new episode count variable
by patid: gen episode_count=_n

*tabulate number of episodes
tab episode_count

append using "pregloss_toappend.dta"

*remove old eventcount variable
drop eventcount
*create new variable to assist with the identification of index diagnoses
gen eventcount=episode_count

sort patid date

gen episodecount_flag=1
bysort episodecount_flag: egen max_episodes=max(episode_count)
local max_episodes = max_episodes
local reduced_max = max_episodes-1
di in red "There is a maximum of `max_episodes' episodes per patient"
di in red "`max_episodes'-1 = `reduced_max'"
drop episodecount_flag max_episodes

*create episode date field
forvalues x==1/`max_episodes' {
	
	gen episode`x'_date=.
	replace episode`x'_date=date if episode_count==`x'
	format episode`x'_date %td

}

*Apply episode number to all interim dates in the episode
forvalues x==1/`max_episodes' {
	
	bysort patid: egen episode`x'_date_all=max(episode`x'_date)
	format episode`x'_date_all %td
}

*Allocate correct episode number to each unassigned, interim date (episode 1 to 5)
forvalues x==1/`reduced_max' {

	local n=`x'+1

	replace episode_count=`x' if (date < episode`n'_date_all & date > episode`x'_date_all & episode_count==. & episode`n'_date_all !=.)
	replace episode_count=`x' if (date > episode`x'_date_all & episode`n'_date_all==. & episode_count==.)	
}


*Allocate correct episode number to each unassigned, interim date (last episode)
replace episode_count=`max_episodes' if (date > episode`max_episodes'_date_all & episode_count==.)
count if episode_count==.

*drop dating fields generated for allocation
forvalues x==1/`max_episodes' {
	
	drop episode`x'_date_all
}

*Outcome prioritisation per episode: 1) Ectopic 2) termination 3) miscarriage 4) molar 5) blighted ovum
forvalues x==1/`max_episodes' {
	
	by patid: gen miscarriage`x'=pregloss_all if (pregloss_all==1 & episode_count==`x') 
		 
	
}

forvalues x==1/`max_episodes' {
	
	by patid: gen termination`x'=pregloss_all if (pregloss_all==2 & episode_count==`x') 
		 
	
}

forvalues x==1/`max_episodes' {
	
	by patid: gen ectopic`x'=pregloss_all if (pregloss_all==3 & episode_count==`x') 
		 
	
}

forvalues x==1/`max_episodes' {
	
	by patid: gen molar`x'=pregloss_all if (pregloss_all==4 & episode_count==`x') 
		 
}

forvalues x==1/`max_episodes' {
	
	by patid: gen blighted`x'=pregloss_all if (pregloss_all==5 & episode_count==`x') 
		 
}

forvalues x==1/`max_episodes' {
	
	by patid: gen prob_top`x'=pregloss_all if (pregloss_all==6 & episode_count==`x')
	
}

forvalues x==1/`max_episodes' {
	
	by patid: gen unspecified`x'=pregloss_all if (pregloss_all==7 & episode_count==`x')
	
}

*apply to all variables
foreach y in miscarriage termination ectopic molar blighted prob_top unspecified {

forvalues x==1/`max_episodes' {
	
	bysort patid: egen `y'`x'_all=max(`y'`x') if episode_count==`x'
		 
	
}

}


*Apply prioritisation: 1) Ectopic 2) termination 3) miscarriage 4) probable TOP 5) molar 6) Unspecified pregnancy loss 7) blighted ovum

forvalues x==1/`max_episodes' {
	
	replace pregloss_all=3 if (eventcount==`x' & ectopic`x'_all==3 & episode_count==`x')
	replace pregloss_all=2 if (eventcount==`x' & termination`x'_all==2 & ectopic`x'_all==. & episode_count==`x')
	replace pregloss_all=1 if (eventcount==`x' & miscarriage`x'_all==1 & termination`x'_all==. & ectopic`x'_all==. & episode_count==`x')
	replace pregloss_all=6 if (eventcount==`x' & prob_top`x'_all==6 & miscarriage`x'_all==. & termination`x'_all==. & ectopic`x'_all==. & episode_count==`x')
	replace pregloss_all=4 if (eventcount==`x' & molar`x'_all==4 & prob_top`x'_all==. & miscarriage`x'_all==. & termination`x'_all==. & ectopic`x'_all==. & episode_count==`x')
	replace pregloss_all=7 if (eventcount==`x' & unspecified`x'_all==7 & molar`x'_all==. & prob_top`x'_all==. & miscarriage`x'_all==. & termination`x'_all==. & ectopic`x'_all==. & episode_count==`x' )
} 

*keep the index event for each episode only
keep if eventcount !=.
tab pregloss_all
	   
drop episode_1 eventcount miscarriage* ectopic* molar* blighted* termination* prob_top* unspecified*

*create dataset variable
gen dataset="loss"

gen source_num=.
replace source_num=1 if source=="HM"
replace source_num=2 if source=="APC"
replace source_num=3 if source=="HP"
replace source_num=4 if source=="GP"

drop source
rename source_num source
label define source 1 "HES maternity" 2 "HES APC" 3 "OPCS" 4 "GP"
la val source source

drop numbaby

*save final dataset
save "final dataset", replace
