# Customer RFM Segmentation Analysis

SQL-based customer segmentation using the RFM 
(Recency, Frequency, Monetary) framework on 
retail transaction data.

## Business Problem
Identify high-value, at-risk, and lost customer 
segments to prioritise retention and growth efforts.

## Dataset
- 1,000 customers | 8,000 transactions
- Generated synthetic retail data via Python

## Methodology
- Calculated raw R, F, M values per customer
- Scored customers 1–3 on each dimension
- Segmented into 8 business-relevant groups

## Key Findings
- Top 2 segments (Loyal + Potential Loyalist) 
  drive 74% of total revenue — classic 80/20 rule
- 65 At-Risk customers represent $132K revenue 
  at risk with avg 127 days since last purchase
- 337 Potential Loyalists averaging $2,306 spend 
  present the largest upsell opportunity
- Monthly revenue stable at ~$165–186K, 
  signalling room for targeted growth strategy

## Segments Identified
| Segment | Customers | Action |
|---|---|---|
| Champion | 50 | Reward & retain |
| Loyal Customer | 345 | Upsell premium |
| Potential Loyalist | 337 | Personalised offers |
| At Risk | 65 | Win-back campaign |
| Needs Attention | 84 | Re-engage |
| New Customer | 51 | Drive 2nd purchase |
| Can't Lose Them | 6 | Personal outreach |
| Lost | 62 | Low priority |

## Tech Stack
MySQL | SQL Aggregations | Window Functions 
| CTEs | Views | DATE functions

## How to Run
1. Run `FINAL.sql` in MySQL Workbench or any 
   MySQL-compatible environment
2. Queries run sequentially — execute in order
