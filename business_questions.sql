USE magist;
-----------3.1.--  1.What categories of tech products does Magist have?
SELECT 
		product_category_name_english
	FROM
		products AS p
			LEFT JOIN
		product_category_name_translation AS translation ON p.product_category_name = translation.product_category_name
	GROUP BY product_category_name_english;
    
  --------- 3.1---  2.What’s the average price of the products being sold?-(filled)-----------------------
        SELECT AVG(price)
          FROM order_items;
          --------OR----
          SELECT ROUND(AVG(price),2) AS 'medium price'
FROM order_items;
          
          
---------3.1--- 3. How many products of these tech categories have been sold (within the time window of the database snapshot)? 
    What percentage does that represent from the overall number of products sold?---(filled )---------------------------------------
    
    SELECT 
    CASE
        WHEN
            t.product_category_name_english IN ('computers_accessories' , 
                'telephony',
                'electronics',
                'consoles_games',
                'audio',
                'computers',
                'tablets_printing_image',
                'pc_gamer')
        THEN
            'tech'
        ELSE 'no_tech'
    END AS 'tech_product',
    COUNT(o.product_id) AS 'total_sales',
    ROUND(100 * COUNT(o.product_id) / (SELECT 
                    COUNT(product_id)
                FROM
                    order_items)) AS 'percent of sales'
FROM
    order_items AS o
        LEFT JOIN
    products AS p USING (product_id)
        LEFT JOIN
    product_category_name_translation AS t USING (product_category_name)
GROUP BY tech_product;


 ------------------- 4.  Are expensive tech products popular?-----(filled)--------
        
        SELECT 
        transl.product_category_name_english AS category,
        COUNT(product_category_name_english) AS n_sold,
        ROUND(AVG(oi.price)) AS avg_price,
        CASE
            WHEN ROUND(AVG(oi.price))  > 500 THEN 'expensive'
            ELSE 'cheap'
        END AS sub_category
    FROM
        order_items AS oi
            LEFT JOIN
        products AS p ON p.product_id = oi.product_id
            LEFT JOIN
        orders AS o ON o.order_id = oi.order_id
            LEFT JOIN
        product_category_name_translation AS transl ON p.product_category_name = transl.product_category_name
    WHERE
        product_category_name_english IN ('computers_accessories' , 
                'telephony',
                'electronics',
                'consoles_games',
                'audio',
                'computers',
                'tablets_printing_image',
                'pc_gamer')
            AND o.order_status IN ('delivered' , 'shipped', 'approved')
    GROUP BY category
    ORDER BY n_sold DESC;
        
        
-----------------------------############################################################################------------------------------------------------------------            
								------------------------  3.2. In relation to the sellers:------------------
----------- 1 How many months of data are included in the magist database?     -------------

    select MIN(order_purchase_timestamp),
    MAX(order_purchase_timestamp)
    from orders ;
   
 -----------2.--How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers? ( filled)

SELECT 
    (SELECT 
            COUNT(DISTINCT seller_id)
        FROM
            sellers) AS 'total_sellers',
    (SELECT 
            COUNT(DISTINCT s.seller_id)
        FROM
            sellers AS s
                LEFT JOIN
            order_items AS o USING (seller_id)
                LEFT JOIN
            products AS p USING (product_id)
                LEFT JOIN
            product_category_name_translation AS t USING (product_category_name)
        WHERE
            t.product_category_name_english IN ('computers_accessories' , 'telephony',
                'electronics',
                'consoles_games',
                'audio',
                'computers',
                'tablets_printing_image',
                'pc_gamer')) AS 'tech_sellers',
    ROUND(100 * (SELECT (tech_sellers)) / (SELECT (total_sellers))) AS 'percentage';
    --------------------3.--- .What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?-------------------------------------------------------------

SELECT 
    ROUND(AVG(AVG_per_month), 2)
FROM
    (SELECT 
        ROUND(SUM(oi.price) / COUNT(DISTINCT s.seller_id), 2) AS 'AVG_per_month'
    FROM
        sellers AS s
    LEFT JOIN order_items AS oi USING (seller_id)
    LEFT JOIN orders AS o USING (order_id)
    LEFT JOIN products AS p USING (product_id)
    LEFT JOIN product_category_name_translation AS t USING (product_category_name)
    WHERE
        t.product_category_name_english IN ('computers_accessories' , 'telephony', 'electronics', 'consoles_games', 'audio', 'computers', 'tablets_printing_image', 'pc_gamer')
    GROUP BY EXTRACT(YEAR_MONTH FROM o.order_purchase_timestamp)) PerMonthTable;
 
 
 ------------ OR------------------------
SELECT 
    ROUND(AVG(AVG_per_month), 2)
FROM
    (SELECT 
        ROUND(SUM(oi.price) / COUNT(DISTINCT s.seller_id), 2) AS 'AVG_per_month'
    FROM
        sellers AS s
    LEFT JOIN order_items AS oi USING (seller_id)
    LEFT JOIN orders AS o USING (order_id)
    GROUP BY EXTRACT(YEAR_MONTH FROM o.order_purchase_timestamp)) PerMonthTable;
    
    
   

----------------------4 Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

select sum(payment_value) 
from order_payments as op 
left join order_items as oi on op.order_id = oi.order_id 
right join products on products.product_id = oi.product_id
  where product_category_name in('tablets_impressao_imagem', 'informatica_acessorios', 'pcs', 'pc_gamer', 'telefonia', 'audio');
----------------OR---------------

SELECT 
    SUM(payment_value)
FROM
    order_payments AS op
        LEFT JOIN
    order_items AS oi ON op.order_id = oi.order_id
        RIGHT JOIN
    products ON products.product_id = oi.product_id
WHERE
    product_category_name IN ('tablets_impressao_imagem' , 'informatica_acessorios',
        'pcs',
        'pc_gamer',
        'telefonia',
        'audio');
        
 
 SELECT 
    SizeTable.size,
    SUM(CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1
        ELSE 0
    END) AS 'on_time_delivery',
    SUM(CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
        ELSE 0
    END) AS 'delayed_delivery',
    SUM(CASE
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 0
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 0
        ELSE 1
    END) AS 'no_delivery',
    ROUND(100 * SUM(CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
                ELSE 0
            END) / (SUM(CASE
                WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 1
                ELSE 0
            END) + SUM(CASE
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
                ELSE 0
            END)),
            2) AS '%_delayed'
FROM
    orders AS o
        LEFT JOIN
    order_items AS oi USING (order_id)
        LEFT JOIN
    (SELECT 
        product_id,
            CASE
                WHEN
                    product_weight_g > 2000
                        OR product_length_cm > 50
                        OR product_height_cm > 50
                        OR product_width_cm > 50
                THEN
                    'big'
                ELSE 'small'
            END AS 'size'
    FROM
        products) SizeTable USING (product_id)
GROUP BY SizeTable.size
HAVING SizeTable.size IN ('small' , 'big');

-----OR------------------
SELECT 
sum(payment_value), YEAR(order_purchase_timestamp) AS y, MONTH(order_purchase_timestamp) AS m
FROM
order_payments
    Left join
order_items on order_items.order_id = order_payments.order_id
        RIGHT JOIN
orders ON order_items.order_id = orders.order_id
group by y, m 
order by y, m, sum(payment_value);
-----OR------
SELECT
    date_format(shipping_limit_date, "%Y-%m") as shipping_month, ROUND(sum(o_i.price)) AS average_monthly_income
FROM
    order_items AS o_i
        LEFT JOIN
    products AS p USING (product_id)
WHERE
    p.product_category_name IN ('audio' , 'pcs',
        'telefonia',
        'informatica_acessorios',
        'consoles_games',
        'pc_gamer',
        'tablets_impressao_imagem',
        'eletronicos')
GROUP BY
    shipping_month
ORDER BY shipping_month ASC;

