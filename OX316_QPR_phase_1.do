/*
*filename	OX316_QPR_phase_1
*author		AS_JH adapted
*date		21.11.2023
*version	1
*/

*-----------------------------------------------------
****This code is for illustrative purposes only******
*-----------------------------------------------------

*SET GLOBALS (Time intervals - Deliveries and Losses)
global min_delivery_duration "175" // minimum length of a delivery episode
global min_loss_duration "56"     // minimum length of a pregnancy loss episode

*-----------------------------------------------------------------------------------
*calculate difference between each field and generate episode marker - HES Maternity
*-----------------------------------------------------------------------------------

forvalues x==2/`max' {
	
	local n = `x'-1
	gen dif`x'=.
	replace dif`x'=pregnancy_date`x'- pregnancy_date`n' if pregnancy_date`x' !=.
	
	count if dif`x' >= gestat_days`x'
	
	if `r(N)' !=0 {
		
	gen episode_marker`x'=""
	replace episode_marker`x'="Episode" if (dif`x' >= gestat_days`x' & dif`x' !=.)
	
	}
	
}

*---------------------------------------------------------------------------
*Define pregnancy episodes for all individuals with a HES Maternity record
*---------------------------------------------------------------------------
	

	forvalues x==2/14 {
	
	local n = `x'- 1
	gen dif`x'=.
	gen dif_preg`x'=.
	gen dif_preg2`x'=.
	replace dif_preg`x'=preg1date_patid`x'-date`x' if preg1date_patid`x' !=.
	replace dif_preg2`x'=preg2date_patid`x'-date`x' if preg2date_patid`x' !=.
	replace dif`x'=date`x'-date`n' if date`x' !=.
	gen level=`x'
	
	count if level==2
	
	if `r(N)' !=0 {
	
	gen dif`n'=.
	gen dif_preg`n'=.
	gen dif_preg2`n'=.
	replace dif_preg`n'=preg1date_patid`n'-date`n'
	replace dif_preg2`n'=preg2date_patid`n'-date`n'
	
	}
	
	********************************
	*events prior to first pregnancy
	********************************
	
	*create episode (event 1)
	replace episode_marker`n'="Episode" if ((level==2 & dif`x' >= gestat_preg1_patid`x'  & pregnancy_type`x'=="Delivery" &pregnancy_type`n'=="Delivery" & maternity_preg_`x'==1 & flag_prior_preg1`n'==1) | (level==2 & dif`n'==. & dif_preg`n' >= gestat_preg1_patid`n' & pregnancy_type`x'=="Delivery" & pregnancy_type`n'=="Delivery" & maternity_preg`x'==1 & flag_prior_preg1`n'==1))
	
	replace episode_marker`n'="Episode" if (level==2 & dif`x' >= gestat_preg1_patid`x' & pregnancy_type`x'=="Delivery" & pregnancy_type`n'=="loss" & maternity_preg`x'==1 & flag_prior_preg1`n'==1)
	
	replace episode_marker`n'="Episode" if (level==2 & dif`n'==. & dif_preg`n' >= gestat_preg1_patid`n' & pregnancy_type`n'=="loss" & pregnancy_type`x'=="loss" & flag_prior_preg1`n'==1 & flag_prior_preg1`x'==1)
	
	replace episode_marker`n'="Episode" if (level==2 & dif`n'==. & dif_preg`n' >= gestat_preg1_patid`n' & pregnancy_type`n'=="loss" & pregnancy_type`x'=="Delivery" & flag_prior_preg1`n'==1 & flag_prior_preg1`x'==1)
	
	*create episode (events >=2)
	replace episode_marker`x'="Episode" if (dif`x' >= $min_delivery_duration & pregnancy_type`x'=="Delivery" & pregnancy_type`n'=="Delivery" & dif_preg`x' >= gestat_preg1_patid`x' & flag_prior_preg1`x'==1 & flag_prior_preg1`n'==1 )
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_loss_duration & pregnancy_type`x'=="loss" & pregnancy_type`n'=="Delivery" & dif_preg`x' >= gestat_preg1_patid`x' & flag_prior_preg1`x'==1 & flag_prior_preg1`n'==1)
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_loss_duration & pregnancy_type`x'=="loss" & pregnancy_type`n'=="loss" & dif_preg`x' >= gestat_preg1_patid`x' & flag_prior_preg1`x'==1 & flag_prior_preg1`n'==1)
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_delivery_duration & pregnancy_type`x'=="Delivery" & pregnancy_type`n'=="loss" & dif_preg`x' >= gestat_preg1_patid`x' & flag_prior_preg1`x'==1 & flag_prior_preg1`n'==1)
	
	*************************************
	*events between 1st and 2nd pregnancy
	*************************************
	replace episode_marker`x'="Episode" if (dif`x' >= $min_delivery_duration & pregnancy_type`x'=="Delivery" & pregnancy_type`n'=="Delivery" & dif_preg`x' <= -$min_delivery_duration & dif_preg2`x' >= gestat_preg2_patid`x' & flag_preg1_preg2`x'==1 & (flag_preg1_preg2`n'==1 | maternity_preg`n'==1))
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_loss_duration & pregnancy_type`x'=="loss" & pregnancy_type`n'=="Delivery" & dif_preg`x' <= -$min_loss_duration & dif_preg2`x' >= gestat_preg2_patid`x' & flag_preg1_preg2`x'==1 & (flag_preg1_preg2`n'==1 | maternity_preg`n'==1))
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_loss_duration & pregnancy_type`x'=="loss" & pregnancy_type`n'=="loss" & dif_preg`x' <= -$min_loss_duration & dif_preg2`x' >= gestat_preg2_patid`x' & flag_preg1_preg2`x'==1 & flag_preg1_preg2`n'==1)
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_delivery_duration & pregnancy_type`x'=="Delivery" & pregnancy_type`n'=="loss" & dif_preg`x' <= -$min_delivery_duration & dif_preg2`x' >= gestat_preg2_patid`x' & flag_preg1_preg2`x'==1 & flag_preg1_preg2`n'==1)
	
	**********************************
	*events after the second pregnancy
	**********************************
	replace episode_marker`x'="Episode" if (dif`x' >= $min_delivery_duration & pregnancy_type`x'=="Delivery" & pregnancy_type`n'=="Delivery" & & dif_preg2`x' <= -$min_delivery_duration & flag_after_preg2`x'==1 & (flag_after_preg2`n'==1 | maternity_preg`n'==2))
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_loss_duration & pregnancy_type`x'=="loss" & pregnancy_type`n'=="Delivery" & dif_preg2`x' <= -$min_loss_duration & flag_after_preg2`x'==1 & (flag_after_preg2`n'==1 | maternity_preg`n'==2))
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_loss_duration & pregnancy_type`x'=="loss" & pregnancy_type`n'=="loss" & dif_preg2`x'  <= -$min_loss_duration & flag_after_preg2`x'==1 & flag_after_preg2`n'==1)
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_delivery_duration & pregnancy_type`x'=="Delivery" & pregnancy_type`n'=="loss" & dif_preg2`x' <= -$min_delivery_duration & flag_after_preg2`x'==1 & flag_after_preg2`n'==1)
	
	drop level
	}