%let path=~/ExcelProjects;

libname data "&path/ExcelData";

*************************************************************
   Deduplicate Invoices. Invoices should be 1 per order;
*************************************************************;

proc sql;
	create table invoices_dedup as
	select *
	from (
	    select *,
	           monotonic() as seq
	    from data.invoices
	)
	group by order_id
	having seq = min(seq);
quit;

*************************************************************
  Aggregate Returns to Invoice Level
  If multiple returns per invoice, summarize first
*************************************************************;

proc sql;
	create table returns_agg as
	select 
	    invoice_id,
	    sum(units_returned) as total_returned_units,
	    max(return_date) as last_return_date format=date9.
	from data.returns
	group by invoice_id;
quit;

*************************************************************
* Step 1: Determine Correct Price Per Order (Temporal Join) *
*************************************************************;

proc sql;

	create table price_latest as
	select
	    o.order_id,
	    p.product_id,
	    p.list_price,
	    p.effective_date
	from data.orders o
	
	left join data.pricing p
	    on o.product_id = p.product_id
	   and p.effective_date <= o.order_date
	
	group by o.order_id
	having p.effective_date = max(p.effective_date);
quit;


*************************************************************
   Step 2: Build Final Reconciliation Base            
*************************************************************;
proc sql;

	create table data.reconciliation_base as
	select
	
	    /* -------- Order Info -------- */
	    o.order_id,
	    o.order_date format=date9.,
	    o.customer_id,
	    o.product_id,
	    o.units as ordered_units,
	
	    /* -------- Invoice Info -------- */
	    i.invoice_id,
	    i.billed_units,
	    i.billed_price,
	
	    /* -------- Returns Info -------- */
	    r.total_returned_units,
	    r.last_return_date format=date9.,
	
	    /* -------- Contract Info -------- */
	    c.contract_price,
	    c.start_date format=date9.,
	    c.end_date format=date9.,
	
	    /* -------- Correct List Price -------- */
	    p.list_price,
	    p.effective_date format=date9.
	
	from data.orders o
	
	/* 1-to-1 invoice */
	left join invoices_dedup i
	    on o.order_id = i.order_id
	
	/* returns via invoice */
	left join returns_agg r
	    on i.invoice_id = r.invoice_id
	
	/* contracts */
	left join data.contracts c
	    on o.customer_id = c.customer_id
	   and o.product_id  = c.product_id
	
	/* correctly selected pricing */
	left join price_latest p
	    on o.order_id = p.order_id
	
	;

quit;




