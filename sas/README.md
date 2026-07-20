# SAS Reconciliation Programs

## Overview

This folder contains the SAS programs used to prepare, reconcile, flag, score, and finalize the synthetic order-to-invoice reconciliation dataset for the Excel Revenue Reconciliation & Risk Dashboard.

The SAS workflow supports the project by:

* Deduplicating invoice records
* Aggregating return records
* Joining orders, invoices, returns, contracts, and pricing data
* Creating reconciliation exception flags
* Assigning PASS / FAIL reconciliation status
* Calculating revenue variance
* Creating a severity score
* Assigning risk level
* Calculating z-scores for variance outlier detection

All data used in this project is synthetic and was created for portfolio and educational purposes.

---

## Program Files

### 1. `P1_Data_Reconciliation.sas`

This program creates the base reconciliation dataset.

Main steps include:

1. Deduplicating invoice records so each order keeps one invoice record.
2. Aggregating returns by invoice.
3. Selecting the most recent applicable list price based on the order date.
4. Joining the following datasets:

   * Orders
   * Deduplicated invoices
   * Aggregated returns
   * Contracts
   * Pricing data
5. Creating the base output dataset:

```text
data.reconciliation_base
```

The program uses orders as the primary dataset and applies left joins so that orders remain in the output even if matching invoice, return, contract, or pricing data is missing.

---

### 2. `P2_Set_Flags_Status.sas`

This program creates reconciliation flags and assigns a business-level PASS / FAIL status.

The following exception flags are created:

| Flag                      | Description                                                    |
| ------------------------- | -------------------------------------------------------------- |
| `missing_invoice`         | Identifies orders without a matching invoice                   |
| `unit_mismatch`           | Identifies differences between ordered units and billed units  |
| `list_price_mismatch`     | Identifies differences between billed price and list price     |
| `contract_price_mismatch` | Identifies differences between billed price and contract price |
| `expired_contract`        | Identifies orders placed after the contract end date           |
| `late_return`             | Identifies returns more than 60 days after the order date      |
| `over_return`             | Identifies cases where returned units exceed ordered units     |

The program then creates a final reconciliation status:

```text
recon_status = PASS
```

when no exception flags are triggered.

```text
recon_status = FAIL
```

when one or more exception flags are triggered.

Output datasets:

```text
data.reconciliation_flags
data.reconciliation_status
```

---

### 3. `P3_Set_Risk_Level_and_Z_Score.sas`

This program adds financial impact, severity scoring, risk level, and variance outlier detection.

The program calculates:

```text
expected_revenue = ordered_units × list_price
```

```text
billed_revenue = billed_units × billed_price
```

```text
revenue_variance = billed_revenue − expected_revenue
```

```text
abs_variance = ABS(revenue_variance)
```

It also creates a weighted severity score:

```text
severity_score =
    missing_invoice × 5
  + unit_mismatch × 3
  + list_price_mismatch × 4
  + contract_price_mismatch × 4
  + expired_contract × 4
  + late_return × 2
  + over_return × 3
  + 5 when abs_variance > 500
```

Risk levels are assigned as:

| Severity Score | Risk Level |
| -------------: | ---------- |
|              0 | LOW        |
|            1–5 | MEDIUM     |
| Greater than 5 | HIGH       |

The program also calculates a z-score for revenue variance and flags records where the absolute z-score is greater than 3.

Output datasets:

```text
data.reconciliation_results
data.reconciliation_final
```

---

## Recommended Execution Order

Run the SAS programs in the following order:

```text
1. P1_Data_Reconciliation.sas
2. P2_Set_Flags_Status.sas
3. P3_Set_Risk_Level_and_Z_Score.sas
```

Each program depends on the output from the previous step.

---

## SAS Library Setup

Each program uses the following project path and library assignment:

```sas
%let path=~/ExcelProjects;

libname data "&path/ExcelData";
```

Before running the programs, update the path if your folder location is different.

Example:

```sas
%let path=/your/project/folder;

libname data "&path/ExcelData";
```

---

## Expected Input Datasets

The programs expect the following SAS datasets to exist in the `data` library:

| Dataset          | Description                                |
| ---------------- | ------------------------------------------ |
| `data.orders`    | Synthetic order-level transaction data     |
| `data.invoices`  | Synthetic invoice data                     |
| `data.returns`   | Synthetic return transaction data          |
| `data.contracts` | Customer and product contract pricing data |
| `data.pricing`   | Product list-price history                 |

---

## Expected Final Output

The final dataset created by the SAS workflow is:

```text
data.reconciliation_final
```

This dataset is used as the source for the Excel reconciliation dashboard.

Key output fields include:

| Field              | Description                                            |
| ------------------ | ------------------------------------------------------ |
| `order_id`         | Unique order identifier                                |
| `invoice_id`       | Matching invoice identifier, when available            |
| `customer_id`      | Customer identifier                                    |
| `product_id`       | Product identifier                                     |
| `ordered_units`    | Quantity ordered                                       |
| `billed_units`     | Quantity billed                                        |
| `billed_price`     | Invoice unit price                                     |
| `list_price`       | Applicable list price                                  |
| `contract_price`   | Customer-specific contract price                       |
| `expected_revenue` | Expected revenue based on ordered units and list price |
| `billed_revenue`   | Revenue based on billed units and billed price         |
| `revenue_variance` | Difference between billed and expected revenue         |
| `abs_variance`     | Absolute value of revenue variance                     |
| `recon_status`     | PASS or FAIL reconciliation status                     |
| `severity_score`   | Weighted risk score                                    |
| `risk_level`       | LOW, MEDIUM, or HIGH                                   |
| `z_score`          | Standardized revenue variance                          |
| `variance_outlier` | Indicator for extreme variance values                  |

---

## Workflow Summary

The SAS workflow follows this process:

```text
Raw synthetic data
        ↓
Deduplicate invoices
        ↓
Aggregate returns
        ↓
Select applicable pricing
        ↓
Create reconciliation base
        ↓
Create exception flags
        ↓
Assign PASS / FAIL status
        ↓
Calculate revenue variance
        ↓
Calculate severity score
        ↓
Assign risk level
        ↓
Calculate z-score and outlier flag
        ↓
Export or use final dataset for Excel dashboard
```

---

## Validation Notes

Validation checks included:

* Reviewing record counts before and after joins
* Confirming that orders were preserved through left joins
* Checking duplicate invoice handling
* Confirming return aggregation logic
* Reviewing missing invoice flags
* Testing quantity and price mismatch flags
* Confirming PASS / FAIL status assignment
* Manually checking selected revenue variance calculations
* Reviewing severity score and risk-level assignments
* Checking z-score outlier logic

---

## Notes for Portfolio Reviewers

The SAS programs are included to demonstrate the back-end data preparation and reconciliation logic behind the Excel dashboard.

The published Excel workbook may contain static values for presentation purposes, but the SAS programs document the analytical workflow used to create the reconciliation output.

This project is intended to demonstrate practical skills in:

* SAS programming
* PROC SQL
* Data joins
* Deduplication
* Aggregation
* Financial reconciliation
* Data-quality flagging
* Risk scoring
* Variance analysis
* Dashboard data preparation
* Technical documentation

---

## Disclaimer

This project uses synthetic data only. No confidential, employer-owned, customer, financial, clinical, or production data is included.

