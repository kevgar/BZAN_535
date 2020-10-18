/*
1.	Determine the number of orders, the first and last shipping date, as well 
as totals for price and units sold. List the 20 products with the highest 
total dollar sales, along with their first and last order dates and number of 
orders and number of units.  How many of these top 20 selling products are 
we still selling in 2016 (the last year in the dataorders)?
*/

select productid
, count(*) as units_sold
, sum(numunits*unitprice) as total_sales
, max(billdate) as last_date
, min(billdate) as first_date
from orderline group by productid 
order by total_sales desc limit 20;

# 17 are still selling in 2016

/*
2.	Product 10361 was the best seller, product 11168 was the second-best seller, 
while product 11196 has had a very long life cycle.  For each of these three products, 
report by year the number of units sold and the average per unit price.  Comment on what 
this reveals about the pattern of sales for popular items.
*/

select productid
, sum(numunits) as total_units
, extract(year from billdate) as year_sold
, avg(unitprice) as mean_unitprice
from orderline 
where productid IN ('10361','11168','11196')
group by year_sold, productid
order by productid, year_sold;


/*
3.	Compute monthly sales totals for this business over the eight years.  Append to this 
the best selling product each month and what % of monthly sales are from this one item.  
Discuss what you learn.  Show output only for 2009 and 2016, but you should examine all 8 
years.
*/


select t1.sales_year, t1.sales_month, t1.total_sales
, t2.productid, t2.maxsales, (t2.maxsales/t1.total_sales)*100 as percent_sales
# Monthly sales totals for business
from (
	select billdate
    , month(billdate) as sales_month
	, year(billdate) as sales_year
	, sum(totalprice) as total_sales
	from orderline
	group by month(billdate), year(billdate)
) as t1

# Monthly sales totals for best selling product
, (
	select billdate
    , month(billdate) as sales_month
	, year(billdate) as sales_year
    , productid
    , max(totalprice_sum) as maxsales
	from (
		select billdate
        , month(billdate) as sales_month
        , year(billdate) as sales_year
        , productid
        , sum(totalprice) as totalprice_sum 
		from orderline
		group by sales_month, sales_year, productid
        order by  sales_year, sales_month, totalprice_sum
	) as a group by sales_month, sales_year
) as t2

where t1.sales_month = t2.sales_month
	and t1.sales_year = t2.sales_year
order by t1.sales_year,t1.sales_month;


/*4.	Order date appears in the orders table while shipping date appears in orderline.  
We should be concerned about delays in shipping.  Join these tables and identify the 
largest shipping delays.  Show the 10 worst cases.
*/
select t1.orderid, t1.orderdate, t2.shipdate
, datediff(t2.shipdate, t1.orderdate) as delay
from orders as t1 join orderline as t2
on t1.orderid = t2.orderid
order by delay desc
limit 10;

#order by delay desc
#limit 10;

#195,158,155,74,74,73,72,72,70,57


/*5.	Extra credit: Choose one item that has encountered serious shipping delays.  
Investigate whether this is a problem that arose at a single point in time, presumably 
due to a stockout, or whether it has been a repeated problem.  Set a standard shipping 
time and determine the % of orders exceeding that time period by month.
*/




