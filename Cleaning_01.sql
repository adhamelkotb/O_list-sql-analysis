-- cleaning section


--  NULL Values Check in "orders" Table
-- We are validating critical columns for data quality.
-- Key Points:
-- 1. Essential columns like order_id, order_status, and order_purchase_timestamp
--    must never be NULL for any order.
-- 2. Timestamp columns related to delivery (approved, carrier, customer, estimated)
--    are expected to be NOT NULL only when the order_status is 'delivered'.
-- 3. Therefore, filtering for 'delivered' orders is applied only to delivery-related columns.
-- This helps ensure that missing data is evaluated in context, improving data accuracy for analysis.
SELECT 
    COUNT(*) FILTER (WHERE order_id IS NULL) AS order_id_nulls,
    COUNT(*) FILTER (WHERE order_status IS NULL) AS order_status_nulls,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS order_purchase_timestamp_nulls,
   COUNT(*) FILTER (WHERE order_approved_at IS NULL And order_status = 'delivered') AS order_approved_at_nulls,
   COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL And order_status = 'delivered') AS order_delivered_carrier_date_nulls,
   COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL And order_status = 'delivered') AS order_delivered_customer_date_nulls,
   COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL And order_status = 'delivered') AS order_estimated_delivery_date_nulls
FROM orders;
  

-- Removed 1 inconsistent delivered order (missing carrier date)
-- Deleted from both orders and order_items to preserve data integrity
SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NULL;

DELETE FROM order_items
WHERE order_id = '2aa91108853cecb43c84a5dc5b277475';

DELETE FROM orders
WHERE order_id = '2aa91108853cecb43c84a5dc5b277475';

-- Removed one 'delivered' order with no carrier or customer delivery dates.
-- This entry lacked delivery confirmation and could skew delivery-related analysis.

SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS  NULL
  AND order_delivered_carrier_date IS NULL;

  DELETE FROM order_items
WHERE order_id = '2d858f451373b04fb5c984a1cc2defaf';

DELETE FROM orders
WHERE order_id = '2d858f451373b04fb5c984a1cc2defaf';

-- Orders missing only one delivery date (either carrier or customer) were removed to prevent skewing delivery-related KPIs.
-- Orders missing both delivery dates were retained, but flagged for future data quality and anomaly analysis.

SELECT *
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS  NULL
  AND order_delivered_carrier_date IS NOT NULL;


-- Step 1: Detect ZIP codes with unwanted whitespace (leading/trailing spaces)
SELECT 
    LENGTH(customer_zip_code_prefix::TEXT) AS LEN_ZIP, 
    LENGTH(TRIM(customer_zip_code_prefix::TEXT)) AS trimmed_length
FROM customers
WHERE LENGTH(customer_zip_code_prefix::TEXT) <> LENGTH(TRIM(customer_zip_code_prefix::TEXT));

-- Step 2: Convert customer_zip_code_prefix from INTEGER to TEXT
-- This allows us to safely apply string-based functions such as LPAD and LIKE
ALTER TABLE customers
ALTER COLUMN customer_zip_code_prefix TYPE TEXT;

-- Step 3: Pad ZIP codes of length 4 with a leading zero
-- This corrects cases where leading zeros were dropped due to the column previously being of type INTEGER
UPDATE customers 
SET customer_zip_code_prefix = LPAD(customer_zip_code_prefix, 5, '0')
WHERE LENGTH(customer_zip_code_prefix) = 4;

-- Step 4: Verify that ZIP codes now correctly start with 0 where appropriate
-- This helps ensure data consistency and correctness, especially for matching against geolocation data

SELECT DISTINCT customer_zip_code_prefix
FROM customers
WHERE customer_zip_code_prefix LIKE '0%';


-- Checked for inconsistencies in 'order_status' (spaces, case sensitivity) — all values are clean

select DISTINCT order_status
from orders

SELECT order_status, COUNT(*) AS num_orders
FROM orders
GROUP BY order_status
ORDER BY num_orders DESC;


-- Identify orders with illogical delivery dates (customer received before carrier).
SELECT order_id, 
       order_delivered_customer_date, 
       order_delivered_carrier_date,
	   order_delivered_customer_date - order_delivered_carrier_date AS days_diff
FROM orders
WHERE order_delivered_customer_date < order_delivered_carrier_date
  AND order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL;


-- Check for seller zip codes that are shorter than 5 digits
SELECT DISTINCT seller_zip_code_prefix
FROM sellers	
WHERE LENGTH(seller_zip_code_prefix) < 5;

-- Convert seller zip code column to TEXT to allow padding with leading zeros
ALTER TABLE sellers
ALTER COLUMN seller_zip_code_prefix TYPE TEXT;

-- Pad 4-digit seller zip codes with a leading zero to make them 5-digit
UPDATE sellers 
SET seller_zip_code_prefix = LPAD(seller_zip_code_prefix, 5, '0')
WHERE LENGTH(seller_zip_code_prefix) = 4;

-- Check for products with missing category names (NULL values)
SELECT COALESCE(product_category_name, 'unknown')
FROM products
WHERE product_category_name IS NULL;

-- Replace NULL product categories with 'unknown'
UPDATE products 
SET product_category_name = 'unknown'
WHERE product_category_name IS NULL;

-- Check for geolocation zip codes that are shorter than 5 digits
SELECT DISTINCT geolocation_zip_code_prefix
FROM geolocation	
WHERE LENGTH(geolocation_zip_code_prefix::TEXT) < 5;

-- Convert geolocation zip code column to TEXT for padding
ALTER TABLE geolocation
ALTER COLUMN geolocation_zip_code_prefix TYPE TEXT;

-- Pad 4-digit geolocation zip codes with a leading zero
UPDATE geolocation 
SET geolocation_zip_code_prefix = LPAD(geolocation_zip_code_prefix, 5, '0')
WHERE LENGTH(geolocation_zip_code_prefix) = 4;

-- Check for any negative payment values (possible errors or refunds)
SELECT payment_value
FROM payments
WHERE payment_value < 0;


-- Check for any order items with negative freight value (invalid shipping cost)
SELECT *
FROM order_items
WHERE freight_value < 0;


-- Checked for NULLs in seller_id and product_id in order_items; no action needed.
-- Checked for NULLs or duplicates in customer_id in customers table; no action needed.
-- Checked for NULLs in payment_type, payment_installments, and payment_value; no action needed.
-- Checked for unrealistic payment_installments values (e.g. negative or >24); no action needed.
-- Checked for duplicate rows in reviews table based on review_id and order_id; no action needed.
-- Checked for NULLs and duplicates in geolocation coordinates; no action needed.
-- Checked for NULLs in product_id and category name in products table; only handled NULL category.
-- Checked for unrealistic freight_value above normal range; all within expected distribution.
-- Checked for logical inconsistencies in order_dates (e.g. delivered before purchase); handled separately.
-- Checked for duplicate sellers or missing seller_ids; no issues found.
