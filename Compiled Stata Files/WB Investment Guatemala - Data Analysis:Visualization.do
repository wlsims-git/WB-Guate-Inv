** Will Sims - Is World Bank Investment in Guatemala Responsive to Departmental Needs?
** May, 2019

** ANALYSIS SCRIPT
** This file is to be read along-side the final paper word doc -- all analysis and visualizations are in order.

** PREAMBLE **
cd "/Users/wlsims/Desktop/WB Investment/Compiled Stata Files"
* Files required in the wd: GuateData.dta, guatedb.dta, guatecoord.dta
ssc install estout, replace
use GuateData.dta, clear


** TITLE PAGE

* Department Population Map
spmap Population_2015 using guatecoord, id(idnum) /// 
fcolor(Blues2) clnumber(22) legenda(off) ///
label(data(guatedb.dta) xcoord(x_c) ycoord(y_c) label(NAME_1) color(white) size(*0.6) length(17))


** INTRODUCTION

* Total World Bank funding figures
summarize World_Bank_Funding
display r(sum)


** SECTION 1

* Guatemalan vegetation map
gen Vegetation_Inverse_2016=(8000-Average_Vegetation_Index_2016)
spmap Vegetation_Inverse_2016 using guatecoord, id(idnum) fcolor(Terrain) /// 
clnumber(16) legenda(off) title("Guatemala Vegetation Index") 
graph export Vegetation_Mao.png, as(png) replace

* Maximum poverty rate
summarize Poverty_Pct

* Relationship between indigenous population and poverty
gen Indigenous_Percentage = Indigenous_Percent*100
reg Poverty_Pct Indigenous_Percentage

* Indigenous population and Poverty Scatterplot
twoway (scatter Indigenous_Percent Poverty_Pct, /// 
msymbol(none) mlabel(Department) mlabposition(0)) ///
(lfit Indigenous_Percent Poverty_Pct, legend(off) ///
title("Ethnicity vs Poverty Rate in Guatemala") /// 
ytitle("Ethnic Mayan Population-Share") xscale(range(40 95)) ///
xtitle("Poverty Rate (%)"))

* Relationship between urbanization and GDP
* 1000 people/square mile "urban" benchmark from: https://www2.census.gov/geo/pdfs/reference/GARM/Ch12GARM.pdf
gen Population_Density_Miles=(Population_Density_2015/0.386102159)
gen Urban=0
replace Urban=1 if Population_Density_Miles>1000
gen GDP_Per_Cap = (Department_GDP*1000000)/Population_2015
* T-test
ttest GDP_Per_Cap, by(Urban)
display (720.7121/4923.207)
* Box and wisker plot
label define Urban 0 "Rural" 1 "Urban"
label values Urban Urban
graph box GDP_Per_Cap, over(Urban) ytitle("GDP Per Capita ($)") ///
scheme(s1mono)  intensity(0) medtype(line) boxgap(5) title("Urban & Rural Department GDP Per Capita")


** SECTION 2

* World Bank Funding by department
graph hbar World_Bank_Funding, over(Department, sort(1) descending) /// 
title("World Bank Funding By Department") ytitle("Total World Bank Funding (1995-2014)") ///
ylabel(0 "$0" 500000000 "$0.5B" 1000000000  "$1.0B" 1500000000 "$1.5B" ) scheme(s1mono)

* World Bank Funding per capita
gen World_Bank_Funding_Per_Capita=(World_Bank_Funding/Population_2015)/19
graph hbar World_Bank_Funding_Per_Capita, over(Department, sort(1) descending) /// 
title("Annual Per-Capita World Bank Funding") ytitle("Annual Per-Capita Funding") ///
ylabel(0 "$0" 20 "$20" 40 "$40" 60 "$60" 80 "$80" 100 "$100") scheme(s1mono)

* World Bank Funding Heatmap
spmap World_Bank_Funding_Per_Capita using guatecoord, id(idnum) /// 
fcolor(Blues2) clnumber(22) legenda(off) title("Annual World Bank Funding Per Capita") ///
label(data(guatedb.dta) xcoord(x_c) ycoord(y_c) label(NAME_1) size(*0.5) length(17))

* Two-Way Regression Model outputs
reg World_Bank_Funding Department_GDP
reg World_Bank_Funding Population_Density_2015
reg World_Bank_Funding Indigenous_Percent
reg World_Bank_Funding Population_2015
* Adding correlation coefficients
corr World_Bank_Funding Department_GDP
corr World_Bank_Funding Population_Density_2015
corr World_Bank_Funding Indigenous_Percent
corr World_Bank_Funding Population_2015

* Regression Models (Divided World Bank Funding by 1 Million in order to have more intelligible coefficients
gen MM_World_Bank_Funding = World_Bank_Funding/1000000
reg MM_World_Bank_Funding Department_GDP Population_Density_2015 Indigenous_Percent
estimates store M1
reg MM_World_Bank_Funding Department_GDP Population_Density_2015 Indigenous_Percent Population_2015
estimates store M2
reg MM_World_Bank_Funding Department_GDP Population_Density_2015 Indigenous_Percent Poverty_Pct
estimates store M3
reg MM_World_Bank_Funding Department_GDP Population_Density_2015 Indigenous_Percent Population_2015 Poverty_Pct
estimates store MC
esttab M1 M2 M3 MC using RegressionOutput.csv

reg MM_World_Bank_Funding Population_2015 Population_Density_2015 Indigenous_Percent
estimates store M4
reg MM_World_Bank_Funding Population_2015 Population_Density_2015
estimates store M5
esttab M4 M5

* Post-Estimation Analysis
reg MM_World_Bank_Funding Population_2015 Population_Density_2015
rvfplot, msymbol(none) mlabel(Department) mlabposition(0) title("Model 5 Residual Plot")
avplot Population_2015, msymbol(none) mlabel(Department) mlabposition(0) xtitle("Population") ytitle("World Bank Funding") title("Population Added-Variable Plot")
avplot Population_Density_2015, msymbol(none) mlabel(Department) mlabposition(0) xtitle("Population Density") ytitle("World Bank Funding") title("Population Density Added-Variable Plot")
lvr2plot, msymbol(none) mlabel(Department) mlabposition(0) title("Model 5 Leverage vs Residual Plot")

** SECTION 3

*Coefficient Interpretation
display(1000000*0.000382)
display 382/19
sum World_Bank_Funding_Per_Capita

* Generating residuals
reg MM_World_Bank_Funding Population_2015 Population_Density_2015
predict M5_Residuals, resid 
save GuateData.dta, replace

* Residual heatmap
spmap M5_Residuals using guatecoord, id(idnum) /// 
fcolor(Reds) clnumber(7) title("Model 5 Residuals Heatmap") legenda(off)
graph play "HeatLabels.grec"
