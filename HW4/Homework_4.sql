#Question 1 

/*a. Show a query that will capture all the transaction data for these upcs and stores,
aggregating the data by week, and computing the total unit sales, summed across
stores and upcs. (You may find it useful to include other columns later, but these
are not required for answering 1a.)*/
use rmee_dh;
select t3.upc, sum(t3.units), t3.week, t3.store, t3.coupon
from ( 
	select t1.upc, t1.units, t1.week, t1.store, t1.coupon
from (
	select * from carbo_transactions ct
	where ct.upc in (3620000250,3620000300,3620000350,3620000441,3620000446)
	and ct.store in (333,352,377)
    ) t1
left outer join (
	select * from carbo_causal_lookup ccl
	where ccl.upc in (3620000250,3620000300,3620000350,3620000441,3620000446)
	and ccl.store in (333,352, 377)
    ) t2
on t1.upc=t2.upc and t1.week=t2.week and t1.store=t2.store
) t3
group by t3.upc, t3.week, t3.store, t3.coupon;




/*a. Show a query that will capture all the transaction data for these upcs and stores,
aggregating the data by week, and computing the total unit sales, summed across
stores and upcs. (You may find it useful to include other columns later, but these
are not required for answering 1a.)*/
use rmee_dh;
select week, sum(units) as sum_units, sum(dollar_sales)/sum(units) as avg_price
from carbo_transactions ct
where ct.upc in (3620000250,3620000300,3620000350,3620000441,3620000446)
and ct.store in (333,352,377)
group by week;

/*b. Using the carbo_causal_lookup table, identify the 18 weeks where these upcs
appear in the interior of the weekly flyer.*/

select *
from carbo_causal_lookup
where upc in (3620000250,3620000300,3620000350,3620000441,3620000446)
and store in (333,352,377)
and feature_desc in ('Interior Page Feature','Interior Page Line Item')
group by week;





