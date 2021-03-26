**
* ANES and minimum wage


* DATA here: https://electionstudies.org/data-center/2020-time-series-study/
use "ANES\anes_timeseries_2020_stata_20210324.dta", clear

*Looking for work
tab V202377 if V202377>0 & V201522==1 [aw=V200010b]
* +less than BA
tab V202377 if V202377>0 & V201522==1 & V201511x>=1 & V201511x<=3 [aw=V200010b]
* +up to 35
tab V202377 if V202377>0 & V201522==1 & V201511x>=1 & V201511x<=3 & V201507x>=18 &  V201507x<=35 [aw=V200010b]


**
* Attitudes about biz & unions

*2020
* biz
gen tcV202163 = V202163
replace tcV202163 = 97 if V202163 >=98 & V202163 <=100
sum tcV202163 if tcV202163>=0 & tcV202163<=100 [aw=V200010b]
scalar bb2020 = r(mean)


* unions
gen tcV202162 = V202162
replace tcV202162 = 97 if V202162 >=98 & V202162 <=100
sum tcV202162 if tcV202162>=0 & tcV202162<=100 [aw=V200010b]
scalar u2020 = r(mean)

foreach var in V202162 V202163 {
gen i_`var'_80p = .
replace i_`var'_80p = 1 if tc`var' >=80 & tc`var' <=97
replace i_`var'_80p = 0 if tc`var' <80 & tc`var' >=0
gen i_`var'_20m = .
replace i_`var'_20m = 1 if tc`var' <=20
replace i_`var'_20m = 0 if tc`var' >20 & tc`var' <=97

foreach val in 20m 80p {
sum i_`var'_`val' [aw=V200010b]
scalar p_`var'_`val' = r(mean)
}
}


* pre-2020 data

* DATA here: https://electionstudies.org/data-center/anes-time-series-cumulative-data-file/
use "\ANES\anes_timeseries_cdf_dta\anes_timeseries_cdf.dta", clear
* BB
bysort VCF0004: sum VCF0209 if VCF0209>=0 & VCF0209<=97 [aw=VCF0009z]
* Unions
bysort VCF0004: sum VCF0210 if VCF0210>=0 & VCF0210<=97 [aw=VCF0009z]

foreach var in VCF0209 VCF0210 {
gen c`var' = `var'
replace c`var' = . if `var' >97

gen i_`var'_80p = .
replace i_`var'_80p = 1 if c`var' >=80 & c`var' <=97
replace i_`var'_80p = 0 if c`var' <80 & c`var' >=0
gen i_`var'_20m = .
replace i_`var'_20m = 1 if c`var' <=20
replace i_`var'_20m = 0 if c`var' >20 & c`var' <=97
}


collapse (mean) cVCF0210 cVCF0209 i_VCF0209_80p i_VCF0209_20m i_VCF0210_80p i_VCF0210_20m [aw=VCF0009z], by(VCF0004)
local new = _N + 1
set obs `new'
replace   VCF0004 = 2020 in `new'
replace cVCF0210 = `=u2020' in `new'
replace cVCF0209 = `=bb2020' in `new'
replace i_VCF0209_80p = `=p_V202163_80p' in `new'
replace i_VCF0209_20m = `=p_V202163_20m' in `new'
replace i_VCF0210_80p = `=p_V202162_80p' in `new'
replace i_VCF0210_20m = `=p_V202162_20m' in `new'
browse

drop if VCF0004<1964

line cVCF0209 cVCF0210 VCF0004 if VCF0004>=1964, title(Trend in Americans' feelings toward) ///
ytitle(Share) ///
legend(label(1 "Big Business") label(2 "Labor Unions") order(2 1) position(2)) xlabel(1964(4)2020) ///
note("Source: American National Election Survey. Average rating on 0-100 feelings thermometer." "@aaronsojourner")
graph export "\ANES\graphs\gr_mean.png", replace


line i_VCF0209_80p i_VCF0210_80p VCF0004 if VCF0004>=1964, title(Share of Americans with strongly positive feelings toward) ///
ytitle(Share) ///
legend(label(1 "Big Business") label(2 "Labor Unions") order(2 1) position(2)) xlabel(1964(4)2020) ///
note("Source: American National Election Survey. Strongly positive is 80+ on 0-100 feelings thermometer." "@aaronsojourner")
graph export "\ANES\graphs\gr_80p.png", replace

line i_VCF0209_20m i_VCF0210_20m VCF0004 if VCF0004>=1964, title(Share of Americans with strongly negative feelings toward) ///
ytitle(Share) ///
legend(label(1 "Big Business") label(2 "Labor Unions") order(2 1) position(2)) ///
note("Source: American National Election Survey. Strongly negative is up to 20 on 0-100 feelings thermometer." "@aaronsojourner")
graph export "\ANES\graphs\gr_20m.png", replace
