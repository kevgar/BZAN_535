/*
> The carbo data lists two Kroger stores in zipcode 37075. This is Hendersonville,
TN, just north of Nashville. The stores are #268 and #275.  

> a) Write a query to capture the weekly carbo sales revenue for each of these
stores. Show your query but not the resulting data. Export the data to
JMP.  
*/


use rmee_dh;

SELECT store, week, sum(dollar_sales*units) as sales_revenue FROM carbo_transactions
where store in (268,275) # 275 is old store, 268 is new store
group by store, week;