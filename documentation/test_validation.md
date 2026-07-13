# Testing and Validation

## 1. Purpose

The purpose of testing and validation was to confirm that the reconciliation process produced complete, accurate, consistent, and traceable results.

Validation was performed across the full workflow, including:

* Source-data review
* Duplicate handling
* Data joins
* Aggregations
* Reconciliation flags
* Financial calculations
* Severity scoring
* Risk classification
* Excel PivotTables
* Dashboard KPIs and charts
* Slicer and filter behavior

All testing was performed using synthetic data created for portfolio and educational purposes.

---

## 2. Validation Objectives

The testing process was designed to confirm that:

1. All expected source records were loaded.
2. Duplicate invoice records were handled correctly.
3. Left joins preserved all order records.
4. One-to-many relationships did not create unintended duplicate rows.
5. Return records were aggregated correctly.
6. Financial calculations were accurate.
7. Reconciliation flags followed the documented business rules.
8. PASS and FAIL status was assigned correctly.
9. Severity scores matched the defined weighting model.
10. Risk levels matched the severity thresholds.
11. Dashboard totals matched the underlying reconciliation data.
12. Slicers controlled the intended PivotTables and charts.
13. The final workbook refreshed without errors.

---

## 3. Source Data Validation

Each source dataset was reviewed before transformation.

The following checks were performed:

* Confirmed that the expected worksheet or file was present.
* Verified that all required columns existed.
* Reviewed column names for consistency.
* Confirmed numeric, text, and date data types.
* Checked for missing primary identifiers.
* Reviewed quantity and price fields for invalid values.
* Identified duplicate records.
* Confirmed source record counts.
* Reviewed date ranges for unexpected values.
* Checked for invalid customer and product references.

### Required Key Fields

The following key fields were expected to be populated.

| Dataset      | Required Key Fields                  |
| ------------ | ------------------------------------ |
| Customers    | Customer ID                          |
| Products     | Product ID                           |
| Orders       | Order ID, Customer ID, Product ID    |
| Invoices     | Invoice ID, Order ID                 |
| Contracts    | Contract ID, Customer ID, Product ID |
| Returns      | Return ID, Order ID, Product ID      |
| Price Master | Product ID                           |

Records with missing key fields were reviewed because they could not be reliably matched during reconciliation.

---

## 4. Source Record Count Validation

Record counts were captured before any transformations.

Example source counts used in the project:

| Dataset      | Expected Record Count |
| ------------ | --------------------: |
| Customers    |                   800 |
| Products     |                   300 |
| Contracts    |                   500 |
| Orders       |                 4,000 |
| Invoices     |                 4,092 |
| Returns      |                   400 |
| Price Master |                   900 |

The invoice count was greater than the order count because the source data included intentional duplicate or multiple invoice records.

Source counts were compared with imported data counts to confirm that no records were lost during import.

---

## 5. Data Type Validation

Data types were reviewed before calculations and joins.

The expected data types included:

| Field Type          | Examples                                       |
| ------------------- | ---------------------------------------------- |
| Text                | Customer ID, Product ID, Order ID              |
| Date                | Order Date, Invoice Date, Return Date          |
| Whole Number        | Ordered Quantity, Invoiced Quantity            |
| Decimal or Currency | List Price, Contract Price, Invoice Unit Price |
| Binary Flag         | Missing Invoice, Unit Mismatch                 |
| Category            | PASS, FAIL, Low, Medium, High                  |

Date fields were checked to confirm that they were stored as valid dates rather than text.

Price and quantity columns were checked to confirm that they could be used in calculations without conversion errors.

---

## 6. Duplicate Invoice Validation

The invoice dataset was reviewed for exact and potential duplicate records.

Duplicates were evaluated using combinations of:

* Invoice ID
* Order ID
* Customer ID
* Product ID
* Invoice Date
* Invoiced Quantity
* Invoice Unit Price
* Invoiced Revenue

### Exact Duplicate Test

Records were considered exact duplicates when all key transaction values were identical.

Expected result:

```text
Only one copy of a confirmed exact duplicate is retained.
```

### Potential Duplicate Test

Records with the same invoice or order identifier but different quantities, prices, or dates were not automatically removed.

These records were reviewed to determine whether they represented:

* Partial invoicing
* Corrected invoices
* Multiple invoice lines
* Data-entry errors
* True duplicate records

### Duplicate Count Reconciliation

The following counts were compared:

```text
Original Invoice Count
− Confirmed Duplicate Records Removed
= Deduplicated Invoice Count
```

The deduplicated count was documented and compared with the output of the duplicate-removal step.

---

## 7. Return Aggregation Validation

Returns were aggregated before joining them to orders.

The aggregation was validated by comparing:

```text
Sum of Source Returned Quantity
=
Sum of Aggregated Returned Quantity
```

The following fields were reviewed:

* Total returned quantity
* First return date
* Last return date
* Return transaction count

For selected orders with multiple returns, the aggregated values were manually recalculated.

Example:

```text
Return 1 Quantity: 2
Return 2 Quantity: 3
Expected Aggregated Quantity: 5
```

The output was expected to contain one return summary record per order and product combination.

---

## 8. Join Validation

The order dataset was used as the primary dataset.

Left joins were used so that all orders remained in the reconciliation output, including orders without matching invoices.

### Order-to-Invoice Join

Validation checks included:

* Confirming that every order remained in the output.
* Identifying orders without invoices.
* Reviewing orders that matched more than one invoice.
* Checking for duplicate output rows.

Expected result:

```text
All 4,000 orders remain available after the left join.
```

### Order-to-Return Join

Validation checks included:

* Confirming that returns were aggregated before joining.
* Ensuring that return joins did not multiply order rows.
* Reviewing unmatched return records.

### Order-to-Contract Join

Validation checks included:

* Matching by Customer ID and Product ID.
* Confirming that the contract was active on the order date.
* Reviewing orders with no matching contract.
* Reviewing overlapping contract periods.

### Order-to-Price-Master Join

Validation checks included:

* Matching by Product ID.
* Confirming the applicable effective-date range.
* Reviewing products with no valid list price.
* Reviewing overlapping price periods.

### Row Multiplication Test

After each join, the output row count was compared with the prior step.

Unexpected increases were investigated for:

* Duplicate invoice records
* Multiple active contracts
* Multiple effective price records
* Unaggregated returns
* Incomplete join conditions

---

## 9. Missing-Key Validation

The final reconciliation dataset was reviewed for missing identifiers.

The following fields were checked:

* Order ID
* Invoice ID
* Customer ID
* Product ID
* Contract ID
* Return ID
* Price reference

A missing invoice ID was permitted when an order had no matching invoice because this condition was part of the reconciliation analysis.

Missing order, customer, or product identifiers were considered data-quality issues.

---

## 10. Financial Calculation Validation

Selected records were manually recalculated to confirm the financial measures.

### Expected Revenue

```text
Expected Revenue = Ordered Quantity × Expected Unit Price
```

Example:

```text
Ordered Quantity: 10
Expected Unit Price: $25.00
Expected Revenue: $250.00
```

### Invoiced Revenue

```text
Invoiced Revenue = Invoiced Quantity × Invoice Unit Price
```

Example:

```text
Invoiced Quantity: 9
Invoice Unit Price: $27.00
Invoiced Revenue: $243.00
```

### Revenue Variance

```text
Revenue Variance = Invoiced Revenue − Expected Revenue
```

Example:

```text
$243.00 − $250.00 = −$7.00
```

### Absolute Revenue Variance

```text
Absolute Revenue Variance = ABS(Revenue Variance)
```

Example:

```text
ABS(−$7.00) = $7.00
```

Totals were also compared across the detailed data and PivotTables.

---

## 11. Reconciliation Flag Testing

Each reconciliation rule was tested independently.

Test records were selected or created so that each condition could be evaluated.

### Missing Invoice

Test condition:

```text
Invoice ID is blank.
```

Expected result:

```text
Missing Invoice = 1
Status = FAIL
```

### Unit Mismatch

Test condition:

```text
Ordered Quantity = 10
Invoiced Quantity = 8
```

Expected result:

```text
Unit Mismatch = 1
```

### List Price Mismatch

Test condition:

```text
List Price = $50.00
Invoice Unit Price = $52.00
```

Expected result:

```text
List Price Mismatch = 1
```

### Contract Price Mismatch

Test condition:

```text
Contract Price = $45.00
Invoice Unit Price = $50.00
```

Expected result:

```text
Contract Price Mismatch = 1
```

### Expired Contract

Test condition:

```text
Contract End Date occurs before Order Date.
```

Expected result:

```text
Expired Contract = 1
```

### Late Return

Test condition:

```text
Return Date is more than 60 days after Order Date.
```

Expected result:

```text
Late Return = 1
```

### Over-Return

Test condition:

```text
Returned Quantity exceeds Invoiced Quantity.
```

Expected result:

```text
Over-Return = 1
```

---

## 12. Boundary Testing

Boundary values were tested to confirm that comparison operators were applied correctly.

### Late Return Boundary

| Days Between Order and Return | Expected Flag |
| ----------------------------: | ------------: |
|                            59 |             0 |
|                            60 |             0 |
|                            61 |             1 |

The business rule defines a late return as more than 60 days.

### Material Variance Boundary

| Absolute Variance | Additional Severity Points |
| ----------------: | -------------------------: |
|           $499.99 |                          0 |
|           $500.00 |                          0 |
|           $500.01 |                          5 |

The rule adds five points only when absolute variance is greater than $500.

### Quantity Match Boundary

| Ordered Quantity | Invoiced Quantity | Unit Mismatch |
| ---------------: | ----------------: | ------------: |
|               10 |                10 |             0 |
|               10 |                 9 |             1 |
|               10 |                11 |             1 |

### Contract Date Boundary

An order on the contract start or end date was considered within the contract period when inclusive date logic was used.

---

## 13. Missing-Value Testing

Missing values were tested to avoid false comparisons.

Examples included:

* Missing invoice quantity
* Missing invoice price
* Missing contract price
* Missing list price
* Missing return date
* Missing contract end date

A missing invoice was expected to trigger the missing-invoice flag.

However, missing reference prices were reviewed separately so they did not automatically create misleading price mismatches.

The logic distinguished between:

```text
Price is missing
```

and:

```text
Price exists but differs from the invoice price
```

---

## 14. Tolerance Testing

The initial project used exact comparisons for price and quantity checks.

In production environments, a tolerance may be required because of rounding.

Example future tolerance rule:

```text
Price Mismatch = 1 when
ABS(Invoice Unit Price − Expected Price) > $0.01
```

Example test cases:

| Expected Price | Invoice Price | Tolerance | Expected Flag |
| -------------: | ------------: | --------: | ------------: |
|         $10.00 |        $10.00 |     $0.01 |             0 |
|         $10.00 |        $10.01 |     $0.01 |             0 |
|         $10.00 |        $10.02 |     $0.01 |             1 |

Tolerance logic was documented as a potential enhancement when exact comparison was used.

---

## 15. PASS and FAIL Validation

The final reconciliation status was tested against the individual flags.

### PASS Test

Condition:

```text
All reconciliation flags equal 0.
```

Expected result:

```text
Status = PASS
```

### FAIL Test

Condition:

```text
At least one reconciliation flag equals 1.
```

Expected result:

```text
Status = FAIL
```

### Multiple-Failure Test

A record with more than one triggered flag was expected to remain a single FAIL record while accumulating all applicable severity points.

---

## 16. Severity Score Validation

The severity score was recalculated manually for selected records.

The formula was:

```text
Severity Score =
    Missing Invoice × 5
  + Unit Mismatch × 3
  + List Price Mismatch × 4
  + Contract Price Mismatch × 4
  + Expired Contract × 4
  + Late Return × 2
  + Over-Return × 3
  + Material Variance Indicator × 5
```

### Example Test

Assume a record has:

```text
Missing Invoice = 0
Unit Mismatch = 1
List Price Mismatch = 0
Contract Price Mismatch = 1
Expired Contract = 0
Late Return = 1
Over-Return = 0
Absolute Variance > $500 = 1
```

Expected calculation:

```text
0 × 5
+ 1 × 3
+ 0 × 4
+ 1 × 4
+ 0 × 4
+ 1 × 2
+ 0 × 3
+ 1 × 5
= 14
```

Expected severity score:

```text
14
```

---

## 17. Risk-Level Validation

Risk level was compared with the severity score.

Example thresholds:

| Severity Score | Expected Risk Level |
| -------------: | ------------------- |
|            0–3 | Low                 |
|            4–7 | Medium              |
|   8 or greater | High                |

Boundary tests included:

| Severity Score | Expected Risk Level |
| -------------: | ------------------- |
|              3 | Low                 |
|              4 | Medium              |
|              7 | Medium              |
|              8 | High                |

The risk-level labels in the detailed output were compared with the dashboard totals.

---

## 18. Aggregate Control Totals

Aggregate totals were compared across source data, transformed data, and dashboard outputs.

Examples included:

```text
Total Ordered Quantity
Total Invoiced Quantity
Total Returned Quantity
Total Expected Revenue
Total Invoiced Revenue
Total Revenue Variance
Total Absolute Revenue Variance
PASS Count
FAIL Count
High-Risk Count
```

The following relationship was checked:

```text
PASS Count + FAIL Count = Total Reconciliation Records
```

Risk-level totals were also checked:

```text
Low Risk + Medium Risk + High Risk
= Total Reconciliation Records
```

---

## 19. PivotTable Validation

Each PivotTable was compared with the reconciliation detail.

Validation included:

* Confirming that the correct source range or Excel table was used.
* Confirming that the PivotTable refreshed successfully.
* Checking that calculated fields used the correct aggregation.
* Confirming that customer rankings used absolute variance.
* Confirming that PASS and FAIL counts matched the detail.
* Confirming that high-risk percentages used the correct denominator.
* Checking date grouping by month.
* Reviewing blank categories.
* Confirming that duplicate source rows did not inflate totals.

### Value-Field Validation

Fields were reviewed to confirm whether they used:

* Sum
* Count
* Distinct count
* Average
* Maximum
* Minimum

For example:

```text
Total Absolute Variance should use SUM,
not COUNT.
```

---

## 20. Dashboard KPI Validation

Each KPI was traced back to the underlying data or PivotTable.

### Total Orders

Expected calculation:

```text
Distinct Count of Order ID
```

The appropriate calculation depends on whether the reconciliation output contains one or multiple rows per order.

### PASS Count

Expected calculation:

```text
Count of records where Status = PASS
```

### FAIL Count

Expected calculation:

```text
Count of records where Status = FAIL
```

### PASS Rate

Expected calculation:

```text
PASS Count ÷ Total Reconciliation Records
```

### Total Absolute Variance

Expected calculation:

```text
SUM(Absolute Revenue Variance)
```

### High-Risk Percentage

Expected calculation:

```text
High-Risk Record Count ÷ Total Reconciliation Records
```

KPI values were checked before and after slicer selections.

---

## 21. Chart Validation

Charts were reviewed for both accuracy and readability.

The following checks were performed:

* Chart source was linked to the correct PivotTable.
* Axis titles matched the displayed measures.
* Chart titles matched the selected analysis.
* Customer charts displayed the intended Top 10 or Top 15 records.
* Absolute variance was used where ranking by financial impact was required.
* Positive and negative variance values were interpreted correctly.
* Secondary axes were used only when necessary.
* Data labels did not overlap excessively.
* Blank categories were removed when appropriate.
* Chart totals matched PivotTable values.

---

## 22. Slicer Validation

Each slicer was tested to confirm that it controlled the intended PivotTables and PivotCharts.

Slicers included:

* Status
* Risk Level
* Month
* Customer
* Product
* Product Category
* Region

Validation steps included:

1. Select one slicer value.
2. Confirm that all intended KPIs and charts update.
3. Confirm that unrelated PivotTables remain unchanged when appropriate.
4. Select multiple values.
5. Clear the filter.
6. Confirm that the full dashboard is restored.

The PivotTable connection settings were reviewed when a chart did not respond to a slicer.

---

## 23. Dynamic Title Validation

Dynamic dashboard and chart titles were tested for each slicer state.

Examples:

```text
All Statuses
PASS
FAIL
Multiple Items
```

The title formula was reviewed to confirm that:

* The selected status was displayed.
* The default title appeared when no filter was applied.
* Multiple selections did not produce a misleading title.
* The title updated after PivotTable refresh.

---

## 24. Refresh Testing

The workbook was refreshed to confirm that the dashboard updated correctly.

Refresh testing included:

* Refreshing individual PivotTables.
* Using Refresh All.
* Refreshing Power Query outputs.
* Confirming that queries completed without errors.
* Confirming that PivotTables used the refreshed output.
* Checking that slicers remained connected.
* Confirming that formulas expanded to new rows.
* Reviewing charts after refresh.

The workbook was saved, closed, reopened, and refreshed again to confirm repeatability.

---

## 25. Formula Validation

Excel formulas were reviewed for:

* Correct cell references
* Correct use of absolute and relative references
* Consistent formulas throughout calculated columns
* Missing formulas in newly added rows
* `#N/A`, `#VALUE!`, `#REF!`, and `#DIV/0!` errors
* Correct handling of blank values
* Correct use of `IF`, `IFERROR`, `ABS`, `SUMIFS`, `COUNTIFS`, `XLOOKUP`, or equivalent functions

When Excel tables were used, calculated columns were checked to confirm that formulas automatically populated new records.

---

## 26. Power Query Validation

Power Query steps were reviewed in sequence.

Validation included:

* Correct source file and worksheet selection
* Correct header promotion
* Correct data types
* Correct duplicate-removal logic
* Correct join type
* Correct join keys
* Correct expanded fields
* Correct aggregation logic
* No unexpected query errors
* Stable row counts
* Correct load destination

Data profiling was set to evaluate the full dataset when possible rather than only the first 1,000 rows.

---

## 27. SAS Validation

Where SAS was used, the following checks were performed:

* Reviewed SAS logs for errors and warnings.
* Confirmed that input datasets opened successfully.
* Reviewed notes about automatic character-to-numeric conversion.
* Checked for uninitialized variables.
* Checked for duplicate BY values.
* Confirmed sort order before merges.
* Compared input and output record counts.
* Used frequency tables to review flags and categories.
* Used summary procedures to validate totals.
* Used `PROC COMPARE` where independent comparison datasets were available.

Example validation procedures included:

```sas
proc contents;
run;

proc freq;
run;

proc means;
run;

proc sql;
quit;

proc compare;
run;
```

The SAS log was considered part of the validation evidence.

---

## 28. Exception Review

A sample of PASS and FAIL records was manually reviewed.

The sample included:

* Records with no discrepancies
* Missing invoices
* Quantity mismatches
* Price mismatches
* Expired contracts
* Late returns
* Over-returns
* High-value variances
* Records with multiple flags
* Records at risk-threshold boundaries

Manual review helped confirm that the automated logic matched the documented business rules.

---

## 29. Regression Testing

After changes to formulas, Power Query steps, SAS programs, or dashboard design, previously validated checks were repeated.

Regression testing focused on:

* Record counts
* PASS and FAIL totals
* Financial totals
* Severity scores
* Risk-level counts
* PivotTable values
* KPI values
* Slicer connections
* Dynamic titles

A change was considered acceptable only when the intended result changed and unrelated results remained stable.

---

## 30. Test Summary Table

The following table can be used as a reusable test log.

| Test ID | Test Description                         | Expected Result                          | Actual Result | Status |
| ------- | ---------------------------------------- | ---------------------------------------- | ------------- | ------ |
| TV-001  | Confirm order source count               | 4,000 records                            | 4,000 records | Pass   |
| TV-002  | Confirm invoice source count             | 4,092 records                            | 4,092 records | Pass   |
| TV-003  | Validate invoice duplicate handling      | Only confirmed duplicates removed        | As expected   | Pass   |
| TV-004  | Confirm orders preserved after left join | All orders retained                      | As expected   | Pass   |
| TV-005  | Validate return aggregation              | Source and aggregated quantities match   | As expected   | Pass   |
| TV-006  | Test missing-invoice flag                | Missing invoice produces flag 1          | As expected   | Pass   |
| TV-007  | Test quantity mismatch                   | Unequal quantities produce flag 1        | As expected   | Pass   |
| TV-008  | Test price mismatch                      | Unequal prices produce flag 1            | As expected   | Pass   |
| TV-009  | Test late-return boundary                | More than 60 days produces flag 1        | As expected   | Pass   |
| TV-010  | Test material-variance boundary          | Greater than $500 adds 5 points          | As expected   | Pass   |
| TV-011  | Validate severity score                  | Manual and calculated scores match       | As expected   | Pass   |
| TV-012  | Validate risk level                      | Score maps to correct category           | As expected   | Pass   |
| TV-013  | Validate PASS and FAIL total             | PASS + FAIL equals total records         | As expected   | Pass   |
| TV-014  | Validate dashboard KPIs                  | KPIs match source totals                 | As expected   | Pass   |
| TV-015  | Validate slicer connections              | Intended visuals update                  | As expected   | Pass   |
| TV-016  | Validate Refresh All                     | Queries and pivots refresh without error | As expected   | Pass   |

The values in the Actual Result and Status columns should be updated to reflect the final execution results.

---

## 31. Known Limitations

The validation approach reflects the simplified scope of this portfolio project.

Additional production testing would be required for:

* Partial shipments
* Split invoices
* Multiple invoice lines per product
* Credit memos
* Cancelled invoices
* Reissued invoices
* Taxes and freight
* Currency conversion
* Contract amendments
* Overlapping contract periods
* Multiple price-master effective periods
* Product substitutions
* Returns linked to multiple invoices
* Rounding tolerances
* System timing differences

These scenarios represent opportunities for future enhancement.

---

## 32. Validation Conclusion

The testing process confirmed that the reconciliation workflow was internally consistent and that the dashboard outputs were traceable to the detailed reconciliation data.

Testing covered:

* Data completeness
* Duplicate handling
* Join integrity
* Calculation accuracy
* Business-rule execution
* Severity scoring
* Risk classification
* PivotTable accuracy
* Dashboard functionality
* Refresh behavior

The final solution provides a repeatable and documented framework for identifying reconciliation exceptions and prioritizing records for review.

