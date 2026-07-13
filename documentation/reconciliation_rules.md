# Reconciliation Rules

The project reconciles order, invoice, return, contract, and pricing data.

## Missing Invoice

An order is flagged when no corresponding invoice is found.

## Unit Mismatch

An order is flagged when the invoiced quantity does not match the ordered quantity.

## List Price Mismatch

An order is flagged when the invoiced unit price differs from the applicable list price.

## Contract Price Mismatch

An order is flagged when the invoiced price differs from the active contract price.

## Expired Contract

An order is flagged when the associated contract was expired on the order date.

## Late Return

A return is flagged when it occurs more than 60 days after the applicable transaction date.

## Over-Return

An order is flagged when the returned quantity exceeds the invoiced or ordered quantity.

## Revenue Variance

Revenue variance is calculated by comparing expected revenue with invoiced revenue.

## Severity Score

The project assigns a weighted severity score:

- Missing invoice: 5 points
- Unit mismatch: 3 points
- List price mismatch: 4 points
- Contract price mismatch: 4 points
- Expired contract: 4 points
- Late return: 2 points
- Over-return: 3 points
- Absolute variance above $500: 5 additional points

The combined score is used to classify records into Low, Medium, and High risk.
