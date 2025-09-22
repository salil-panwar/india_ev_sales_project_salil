SELECT *
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]

--1 pivoting by vehicle class and total sales code
SELECT
state_name,
vehicle_class,
SUM (ev_sales_quantity) AS total_ev_sales_per_state
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
GROUP BY state_name, vehicle_class
ORDER BY state_name ASC, total_ev_sales_per_state DESC
--1 pivoting by vehicle class and total sales code
--2 pivoting based on sale per year for each state
SELECT *
FROM(
SELECT years, state_name, ev_sales_quantity
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS source_table
PIVOT(
SUM(ev_sales_quantity)
FOR years IN ([2014],[2015],[2016],[2017],[2018],[2019],[2020],[2021],[2022],[2023])
)AS pivot_table
ORDER BY state_name;
--2 pivoting based on sale per year for each state
--3 pivoting based on sum of all vehicles per vehicle categories per state
SELECT *
FROM(
SELECT state_name, vehicle_category, ev_sales_quantity
FROM[ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS source_table
PIVOT(
SUM(ev_sales_quantity)
FOR vehicle_category IN ([Others],[Bus],[2-Wheelers],[4-Wheelers],[3-Wheelers])
) AS pivot_vehiclecategory_evsalesquantity
ORDER BY state_name;

--3 pivoting based on sum of all vehicles per vehicle categories per state

--4 Dynamic pivot of ev sales by state per year

DECLARE @total_per_sate_per_year NVARCHAR(MAX),
@no_of_years NVARCHAR(MAX),
@new_pivot_table_per_state_per_year NVARCHAR(MAX);
--Get sum of all years of sales into one column dynamically
SELECT @total_per_sate_per_year = STRING_AGG(QUOTENAME(years), '+') 
FROM 
( SELECT DISTINCT years
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS sum_of_years;
--Get all the years inserted dynamically into columns
SELECT @no_of_years = STRING_AGG(QUOTENAME(years), ',')
FROM(
SELECT DISTINCT years
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS aggregated_years;
--Create Dynamic SQL pivot as new_pivot_table_per_state_per_year
SET @new_pivot_table_per_state_per_year =
'
SELECT state_name , ' + @no_of_years + ' , ' + @total_per_sate_per_year + ' AS sum_of_all_years_sales
FROM
(SELECT state_name,
years,
ev_sales_quantity
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS primary_table_for_pivot
PIVOT(
SUM(ev_sales_quantity) FOR years IN (' +@no_of_years+ ')
) AS pivoted_table
ORDER BY state_name;
';
EXEC sp_executesql @new_pivot_table_per_state_per_year

--4 Dynamic pivot of ev sales by state per year

--5 Dynamic pivot of ev sales per state per vehicle types

DECLARE 
@total_vehicle_sales_alltypes NVARCHAR(MAX),
@vehicle_types NVARCHAR(MAX),
@pivoted_table_statewise NVARCHAR(MAX)

SELECT @total_vehicle_sales_alltypes = STRING_AGG('ISNULL(' + QUOTENAME(vehicle_type) + ', 0)', ' + ')
FROM(
    SELECT DISTINCT vehicle_type
    FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS vehicles_aggregated

SELECT @vehicle_types = STRING_AGG(QUOTENAME(vehicle_type), ',')
FROM(
SELECT DISTINCT vehicle_type
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS vehicle_types_aggregated;

SET @pivoted_table_statewise = 
'
SELECT state_name, ' + @vehicle_types + ' , ' + @total_vehicle_sales_alltypes + ' AS total_sales
FROM(
SELECT state_name, vehicle_type, ev_sales_quantity
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS primary_table
PIVOT
( SUM(ev_sales_quantity) FOR vehicle_type IN (' + @vehicle_types + ')
) AS pivoted_table
ORDER BY state_name;
'
EXEC sp_executesql @pivoted_table_statewise

--5 Dynamic pivot of ev sales per state per vehicle types

--6 Dynamic pivot of yearly ev sales based on vehicle category

DECLARE @vehicle_sales_yearly NVARCHAR(MAX) , @total_vehicle_sales NVARCHAR(MAX) , @pivot_table_vehicle_type NVARCHAR(MAX)

SELECT @vehicle_sales_yearly = STRING_AGG(QUOTENAME(years), ',')
FROM
(
SELECT DISTINCT years
FROM [ev_sales_india_project].dbo.ev_sales_statewise_india
) AS years_aggregated_for_pivot;

SELECT @total_vehicle_sales = STRING_AGG(QUOTENAME(years), '+')
FROM
(SELECT DISTINCT years
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS total_years_aggregated

SET @pivot_table_vehicle_type ='
SELECT vehicle_category , ' + @vehicle_sales_yearly + ' , ' + @total_vehicle_sales+ ' AS total_vehicle_sales
FROM
(
SELECT 
vehicle_category, 
years, 
ev_sales_quantity
FROM [ev_sales_india_project].dbo.[ev_sales_statewise_india]
) AS primary_source_table
PIVOT
( SUM(ev_sales_quantity) FOR years IN (' + @vehicle_sales_yearly+ ')
) AS pivoted_table
ORDER BY vehicle_category;
';
EXEC sp_executesql @pivot_table_vehicle_type
--6 Dynamic pivot of yearly ev sales based on vehicle category
