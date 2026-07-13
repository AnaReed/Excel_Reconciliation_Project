# Project Workflow

## 1. Project Objective

The objective of this project was to develop an end-to-end reconciliation process that compares order, invoice, pricing, contract, and return data.

The process identifies financial and operational discrepancies, assigns a reconciliation status and severity level, and presents the results in an interactive Excel dashboard.

The project was designed to demonstrate practical skills in:

* Data preparation
* Multi-source data integration
* Data reconciliation
* Business-rule development
* Data-quality validation
* Financial variance analysis
* Risk scoring
* Dashboard development
* Technical documentation

All data used in this project is synthetic and was created solely for educational and portfolio purposes.

---

## 2. Source Data

The project uses the following synthetic datasets.

### Customers

Contains customer-level reference information.

Example fields:

* Customer ID
* Customer Name
* Customer Segment
* Region
* State

### Products

Contains product-level reference information.

Example fields:

* Product ID
* Product Name
* Product Category
* Standard Unit
* Product Status

### Orders

Contains customer order transactions.

Example fields:

* Order ID
* Order Date
* Customer ID
* Product ID
* Ordered Quantity
* Order Unit Price
* Expected Revenue

### Invoices

Contains invoice transactions associated with customer orders.

Example fields:

* Invoice ID
* Order ID
* Invoice Date
* Customer ID
* Product ID
* Invoiced Quantity
* Invoice Unit Price
* Invoiced Revenue

The source invoice data includes intentional duplicate and inconsistent records to support reconciliation testing.

### Contracts

Contains customer-specific product pricing agreements.

Example fields:

* Contract ID
* Customer ID
* Product ID
* Contract Price
* Contract Start Date
* Contract End Date

### Price Master

Contains standard list prices by product.

Example fields:

* Product ID
* List Price
* Effective Start Date
* Effective End Date

### Returns

Contains customer product-return transactions.

Example fields:

* Return ID
* Order ID
* Product ID
* Return Date
* Returned Quantity

---

## 3. Data Preparation

Before joining the datasets, each source was reviewed and prepared.

The data-preparation process included:

1. Confirming that expected columns were present.
2. Standardizing field names.
3. Assigning the correct data types.
4. Converting text dates into valid date values.
5. Reviewing missing customer, product, order, and invoice identifiers.
6. Checking numeric fields for invalid values.
7. Reviewing quantity and price fields for negative or unrealistic values.
8. Standardizing customer and product keys.
9. Identifying duplicate invoice records.
10. Confirming source-level record counts.

Data preparation was completed using a combination of Excel, Power Query, and SAS.

---

## 4. Invoice Duplicate Review

The invoice dataset contained more records than the order dataset because some invoice records were duplicated.

Duplicate invoices were reviewed using fields such as:

* Invoice ID
* Order ID
* Customer ID
* Product ID
* Invoice Date
* Invoiced Quantity
* Invoice Unit Price

The duplicate-review process included:

1. Grouping records by invoice and order identifiers.
2. Counting the number of records for each invoice.
3. Comparing quantities, prices, and dates.
4. Separating exact duplicates from potentially valid multiple-invoice situations.
5. Retaining one record when duplicates were confirmed.
6. Documenting the invoice count before and after duplicate handling.

A cleaned invoice dataset was then used in the reconciliation process.

---

## 5. Return Aggregation

An order may have more than one return transaction.

To prevent multiple return records from creating duplicate reconciliation rows, returns were aggregated before being joined to the order data.

Returns were grouped by:

* Order ID
* Product ID

The following fields were calculated:

* Total Returned Quantity
* First Return Date
* Last Return Date
* Number of Return Transactions

The aggregated return dataset produced one summarized return record per order and product combination.

---

## 6. Reconciliation Base Creation

The order dataset was used as the primary source because every order needed to remain in the reconciliation output, including orders without invoices.

A left-join strategy was used.

The datasets were joined in the following order:

1. Orders
2. Deduplicated Invoices
3. Aggregated Returns
4. Contracts
5. Price Master
6. Customer Reference Data
7. Product Reference Data

The main join relationships were:

```text
Orders.Order_ID = Invoices.Order_ID

Orders.Order_ID = Returns.Order_ID

Orders.Product_ID = Returns.Product_ID

Orders.Customer_ID = Contracts.Customer_ID

Orders.Product_ID = Contracts.Product_ID

Orders.Product_ID = Price_Master.Product_ID

Orders.Customer_ID = Customers.Customer_ID

Orders.Product_ID = Products.Product_ID
```

Date conditions were also considered when identifying the applicable contract and list price.

The order date was expected to fall between the applicable effective start and end dates.

---

## 7. Calculated Financial Fields

Several financial measures were calculated for each reconciliation record.

### Expected Revenue

```text
Expected Revenue = Ordered Quantity × Expected Unit Price
```

The expected unit price may be based on the applicable contract price or list price, depending on the business rule.

### Invoiced Revenue

```text
Invoiced Revenue = Invoiced Quantity × Invoice Unit Price
```

### Revenue Variance

```text
Revenue Variance = Invoiced Revenue − Expected Revenue
```

A positive variance indicates that invoiced revenue is greater than expected revenue.

A negative variance indicates that invoiced revenue is lower than expected revenue.

### Absolute Revenue Variance

```text
Absolute Revenue Variance = Absolute Value of Revenue Variance
```

Absolute variance was used in dashboard rankings and severity scoring because it measures the total financial impact regardless of direction.

---

## 8. Reconciliation Rules

The project applies a series of business rules to identify discrepancies.

### Missing Invoice

The record is flagged when an order does not have a corresponding invoice.

```text
Missing Invoice = 1 when Invoice ID is missing
```

### Unit Mismatch

The record is flagged when the invoiced quantity does not equal the ordered quantity.

```text
Unit Mismatch = 1 when Invoiced Quantity ≠ Ordered Quantity
```

### List Price Mismatch

The record is flagged when the invoice unit price differs from the applicable price-master value.

```text
List Price Mismatch = 1 when Invoice Unit Price ≠ List Price
```

### Contract Price Mismatch

The record is flagged when the invoice unit price differs from the applicable customer contract price.

```text
Contract Price Mismatch = 1 when Invoice Unit Price ≠ Contract Price
```

### Expired Contract

The record is flagged when the contract was not active on the order date.

```text
Expired Contract = 1 when Order Date is later than Contract End Date
```

A record may also be flagged when the order date occurs before the contract start date.

### Late Return

The record is flagged when the return occurs more than 60 days after the applicable transaction date.

```text
Late Return = 1 when Return Date − Order Date > 60 days
```

### Over-Return

The record is flagged when the returned quantity is greater than the ordered or invoiced quantity.

```text
Over-Return = 1 when Returned Quantity > Invoiced Quantity
```

When invoice quantity is unavailable, ordered quantity may be used as the comparison value.

---

## 9. PASS and FAIL Status

A final reconciliation status was assigned to each record.

### PASS

A record receives a PASS status when none of the reconciliation rules are triggered.

```text
Status = PASS when all discrepancy flags equal 0
```

### FAIL

A record receives a FAIL status when one or more reconciliation rules are triggered.

```text
Status = FAIL when at least one discrepancy flag equals 1
```

The FAIL status indicates that the record requires additional review.

It does not automatically indicate fraud, financial loss, or an accounting error.

---

## 10. Severity Score

A weighted severity score was created to prioritize records based on the type and financial importance of the discrepancy.

The score was calculated as follows:

```text
Severity Score =
    Missing Invoice × 5
  + Unit Mismatch × 3
  + List Price Mismatch × 4
  + Contract Price Mismatch × 4
  + Expired Contract × 4
  + Late Return × 2
  + Over-Return × 3
  + 5 when Absolute Revenue Variance > 500
```

Higher weights were assigned to discrepancies that could have a greater financial or operational impact.

Examples include:

* Missing invoices
* Pricing mismatches
* Expired contracts
* Material revenue variances

---

## 11. Risk-Level Assignment

Records were grouped into risk levels based on the severity score.

An example risk classification is:

```text
Low Risk: Severity Score from 0 to 3

Medium Risk: Severity Score from 4 to 7

High Risk: Severity Score of 8 or greater
```

The thresholds can be adjusted based on business requirements.

A PASS record with a severity score of zero is considered low risk.

High-risk records should be reviewed first because they may include multiple discrepancies or a material financial variance.

---

## 12. Reconciliation Output

The final reconciliation dataset contains one primary record per order and product combination.

The output includes:

* Order ID
* Invoice ID
* Customer ID
* Customer Name
* Product ID
* Product Name
* Order Date
* Invoice Date
* Ordered Quantity
* Invoiced Quantity
* Returned Quantity
* List Price
* Contract Price
* Invoice Unit Price
* Expected Revenue
* Invoiced Revenue
* Revenue Variance
* Absolute Revenue Variance
* Individual discrepancy flags
* PASS or FAIL status
* Severity Score
* Risk Level

The output serves as the source for PivotTables, charts, KPI calculations, and detailed exception analysis.

---

## 13. Excel Dashboard Development

The final reconciliation output was loaded into Excel and used to create PivotTables and PivotCharts.

The dashboard includes KPI cards such as:

* Total Orders
* PASS Count
* FAIL Count
* PASS Rate
* Total Absolute Revenue Variance
* High-Risk Order Count
* High-Risk Order Percentage

The dashboard also includes visualizations such as:

* PASS versus FAIL distribution
* Risk-level distribution
* Monthly revenue variance trend
* Monthly reconciliation-status trend
* Top customers by absolute revenue variance
* Orders and revenue variance by customer
* Discrepancy type counts

Interactive slicers allow users to filter by:

* Reconciliation Status
* Risk Level
* Month
* Customer
* Product
* Product Category
* Region

Dynamic chart titles were used where appropriate so the selected status or filter is reflected in the chart title.

---

## 14. Dashboard Design Considerations

Several design principles were applied to improve usability.

### Limited Customer Rankings

Customer charts display only the Top 10 or Top 15 customers by absolute variance.

This prevents overlapping labels and makes the financial impact easier to interpret.

### Absolute Variance for Ranking

Customers were ranked by absolute revenue variance rather than signed variance.

This ensures that large positive and negative discrepancies are both treated as significant.

### Separate Measures Where Appropriate

When order count and revenue variance have very different scales, they may be displayed using:

* Separate charts
* A secondary axis
* Different chart types
* Separate dashboard sections

This prevents one measure from becoming visually compressed.

### Consistent Risk and Status Labels

PASS, FAIL, Low, Medium, and High labels were used consistently across:

* KPI cards
* PivotTables
* Charts
* Slicers
* Dynamic titles

---

## 15. Validation and Quality Control

Validation was performed throughout the workflow.

### Source Record Validation

The source record count was confirmed for each dataset before transformation.

### Duplicate Validation

Invoice counts were compared before and after duplicate handling.

### Join Validation

Record counts were reviewed after every major join.

The order count was expected to remain stable after left joins unless a one-to-many relationship created duplicate rows.

### Missing-Key Validation

The reconciliation output was reviewed for missing:

* Order IDs
* Customer IDs
* Product IDs
* Invoice IDs
* Contract values
* Price-master values

### Calculation Validation

Selected records were manually recalculated to confirm:

* Expected revenue
* Invoiced revenue
* Revenue variance
* Absolute variance
* Severity score

### Flag Validation

Sample records were created or selected to confirm that each reconciliation rule correctly produced a value of 0 or 1.

### Dashboard Validation

Dashboard totals were compared with the detailed reconciliation output.

The following were confirmed:

* KPI values matched PivotTable totals.
* PASS and FAIL counts matched the detailed data.
* Risk-level totals matched severity classifications.
* Customer rankings were based on absolute variance.
* Slicers controlled the intended PivotTables and charts.
* Dynamic titles reflected the selected filters.

---

## 16. Final Deliverables

The project includes the following deliverables:

```text
data/
    Synthetic source data
    Data dictionary

excel/
    Final reconciliation workbook
    Interactive dashboard

sas/
    Data import programs
    Data-preparation programs
    Reconciliation logic
    Validation programs
    Export programs

documentation/
    Project workflow
    Reconciliation rules
    Testing and validation documentation

images/
    Dashboard overview
    KPI section
    Risk analysis
    Monthly trend
    Customer variance analysis
```

---

## 17. Skills Demonstrated

This workflow demonstrates the following technical and analytical skills:

* Excel
* Power Query
* PivotTables
* PivotCharts
* Excel formulas
* Dashboard design
* SAS programming
* PROC SQL
* Data joins
* Data aggregation
* Duplicate handling
* Data-quality auditing
* Financial reconciliation
* Business-rule development
* Risk scoring
* Variance analysis
* Quality control
* Technical documentation
* Business-focused data presentation

---

## 18. Project Limitations

This project uses synthetic data and simplified business rules.

In a production environment, the process may also need to address:

* Partial shipments
* Multiple invoices per order
* Multiple products per invoice
* Credit memos
* Taxes
* Freight charges
* Currency conversion
* Contract amendments
* Product substitutions
* Invoice cancellations
* Rebilling
* Pricing tolerances
* Different return-policy periods
* Timing differences between systems

These scenarios were outside the initial project scope but could be included in a future version.

---

## 19. Potential Future Enhancements

Possible enhancements include:

* Adding configurable price and quantity tolerances
* Separating underbilling and overbilling
* Adding invoice-aging analysis
* Adding root-cause categories
* Including exception ownership and resolution status
* Creating an issue-resolution tracking table
* Adding Power BI reporting
* Automating refresh through Power Query
* Adding SAS macros for reusable reconciliation rules
* Creating automated validation reports
* Adding month-over-month trend comparisons
* Adding contract-expiration alerts
* Comparing original and corrected invoice values

---

## 20. Conclusion

This project demonstrates how data from multiple operational sources can be combined into a structured reconciliation process.

The workflow identifies exceptions, measures financial impact, assigns risk, validates results, and communicates findings through an interactive dashboard.

The final solution provides a repeatable framework for reviewing transaction accuracy, prioritizing high-risk records, and supporting business decision-making.

