/* Quick validation checks after build */

SELECT 'dim_location null PK' AS CheckName, COUNT(*) AS RowCount
FROM dbo.dim_location
WHERE LocationID IS NULL
UNION ALL
SELECT 'dim_properties null PK', COUNT(*)
FROM dbo.dim_properties
WHERE PropertyID IS NULL
UNION ALL
SELECT 'fact_sales null PropertyID', COUNT(*)
FROM dbo.fact_perth_property_sales
WHERE PropertyID IS NULL
UNION ALL
SELECT 'fact_sales null DateID', COUNT(*)
FROM dbo.fact_perth_property_sales
WHERE DateID IS NULL;
GO

SELECT PropertyID, COUNT(*) AS DuplicateCount
FROM dbo.dim_properties
GROUP BY PropertyID
HAVING COUNT(*) > 1;
GO

SELECT s.PropertyID
FROM dbo.fact_perth_property_sales s
LEFT JOIN dbo.dim_properties p ON s.PropertyID = p.PropertyID
WHERE p.PropertyID IS NULL;
GO

SELECT s.LocationID
FROM dbo.fact_perth_property_sales s
LEFT JOIN dbo.dim_location l ON s.LocationID = l.LocationID
WHERE l.LocationID IS NULL;
GO

SELECT a.SA2Code
FROM dbo.fact_aus_population_area a
LEFT JOIN dbo.dim_sa2 s ON a.SA2Code = s.SA2Code
WHERE s.SA2Code IS NULL;
GO

SELECT g.GCCSACode
FROM dbo.fact_population_gccsa g
LEFT JOIN dbo.dim_gccsa d ON g.GCCSACode = d.GCCSACode
WHERE d.GCCSACode IS NULL;
GO
