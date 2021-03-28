/* NOTE: The dataset is imported into a table named "data" */

/*Making some changes in the dataset*/
alter table data add column claim_flag integer;
update data set claim_flag = (case when ClaimNum=0 then 0 else 1 end);
/*Here we have set the value to 0 when ClaimNum is  0 and 1 otherwise.
This column can be used to find out whether a claim has been made or not
1 means 'Yes' and 0 means 'No'
*/

/* The following set of question are answered to perform EDA*/

/* Q1. What % of the customers have made a claim in the given exposure period*/
select round(sum(case when ClaimNum=0 then 0 else 1 end)*100/round(count(*)),2) as 'Percent_of_customers' from data;
/*Ans: 5.02% of customers have made a claim in the present exposure period*/

/* Q2. What is the average exposure period for those who have made a claim? */
select claim_flag , round(avg(Exposure),2) as 'Avg_Exposure' from data group by claim_flag;
/*Ans: 0.64 is the average exposure period for those who have claimed
Average exposure for those who have claimed (0.64) is more than those who haven’t (0.52). 
It means that customers having higher exposure to insurance are more likely to claim a policy.
*/

/* Q3. Divide the data into exposure buckets and find out what is the % of total claims by these buckets?
Buckets used => E1 = 0 to 0.25, E2 = 0.26 to 0.5, E3 = 0.51 to 0.75, E4 > 0.75 */
select case when (Exposure>=0 and Exposure<=0.25) then 'E1'
when (Exposure>=0.26 and Exposure<=0.5) then 'E2'
when (Exposure>=0.51 and Exposure<=0.75) then 'E3'  
when Exposure>0.75 then 'E4'
END as 'buckets', 
round(sum(ClaimNum)*100/round(count(*)),1) as 'percent_claim_by_bkts' from data group by buckets;
/*Ans: E1 – 3.2%, E2 – 4.9%, E3 – 6.5%, E4- 7.1% 
Here we have used ClaimNum field to get the total claim count */

/* Q4. Which area has the highest number of average claims? */
select Area, round(avg(ClaimNum)*100,2) as 'percent_avg_claims' from data group by Area order by 'percent_avg_claims' DESC;
/*Ans: Area 'F' has the highest percent of avg claims = 6.3% */

/* Q5. Grouping Area and Exposure Buckets together to analyze the claim rate*/
select 
case 	
	when (Exposure>=0 and Exposure<=0.25) then 'E1'
	when (Exposure>=0.26 and Exposure<=0.5) then 'E2'
	when (Exposure>=0.51 and Exposure<=0.75) then 'E3'  
	when Exposure>0.75 then 'E4'
END as 'buckets', 
Area, round(sum(ClaimNum)*100/round(count(*)),4) as 'percent_buckets' 
from data 
group by buckets, Area order by percent_buckets DESC;
/*The highest claim rate found was of customers in exposure bucket E4(having exposure > 0.75) and of Area ‘F’ (=8.8278%); followed up by customers of Area ‘E’ in the same exposure bucket (approximately 8.6%).
The trend that people having more exposure, have higher claim rate can also be seen here. 
Moreover, people in Area ‘F’ are found to have the highest claim rate in their corresponding exposure buckets (except E3).*/

/* Q6. Find out the average Vehicle Age for those who claimed vs those who didn't claim?*/
select case when claim_flag=1 then 'Claimed' else 'Not Claimed' end as 'Claimed_or_Not', 
round(avg(VehicleAge),3) as 'Avg_Vehicle_Age' 
from data group by Claimed_or_Not;
/*The average age of vehicle for those who claimed (6.5 years) was found less than those who didn’t (7.1 years) but not by much (approximately half year).*/

/* Q7. Calculate the average Vehicle Age for those who claimed and group them by Area*/
select case when claim_flag=1 then 'Claimed' else 'Not Claimed' end as 'Claimed_or_Not',
Area, round(avg(VehicleAge),3) as 'Avg_Vehicle_Age' 
from data 
where Claimed_or_Not='Claimed' group by Area order by Avg_Vehicle_Age DESC;
/*The average vehicle age of customers in Area ‘A’ was found to be the maximum (roughly 7.5 years) meanwhile it was lowest for customers of Area ‘F’ (roughly 4 years).
Earlier we have seen that customers from Area F usually have more claim rate than rest of the areas, this seems to conform with the average vehicle age analysis as done above.
This can also mean that average accident rate in Area A is much less than that of Area F.*/

/* Q8. Calculate the average vehicle age by exposure bucket,and find out the hidden trend between those who claimed vs those who didn't?*/
select 
case 
	when (Exposure>=0 and Exposure<=0.25) then 'E1'
	when (Exposure>=0.26 and Exposure<=0.5) then 'E2'
	when (Exposure>=0.51 and Exposure<=0.75) then 'E3'  
	when Exposure>0.75 then 'E4'
END as 'buckets',
case when claim_flag=1 then 'Claimed' else 'Not Claimed' end as 'Claimed_or_Not', 
round(avg(VehicleAge),2) as 'Avg_Vehicle_Age' 
from data group by buckets,Claimed_or_Not
order by Avg_Vehicle_Age DESC;
/*From the output table it can be observed that customers in exposure bucket(E4) have the highest average vehicle age whether it be claimed or not.
And it is found that customers who haven’t claimed the policy have more average vehicle age than their claimed counter-part. This can be supported by the remarkable difference present between the average vehicle age of not-claimed and claimed category for E1 bucket, i.e. 6.37 - 4.9 = 1.47 years (approximately 1.5 years)
This means that new vehicles are at higher risk in case of low exposure customers.*/

/* Q9.1. Create a Claim_Ct flag on the ClaimNum field as below, and take average of the BM by Claim_Ct.
Note: Claim_Ct = '1 Claim' where ClaimNum = 1, Claim_Ct = 'MT 1 Claims' where ClaimNum > 1, 
Claim_Ct = 'No Claims' where ClaimNum = 0. */

/*Adding a new column to the table*/
alter table data add column Claim_Ct varchar(25);  

/*Inserting values into the column according to the given condition*/
update data set Claim_Ct = (
case 	when ClaimNum=1 then '1 Claim'
		when ClaimNum = 0 then 'No Claims'
		else 'MT 1 Claims' 
end);

select Claim_Ct,round(avg(BM),4) as 'Avg_BM' from data group by Claim_Ct order by Avg_BM DESC;
/*The average bonus malus is maximum (67.55) for category ‘MT 1 Claims’ (i.e. those who claim more than once). 
This shows that those who claim more frequently get less discount in insurance premiums.*/

/* Q9.2. Using the same Claim_Ct logic created above, if we aggregate the Density column (take average) by Claim_Ct, 
what inference can be found from data?*/
select Claim_Ct, round(avg(Density),2) as 'Avg_Density' from data GROUP by Claim_Ct;
/*The average population density is much higher for those areas where a claim has been made (1947,2297 as compared to 1783). 
Within the regions of claim (claim made once or more than once), where the claim counts are more than one, the population density is even higher (2297.45).*/

/* Q10. Which Vehicle Brand & Vehicle Gas combination have the highest number of Average Claims ?*/
select VehicleBrand as 'Vehicle_Brand', FuelType as 'Gas_type', round(avg(ClaimNum)*100,2) as 'Avg_Claim' 
from data group by VehicleBrand,FuelType order by Avg_Claim DESC;
/*Vehicle Brand ‘B12’ and Vehicle Gas as ‘Regular’ has the highest average claims (= 6.39%) amongst all vehicle brand and gas types*/

/* Q11. List the Top 5 Regions & Exposure[use the buckets created above] Combination from Claim Rate's perspective. */
select 
	case 
		when (Exposure>=0 and Exposure<=0.25) then 'E1'
		when (Exposure>=0.26 and Exposure<=0.5) then 'E2'
		when (Exposure>=0.51 and Exposure<=0.75) then 'E3'  
		when Exposure>0.75 then 'E4'
	END as 'Exposure_Bkt',
Region,
sum(ClaimNum) as 'claim_cnt',
count(ID) as 'policy_cnt',
round(avg(claim_flag),3) as 'claim_rate'
from data 
group by Region,Exposure_Bkt
order by claim_rate DESC
LIMIT 5;


/* Q12. Are there any cases of illegal driving i.e. underaged folks driving and committing accidents?*/
select count(*) as 'Illegal_count' from data where DriverAge<18;
/*Ans: No there are no cases of illegal driving*/

/* Q13. Create a bucket on DriverAge and then take average of BM by this Age Group Category. 
What do you infer from the summary?  
Note: DriverAge=18 then 1-Beginner, DriverAge<=30 then 2-Junior, DriverAge<=45 then 3-Middle Age, 
DriverAge<=60 then 4-Mid-Senior, DriverAge>60 then 5-Senior*/
select 
case 
	when (DriverAge=18) then '1-Beginner'
	when (DriverAge<=30) then '2-Junior'
	when (DriverAge<=45) then '3-Middle Age'
	when (DriverAge<=60) then '4-Mid-Senior'  
	when (DriverAge>60) then '5-Senior'  
END as 'age_group',
round(avg(BM),3) as 'avg_BM'
from data 
group by age_group;
/*It can be seen that as driving age increases average bonus malus decreases. 
This trend can be validated as the beginners have higher risk of committing accident, they will eventually make claims. 
Therefore, the discount given to these customers are much lower than other age groups.*/