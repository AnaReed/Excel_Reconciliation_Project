%let path=~/ExcelProjects;

libname data "&path/ExcelData";


*************************************************************
  Create Reconciliation Flags
*************************************************************;

data data.reconciliation_flags;
	set data.reconciliation_base;
	
	/* Missing invoice */
	missing_invoice = missing(invoice_id);
	
	/* Unit mismatch */
	unit_mismatch =
	    not missing(billed_units)
	    and ordered_units ne billed_units;
	
	/* Price mismatch vs list price */
	list_price_mismatch =
	    not missing(billed_price)
	    and not missing(list_price)
	    and billed_price ne list_price;
	
	/* Price mismatch vs contract */
	contract_price_mismatch =
	    not missing(contract_price)
	    and billed_price ne contract_price;
	
	/* Expired contract */
	expired_contract =
	    not missing(end_date)
	    and order_date > end_date;
	
	/* Late return */
	late_return =
	    not missing(last_return_date)
	    and last_return_date > order_date + 60;
	
	/* Over return */
	over_return =
	    total_returned_units > ordered_units;

run;

*************************************************************
  Create Business-Level Status - Assign PASS / FAIL.
*************************************************************;
data data.reconciliation_status;
	set data.reconciliation_flags;
	
	if missing_invoice
	 or unit_mismatch
	 or list_price_mismatch
	 or contract_price_mismatch
	 or expired_contract
	 or late_return
	 or over_return
	then recon_status="FAIL";
	else recon_status="PASS";

run;





