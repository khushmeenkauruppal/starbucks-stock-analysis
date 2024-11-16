-- Create table
CREATE TABLE sbux_stock_data (
    Date DATE,
    Open DECIMAL(10, 6) NULL,
    High DECIMAL(10, 6) NULL,
    Low DECIMAL(10, 6) NULL,
    Close DECIMAL(10, 6) NULL,
    Adj_Close DECIMAL(10, 6) NULL,
    Volume INT
);

-- Load data
LOAD DATA LOCAL INFILE '/Users/khushmeenuppal/Documents/portfolio-projects/sbux-stock-analysis/SBUX.csv'
INTO TABLE sbux_stock_data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS; -- this skips the haeder row

-- Data exploration
SELECT * 
FROM sbux_stock_data
ORDER BY Date DESC
LIMIT 20;

-- Null values check
SELECT 
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN Date IS NULL THEN 1 ELSE 0 END) AS Nulls_in_column1,
    SUM(CASE WHEN Open IS NULL THEN 1 ELSE 0 END) AS Nulls_in_column2,
	SUM(CASE WHEN High IS NULL THEN 1 ELSE 0 END) AS Nulls_in_column3,
    SUM(CASE WHEN Low IS NULL THEN 1 ELSE 0 END) AS Nulls_in_column4,
    SUM(CASE WHEN Close IS NULL THEN 1 ELSE 0 END) AS Nulls_in_column5,
    SUM(CASE WHEN Adj_Close IS NULL THEN 1 ELSE 0 END) AS Nulls_in_column6,
    SUM(CASE WHEN Volume IS NULL THEN 1 ELSE 0 END) AS Nulls_in_column7
FROM sbux_stock_data;

-- Duplicate values check
SELECT 
    Date, Open, High, Low, Close, Adj_Close, Volume, COUNT(*)
FROM sbux_stock_data
GROUP BY Date, Open, High, Low, Close, Adj_Close, Volume
HAVING COUNT(*) > 1;

-- Data Transformation

-- some troubleshooters while working with MySQL Workbench
SHOW VARIABLES LIKE 'local_infile'; -- it was OFF
SET GLOBAL local_infile = 1; -- Enable local_infile temporarily
SET SQL_SAFE_UPDATES = 0; -- temporarily disable safe mode
SET SQL_SAFE_UPDATES = 1; -- re-enable safe mode

ALTER TABLE sbux_stock_data
MODIFY COLUMN Volume DECIMAL(15, 6) NULL;

UPDATE sbux_stock_data
SET Volume = Volume / 1000000;

ALTER TABLE sbux_stock_data
CHANGE Volume Volume_million DECIMAL(10, 2) NULL;

DELETE FROM sbux_stock_data
WHERE DATE_FORMAT(Date, '%Y-%m') < '1992-07' OR DATE_FORMAT(Date, '%Y-%m') > '2023-11';

-- Data analysis

-- Monthly aggregation
CREATE TABLE avg_close_monthly AS
SELECT DATE_FORMAT(Date, '%Y-%m') AS Month, ROUND(AVG(Close), 2) AS Avg_Close_monthly
FROM sbux_stock_data
GROUP BY Month
ORDER BY Month;

SELECT * FROM avg_close_monthly;

-- Yearly aggregation
CREATE TABLE avg_close_yearly AS
SELECT DATE_FORMAT(Date, '%Y') AS Year, ROUND(AVG(Close), 2) AS AVG_Close_yearly
FROM sbux_stock_data
GROUP BY Year
ORDER BY Year;

SELECT * FROM avg_close_yearly;

-- Time series analysis

-- Simple Moving Average
CREATE TABLE simple_moving_avg AS
SELECT a.Date, a.Close AS Current_Close,
	(SELECT ROUND(AVG(b.Close), 2)
    FROM sbux_stock_data b
    WHERE b.Date BETWEEN DATE_SUB(a.Date, INTERVAL 6 DAY) AND a.Date) AS SMA_7,
    (SELECT ROUND(AVG(c.Close), 2)
    FROM sbux_stock_data c
    WHERE c.Date BETWEEN DATE_SUB(a.Date, INTERVAL 29 DAY) AND a.Date) AS SMA_30,
    (SELECT ROUND(AVG(d.Close), 2)
    FROM sbux_stock_data d
    WHERE d.Date BETWEEN DATE_SUB(a.Date, INTERVAL 49 DAY) AND a.Date) AS SMA_50
FROM sbux_stock_data a
ORDER BY a.Date;

SELECT * FROM simple_moving_avg;

-- Daily returns
CREATE TABLE daily_returns AS
SELECT 
    Date,
    Close AS Price_Today,
    LAG(Close) OVER (ORDER BY Date) AS Price_Yesterday,
    ROUND(((Close - LAG(Close) OVER (ORDER BY Date)) / LAG(Close) OVER (ORDER BY Date)) * 100, 2) AS Daily_Return
FROM sbux_stock_data
ORDER BY Date;

-- Volatility
CREATE TABLE volatility AS
SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS Month,
    ROUND(AVG(Daily_Return), 2) AS Avg_Return,
    ROUND(STDDEV(Daily_Return), 2) AS Volatility
FROM daily_returns
WHERE Daily_Return IS NOT NULL
GROUP BY DATE_FORMAT(Date, '%Y-%m')
ORDER BY Month;

