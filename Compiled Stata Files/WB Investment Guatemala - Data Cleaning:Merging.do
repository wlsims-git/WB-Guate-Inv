** Will Sims - Is World Bank Investment in Guatemala Responsive to Departmental Needs?
** May, 2019

** DATA CLEANING/MERGING SCRIPT
** The purpose of this do file is to clean and merge the three datasets to prepare them for analysis.
** It also prepares and merges the shape file for mapping.

** PREAMBLE **
cd "/Users/wlsims/Desktop/WB Investment/Compiled Stata Files"
ssc install spmap
ssc install shp2dta 
* Files required in the wd: EthnicityData.xlsx, AidData.csv, PovertyData.xlsx, gadm36_GTM_1.shp, gadm36_GTM_1.dbf

** CLEANING ETHNICITY DATA **
import excel "EthnicityData.xlsx", sheet("Sheet1") firstrow
* Fixing weird characters 
replace Ladino = subinstr(Ladino, ",", ".", .)
replace Departamento = subinstr(Departamento, "é", "e", .)
replace Departamento = subinstr(Departamento, "á", "a", .)
* Rename and relabel variables
rename Departamento Department
rename Ladino NonIndigenous_Share
label variable Department "Name of Department"
label variable NonIndigenous_Share "Share of the population not of indigenous descent"
*Creating new variable to represent indigenous share of population
gen Indigenous_Percent = 1-(real(NonIndigenous_Share)/100)
label variable Indigenous_Percent "Percentage of the population of indigenous descent"
* Remove misspellings and leading spaces from Department names
replace Department = subinstr(Department, " ", "", 1)
replace Department = subinstr(Department, "Quetzaltenango", "Quezaltenango", .)
* Save cleaned dataset
save EthnicityData_CLEAN.dta, replace
clear


** CLEANING AID DATA **
import delimited "AidData.csv"
* Removing unnecessary variables (ran as separate commands for auditability)
drop asdf_id
egen Conflict_Deaths=rowtotal(ucdp_deaths*)
drop ucdp_deaths*
drop access*
drop v*
drop gdp_gridnonemax gdp_gridnonemin gdp_gridnonemean
drop ltdr*min
drop ltdr*max
drop gpw_v4_density*min
drop gpw_v4_density*max
drop gpw_v4_density*count
drop ccn_1
drop name_0
drop engtype_1
drop id_0
drop cca_1
drop id_1
drop type_1
drop nl_name_1
drop iso
*Fixing Department variable
rename name_1 Department
replace Department = subinstr(Department, "Ã©", "e", .)
replace Department = subinstr(Department, "Ã¡", "a", .)
label variable Department "Name of Department"
* Renaming variables (I'm not going to worry about labels for now)
rename worldbank_geocodedresearchreleas World_Bank_Funding
rename gdp_gridnonesum Department_GDP
preserve
rename ltdr_avhrr_ndvi_v4_yearly*mea Average_Vegetation_Index_*
rename gpw_v4_density*mean Population_Density_*
rename gpw_v4_count*sum Population_*
rename shape_area Shape_Area
rename hasc_1 Department_Code
rename shape_length Shape_Length
* Reordering variables
order Average_Vegetation_Index_*, sequential
order Population_Density_*, sequential
order Population_*, sequential
order Department Department_GDP World_Bank_Funding Conflict_Deaths
*Save cleaned dataset
save AidData_CLEAN.dta
clear

** CLEANING POVERTY DATA **
import excel "PovertyData.xlsx", sheet("Pobreza") cellrange(A4:I348) firstrow
* Remove unnecessary rows and variables
drop if G==.
drop C D F G H I
duplicates drop Municipio, force
* Rename variables
rename Municipio Department
rename Pobrezaextrema Extreme_Poverty_Pct
rename Pobrezatotal Poverty_Pct
* Fix weird characers and misspelling
replace Department = subinstr(Department, "é", "e", .)
replace Department = subinstr(Department, "á", "a", .)
replace Department = subinstr(Department, "Quetzaltenango", "Quezaltenango", .)
* Fix variable types
destring Extreme_Poverty_Pct, replace
destring Poverty_Pct, replace
* Save cleaned dataset
save PovertyData_CLEAN.dta, replace
clear

** MERGING DATASETS
* Merge based on Department names in AidData
use AidData_CLEAN.dta
merge 1:1 Department using EthnicityData_CLEAN.dta
drop _merge
merge 1:1 Department using PovertyData_CLEAN.dta
drop if _merge==2
drop _merge
save GuateData.dta, replace

** PREPARING SHAPE FILE **
shp2dta using gadm36_GTM_1, database(guatedb) coordinates(guatecoord) genid(idnum) genc(c) replace
use guatedb.dta, clear
rename HASC_1 Department_Code
save guatedb.dta, replace
clear
* Merging shape file
use GuateData.dta
merge 1:1 Department_Code using guatedb.dta, keepusing(idnum)
drop _merge
save GuateData.dta, replace

* Data cleaning complete -- Please proceed to Data Analysis/Visualization script.
