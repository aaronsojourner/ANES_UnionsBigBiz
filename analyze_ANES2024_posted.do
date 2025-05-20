* ANES for unions and big business 2024
* Aaron Sojourner & Adam Reich

global mainpath ""
global working "${mainpath}working\\"
global output "${mainpath}output\\"



* Load full 2024 ANES sample (FTF+panel+web+PAPI)
use "${mainpath}anes_timeseries_2024_stata_20250430\anes_timeseries_2024_stata_20250430.dta" , clear

gen wt = V240107b
svyset [pweight=wt], strata(V240107d) psu(V240107c)

* Define groups
gen raceeth = .
replace raceeth = 1 if V241501x==1
replace raceeth = 2 if V241501x==2
replace raceeth = 3 if V241501x==3
replace raceeth = 4 if V241501x>=4 & V241501x<=6
label define raceeth4  1 "White" 2 "Black" 3 "Hispanic" 4 "Multiple or other"
label values raceeth raceeth4

gen gender = .
replace gender = 1 if V241551==1
replace gender = 2 if V241551==2
label define l_gender  1 "Men" 2 "Women" 
label values gender l_gender

gen libcon = .
replace libcon = 1 if inrange(V241177,1,2)
replace libcon = 2 if inrange(V241177,3,5)
replace libcon = 3 if inrange(V241177,6,7)
replace libcon = 4 if V241177==99
label define l_libcon 1 "Liberals" 2 "Moderates" 3 "Conservatives" 4 "Don't Knows"
label values libcon l_libcon

gen educ = .
replace educ= 1 if inrange(V241463,1,8)
replace educ= 2 if V241463==9
replace educ= 3 if inrange(V241463,10,12)
replace educ= 4 if inrange(V241463,13,16)
label define l_educ4 1 "Less than HS" 2 "HS Only" 3 "Some College" 4 "Bachelor+"
label values educ l_educ4

gen state = V243001

gen cat4_hhunion = . 
replace cat4_hhunion = 0 if V241498a==0 & V241498b==0 & V241498c==0
replace cat4_hhunion = 1 if V241498a==1 & V241498b==0  & V241498c==0
replace cat4_hhunion = 2 if V241498a==0 & (V241498b==1 | V241498c==1)
replace cat4_hhunion = 3 if V241498a==1 & (V241498b==1 | V241498c==1)
label define l_cat4_hhunion 0 "No one" 1 "Self Only" 2 "Other only" 3 "Self and Other"  
label values cat4_hhunion l_cat4_hhunion

gen i_union = . 
replace i_union = 0 if V241498a==0 
replace i_union = 1 if V241498a==1 
label define l_union 0 "Nonunion" 1 "Union" 
label values i_union l_union

* For some of the early years, rating responses above 97 are only reported as 97, so round these down to match
foreach var in V242140 V242141 {
	svy: mean  `var' if `var'>=0 & `var'<=100 
	gen tc`var' = `var'
	replace tc`var' = 97 if `var' >=98 & `var' <=100
	replace tc`var' = . if `var' <0 | `var' >100
	}

rename tcV242140 tcLU
rename tcV242141 tcBB 
sum tcLU tcBB [aw=wt]
mvpatterns  tcLU tcBB
gen year = 2024

sum tcLU if tcBB==.
sum tcLU if tcBB~=.

sum tcBB if tcLU==.
sum tcBB if tcLU~=.

gen dLUBB = tcLU-tcBB
sum dLUBB [aw=wt]

keep wt year tc* dLUBB raceeth gender libcon educ state i_union cat4_hhunion
save "${working}2024.dta", replace

* pre-2024 cumulative : 2022 version
* https://electionstudies.org/data-center/anes-time-series-cumulative-data-file/
use "${mainpath}anes_timeseries_cdf_stata_20220916.dta", clear

*Make parallel groups
gen raceeth = .
replace raceeth = 1 if VCF0105b==1
replace raceeth = 2 if VCF0105b==2
replace raceeth = 3 if VCF0105b==3
replace raceeth = 4 if VCF0105b==4
label values raceeth raceeth4

gen gender = .
replace gender = 1 if VCF0104==1
replace gender = 2 if VCF0104==2
label values gender l_gender

gen libcon = .
replace libcon = 1 if inrange(VCF0803,1,2)
replace libcon = 2 if inrange(VCF0803,3,5)
replace libcon = 3 if inrange(VCF0803,6,7)
replace libcon = 4 if VCF0803==9
label values libcon l_libcon

gen educ = .
replace educ= 1 if inrange(VCF0140,1,2)
replace educ= 2 if inrange(VCF0140,3,4)
replace educ= 3 if inrange(VCF0140,5,5)
replace educ= 4 if inrange(VCF0140,6,6)
label values educ l_educ4

gen state = VCF0901b

* members
gen cat4_hhunion = . 
replace cat4_hhunion = 0 if VCF0127b==0
replace cat4_hhunion = 1 if VCF0127b==1
replace cat4_hhunion = 2 if VCF0127b==2
replace cat4_hhunion = 3 if VCF0127b==3
label define l_cat4_hhunion 0 "No one" 1 "Self Only" 2 "Other only" 3 "Self and Other"  
label values cat4_hhunion l_cat4_hhunion

gen i_union = . 
replace i_union = 1 if VCF0127b==1 | VCF0127b==3 
replace i_union = 0 if VCF0127b==0 | VCF0127b==2 
label define l_union 0 "Nonunion" 1 "Union" 
label values i_union l_union


tab VCF0210
gen tcLU = VCF0210
replace tcLU = . if VCF0210>= 98

gen tcBB = VCF0209
replace tcBB = . if VCF0209>= 98

mvpatterns  tcLU tcBB

gen dLUBB = tcLU-tcBB

gen year = VCF0004

gen wt = VCF0011z

keep wt year tc* dLUBB raceeth gender libcon educ state i_union cat4_hhunion
save "${working}pre2024", replace

* Stack 2024 on top of pre2024
append using "${working}2024.dta"
save "${working}all.dta", replace

* Make two trend graph				
preserve
	collapse (mean) tcLU tcBB [aw=wt], by(year)
	drop if tcLU==.
	twoway (connected tcLU year)  || (connected tcBB year), ///
		legend(label(1 "Labor Unions") label(2 "Big Business") pos(12) ring(0)) ///
		ytitle("Average Rating, 0-100") ///
		title("Trends in Americans' sentiment toward Labor Unions & Big Business") ///
		 xlabel(1964(4)2024) xtitle("Year of Study") ///
		note("Source: American National Election Studies. Average rating on 0-100 feelings thermometer. For consistency over time, 98-100 rounded to 97." "Calcs & Graph: @aaronsojourner.org.") 
	graph export "${output}gr_trend.png", replace
restore

*Make map
preserve 
	drop if dLUBB==.
	collapse (mean) dLUBB [aw=wt], by(year state)
	bysort state (year): gen dd_st =  dLUBB - dLUBB[_n-3]
	keep if year == 2024
	maptile dd_st, geo(statehex) geoid(state) cutvalues(-20(20)40)
	graph export "${output}sthex.png", replace
restore

* Make gap trend
preserve
	drop if dLUBB==.
	collapse (mean) dLUBB [aw=wt], by(year)
	twoway (connected dLUBB year), ///
		ytitle("Average in-person sentiment difference") ///
		title("Trend in Average Within Person (Labor Unions - Big Business) Sentiment Difference ") ///
		 xlabel(1964(4)2024) xtitle("Year of Study") ///
		 yline(0) text(1 2020 "{&uarr} more pro-union     ") ///
		 text(-1 2020 "{&darr} more pro-business")   ///
		note("Source: American National Election Studies. Average rating on 0-100 feelings thermometer. For consistency over time, 98-100 rounded to 97." "Difference within respondent. Calcs & Graph: @aaronsojourner.org.") 
	graph export "${output}gr_trdLUBB.png", replace
restore

*** Gap trends by different groups
* Race/ethnicity
preserve
	drop if dLUBB==.
	collapse (mean) dLUBB [aw=wt], by(year raceeth)
	twoway (line dLUBB year if raceeth ==2 ) (line dLUBB year if raceeth ==3 ) ///
	(line dLUBB year if raceeth ==4 ) (line dLUBB year if raceeth ==1 ), ///
		ytitle("Average in-person sentiment difference") ///
		title("Trend in Average Within Person (Labor Unions - Big Business) Sentiment Difference by Race/Ethnicity", size(medium)) ///
		 xlabel(1964(4)2024) xtitle("Year of Study") ///
		 legend(label(1 "Black Only") label(2 "Hispanic") label(3 "Others") label(4 "White Only")  pos(12) ring(0) size(small)) ///
		 yline(0) text(1 2020 "{&uarr} more pro-union     ") ///
		 text(-1 2020 "{&darr} more pro-business")   ///
		note("Source: American National Election Studies. Average rating on 0-100 feelings thermometer. For consistency over time, 98-100 rounded to 97." "Difference within respondent. Calcs & Graph: @aaronsojourner.org.") 
	graph export "${output}gr_trdLUBB_re.png", replace
restore

* Gender
preserve
	drop if dLUBB==.
	collapse (mean) dLUBB [aw=wt], by(year gender)
	twoway (line dLUBB year if gender ==2 ) (line dLUBB year if gender ==1 ), ///
		ytitle("Average in-person sentiment difference") ///
		title("Trend in Average Within Person (Labor Unions - Big Business) Sentiment Difference by Gender", size(medium)) ///
		 xlabel(1964(4)2024) xtitle("Year of Study") ///
		 legend(label(1 "Women") label(2 "Men") pos(12) ring(0) size(small)) ///
		 yline(0) text(1 2020 "{&uarr} more pro-union     ") ///
		 text(-1 2020 "{&darr} more pro-business")   ///
		note("Source: American National Election Studies. Average rating on 0-100 feelings thermometer. For consistency over time, 98-100 rounded to 97." "Difference within respondent. Calcs & Graph: @aaronsojourner.org.") 
	graph export "${output}gr_trdLUBB_gender.png", replace
restore

* political ideology
preserve
	drop if dLUBB==.
	collapse (mean) dLUBB [aw=wt], by(year libcon)
	twoway (line dLUBB year if libcon ==1 ) (line dLUBB year if libcon ==2 ) ///
	(line dLUBB year if libcon ==3 ) (line dLUBB year if libcon ==4 ), ///
		ytitle("Average in-person sentiment difference") ///
		title("Trend in Average Within Person (Labor Unions - Big Business) Sentiment Difference by Liberal/Conservative", size(medium)) ///
		 xlabel(1972(4)2024) xtitle("Year of Study") ///
		 legend(label(1 "Liberals") label(2 "Moderates") label(3 "Conservatives") label(4 "Don't Knows")  pos(12) ring(0) size(small) rowgap(1)) ///
		 yline(0) text(2 2018 "{&uarr} more pro-union     ") ///
		 text(-2 2018 "{&darr} more pro-business")   ///
		note("Source: American National Election Studies. Average rating on 0-100 feelings thermometer. For consistency over time, 98-100 rounded to 97." "Liberal = (extremely) liberal. Moderates = Slightly liberal, moderate, slightly conservative. Conservative = (extremely) conservative." "Difference within respondent. Calcs & Graph: @aaronsojourner.org.") 
	graph export "${output}gr_trdLUBB_libcon.png", replace
restore


* education
preserve
	drop if dLUBB==.
	collapse (mean) dLUBB [aw=wt], by(year educ)
	twoway (line dLUBB year if educ ==1 ) (line dLUBB year if educ ==2 ) ///
	(line dLUBB year if educ ==3 ) (line dLUBB year if educ ==4 ), ///
		ytitle("Average in-person sentiment difference") ///
		title("Trend in Average Within Person (Labor Unions - Big Business) Sentiment Difference by Formal Education", size(medium)) ///
		 xlabel(1964(4)2024) xtitle("Year of Study") ///
		 legend(label(1 "Less than HS") label(2 "HS Grads") label(3 "Some College") label(4 "Bachelor+")  pos(12) ring(0) size(small) rowgap(1)) ///
		 yline(0) text(2 2020 "     {&uarr} more pro-union") ///
		 text(-2 2020 "{&darr} more pro-business")   ///
		note("Source: American National Election Studies. Average rating on 0-100 feelings thermometer." "Difference within respondent. Calcs & Graph: @aaronsojourner.org.") 
	graph export "${output}gr_trdLUBB_educ.png", replace
restore

* Union membership
preserve
	drop if dLUBB==.
	collapse (mean) dLUBB [aw=wt], by(year i_union)
	twoway (line dLUBB year if i_union ==0 ) (line dLUBB year if i_union ==1 ), ///
		ytitle("Average in-person sentiment difference") ///
		title("Trend in Average Within Person (Labor Unions - Big Business) Sentiment Difference by Union Membership", size(medium)) ///
		 xlabel(1964(4)2024) xtitle("Year of Study") ///
		 legend(label(1 "Nonunion") label(2 "Union member") pos(12) ring(0) size(small) rowgap(1)) ///
		 yline(0) text(2 2020 "     {&uarr} more pro-union") ///
		 text(-2 2020 "{&darr} more pro-business")   ///
		note("Source: American National Election Studies. Average rating on 0-100 feelings thermometer." "Difference within respondent. Calcs & Graph: @aaronsojourner.org.") 
	graph export "${output}gr_trdLUBB_union.png", replace
restore

* Union household
preserve
	drop if dLUBB==.
	collapse (mean) dLUBB [aw=wt], by(year cat4_hhunion)
	twoway (line dLUBB year if cat4_hhunion ==0 ) (line dLUBB year if cat4_hhunion ==1 ) ///
	(line dLUBB year if cat4_hhunion ==2 ) (line dLUBB year if cat4_hhunion ==3 ), ///
		ytitle("Average in-person sentiment difference") ///
		title("Trend in Average Within Person (Labor Unions - Big Business) Sentiment Difference by HH Union Status", size(medium)) ///
		 xlabel(1964(4)2024) xtitle("Year of Study") ///
		 legend(label(1 "No one") label(2 "Self Only") label(3 "Other Only") label(4 "Self & Other")  pos(12) ring(0) size(small) rowgap(1)) ///
		 yline(0) text(2 2020 "     {&uarr} more pro-union") ///
		 text(-2 2020 "{&darr} more pro-business")   ///
		note("Source: American National Election Studies. Average rating on 0-100 feelings thermometer." "Difference within respondent. Calcs & Graph: @aaronsojourner.org.") 
	graph export "${output}gr_trdLUBB_cat4hhunion.png", replace
restore