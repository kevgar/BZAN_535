/*
a. How many brands are there for each commodity and how many UPCs are there for each commodity? 
Show the mySQL query for answering this pair of questions and report the results. 
*/ 
use rmee_sqlbook;
select commodity
, count(distinct brand) as num_brands
, count(distinct upc) as num_upcs
from rmee_dh.carbo_product_lookupq3_e
group by commodity;


use rmee_dh;
select *
from carbo_product_lookup cpl
left join carbo_transactions ct
on cpl.upc=ct.upc;