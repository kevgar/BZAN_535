use rmee_dh;
SELECT jt.basket_id, sum(jt.sales_value) as sales
, max(case when jp.department='PRODUCE' then 1 else 0 end) Produce
, max(case when jp.commodity_desc='SOFT DRINKS' then 1 else 0 end) softdrink 
FROM journey_transaction_data jt JOIN journey_product jp 
ON jt.product_id=jp.product_id
WHERE jp.department NOT IN ('KIOSK-GAS', 'MISC SALES TRAN')
GROUP BY basket_id;