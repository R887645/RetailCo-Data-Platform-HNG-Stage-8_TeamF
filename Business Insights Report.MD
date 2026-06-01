# RetailCo Data Platform — Business Insights Report

**Team F | HNG Stage 8 | Data Engineering Pipeline**
**Reporting Period: May 2024 — May 2026**

-----

## Executive Summary

This report answers five management questions using data extracted from RetailCo’s legacy ERP system, loaded into a PostgreSQL data warehouse, and transformed using Kimball dimensional models. All figures are drawn directly from the analytics warehouse and reflect real transaction data across RetailCo’s four Nigerian stores in Lagos, Abuja, Port Harcourt, and Kano.

-----

## Question 1 — Revenue Performance

### Which stores, products, and categories are driving sales, and how does it trend over time?

**Revenue Trend**

RetailCo’s revenue has grown consistently and dramatically since May 2024. Monthly category revenue started at under ₦800,000 in May 2024 and reached over ₦300 billion per category by April 2026 — a growth of more than 37,000% in under two years. This reflects strong customer acquisition and increasing order volumes across all store locations.

**Top Performing Categories (April 2026)**

|Category       |Monthly Revenue|
|---------------|---------------|
|Books & Media  |₦324.4 billion |
|Automotive     |₦290.7 billion |
|Sports         |₦288.5 billion |
|Electronics    |₦279.3 billion |
|Clothing       |₦265.9 billion |
|Home & Garden  |₦261.9 billion |
|Food & Beverage|₦261.8 billion |
|Health & Beauty|₦238.1 billion |

Books & Media has emerged as the top revenue category as of early 2026, overtaking Sports and Electronics which dominated in late 2024. All 8 categories show strong and consistent growth month over month.

**Top Performing Products**

|Product                |Category       |Net Revenue  |
|-----------------------|---------------|-------------|
|Practical Frozen Towels|Food & Beverage|₦29.3 billion|
|Rustic Fresh Bacon     |Food & Beverage|₦25.6 billion|
|Licensed Bronze Cheese |Electronics    |₦24.5 billion|
|Small Metal Fish       |Health & Beauty|₦23.8 billion|
|Gorgeous Rubber Soap   |Sports         |₦22.8 billion|

Food & Beverage dominates the top product list, with Practical Frozen Towels generating the highest lifetime revenue of ₦29.3 billion across 57 orders.

**Revenue by Store**

All four RetailCo stores — Lagos, Abuja, Port Harcourt, and Kano — contribute meaningfully to revenue. Top-performing individual product-store combinations include RetailCo Port Harcourt with Rustic Fresh Bacon (₦1.48 billion in December 2024) and RetailCo Abuja with Sleek Steel Pizza (₦1.36 billion in December 2024).

**Key Insight:** Revenue growth is accelerating quarter over quarter. Sports and Automotive categories show the most consistent top-3 performance, while Books & Media has shown the strongest recent growth trend.

-----

## Question 2 — Customer Behaviour

### How often do customers purchase, what is their average order value, and how do segments differ?

RetailCo serves four customer segments — wholesale, retail, corporate, and VIP — each further divided into four tiers: platinum, gold, silver, and bronze.

**Segment Summary**

|Segment  |Total Orders|Unique Customers|Avg Orders per Customer|Avg Order Value|
|---------|------------|----------------|-----------------------|---------------|
|Wholesale|7,753       |1,106           |7.0                    |₦619,004       |
|Retail   |7,480       |1,059           |7.1                    |₦629,555       |
|Corporate|7,401       |1,040           |7.1                    |₦625,196       |
|VIP      |7,289       |1,077           |6.8                    |₦627,267       |

**Segment and Tier Detail**

The highest revenue combination is Retail Platinum with ₦1.31 trillion in total revenue across 2,100 orders and 281 customers. The average revenue per retail platinum customer is ₦4.67 million.

|Segment  |Tier    |Customers|Orders|Avg Order Value|Total Revenue |
|---------|--------|---------|------|---------------|--------------|
|Retail   |Platinum|281      |2,100 |₦624,546       |₦1.31 trillion|
|VIP      |Silver  |296      |2,100 |₦617,730       |₦1.30 trillion|
|Corporate|Silver  |278      |1,992 |₦645,812       |₦1.29 trillion|
|Wholesale|Silver  |279      |2,052 |₦617,619       |₦1.27 trillion|

**Key Insights:**

- All segments purchase at a remarkably similar frequency of 6.8 to 7.1 orders per customer — indicating consistent engagement across all customer types
- VIP customers surprisingly have the lowest purchase frequency (6.8) despite being premium customers
- Corporate Silver customers have the highest average order value at ₦645,812 — suggesting large bulk purchases
- Retail Platinum is the single most valuable segment by total revenue

-----

## Question 3 — Product and Discount Analysis

### What sells, what gets discounted, and what is the margin impact?

**Top 10 Products by Gross Profit**

|Product                   |Category       |Units Sold|Total Margin |Margin %|
|--------------------------|---------------|----------|-------------|--------|
|Incredible Metal Tuna     |Health & Beauty|505       |₦14.7 billion|38.6%   |
|Practical Frozen Towels   |Food & Beverage|362       |₦12.0 billion|40.1%   |
|Rustic Fresh Bacon        |Food & Beverage|370       |₦9.8 billion |36.7%   |
|Gorgeous Rubber Soap      |Sports         |298       |₦9.4 billion |39.2%   |
|Intelligent Plastic Gloves|Automotive     |273       |₦9.3 billion |39.6%   |
|Licensed Bronze Cheese    |Electronics    |327       |₦9.3 billion |36.4%   |
|Tasty Bronze Fish         |Sports         |301       |₦9.2 billion |41.2%   |
|Small Metal Fish          |Health & Beauty|316       |₦9.1 billion |37.1%   |
|Ergonomic Steel Shoes     |Sports         |288       |₦8.8 billion |38.9%   |

**Discount Analysis by Category**

|Category       |Avg Discount per Order|Total Discounts Given|Discount Rate|
|---------------|----------------------|---------------------|-------------|
|Books & Media  |₦7,130                |₦52.0 billion        |3.7%         |
|Food & Beverage|₦7,520                |₦46.2 billion        |3.6%         |
|Health & Beauty|₦7,165                |₦41.7 billion        |3.6%         |
|Electronics    |₦7,057                |₦48.6 billion        |3.5%         |
|Sports         |₦6,557                |₦47.6 billion        |3.4%         |
|Clothing       |₦6,653                |₦41.2 billion        |3.4%         |
|Home & Garden  |₦6,492                |₦42.2 billion        |3.4%         |

**Margin by Category**

|Category       |Total Margin  |Margin %|
|---------------|--------------|--------|
|Sports         |₦372.3 billion|27.4%   |
|Electronics    |₦363.5 billion|27.1%   |
|Books & Media  |₦363.2 billion|27.0%   |
|Food & Beverage|₦320.9 billion|25.8%   |
|Automotive     |₦331.4 billion|25.3%   |
|Home & Garden  |₦301.7 billion|24.9%   |
|Health & Beauty|₦279.7 billion|24.8%   |

**Key Insights:**

- Discount rates are very consistent across all categories — ranging from 3.4% to 3.7% — suggesting a uniform discounting policy
- Sports has the highest margin percentage at 27.4% despite not having the highest discount rate
- Health & Beauty has the highest margin product — Incredible Metal Tuna at 38.6% margin
- Books & Media receives the most discounts in absolute terms but still maintains strong margins
- Products with the highest discount rates (Generic Soft Pizza at 21%, Modern Concrete Bike at 19.7%) are niche items with low revenue contribution

-----

## Question 4 — Payment Channel Insights

### Which payment methods are used, and are there anomalies?

**Payment Method Breakdown**

|Payment Method|Provider         |Digital|Transactions|Share |Total Collected|Avg Payment|Refunds|
|--------------|-----------------|-------|------------|------|---------------|-----------|-------|
|Mobile Money  |Jaskolski-Farrell|Yes    |4,016       |20.41%|₦3.27 trillion |₦813,606   |97     |
|Bank Transfer |Wehner LLC       |Yes    |3,926       |19.95%|₦3.21 trillion |₦816,633   |79     |
|Cash          |—                |No     |3,884       |19.74%|₦3.19 trillion |₦821,320   |85     |
|USSD          |Ankunding LLC    |Yes    |3,953       |20.09%|₦3.19 trillion |₦806,959   |81     |
|Card          |Schaden-Boehm    |Yes    |3,898       |19.81%|₦3.15 trillion |₦808,344   |86     |

**Key Insights:**

- Payment methods are remarkably evenly distributed — each handling approximately 20% of transactions
- Mobile Money leads with 4,016 transactions and ₦3.27 trillion collected — ranked 1st by revenue
- Cash remains a significant channel at 19.74% of transactions — showing strong offline customer base
- Digital payments (Mobile Money, Bank Transfer, USSD, Card) collectively handle 80.26% of transactions
- Mobile Money has the highest refund count (97) — possibly indicating disputes or failed delivery scenarios
- Average payment amounts are consistent across all methods — ranging from ₦807k to ₦821k
- No single payment method dominates — indicating healthy payment channel diversification

**Payment Anomalies:**

|Anomaly Type               |Count    |Amount at Risk|
|---------------------------|---------|--------------|
|Unexplained negative amount|754      |₦1,888,016    |
|Zero amount payment        |644      |₦0            |
|**Total**                  |**1,398**|**₦1,888,016**|

1,398 anomalous payments were detected and isolated in the `flagged_payments` table. These have been excluded from all revenue calculations to ensure clean reporting.

-----

## Question 5 — Operational Data Quality

### What anomalies exist in the raw data, and how are they flagged?

**Flagged Payment Anomalies**

|Reason                     |Count|Amount at Risk|
|---------------------------|-----|--------------|
|Unexplained negative amount|754  |₦1,888,016    |
|Zero amount payment        |644  |₦0            |

A total of 1,398 anomalous payment records were detected by the pipeline. These represent 6.6% of all payment records and have been quarantined in the `flagged_payments` data quality artifact. The ₦1.89 million at risk from unexplained negative payments has been flagged for compliance review.

**Order Lifecycle Health**

|Status   |Order Count|Avg Days|Min Days|Max Days|
|---------|-----------|--------|--------|--------|
|Delivered|20,895     |13 days |2 days  |24 days |
|Shipped  |6,780      |—       |—       |—       |
|Paid     |3,480      |—       |—       |—       |
|Cancelled|1,795      |—       |—       |—       |
|Pending  |1,696      |—       |—       |—       |

**Key Observations:**

- 20,895 orders have been successfully delivered — representing 60.2% of all orders
- Average delivery time is 13 days from order creation — within acceptable range
- 6,780 orders are currently in shipped status — in transit and progressing normally
- 1,795 orders were cancelled — representing 5.2% cancellation rate
- 1,696 orders remain in pending status — may require follow-up

**Inventory Data Quality**

The daily inventory snapshot reveals products with zero stock activity (opening stock = 0, stock received = 0, stock sold = 0, closing stock = 0). This indicates products that exist in the product catalogue but have had no inventory movements recorded in the pipeline period.

Additionally, a small number of products show negative stock_sold values resulting in positive closing stock — this is a data quality signal that the inventory movement categorisation for these products needs review.

**Overall Data Quality Summary**

|Check              |Issue Count|Description                              |
|-------------------|-----------|-----------------------------------------|
|Flagged payments   |1,398      |Anomalous payment records isolated       |
|Zero stock products|Multiple   |Products with no inventory activity      |
|Orders delivered   |20,895     |Successfully completed — pipeline working|
|dbt tests          |All passing|not_null, unique, relationship tests pass|

**Key Insight:** The data platform is functioning correctly. The dbt test suite — covering not_null, unique, relationships, and accepted_values tests across all 11 warehouse tables — passes without errors, confirming data integrity across the entire pipeline.

-----

## Summary of Key Findings

1. **Revenue is growing rapidly** — from under ₦1 million per category in May 2024 to over ₦300 billion per category by April 2026
1. **All customer segments are equally engaged** — purchasing 6.8 to 7.1 times per customer with similar order values around ₦620,000 to ₦645,000
1. **Discounting is uniform and controlled** — 3.4% to 3.7% across all categories with no evidence of excessive discounting harming margins
1. **Payment channels are well diversified** — Mobile Money leads but no single method dominates; 80% of transactions are digital
1. **Data quality is monitored and controlled** — 1,398 anomalous payments detected and quarantined; dbt tests confirm warehouse integrity


