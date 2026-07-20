%let path=~/ExcelProjects;

libname data "&path/ExcelData";

*************************************************************
   Add Financial Impact
*************************************************************;

data data.reconciliation_results;
	set data.reconciliation_status;
	
	expected_revenue = ordered_units * list_price;
	billed_revenue   = billed_units * billed_price;
	
	revenue_variance = billed_revenue - expected_revenue;
	
	abs_variance = abs(revenue_variance);
	
	*** Risk Scoring Model ;
	
	severity_score =
	      missing_invoice*5
	    + unit_mismatch*3
	    + list_price_mismatch*4
	    + contract_price_mismatch*4
	    + expired_contract*4
	    + late_return*2
	    + over_return*3
	    + (abs_variance > 500)*5;
	
	
	*** Categorize: ;
	
	if severity_score=0 then risk_level="LOW";
	else if severity_score<=5 then risk_level="MEDIUM";
	else risk_level="HIGH";

run;

proc means data=data.reconciliation_results noprint;
	var revenue_variance;
	output out=stats mean=mean_var std=std_var;
run;

data data.reconciliation_final;
	if _n_=1 then set stats;
	set data.reconciliation_results;
	
	z_score = (revenue_variance - mean_var)/std_var;
	
	if abs(z_score)>3 then variance_outlier=1;
	else variance_outlier=0;
run;


/*
proc means data=reconciliation_results noprint;
var revenue_variance;
output out=stats mean=mean_var std=std_var;
run;

data reconciliation_results;
if _n_=1 then set stats;
set reconciliation_results;

z_score = (revenue_variance - mean_var)/std_var;

if abs(z_score)>3 then variance_outlier=1;
else variance_outlier=0;
run;
*/
