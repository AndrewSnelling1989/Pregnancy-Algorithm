/*
*filename	OX316_QPR_phase_2
*author		AS_JH adapted
*date		21.11.2023
*/

*-----------------------------------------------------
****This code is for illustrative purposes only******
*-----------------------------------------------------

*SET GLOBALS (Time intervals - Deliveries and Losses)
global min_delivery_duration "175" // minimum length of a delivery episode
global min_loss_duration "56"     // minimum length of a pregnancy loss episode

*Identify pregnancy episodes
forvalues x==2/`n' {
	

	local y = `x'- 1
	gen dif`x'=.
	replace dif`x'=date`x'-date`y' if date`x' !=.
	
	replace episode_marker`x'="Episode" if (dif`x' >= $min_delivery_duration & dataset`x'=="Delivery" & dataset`y'=="Delivery") 
	replace episode_marker`x'="Episode" if (dif`x' >= $min_loss_duration & dataset`x'=="loss" & dataset`y'=="Delivery")
	replace episode_marker`x'="Episode" if (dif`x' >= $min_loss_duration & dataset`x'=="loss" & dataset`y'=="loss")
	replace episode_marker`x'="Episode" if (dif`x' >= $min_delivery_duration & dataset`x'=="Delivery" & dataset`y'=="loss")
	
}