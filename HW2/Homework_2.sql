use rmee_dh;

/*
1. CARBO: Using the dh carbo data, compute dollar sales per store for pasta
sauce and separately the dollar sales for pasta.
a) Present the SQL query you used for this calculation.
b) Using JMP’s Graph Builder, create side-by-side box plots of these totals per
store, separated by geography. (You will have 4 box plots.) Copy the graph
and comment on what insights this graph provides.
*/

select t1.dollar_sales_pasta_sauce, t2.dollar_sales_pasta, t1.store, t1.geography
from 
	# dollar sales per store for pasta sauce
	(select sum(ct.dollar_sales*ct.units) as dollar_sales_pasta_sauce, ct.store, ct.geography, cpl.commodity
	from carbo_transactions as ct 
    join carbo_product_lookup cpl 
    on ct.upc=cpl.upc
	where cpl.commodity = 'pasta sauce'
	group by ct.store) as t1
    
    join
    # dollar sales per store for pasta
	(select sum(ct.dollar_sales*ct.units) as dollar_sales_pasta_sauce, ct.store, ct.geography, cpl.commodity
	from carbo_transactions as ct 
    join carbo_product_lookup cpl 
    on ct.upc=cpl.upc
	where cpl.commodity = 'pasta'
	group by ct.store) as t2
    
where t1.store = t2.store and t1.geography = t2.geography;

#--------------------------------------

select t1.dollar_sales_pasta_sauce, t2.dollar_sales_pasta, t1.store, t1.geography
from 
	# dollar sales per store for pasta sauce
	(select sum(dollar_sales*units) as dollar_sales_pasta_sauce, store, geography
	from carbo_transactions
	where upc IN (select distinct upc from carbo_product_lookup where commodity = 'pasta sauce')
	group by store) as t1 join
    # dollar sales per store for pasta
	(select sum(dollar_sales*units) as dollar_sales_pasta, store, geography
	from carbo_transactions
	where upc IN (select distinct upc from carbo_product_lookup where commodity = 'pasta')
	group by store) as t2
on t1.store = t2.store and t1.geography = t2.geography;

# select distinct upc from carbo_product_lookup where commodity = 'pasta sauce';
# select distinct upc from carbo_product_lookup where commodity = 'pasta';
# select distinct geography from carbo_transactions;
# select distinct store from carbo_transactions;

# Part a
use rmee_sqlbook;
SELECT zc.zipcode, longitude, latitude, numords
, (CASE WHEN hh = 0 THEN 0.0 ELSE numords*1000/hh END) as penetration
FROM zipcensus zc 
JOIN (SELECT zipcode, COUNT(*) as numords
from orders
group by zipcode) o
ON zc.zipcode = o.zipcode;

# Part b
select t1.scf, ifnull(numords,0) as numords
, ifnull((CASE WHEN sum_hh = 0 THEN 0.0 ELSE numords*1000/sum_hh END),0) as penetration
from (select sum(hh) as sum_hh, left(zipcode,3) as scf
from zipcensus group by scf) t1
left join (select LEFT(zipcode,3) as scf, COUNT(*) as numords FROM orders GROUP BY LEFT(zipcode,3)) t2
on t1.scf=t2.scf;

#Part c
select t1.state, ifnull(numords,0) as numords
, ifnull((CASE WHEN sum_hh = 0 THEN 0.0 ELSE numords*1000/sum_hh END),0) as penetration
from (select sum(hh) as sum_hh, state from zipcensus group by state) t1
left join (select state, COUNT(*) as numords FROM orders GROUP BY state) t2
on t1.state=t2.state;

