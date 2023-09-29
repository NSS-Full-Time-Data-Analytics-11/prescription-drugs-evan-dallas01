--MVP--

/*a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.*/
SELECT npi, SUM(total_claim_count+total_claim_count_ge65) AS claims
FROM prescriber
FULL JOIN prescription
USING(npi)
GROUP BY npi
ORDER BY claims DESC NULLS LAST;

/*b. Repeat the above, but this time report the nppes_provider_first_name, 
	 nppes_provider_last_org_name,  specialty_description, and the total number of claims.*/
SELECT CONCAT(nppes_provider_first_name, ' ', nppes_provider_last_org_name) AS prescriber_name, 
		npi, 
		specialty_description, 
		SUM(total_claim_count+total_claim_count_ge65) AS claims
FROM prescriber
FULL JOIN prescription
USING(npi)
GROUP BY npi, 
		prescriber_name, 
		specialty_description
ORDER BY claims DESC NULLS LAST;

/*a. Which specialty had the most total number of claims (totaled over all drugs)?*/

SELECT specialty_description, 
		SUM(total_claim_count+total_claim_count_ge65) AS claims
FROM prescriber
FULL JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY claims DESC NULLS LAST;

/* b. Which specialty had the most total number of claims for opioids?*/

SELECT specialty_description, 
		SUM(total_claim_count+total_claim_count_ge65) AS claims
FROM prescription
FULL JOIN prescriber
USING(npi)
FULL JOIN drug
USING(drug_name)
WHERE opioid_drug_flag='Y' OR long_acting_opioid_drug_flag='Y'
GROUP BY specialty_description
ORDER BY claims DESC NULLS LAST;

/*c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?*/

SELECT specialty_description,
		SUM(total_claim_count) AS claims
FROM prescriber
FULL JOIN prescription
USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claim_count) IS NULL OR SUM(total_claim_count)=0;

/*d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. 
	 Which specialties have a high percentage of opioids?*/

SELECT ROUND(SUM((opioid_ct.num_opioid_claims/total_ct.num_of_claims)*100),3) AS percentage_opioid, opioid_ct.specialty_description
FROM 
		--table that contains # of opioid claims by specialty
		(SELECT SUM(total_claim_count) AS num_opioid_claims, specialty_description
			 FROM prescription
			 FULL JOIN prescriber
			 USING(npi)
			 FULL JOIN drug
			 USING(drug_name)
			 WHERE opioid_drug_flag='Y' OR long_acting_opioid_drug_flag='Y'
		 	 GROUP BY specialty_description
		  	 HAVING SUM(total_claim_count)>0
		 	 ORDER BY SUM(total_claim_count) DESC) AS opioid_ct,
	 	--table that contains total claims by specialty
	 	(SELECT SUM(total_claim_count) AS num_of_claims, specialty_description
			 FROM prescription
			 FULL JOIN prescriber
 			 USING(npi) 
			 GROUP BY specialty_description
			 HAVING SUM(total_claim_count)>0
			 ORDER BY num_of_claims DESC) AS total_ct
WHERE opioid_ct.specialty_description=total_ct.specialty_description
GROUP BY opioid_ct.specialty_description
ORDER BY percentage_opioid DESC;


/*a. Which drug (generic_name) had the highest total drug cost?*/

SELECT generic_name, SUM(total_drug_cost+total_drug_cost_ge65) AS tot_cost
FROM drug
FULL JOIN prescription
USING(drug_name)
GROUP BY generic_name
ORDER BY tot_cost DESC NULLS LAST;

/*b. Which drug (generic_name) has the hightest total cost per day? 
 	 Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.*/

SELECT generic_name, ROUND(SUM((total_drug_cost+total_drug_cost_ge65)/365),2) AS tot_cost_per_day
FROM drug
FULL JOIN prescription
USING(drug_name)
GROUP BY generic_name
ORDER BY tot_cost_per_day DESC NULLS LAST;

/*a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which 
	 have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.*/
	 
SELECT drug_name,
		CASE WHEN opioid_drug_flag='Y' THEN 'opioid' 
		WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug
GROUP BY drug_name, drug_type;

/* b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics.
	  Hint: Format the total costs as MONEY for easier comparision.*/
	  
SELECT CASE WHEN opioid_drug_flag='Y' THEN 'opioid' 
		WHEN antibiotic_drug_flag='Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type,
		CAST(SUM(total_drug_cost) AS money) AS cost
FROM drug
FULL JOIN prescription
USING(drug_name)
GROUP BY drug_type
ORDER BY cost DESC;

/*a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.*/

SELECT COUNT(DISTINCT cbsa) AS num_of_cbsa
FROM cbsa
FULL JOIN fips_county
USING(fipscounty)
WHERE state='TN';

/*b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.*/

SELECT cbsaname, SUM(population) AS pop_total
FROM cbsa
JOIN fips_county
USING(fipscounty)
JOIN population
USING(fipscounty)
GROUP BY cbsaname
ORDER BY pop_total DESC;

/*c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.*/

SELECT cbsa, county, SUM(population) AS pop_total
FROM cbsa
FULL JOIN fips_county
USING(fipscounty)
FULL JOIN population
USING(fipscounty)
WHERE cbsa IS NULL
GROUP BY county, cbsa
ORDER BY pop_total DESC NULLS LAST;

/*a. Find all rows in the prescription table where total_claims is at least 3000. 
	 Report the drug_name and the total_claim_count.*/
	 
SELECT drug_name, total_claim_count
FROM prescription
JOIN drug
USING(drug_name)
WHERE total_claim_count>3000
ORDER BY total_claim_count DESC;

/*b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.*/

SELECT drug_name, total_claim_count,
		CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		ELSE 'non-opioid' END AS drug_type
FROM prescription
JOIN drug
USING(drug_name)
WHERE total_claim_count>3000
ORDER BY total_claim_count DESC;

/*c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.*/

SELECT drug_name, total_claim_count,
		CASE WHEN opioid_drug_flag='Y' THEN 'opioid'
		ELSE 'non-opioid' END AS drug_type,
		CONCAT(nppes_provider_first_name,' ',nppes_provider_last_org_name) AS prescriber_name
FROM prescription
JOIN drug
USING(drug_name)
JOIN prescriber
USING(npi)
WHERE total_claim_count>3000
ORDER BY total_claim_count DESC;

/*The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid.
**Hint:** The results from all 3 parts will have 637 rows.

a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment')
in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. 
You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.*/

SELECT prescriber.npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description='Pain Management' 
	  AND nppes_provider_city='NASHVILLE' 
	  AND opioid_drug_flag='Y'
ORDER BY npi ASC, drug_name ASC;


/*b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
You should report the npi, the drug name, and the number of claims (total_claim_count).

  c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.*/

WITH drug_combos AS (SELECT prescriber.npi, drug_name
					 FROM prescriber
					 CROSS JOIN drug
					 WHERE specialty_description='Pain Management' 
	 					 AND nppes_provider_city='NASHVILLE' 
	  					 AND opioid_drug_flag='Y'
					 ORDER BY npi ASC, drug_name ASC),
					 
	real_presc  AS (SELECT npi, drug_name, SUM(total_claim_count) AS total_ct
					FROM prescription
					JOIN prescriber
					USING(npi)
					JOIN drug
					USING(drug_name)
					WHERE specialty_description='Pain Management' 
											 AND nppes_provider_city='NASHVILLE' 
											 AND opioid_drug_flag='Y'
					GROUP BY drug_name,npi
					ORDER BY total_ct DESC, npi)

SELECT drug_combos.npi,
	   drug_combos.drug_name, 
	   COALESCE(total_ct, 0) AS total_claims
FROM drug_combos
LEFT JOIN real_presc
ON drug_combos.npi=real_presc.npi AND drug_combos.drug_name=real_presc.drug_name
ORDER BY  drug_combos.npi, total_claims DESC NULLS LAST;


	  
--BONUS------------------------------------	  

/*1. How many npi numbers appear in the prescriber table but not in the prescription table?*/

SELECT COUNT(DISTINCT prescriber.npi) AS prescriber_total_npis,
	   COUNT(DISTINCT prescription.npi) AS prescription_total_npis,
	   COUNT(DISTINCT prescriber.npi)-COUNT(DISTINCT prescription.npi) AS difference
FROM prescriber
FULL JOIN prescription
USING(npi);

/*2.a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.*/

SELECT generic_name, SUM(total_claim_count) AS total_claims,specialty_description
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber
USING(npi)
WHERE specialty_description ILIKE 'Family Practice'
GROUP BY generic_name, specialty_description
ORDER BY total_claims DESC
LIMIT 5;

/*b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.*/

SELECT generic_name, SUM(total_claim_count) AS total_claims,specialty_description
FROM drug
JOIN prescription
USING(drug_name)
JOIN prescriber
USING(npi)
WHERE specialty_description ILIKE 'Cardiology'
GROUP BY generic_name, specialty_description
ORDER BY total_claims DESC
LIMIT 5;

/*c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 
     Combine what you did for parts a and b into a single query to answer this question.*/

WITH cardio_drug AS (SELECT generic_name, SUM(total_claim_count) AS cardio_total_claims, specialty_description
					FROM drug
					JOIN prescription
					USING(drug_name)
					JOIN prescriber
					USING(npi)
					WHERE specialty_description ILIKE 'Cardiology'
					GROUP BY generic_name, specialty_description
					ORDER BY cardio_total_claims DESC
					LIMIT 5),
				
   fam_prac_drug AS (SELECT generic_name, SUM(total_claim_count) AS famprac_total_claims, specialty_description
					FROM drug
					JOIN prescription
					USING(drug_name)
					JOIN prescriber
					USING(npi)
					WHERE specialty_description ILIKE 'Family Practice'
					GROUP BY generic_name, specialty_description
					ORDER BY famprac_total_claims DESC
					LIMIT 5)
				
SELECT generic_name, famprac_total_claims, cardio_total_claims
FROM fam_prac_drug
INNER JOIN cardio_drug
USING(generic_name);
	 
/*3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
	
	a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. 
	Report the npi, the total number of claims, and include a column showing the city.*/
	
SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city
FROM prescriber
JOIN prescription
USING(npi)
WHERE nppes_provider_city ILIKE 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC, npi
LIMIT 5;
	
/*  b. Now, report the same for Memphis.*/

SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city
FROM prescriber
JOIN prescription
USING(npi)
WHERE nppes_provider_city ILIKE 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC, npi
LIMIT 5;

/*c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.*/

(SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city
	FROM prescriber
	JOIN prescription
	USING(npi)
	WHERE nppes_provider_city ILIKE 'NASHVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC, npi
	LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city
	FROM prescriber
	JOIN prescription
	USING(npi)
	WHERE nppes_provider_city ILIKE 'MEMPHIS'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC, npi
	LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city
	FROM prescriber
	JOIN prescription
	USING(npi)
	WHERE nppes_provider_city ILIKE 'KNOXVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC, npi
	LIMIT 5)
UNION
(SELECT npi, SUM(total_claim_count) AS total_claims, nppes_provider_city
	FROM prescriber
	JOIN prescription
	USING(npi)
	WHERE nppes_provider_city ILIKE 'CHATTANOOGA'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC, npi
	LIMIT 5)
ORDER BY nppes_provider_city DESC, total_claims DESC;


/*4. Find all counties which had an above-average number of overdose deaths. 
	 Report the county name and number of overdose deaths.*/

SELECT county, SUM(overdose_deaths) AS total_od_deaths
FROM fips_county
JOIN overdose_deaths
ON (fips_county.fipscounty)::integer=overdose_deaths.fipscounty
WHERE overdose_deaths > (SELECT AVG(overdose_deaths)
						 FROM overdose_deaths)
GROUP BY county
ORDER BY total_od_deaths DESC;

/*5. a. Write a query that finds the total population of Tennessee.*/

SELECT SUM(population) AS TN_population
FROM population
JOIN fips_county
USING(fipscounty)
GROUP BY state;

/*b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, 
	 and the percentage of the total population of Tennessee that is contained in that county.*/
SELECT county, 
	   population, 
	   ROUND((population/(SELECT SUM(population)
					FROM population
					JOIN fips_county
					USING(fipscounty)
					GROUP BY state))*100,3) AS percent_of_TN_pop	 
FROM population
JOIN fips_county
USING(fipscounty)
ORDER BY percent_of_TN_pop DESC;



